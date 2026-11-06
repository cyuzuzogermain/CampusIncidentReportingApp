import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_form_state.dart';

/// Submits the login, sign-up and forgot-password forms.
///
/// Once sign-in or sign-up succeeds, [AuthCubit] picks up the new session and
/// the router redirects, so this cubit only tracks the submission itself.
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit(this._authRepository) : super(const AuthFormState());

  final AuthRepository _authRepository;

  Future<void> signIn({required String email, required String password}) =>
      _run(() => _authRepository.signIn(email: email, password: password));

  Future<void> signUp({
    required String name,
    required String email,
    required String department,
    required String password,
  }) => _run(
    () => _authRepository.signUp(
      name: name,
      email: email,
      department: department,
      password: password,
    ),
  );

  Future<void> sendPasswordReset(String email) =>
      _run(() => _authRepository.sendPasswordReset(email));

  Future<void> _run(Future<void> Function() action) async {
    if (state.isSubmitting) return;
    emit(const AuthFormState(status: AuthFormStatus.submitting));
    try {
      await action();
      // The router may already have closed this screen (and this cubit) once
      // the new session arrived.
      if (isClosed) return;
      emit(const AuthFormState(status: AuthFormStatus.success));
    } catch (error) {
      if (isClosed) return;
      emit(
        AuthFormState(
          status: AuthFormStatus.failure,
          errorMessage: AppException.from(error).message,
        ),
      );
    }
  }
}
