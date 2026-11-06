import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/data/models/incident.dart';
import 'package:campus_incident_app/data/models/status_change.dart';
import 'package:campus_incident_app/presentation/widgets/status_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  Incident withHistory(IncidentStatus status, List<StatusChange> extra) {
    final base = buildIncident(status: status);
    return Incident(
      id: base.id,
      title: base.title,
      description: base.description,
      category: base.category,
      location: base.location,
      imageUrl: null,
      status: status,
      reporterId: base.reporterId,
      reporterName: base.reporterName,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      statusHistory: [...base.statusHistory, ...extra],
    );
  }

  StatusChange change(IncidentStatus status, int minutes, [String? comment]) =>
      StatusChange(
        status: status,
        changedBy: testStaff.uid,
        changedByName: testStaff.name,
        timestamp: testDate.add(Duration(minutes: minutes)),
        comment: comment,
      );

  Future<void> pump(WidgetTester tester, Incident incident) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatusTimeline(incident: incident),
          ),
        ),
      ),
    );
  }

  testWidgets('shows staff comments under their step', (tester) async {
    await pump(
      tester,
      withHistory(IncidentStatus.inProgress, [
        change(IncidentStatus.inProgress, 5, 'Technician on the way'),
      ]),
    );

    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('Technician on the way'), findsOneWidget);
  });

  testWidgets('a rejected report ends with Rejected and its reason', (
    tester,
  ) async {
    await pump(
      tester,
      withHistory(IncidentStatus.rejected, [
        change(IncidentStatus.rejected, 5, 'Duplicate report'),
      ]),
    );

    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Duplicate report'), findsOneWidget);
    // Steps it never reached are left out.
    expect(find.text('In Progress'), findsNothing);
    expect(find.text('Resolved'), findsNothing);
  });
}
