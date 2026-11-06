import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../logic/cubits/auth_form/auth_form_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthFormCubit(context.read<AuthRepository>()),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthFormCubit>().sendPasswordReset(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthFormCubit, AuthFormState>(
      listenWhen: (previous, current) =>
          current.status == AuthFormStatus.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        final sent = state.status == AuthFormStatus.success;
        return AuthScaffold(
          showBackButton: true,
          title: 'Forgot password?',
          subtitle: "Enter your email and we'll send you a reset link",
          child: sent
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            color: AppColors.resolved,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'If an account exists for '
                              '${_emailController.text.trim()}, a password '
                              'reset link is on its way.',
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Back to Sign In',
                      onPressed: () => context.pop(),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'Email',
                        hint: 'you@university.edu',
                        controller: _emailController,
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: Validators.email,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'Send Reset Link',
                        isLoading: state.isSubmitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
