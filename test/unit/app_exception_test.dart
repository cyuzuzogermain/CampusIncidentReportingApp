import 'package:campus_incident_app/data/repositories/app_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException.from', () {
    test('maps auth error codes to friendly messages', () {
      expect(
        AppException.from(
          FirebaseAuthException(code: 'invalid-credential'),
        ).message,
        'Incorrect email or password.',
      );
      expect(
        AppException.from(
          FirebaseAuthException(code: 'email-already-in-use'),
        ).message,
        'An account already exists with this email.',
      );
    });

    test('maps Firestore and Storage errors', () {
      expect(
        AppException.from(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ).message,
        'You do not have permission to do that.',
      );
    });

    test('unknown errors get a generic message', () {
      expect(
        AppException.from(Exception('boom')).message,
        AppException.genericMessage,
      );
    });

    test('keeps an existing AppException', () {
      const error = AppException('Custom');
      expect(AppException.from(error), same(error));
    });
  });
}
