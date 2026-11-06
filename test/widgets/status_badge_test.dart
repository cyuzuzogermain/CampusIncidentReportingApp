import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBadge(WidgetTester tester, IncidentStatus status) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: StatusBadge(status: status)),
        ),
      ),
    );
  }

  for (final status in IncidentStatus.values) {
    testWidgets('shows the ${status.label} label in its color', (tester) async {
      await pumpBadge(tester, status);

      final text = tester.widget<Text>(find.text(status.label));
      expect(text.style?.color, status.color);

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text(status.label),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, status.backgroundColor);
    });
  }
}
