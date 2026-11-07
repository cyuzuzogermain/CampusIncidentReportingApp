part of 'auth_cubit.dart';

enum AuthStatus { unknown, unverified, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.user,
    this._unverifiedEmail,
    this.errorMessage,
  });

  /// Before the first auth event, or while the profile is loading.
  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  /// Signed in with an ALU email that hasn't been verified yet.
  const AuthState.unverified(String email)
    : this._(status: AuthStatus.unverified, unverifiedEmail: email);

  const AuthState.authenticated(AppUser user)
    : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated({String? errorMessage})
    : this._(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  final AuthStatus status;

  /// The signed-in user's profile, including their role.
  final AppUser? user;

  final String? _unverifiedEmail;

  /// Why the session ended, for example a missing profile.
  final String? errorMessage;

  /// The signed-in account's email, also known before it is verified.
  String? get email => user?.email ?? _unverifiedEmail;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnverified => status == AuthStatus.unverified;
  bool get isStaff => user?.isStaff ?? false;

  @override
  List<Object?> get props => [status, user, _unverifiedEmail, errorMessage];
}
