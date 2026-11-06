part of 'auth_form_cubit.dart';

enum AuthFormStatus { initial, submitting, success, failure }

class AuthFormState extends Equatable {
  const AuthFormState({
    this.status = AuthFormStatus.initial,
    this.errorMessage,
  });

  final AuthFormStatus status;
  final String? errorMessage;

  bool get isSubmitting => status == AuthFormStatus.submitting;

  /// True while submitting, and after a successful sign-in or sign-up until
  /// the router moves on, so the button keeps its spinner.
  bool get isBusy => isSubmitting || status == AuthFormStatus.success;

  @override
  List<Object?> get props => [status, errorMessage];
}
