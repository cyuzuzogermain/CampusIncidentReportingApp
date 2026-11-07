import 'package:bloc_test/bloc_test.dart';
import 'package:campus_incident_app/data/repositories/app_exception.dart';
import 'package:campus_incident_app/logic/cubits/verify_email/verify_email_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_helpers.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.sendEmailVerification()).thenAnswer((_) async {});
  });

  VerifyEmailCubit build({
    Future<bool> Function()? checkVerified,
    Duration cooldown = const Duration(seconds: 2),
  }) => VerifyEmailCubit(
    repository,
    checkVerified: checkVerified ?? () async => false,
    cooldown: cooldown,
  );

  group('VerifyEmailCubit', () {
    test('can resend straight away', () {
      expect(build().state.canResend, isTrue);
    });

    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'resend sends the email and starts the cooldown',
      build: build,
      act: (cubit) => cubit.resend(),
      expect: () => const [
        VerifyEmailState(isSending: true),
        VerifyEmailState(
          cooldownSeconds: 2,
          message: VerifyEmailCubit.emailSentMessage,
        ),
      ],
      verify: (cubit) {
        verify(() => repository.sendEmailVerification()).called(1);
        expect(cubit.state.canResend, isFalse);
      },
    );

    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'ignores resend during the cooldown, then counts down to zero',
      build: build,
      act: (cubit) async {
        await cubit.resend();
        await cubit.resend(); // Ignored: still cooling down.
        await Future<void>.delayed(const Duration(milliseconds: 2100));
      },
      wait: Duration.zero,
      skip: 2,
      expect: () => const [
        VerifyEmailState(cooldownSeconds: 1),
        VerifyEmailState(),
      ],
      verify: (cubit) {
        verify(() => repository.sendEmailVerification()).called(1);
        expect(cubit.state.canResend, isTrue);
      },
    );

    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'shows a friendly message when the email cannot be sent',
      setUp: () => when(() => repository.sendEmailVerification()).thenThrow(
        const AppException(
          'Too many attempts. Please wait a moment and try '
          'again.',
        ),
      ),
      build: build,
      act: (cubit) => cubit.resend(),
      expect: () => const [
        VerifyEmailState(isSending: true),
        VerifyEmailState(
          message: 'Too many attempts. Please wait a moment and try again.',
        ),
      ],
      verify: (cubit) => expect(cubit.state.canResend, isTrue),
    );

    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'checkVerified says so when the email is not verified yet',
      build: build,
      act: (cubit) => cubit.checkVerified(),
      expect: () => const [
        VerifyEmailState(isChecking: true),
        VerifyEmailState(message: VerifyEmailCubit.notVerifiedMessage),
      ],
    );

    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'checkVerified keeps the spinner while the session moves on',
      build: () => build(checkVerified: () async => true),
      act: (cubit) => cubit.checkVerified(),
      expect: () => const [VerifyEmailState(isChecking: true)],
    );

    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'checkVerified shows a friendly message on failure',
      build: () => build(
        checkVerified: () async => throw const AppException('No internet.'),
      ),
      act: (cubit) => cubit.checkVerified(),
      expect: () => const [
        VerifyEmailState(isChecking: true),
        VerifyEmailState(message: 'No internet.'),
      ],
    );
  });
}
