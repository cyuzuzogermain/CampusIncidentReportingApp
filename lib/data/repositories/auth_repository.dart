import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';
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

  /// Emits the signed-in account (including whether its email is verified),
  /// or `null` when signed out. Also emits after [reloadSession] picks up a
  /// newly verified email.
  Stream<AuthSession?> authStateChanges() =>
      _auth.userChanges().map(_toSession).distinct();

  static AuthSession? _toSession(User? user) => user == null
      ? null
      : AuthSession(
          uid: user.uid,
          email: user.email ?? '',
          emailVerified: user.emailVerified,
        );

  /// How long to wait for Firestore to confirm a profile read or write.
  static const Duration profileWriteTimeout = Duration(seconds: 15);

  static const String _profileUnreachableMessage =
      'Could not reach the database to save your profile. '
      'Check your connection and try again.';

  /// The name and department from the sign-up form. The security rules only
  /// let a verified account write to Firestore, so the `users/{uid}` profile
  /// is created by [ensureProfile] once the email has been verified.
  _PendingProfile? _pendingProfile;

  static void _requireAluEmail(String email) {
    if (!Validators.isAluEmail(email)) {
      throw const AppException(Validators.aluEmailMessage);
    }
  }

  /// Creates the Auth account and sends the verification email. The
  /// `users/{uid}` profile (always a `student`; staff are promoted in the
  /// Firebase console) is written after the email is verified.
  ///
  /// If the email already has an Auth account (a sign-up that was
  /// interrupted), signing up again with the same password signs in to it so
  /// the user can finish verifying.
  Future<void> signUp({
    required String name,
    required String email,
    required String department,
    required String password,
  }) async {
    _requireAluEmail(email);

    final User user;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user!;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        return _resumeSignUp(
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

    _pendingProfile = _PendingProfile(
      uid: user.uid,
      name: name.trim(),
      department: department.trim(),
    );
    try {
      // Kept on the Auth account too, in case the app restarts before the
      // email is verified and the pending profile is lost.
      await user.updateDisplayName(name.trim());
    } catch (_) {}
    try {
      await user.sendEmailVerification();
    } catch (_) {
      // The account exists now. The verify-email screen lets the user
      // resend the email, so a failure here isn't fatal.
    }
  }

  /// Handles sign-up for an email that already has an Auth account. Only
  /// someone who knows the account's password gets past the sign-in, and
  /// [ensureProfile] only writes a profile when none exists, so this can't be
  /// used to take over or overwrite another user's account.
  Future<void> _resumeSignUp({
    required String name,
    required String email,
    required String department,
    required String password,
  }) async {
    const alreadyExists = AppException(
      'An account already exists with this email. Please log in instead.',
    );

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _pendingProfile = _PendingProfile(
        uid: credential.user!.uid,
        name: name.trim(),
        department: department.trim(),
      );
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
  }

  /// Makes sure a verified account has its `users/{uid}` profile, writing a
  /// `student` profile if it is missing. Waits until Firestore has confirmed
  /// the write: without the timeout, an unreachable or missing database
  /// leaves the write pending forever.
  Future<void> ensureProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw const AppException(AppException.genericMessage);

    try {
      // The rules read email_verified from the ID token, so a token issued
      // before the email was verified must be refreshed first.
      final token = await user.getIdTokenResult();
      if (token.claims?['email_verified'] != true) {
        await user.getIdToken(true);
      }

      final doc = _users.doc(user.uid);
      final existing = await doc.get().timeout(profileWriteTimeout);
      if (existing.exists) return;

      final pending = _pendingProfile?.uid == user.uid ? _pendingProfile : null;
      final email = (user.email ?? '').trim();
      var name = pending?.name ?? (user.displayName ?? '').trim();
      if (name.isEmpty) name = email.split('@').first;

      await doc
          .set({
            'name': name,
            'email': email,
            'role': UserRole.student.value,
            'department': pending?.department ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(profileWriteTimeout);
      _pendingProfile = null;
    } on TimeoutException {
      throw const AppException(_profileUnreachableMessage);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _requireAluEmail(email);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Sends (or re-sends) the verification email to the signed-in user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw const AppException(AppException.genericMessage);
    try {
      await user.sendEmailVerification();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Reloads the signed-in account from the server to pick up a newly
  /// verified email. The ID token is refreshed first so Firestore and
  /// Storage see the new `email_verified` claim as soon as the app does.
  Future<AuthSession?> reloadSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      await user.getIdToken(true);
      await user.reload();
    } catch (error) {
      throw AppException.from(error);
    }
    return _toSession(_auth.currentUser);
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
  /// live. Emits `null` while the document does not exist yet.
  Stream<AppUser?> watchUserProfile(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null)
        .transform(AppException.streamTransformer());
  }
}

class _PendingProfile {
  const _PendingProfile({
    required this.uid,
    required this.name,
    required this.department,
  });

  final String uid;
  final String name;
  final String department;
}
