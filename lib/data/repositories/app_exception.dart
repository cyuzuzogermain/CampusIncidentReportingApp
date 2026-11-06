import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// An error with a message that is safe to show to the user. Repositories
/// convert every Firebase error into one of these.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  static const String genericMessage =
      'Something went wrong. Please try again.';

  /// Converts any error into an [AppException] with a friendly message.
  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) {
      return AppException(_authMessage(error.code));
    }
    if (error is FirebaseException) {
      return AppException(_firebaseMessage(error.code));
    }
    return const AppException(genericMessage);
  }

  static String _authMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'That password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this project.';
      default:
        return _firebaseMessage(code);
    }
  }

  static String _firebaseMessage(String code) {
    switch (code) {
      case 'permission-denied':
      case 'unauthorized':
      case 'unauthenticated':
        return 'You do not have permission to do that.';
      case 'unavailable':
      case 'network-request-failed':
      case 'retry-limit-exceeded':
        return 'The service is unavailable. Check your connection and try again.';
      case 'not-found':
      case 'object-not-found':
        return 'The requested item could not be found.';
      case 'canceled':
        return 'The operation was cancelled.';
      case 'quota-exceeded':
      case 'resource-exhausted':
        return 'Storage quota exceeded. Please try again later.';
      default:
        return genericMessage;
    }
  }

  /// A stream transformer that turns stream errors into [AppException]s.
  static StreamTransformer<T, T> streamTransformer<T>() {
    return StreamTransformer<T, T>.fromHandlers(
      handleError: (error, stackTrace, sink) =>
          sink.addError(AppException.from(error), stackTrace),
    );
  }

  @override
  String toString() => message;
}
