import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/auth_form/auth_form_cubit.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'auth_scaffold.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthFormCubit(context.read<AuthRepository>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Show a session error (e.g. a missing profile) that sent us back here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authCubit = context.read<AuthCubit>();
      final message = authCubit.state.errorMessage;
      if (message != null) {
        _showError(message);
        authCubit.clearError();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthFormCubit>().signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthFormCubit, AuthFormState>(
          listenWhen: (previous, current) =>
              current.status == AuthFormStatus.failure,
          listener: (context, state) => _showError(state.errorMessage!),
        ),
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              current.errorMessage != null &&
              current.errorMessage != previous.errorMessage,
          listener: (context, state) {
            _showError(state.errorMessage!);
            context.read<AuthCubit>().clearError();
          },
        ),
      ],
      child: AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in to report and track campus issues',
        child: BlocBuilder<AuthFormCubit, AuthFormState>(
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Email',
                      hint: 'you@university.edu',
                      controller: _emailController,
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: Validators.password,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: state.isBusy
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Sign In',
                      isLoading: state.isBusy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: AppTextStyles.bodySecondary,
                        ),
                        TextButton(
                          onPressed: state.isBusy
                              ? null
                              : () => context.go(AppRoutes.signUp),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
