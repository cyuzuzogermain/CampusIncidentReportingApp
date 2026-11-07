import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/verify_email/verify_email_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';
import 'auth_scaffold.dart';

/// Shown to a signed-in user whose ALU email isn't verified yet. The router
/// keeps them here until it is.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VerifyEmailCubit(
        context.read<AuthRepository>(),
        checkVerified: context.read<AuthCubit>().checkEmailVerified,
      ),
      child: const _VerifyEmailView(),
    );
  }
}

class _VerifyEmailView extends StatelessWidget {
  const _VerifyEmailView();

  @override
  Widget build(BuildContext context) {
    final email = context.select((AuthCubit cubit) => cubit.state.email) ?? '';

    return BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
      listenWhen: (previous, current) =>
          current.message != null && current.message != previous.message,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.message!)));
      },
      builder: (context, state) {
        final cubit = context.read<VerifyEmailCubit>();
        return AuthScaffold(
          title: 'Verify your email',
          subtitle:
              'Open the link we sent you to finish setting up your '
              'account.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verification email sent to',
                            style: AppTextStyles.bodySecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(email, style: AppTextStyles.cardTitle),
                          const SizedBox(height: 4),
                          const Text(
                            'Can’t find it? Check your spam folder.',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'I’ve verified',
                icon: Icons.verified_outlined,
                isLoading: state.isChecking,
                onPressed: state.isBusy ? null : cubit.checkVerified,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.canResend ? cubit.resend : null,
                icon: state.isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  state.cooldownSeconds > 0
                      ? 'Resend email (${state.cooldownSeconds}s)'
                      : 'Resend email',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: state.isBusy
                    ? null
                    : () => context.read<AuthCubit>().signOut(),
                child: const Text('Use another account'),
              ),
            ],
          ),
        );
      },
    );
  }
}
