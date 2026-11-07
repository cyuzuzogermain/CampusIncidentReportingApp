import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../logic/cubits/auth_form/auth_form_cubit.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'auth_scaffold.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthFormCubit(context.read<AuthRepository>()),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthFormCubit>().signUp(
      name: _nameController.text,
      email: _emailController.text,
      department: _departmentController.text,
      password: _passwordController.text,
    );
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
        return AuthScaffold(
          title: 'Create account',
          subtitle: 'Join to help make our campus safer',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Full name',
                  hint: 'e.g. Jane Doe',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  hint: 'you@alustudent.com',
                  controller: _emailController,
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.aluEmail,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Department',
                  hint: 'e.g. Computer Science',
                  controller: _departmentController,
                  prefixIcon: Icons.school_outlined,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.department,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: 'At least 6 characters',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  controller: _confirmController,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Sign Up',
                  isLoading: state.isBusy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: AppTextStyles.bodySecondary,
                    ),
                    TextButton(
                      onPressed: state.isBusy
                          ? null
                          : () => context.go(AppRoutes.login),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
