import 'package:campus_incident_app/core/constants/incident_category.dart';
import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/data/models/app_user.dart';
import 'package:campus_incident_app/data/models/incident.dart';
import 'package:campus_incident_app/data/models/status_change.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AppUser', () {
    test('fromMap reads every field', () {
      final user = AppUser.fromMap('u1', {
        'name': 'Jane Student',
        'email': 'jane@uni.edu',
        'role': 'staff',
        'department': 'Estates',
        'createdAt': Timestamp.fromDate(testDate),
      });

      expect(user.uid, 'u1');
      expect(user.name, 'Jane Student');
      expect(user.email, 'jane@uni.edu');
      expect(user.role, UserRole.staff);
      expect(user.isStaff, isTrue);
      expect(user.department, 'Estates');
      expect(user.createdAt, testDate);
    });

    test('toMap then fromMap round-trips', () {
      final map = testStudent.toMap();
      expect(map['role'], 'student');
      expect(map['createdAt'], isA<Timestamp>());
      expect(AppUser.fromMap(testStudent.uid, map), testStudent);
    });

    test('unknown or missing role falls back to student', () {
      final user = AppUser.fromMap('u1', {'role': 'admin'});
      expect(user.role, UserRole.student);
      expect(user.name, '');
    });

    test('firstName and initial', () {
      expect(testStudent.firstName, 'Jane');
      expect(testStudent.initial, 'J');
    });
  });

  group('StatusChange', () {
    test('toMap then fromMap round-trips', () {
      final change = StatusChange(
        status: IncidentStatus.inProgress,
        changedBy: 'staff-1',
        changedByName: 'Sam Staff',
        timestamp: testDate,
      );
      final map = change.toMap();
      expect(map['status'], 'in_progress');
      expect(StatusChange.fromMap(map), change);
    });
  });

  group('Incident', () {
    test('fromMap reads fields, enums and status history', () {
      final incident = Incident.fromMap('i1', {
        'title': 'Leaking tap',
        'description': 'Water is leaking everywhere.',
        'category': 'water',
        'location': 'Cafeteria',
        'imageUrl': 'https://example.com/a.jpg',
        'status': 'in_progress',
        'reporterId': 'student-1',
        'reporterName': 'Jane Student',
        'createdAt': Timestamp.fromDate(testDate),
        'updatedAt': Timestamp.fromDate(testDate),
        'statusHistory': [
          {
            'status': 'in_progress',
            'changedBy': 'staff-1',
            'changedByName': 'Sam Staff',
            'timestamp': Timestamp.fromDate(
              testDate.add(const Duration(hours: 1)),
            ),
          },
          {
            'status': 'submitted',
            'changedBy': 'student-1',
            'changedByName': 'Jane Student',
            'timestamp': Timestamp.fromDate(testDate),
          },
        ],
      });

      expect(incident.id, 'i1');
      expect(incident.category, IncidentCategory.water);
      expect(incident.status, IncidentStatus.inProgress);
      expect(incident.hasImage, isTrue);
      // History is sorted oldest first.
      expect(incident.statusHistory.map((e) => e.status), [
        IncidentStatus.submitted,
        IncidentStatus.inProgress,
      ]);
      expect(
        incident.historyFor(IncidentStatus.inProgress)?.changedByName,
        'Sam Staff',
      );
      expect(incident.historyFor(IncidentStatus.resolved), isNull);
    });

    test('a status change keeps its optional comment', () {
      final change = StatusChange(
        status: IncidentStatus.rejected,
        changedBy: testStaff.uid,
        changedByName: testStaff.name,
        timestamp: testDate,
        comment: 'Duplicate report',
      );
      expect(StatusChange.fromMap(change.toMap()), change);
      expect(change.hasComment, isTrue);

      final plain = StatusChange(
        status: IncidentStatus.inProgress,
        changedBy: testStaff.uid,
        changedByName: testStaff.name,
        timestamp: testDate,
      );
      expect(plain.toMap().containsKey('comment'), isFalse);
      expect(plain.hasComment, isFalse);
    });

    test('rejectionReason comes from the rejected history entry', () {
      final incident = Incident.fromMap('i1', {
        'status': 'rejected',
        'statusHistory': [
          {'status': 'submitted'},
          {'status': 'rejected', 'comment': 'Not a campus issue'},
        ],
      });
      expect(incident.rejectionReason, 'Not a campus issue');
      expect(buildIncident().rejectionReason, isNull);
    });

    test('toMap then fromMap round-trips', () {
      final incident = buildIncident(
        imageUrl: 'https://example.com/a.jpg',
        affectedUserIds: ['student-2', 'student-3'],
      );
      final map = incident.toMap();

      expect(map['category'], 'electricity');
      expect(map['status'], 'submitted');
      expect(map.containsKey('id'), isFalse);
      expect(Incident.fromMap(incident.id, map), incident);
    });

    test('missing fields get safe defaults', () {
      final incident = Incident.fromMap('i1', const {});
      expect(incident.title, '');
      expect(incident.imageUrl, isNull);
      expect(incident.hasImage, isFalse);
      expect(incident.status, IncidentStatus.submitted);
      expect(incident.statusHistory, isEmpty);
      expect(incident.affectedUserIds, isEmpty);
    });

    test('affected students and reporter permissions', () {
      final incident = buildIncident(affectedUserIds: ['student-2']);
      expect(incident.affectedCount, 1);
      expect(incident.isAffected('student-2'), isTrue);
      expect(incident.isAffected('student-3'), isFalse);
      expect(incident.isReportedBy(testStudent.uid), isTrue);
      expect(incident.canBeChangedByReporter, isTrue);
      expect(
        buildIncident(status: IncidentStatus.inProgress).canBeChangedByReporter,
        isFalse,
      );
    });

    test('a pending server timestamp (null) does not throw', () {
      final incident = Incident.fromMap('i1', const {'createdAt': null});
      expect(incident.createdAt, isA<DateTime>());
    });
  });
}
