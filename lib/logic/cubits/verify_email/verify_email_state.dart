part of 'verify_email_cubit.dart';

class VerifyEmailState extends Equatable {
  const VerifyEmailState({
    this.cooldownSeconds = 0,
    this.isSending = false,
    this.isChecking = false,
    this.message,
  });

  /// Seconds left before another verification email can be sent.
  final int cooldownSeconds;

  /// Sending a verification email.
  final bool isSending;

  /// Reloading the account to see whether the email is verified.
  final bool isChecking;

  /// A one-off message to show in a snack bar.
  final String? message;

  bool get isBusy => isSending || isChecking;
  bool get canResend => !isBusy && cooldownSeconds == 0;

  /// [message] is cleared unless a new one is given, so the same message can
  /// be shown again later.
  VerifyEmailState copyWith({
    int? cooldownSeconds,
    bool? isSending,
    bool? isChecking,
    String? message,
  }) {
    return VerifyEmailState(
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      isSending: isSending ?? this.isSending,
      isChecking: isChecking ?? this.isChecking,
      message: message,
    );
  }

  @override
  List<Object?> get props => [cooldownSeconds, isSending, isChecking, message];
}
