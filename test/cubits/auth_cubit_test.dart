import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:campus_incident_app/data/models/app_user.dart';
import 'package:campus_incident_app/data/repositories/app_exception.dart';
import 'package:campus_incident_app/logic/cubits/auth/auth_cubit.dart';
import 'package:campus_incident_app/logic/cubits/auth_form/auth_form_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_helpers.dart';

void main() {
  late MockAuthRepository repository;
  late StreamController<String?> authController;
  late StreamController<AppUser?> profileController;

  setUp(() {
    repository = MockAuthRepository();
    authController = StreamController<String?>();
    profileController = StreamController<AppUser?>();
    when(
      () => repository.authStateChanges(),
    ).thenAnswer((_) => authController.stream);
    when(
      () => repository.watchUserProfile(any()),
    ).thenAnswer((_) => profileController.stream);
    when(() => repository.signOut()).thenAnswer((_) async {});
  });

  tearDown(() {
    authController.close();
    profileController.close();
  });

  group('AuthCubit', () {
    test('starts in the unknown state', () {
      expect(AuthCubit(repository).state, const AuthState.unknown());
    });

    blocTest<AuthCubit, AuthState>(
      'emits unauthenticated when nobody is signed in',
      build: () => AuthCubit(repository),
      act: (_) => authController.add(null),
      expect: () => [const AuthState.unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'loads the profile (with role) after sign-in',
      build: () => AuthCubit(repository),
      act: (_) async {
        authController.add(testStudent.uid);
        await Future<void>.delayed(Duration.zero);
        profileController.add(testStudent);
      },
      expect: () => [AuthState.authenticated(testStudent)],
      verify: (cubit) {
        verify(() => repository.watchUserProfile(testStudent.uid)).called(1);
        expect(cubit.state.isStaff, isFalse);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'recognises a staff profile',
      build: () => AuthCubit(repository),
      act: (_) async {
        authController.add(testStaff.uid);
        await Future<void>.delayed(Duration.zero);
        profileController.add(testStaff);
      },
      expect: () => [AuthState.authenticated(testStaff)],
      verify: (cubit) => expect(cubit.state.isStaff, isTrue),
    );

    blocTest<AuthCubit, AuthState>(
      'waits while the profile document is still being created at sign-up',
      build: () => AuthCubit(repository),
      act: (_) async {
        authController.add(testStudent.uid);
        await Future<void>.delayed(Duration.zero);
        profileController.add(null);
        await Future<void>.delayed(Duration.zero);
        profileController.add(testStudent);
      },
      expect: () => [AuthState.authenticated(testStudent)],
    );

    blocTest<AuthCubit, AuthState>(
      'signs out with an error when the profile never appears',
      build: () => AuthCubit(
        repository,
        profileTimeout: const Duration(milliseconds: 20),
      ),
      act: (_) async {
        authController.add(testStudent.uid);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      expect: () => [
        const AuthState.unauthenticated(
          errorMessage:
              'Your account profile could not be found. If your '
              'sign-up did not finish, sign up again with the same email '
              'and password.',
        ),
      ],
      verify: (_) => verify(() => repository.signOut()).called(1),
    );

    blocTest<AuthCubit, AuthState>(
      'signOut calls the repository and emits unauthenticated',
      build: () => AuthCubit(repository),
      seed: () => AuthState.authenticated(testStudent),
      act: (cubit) => cubit.signOut(),
      expect: () => [const AuthState.unauthenticated()],
      verify: (_) => verify(() => repository.signOut()).called(1),
    );
  });

  group('AuthFormCubit', () {
    blocTest<AuthFormCubit, AuthFormState>(
      'signIn emits submitting then success',
      setUp: () => when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {}),
      build: () => AuthFormCubit(repository),
      act: (cubit) => cubit.signIn(email: 'jane@uni.edu', password: 'secret1'),
      expect: () => const [
        AuthFormState(status: AuthFormStatus.submitting),
        AuthFormState(status: AuthFormStatus.success),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'signIn emits a friendly failure message',
      setUp: () => when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AppException('Incorrect email or password.')),
      build: () => AuthFormCubit(repository),
      act: (cubit) => cubit.signIn(email: 'jane@uni.edu', password: 'wrong1'),
      expect: () => const [
        AuthFormState(status: AuthFormStatus.submitting),
        AuthFormState(
          status: AuthFormStatus.failure,
          errorMessage: 'Incorrect email or password.',
        ),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'signUp passes the form fields to the repository',
      setUp: () => when(
        () => repository.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          department: any(named: 'department'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {}),
      build: () => AuthFormCubit(repository),
      act: (cubit) => cubit.signUp(
        name: 'Jane',
        email: 'jane@uni.edu',
        department: 'CS',
        password: 'secret1',
      ),
      expect: () => const [
        AuthFormState(status: AuthFormStatus.submitting),
        AuthFormState(status: AuthFormStatus.success),
      ],
      verify: (_) => verify(
        () => repository.signUp(
          name: 'Jane',
          email: 'jane@uni.edu',
          department: 'CS',
          password: 'secret1',
        ),
      ).called(1),
    );
  });
}
