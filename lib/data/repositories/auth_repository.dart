import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_user.dart';
import 'app_exception.dart';

/// Wraps Firebase Auth and the `users` collection. It never exposes Firebase
/// types to the layers above it.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  /// Emits the signed-in user's UID, or `null` when signed out.
  Stream<String?> authStateChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  /// How long to wait for Firestore to confirm a profile read or write.
  static const Duration profileWriteTimeout = Duration(seconds: 15);

  static const String _profileUnreachableMessage =
      'Could not reach the database to save your profile. '
      'Check your connection and try again.';

  /// Creates the Auth account and its `users/{uid}` profile. The role is
  /// always `student`; staff accounts are promoted in the Firebase console.
  ///
  /// If the email already has an Auth account but no profile (a sign-up that
  /// was interrupted after the account was created), signing up again with
  /// the same password finishes it by writing the missing profile.
  Future<void> signUp({
    required String name,
    required String email,
    required String department,
    required String password,
  }) async {
    final User user;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user!;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        return _completeInterruptedSignUp(
          name: name,
          email: email,
          department: department,
          password: password,
        );
      }
      throw AppException.from(error);
    } catch (error) {
      throw AppException.from(error);
    }

    try {
      await _createProfile(user, name: name, department: department);
    } catch (error) {
      // Don't leave behind an Auth account that has no profile.
      try {
        await user.delete();
      } catch (_) {}
      throw AppException.from(error);
    }
  }

  /// Handles sign-up for an email that already has an Auth account. Only
  /// someone who knows the account's password gets past the sign-in, and the
  /// profile is only written when none exists, so this can't be used to
  /// take over or overwrite another user's account.
  Future<void> _completeInterruptedSignUp({
    required String name,
    required String email,
    required String department,
    required String password,
  }) async {
    const alreadyExists = AppException(
      'An account already exists with this email. Please log in instead.',
    );

    final User user;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user!;
    } on FirebaseAuthException catch (error) {
      // A wrong password means we can't tell whose account this is.
      const wrongCredentials = {
        'wrong-password',
        'invalid-credential',
        'INVALID_LOGIN_CREDENTIALS',
      };
      if (wrongCredentials.contains(error.code)) throw alreadyExists;
      throw AppException.from(error);
    } catch (error) {
      throw AppException.from(error);
    }

    try {
      final existing = await _users
          .doc(user.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(profileWriteTimeout);
      if (existing.exists) {
        // A complete account: the user signed up before and is now signed in.
        return;
      }
      await _createProfile(user, name: name, department: department);
    } catch (error) {
      try {
        await _auth.signOut();
      } catch (_) {}
      if (error is TimeoutException) {
        throw const AppException(_profileUnreachableMessage);
      }
      throw AppException.from(error);
    }
  }

  /// Writes the student profile and waits until Firestore has confirmed it.
  ///
  /// Without the timeout, an unreachable or missing database leaves the write
  /// pending forever: the app shows the profile from its local cache, but it
  /// never reaches the server and is gone once the cache is cleared.
  Future<void> _createProfile(
    User user, {
    required String name,
    required String department,
  }) async {
    try {
      await user.updateDisplayName(name.trim());
      await _users
          .doc(user.uid)
          .set({
            'name': name.trim(),
            'email': (user.email ?? '').trim(),
            'role': UserRole.student.value,
            'department': department.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(profileWriteTimeout);
    } on TimeoutException {
      throw const AppException(_profileUnreachableMessage);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Reads the profile once. Returns `null` if the document does not exist.
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      return doc.exists ? AppUser.fromFirestore(doc) : null;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Watches the profile so a role change made in the console is picked up
  /// live. Emits `null` while the document does not exist yet, for example
  /// for the brief moment between creating the account and writing its
  /// profile during sign-up.
  Stream<AppUser?> watchUserProfile(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null)
        .transform(AppException.streamTransformer());
  }
}
