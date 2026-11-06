import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'timestamp_parser.dart';

/// The two roles an account can have. Stored as a string on `users/{uid}`.
enum UserRole {
  student('student', 'Student'),
  staff('staff', 'Staff');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromValue(String? value) =>
      value == UserRole.staff.value ? UserRole.staff : UserRole.student;
}

/// The profile stored at `users/{uid}`.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final DateTime createdAt;

  bool get isStaff => role == UserRole.staff;

  /// First name, used in greetings.
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  /// Upper-case first letter, used for the avatar.
  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromValue(map['role'] as String?),
      department: map['department'] as String? ?? '',
      createdAt: parseTimestamp(map['createdAt']),
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.value,
      'department': department,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [uid, name, email, role, department, createdAt];
}
