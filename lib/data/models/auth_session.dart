import 'package:equatable/equatable.dart';

/// The signed-in Firebase Auth account, without any Firebase types: who it
/// is and whether its email address has been verified.
class AuthSession extends Equatable {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });

  final String uid;
  final String email;
  final bool emailVerified;

  @override
  List<Object?> get props => [uid, email, emailVerified];
}
