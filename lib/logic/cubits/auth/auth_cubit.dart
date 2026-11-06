import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/app_user.dart';
import '../../../data/repositories/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_state.dart';

/// Holds the session: whether someone is signed in and who they are,
/// including their role. The router reads this state for its redirects.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._authRepository, {
    this.profileTimeout = const Duration(seconds: 10),
  }) : super(const AuthState.unknown()) {
    _authSubscription = _authRepository.authStateChanges().listen(
      _onUidChanged,
    );
  }

  final AuthRepository _authRepository;

  /// How long to wait for a missing `users/{uid}` document before giving up.
  final Duration profileTimeout;

  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<AppUser?>? _profileSubscription;
  Timer? _profileTimer;

  void _onUidChanged(String? uid) {
    _cancelProfileWatch();

    if (uid == null) {
      // Keep a pending error (e.g. "profile not found") visible on the login
      // screen after the sign-out we triggered ourselves.
      emit(AuthState.unauthenticated(errorMessage: state.errorMessage));
      return;
    }

    if (state != const AuthState.unknown()) emit(const AuthState.unknown());
    _startProfileTimer();
    _profileSubscription = _authRepository
        .watchUserProfile(uid)
        .listen(
          (profile) {
            if (profile == null) return; // Still being created during sign-up.
            _profileTimer?.cancel();
            emit(AuthState.authenticated(profile));
          },
          onError: (Object error) {
            _failSession(AppException.from(error).message);
          },
        );
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
    emit(AuthState.unauthenticated(errorMessage: message));
    try {
      await _authRepository.signOut();
    } catch (_) {}
  }

  /// Signs the current user out. The router then sends them to login.
  Future<void> signOut() async {
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
