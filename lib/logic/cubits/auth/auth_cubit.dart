import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/auth_session.dart';
import '../../../data/repositories/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_state.dart';

/// Holds the session: whether someone is signed in, whether their ALU email
/// is verified, and who they are, including their role. The router reads
/// this state for its redirects.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._authRepository, {
    this.profileTimeout = const Duration(seconds: 10),
  }) : super(const AuthState.unknown()) {
    _authSubscription = _authRepository.authStateChanges().listen(
      _onSessionChanged,
    );
  }

  final AuthRepository _authRepository;

  /// How long to wait for a missing `users/{uid}` document before giving up.
  final Duration profileTimeout;

  StreamSubscription<AuthSession?>? _authSubscription;
  StreamSubscription<AppUser?>? _profileSubscription;
  Timer? _profileTimer;

  /// The account the current state was built for. Repeated events for the
  /// same account and verification status are ignored.
  AuthSession? _session;

  void _onSessionChanged(AuthSession? session) {
    if (session != null && session == _session) return;
    _session = session;
    _cancelProfileWatch();

    if (session == null) {
      // Keep a pending error (e.g. "profile not found") visible on the login
      // screen after the sign-out we triggered ourselves.
      emit(AuthState.unauthenticated(errorMessage: state.errorMessage));
      return;
    }

    // Normally stopped at login, but an older session could still be
    // signed in with another domain.
    if (!Validators.isAluEmail(session.email)) {
      _failSession(Validators.aluEmailMessage);
      return;
    }

    if (!session.emailVerified) {
      emit(AuthState.unverified(session.email));
      return;
    }

    _loadProfile(session);
  }

  Future<void> _loadProfile(AuthSession session) async {
    if (state != const AuthState.unknown()) emit(const AuthState.unknown());
    try {
      await _authRepository.ensureProfile();
    } catch (error) {
      if (_session == session) {
        await _failSession(AppException.from(error).message);
      }
      return;
    }
    // Signed out or switched account while the profile was being checked.
    if (_session != session || isClosed) return;

    _startProfileTimer();
    _profileSubscription = _authRepository
        .watchUserProfile(session.uid)
        .listen(
          (profile) {
            if (profile == null) return; // Not written yet.
            _profileTimer?.cancel();
            emit(AuthState.authenticated(profile));
          },
          onError: (Object error) {
            _failSession(AppException.from(error).message);
          },
        );
  }

  /// Reloads the account to see whether its email has been verified since.
  /// Returns `true` (and moves on to loading the profile) if it has.
  Future<bool> checkEmailVerified() async {
    final session = await _authRepository.reloadSession();
    if (session == null) return false;
    _onSessionChanged(session);
    return session.emailVerified;
  }

  void _startProfileTimer() {
    _profileTimer = Timer(profileTimeout, () {
      if (state.status == AuthStatus.unknown) {
        _failSession(
          'Your account profile could not be found. If your sign-up did not '
          'finish, sign up again with the same email and password.',
        );
      }
    });
  }

  Future<void> _failSession(String message) async {
    _cancelProfileWatch();
    _session = null;
    if (isClosed) return;
    emit(AuthState.unauthenticated(errorMessage: message));
    try {
      await _authRepository.signOut();
    } catch (_) {}
  }

  /// Signs the current user out. The router then sends them to login.
  Future<void> signOut() async {
    _cancelProfileWatch();
    _session = null;
    emit(const AuthState.unauthenticated());
    await _authRepository.signOut();
  }

  /// Clears a shown session error.
  void clearError() {
    if (state.errorMessage != null) {
      emit(AuthState.unauthenticated());
    }
  }

  void _cancelProfileWatch() {
    _profileTimer?.cancel();
    _profileTimer = null;
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelProfileWatch();
    _authSubscription?.cancel();
    return super.close();
  }
}
