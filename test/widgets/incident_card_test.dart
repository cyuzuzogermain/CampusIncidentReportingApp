import 'package:campus_incident_app/core/constants/incident_category.dart';
import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/presentation/widgets/incident_card.dart';
import 'package:campus_incident_app/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  final incident = buildIncident(
    title: 'Leaking tap',
    category: IncidentCategory.water,
    location: 'Cafeteria',
    status: IncidentStatus.inProgress,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    VoidCallback? onTap,
    bool showReporter = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncidentCard(
            incident: incident,
            onTap: onTap,
            showReporter: showReporter,
          ),
        ),
      ),
    );
  }

  testWidgets('shows title, location, date, category icon and status', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('Leaking tap'), findsOneWidget);
    expect(find.text('Cafeteria'), findsOneWidget);
    expect(find.text('Nov 3, 2026'), findsOneWidget);
    expect(find.byIcon(IncidentCategory.water.icon), findsOneWidget);
    expect(find.byType(StatusBadge), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
  });

  testWidgets('shows the reporter when asked (staff view)', (tester) async {
    await pumpCard(tester, showReporter: true);
    expect(find.text('Nov 3, 2026 • Jane Student'), findsOneWidget);
  });

  testWidgets('calls onTap', (tester) async {
    var tapped = 0;
    await pumpCard(tester, onTap: () => tapped++);

    await tester.tap(find.byType(IncidentCard));
    expect(tapped, 1);
  });
}
