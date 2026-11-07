import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';

part 'verify_email_state.dart';

/// Drives the "Verify your email" screen: re-sending the verification email
/// (with a cooldown) and checking whether the email has been verified.
class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit(
    this._authRepository, {
    required this._checkVerified,
    this.cooldown = AppConstants.verificationResendCooldown,
  }) : super(const VerifyEmailState());

  final AuthRepository _authRepository;

  /// Reloads the account and reports whether it is verified, normally
  /// `AuthCubit.checkEmailVerified`, which also moves the session on.
  final Future<bool> Function() _checkVerified;

  /// How long to wait between verification emails.
  final Duration cooldown;

  static const String emailSentMessage =
      'Verification email sent. Check your inbox.';
  static const String notVerifiedMessage =
      'Your email isn’t verified yet. Open the link in the email, then try '
      'again.';

  Timer? _cooldownTimer;

  Future<void> resend() async {
    if (!state.canResend) return;
    emit(state.copyWith(isSending: true));
    try {
      await _authRepository.sendEmailVerification();
      if (isClosed) return;
      emit(
        state.copyWith(
          isSending: false,
          cooldownSeconds: cooldown.inSeconds,
          message: emailSentMessage,
        ),
      );
      _startCooldown();
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSending: false,
          message: AppException.from(error).message,
        ),
      );
    }
  }

  /// Checks whether the email has been verified. When it has, the session
  /// moves on and the router leaves this screen, so the spinner stays.
  Future<void> checkVerified() async {
    if (state.isBusy) return;
    emit(state.copyWith(isChecking: true));
    try {
      final verified = await _checkVerified();
      if (isClosed || verified) return;
      emit(state.copyWith(isChecking: false, message: notVerifiedMessage));
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isChecking: false,
          message: AppException.from(error).message,
        ),
      );
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.cooldownSeconds - 1;
      if (left <= 0) timer.cancel();
      emit(state.copyWith(cooldownSeconds: left < 0 ? 0 : left));
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
