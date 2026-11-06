part of 'auth_cubit.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._({required this.status, this.user, this.errorMessage});

  /// Before the first auth event, or while the profile is loading.
  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.authenticated(AppUser user)
    : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated({String? errorMessage})
    : this._(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  final AuthStatus status;

  /// The signed-in user's profile, including their role.
  final AppUser? user;

  /// Why the session ended, for example a missing profile.
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isStaff => user?.isStaff ?? false;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
