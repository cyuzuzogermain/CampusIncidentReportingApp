import 'package:campus_incident_app/core/constants/incident_category.dart';
import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentStatus', () {
    test('Firestore values and labels', () {
      expect(IncidentStatus.submitted.value, 'submitted');
      expect(IncidentStatus.inProgress.value, 'in_progress');
      expect(IncidentStatus.resolved.value, 'resolved');
      expect(IncidentStatus.rejected.value, 'rejected');
      expect(IncidentStatus.inProgress.label, 'In Progress');
    });

    test('fromValue parses values and falls back to submitted', () {
      expect(
        IncidentStatus.fromValue('in_progress'),
        IncidentStatus.inProgress,
      );
      expect(IncidentStatus.fromValue('resolved'), IncidentStatus.resolved);
      expect(IncidentStatus.fromValue('bogus'), IncidentStatus.submitted);
      expect(IncidentStatus.fromValue(null), IncidentStatus.submitted);
    });

    test('next follows Submitted → In Progress → Resolved', () {
      expect(IncidentStatus.submitted.next, IncidentStatus.inProgress);
      expect(IncidentStatus.inProgress.next, IncidentStatus.resolved);
      expect(IncidentStatus.resolved.next, isNull);
      expect(IncidentStatus.rejected.next, isNull);
    });

    test('resolved and rejected are closed; open reports can be rejected', () {
      expect(IncidentStatus.submitted.canBeRejected, isTrue);
      expect(IncidentStatus.inProgress.canBeRejected, isTrue);
      expect(IncidentStatus.resolved.isClosed, isTrue);
      expect(IncidentStatus.rejected.isClosed, isTrue);
      expect(IncidentStatus.rejected.canBeRejected, isFalse);
    });

    test('isReachedBy', () {
      expect(
        IncidentStatus.submitted.isReachedBy(IncidentStatus.submitted),
        isTrue,
      );
      expect(
        IncidentStatus.inProgress.isReachedBy(IncidentStatus.submitted),
        isFalse,
      );
      expect(
        IncidentStatus.inProgress.isReachedBy(IncidentStatus.resolved),
        isTrue,
      );
      // A rejected report doesn't move along the normal flow.
      expect(
        IncidentStatus.resolved.isReachedBy(IncidentStatus.rejected),
        isFalse,
      );
    });

    test('badge colors: amber, blue-purple, green', () {
      expect(IncidentStatus.submitted.color, AppColors.submitted);
      expect(IncidentStatus.inProgress.color, AppColors.inProgress);
      expect(IncidentStatus.rejected.color, AppColors.rejected);
      expect(IncidentStatus.resolved.color, AppColors.resolved);
    });
  });

  group('IncidentCategory', () {
    test('has the five required categories in order', () {
      expect(IncidentCategory.values.map((c) => c.label), [
        'Facilities',
        'Water',
        'Electricity',
        'Safety',
        'Sanitation',
      ]);
    });

    test('fromValue round-trips every value', () {
      for (final category in IncidentCategory.values) {
        expect(IncidentCategory.fromValue(category.value), category);
      }
      expect(
        IncidentCategory.fromValue('unknown'),
        IncidentCategory.facilities,
      );
    });

    test('every category has a distinct icon', () {
      final icons = IncidentCategory.values.map((c) => c.icon).toSet();
      expect(icons.length, IncidentCategory.values.length);
    });
  });
}
