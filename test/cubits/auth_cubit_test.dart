import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:campus_incident_app/data/models/app_user.dart';
import 'package:campus_incident_app/data/models/auth_session.dart';
import 'package:campus_incident_app/data/repositories/app_exception.dart';
import 'package:campus_incident_app/logic/cubits/auth/auth_cubit.dart';
import 'package:campus_incident_app/logic/cubits/auth_form/auth_form_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_helpers.dart';

AuthSession sessionFor(AppUser user, {bool verified = true}) =>
    AuthSession(uid: user.uid, email: user.email, emailVerified: verified);

void main() {
  late MockAuthRepository repository;
  late StreamController<AuthSession?> authController;
  late StreamController<AppUser?> profileController;

  setUp(() {
    repository = MockAuthRepository();
    authController = StreamController<AuthSession?>();
    profileController = StreamController<AppUser?>();
    when(
      () => repository.authStateChanges(),
    ).thenAnswer((_) => authController.stream);
    when(
      () => repository.watchUserProfile(any()),
    ).thenAnswer((_) => profileController.stream);
    when(() => repository.ensureProfile()).thenAnswer((_) async {});
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
        authController.add(sessionFor(testStudent));
        await Future<void>.delayed(Duration.zero);
        profileController.add(testStudent);
      },
      expect: () => [AuthState.authenticated(testStudent)],
      verify: (cubit) {
        verify(() => repository.ensureProfile()).called(1);
        verify(() => repository.watchUserProfile(testStudent.uid)).called(1);
        expect(cubit.state.isStaff, isFalse);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'recognises a staff profile',
      build: () => AuthCubit(repository),
      act: (_) async {
        authController.add(sessionFor(testStaff));
        await Future<void>.delayed(Duration.zero);
        profileController.add(testStaff);
      },
      expect: () => [AuthState.authenticated(testStaff)],
      verify: (cubit) => expect(cubit.state.isStaff, isTrue),
    );

    blocTest<AuthCubit, AuthState>(
      'waits while the profile document is still being written',
      build: () => AuthCubit(repository),
      act: (_) async {
        authController.add(sessionFor(testStudent));
        await Future<void>.delayed(Duration.zero);
        profileController.add(null);
        await Future<void>.delayed(Duration.zero);
        profileController.add(testStudent);
      },
      expect: () => [AuthState.authenticated(testStudent)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits unverified, without touching Firestore, until the email is '
      'verified',
      build: () => AuthCubit(repository),
      act: (_) => authController.add(sessionFor(testStudent, verified: false)),
      expect: () => [AuthState.unverified(testStudent.email)],
      verify: (cubit) {
        expect(cubit.state.email, testStudent.email);
        verifyNever(() => repository.ensureProfile());
        verifyNever(() => repository.watchUserProfile(any()));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'signs out a session whose email is not on an ALU domain',
      build: () => AuthCubit(repository),
      act: (_) => authController.add(
        const AuthSession(
          uid: 'outsider',
          email: 'someone@gmail.com',
          emailVerified: true,
        ),
      ),
      expect: () => [
        const AuthState.unauthenticated(
          errorMessage: 'Please use your ALU email address',
        ),
      ],
      verify: (_) {
        verify(() => repository.signOut()).called(1);
        verifyNever(() => repository.ensureProfile());
      },
    );

    blocTest<AuthCubit, AuthState>(
      'checkEmailVerified loads the profile once the email is verified',
      setUp: () => when(
        () => repository.reloadSession(),
      ).thenAnswer((_) async => sessionFor(testStudent)),
      build: () => AuthCubit(repository),
      act: (cubit) async {
        authController.add(sessionFor(testStudent, verified: false));
        await Future<void>.delayed(Duration.zero);
        expect(await cubit.checkEmailVerified(), isTrue);
        await Future<void>.delayed(Duration.zero);
        profileController.add(testStudent);
      },
      expect: () => [
        AuthState.unverified(testStudent.email),
        const AuthState.unknown(),
        AuthState.authenticated(testStudent),
      ],
      verify: (_) => verify(() => repository.ensureProfile()).called(1),
    );

    blocTest<AuthCubit, AuthState>(
      'checkEmailVerified stays unverified when the email still is not',
      setUp: () => when(
        () => repository.reloadSession(),
      ).thenAnswer((_) async => sessionFor(testStudent, verified: false)),
      build: () => AuthCubit(repository),
      act: (cubit) async {
        authController.add(sessionFor(testStudent, verified: false));
        await Future<void>.delayed(Duration.zero);
        expect(await cubit.checkEmailVerified(), isFalse);
      },
      expect: () => [AuthState.unverified(testStudent.email)],
      verify: (_) => verifyNever(() => repository.ensureProfile()),
    );

    blocTest<AuthCubit, AuthState>(
      'signs out with the error when the profile cannot be created',
      setUp: () => when(
        () => repository.ensureProfile(),
      ).thenThrow(const AppException('You do not have permission to do that.')),
      build: () => AuthCubit(repository),
      act: (_) => authController.add(sessionFor(testStudent)),
      expect: () => [
        const AuthState.unauthenticated(
          errorMessage: 'You do not have permission to do that.',
        ),
      ],
      verify: (_) => verify(() => repository.signOut()).called(1),
    );

    blocTest<AuthCubit, AuthState>(
      'signs out with an error when the profile never appears',
      build: () => AuthCubit(
        repository,
        profileTimeout: const Duration(milliseconds: 20),
      ),
      act: (_) async {
        authController.add(sessionFor(testStudent));
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
      act: (cubit) =>
          cubit.signIn(email: 'jane@alustudent.com', password: 'secret1'),
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
      act: (cubit) =>
          cubit.signIn(email: 'jane@alustudent.com', password: 'wrong1'),
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
        email: 'jane@alustudent.com',
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
          email: 'jane@alustudent.com',
          department: 'CS',
          password: 'secret1',
        ),
      ).called(1),
    );
  });
}
