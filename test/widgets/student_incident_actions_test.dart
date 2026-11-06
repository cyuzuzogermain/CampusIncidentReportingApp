import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/logic/cubits/auth/auth_cubit.dart';
import 'package:campus_incident_app/logic/cubits/incident_actions/incident_actions_cubit.dart';
import 'package:campus_incident_app/presentation/widgets/student_incident_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_helpers.dart';

void main() {
  late MockIncidentRepository repository;
  late MockAuthCubit authCubit;

  setUpAll(registerTestFallbacks);

  setUp(() {
    repository = MockIncidentRepository();
    authCubit = MockAuthCubit();
    when(
      () => authCubit.state,
    ).thenReturn(AuthState.authenticated(otherStudent));
    when(
      () => repository.setAffected(
        any(),
        any(),
        affected: any(named: 'affected'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider(create: (_) => IncidentActionsCubit(repository)),
            ],
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  group('ReporterActionsSection', () {
    testWidgets('offers Edit and Withdraw while the report is submitted', (
      tester,
    ) async {
      await pump(tester, ReporterActionsSection(incident: buildIncident()));

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Withdraw'), findsOneWidget);
    });

    testWidgets('is locked once staff start on the report', (tester) async {
      await pump(
        tester,
        ReporterActionsSection(
          incident: buildIncident(status: IncidentStatus.inProgress),
        ),
      );

      expect(find.text('Edit'), findsNothing);
      expect(find.text('Withdraw'), findsNothing);
      expect(find.textContaining('can no longer be edited'), findsOneWidget);
    });

    testWidgets('Withdraw asks for confirmation first', (tester) async {
      await pump(tester, ReporterActionsSection(incident: buildIncident()));

      await tester.tap(find.text('Withdraw'));
      await tester.pumpAndSettle();
      expect(find.text('Withdraw report?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => repository.withdrawIncident(any(), any()));
    });
  });

  group('AffectedSection', () {
    testWidgets('another student can mark themselves as affected', (
      tester,
    ) async {
      final incident = buildIncident();
      await pump(
        tester,
        AffectedSection(incident: incident, uid: otherStudent.uid),
      );

      await tester.tap(find.text('This affects me too'));
      await tester.pump();

      verify(
        () => repository.setAffected(incident.id, otherStudent, affected: true),
      ).called(1);
    });

    testWidgets('an affected student can remove themselves', (tester) async {
      await pump(
        tester,
        AffectedSection(
          incident: buildIncident(affectedUserIds: [otherStudent.uid]),
          uid: otherStudent.uid,
        ),
      );

      expect(find.text('You said this issue affects you too.'), findsOneWidget);
      expect(find.text('I’m no longer affected'), findsOneWidget);
    });

    testWidgets('no button on a resolved issue', (tester) async {
      await pump(
        tester,
        AffectedSection(
          incident: buildIncident(status: IncidentStatus.resolved),
          uid: otherStudent.uid,
        ),
      );

      expect(find.text('This affects me too'), findsNothing);
    });
  });
}
