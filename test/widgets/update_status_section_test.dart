import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/logic/cubits/auth/auth_cubit.dart';
import 'package:campus_incident_app/logic/cubits/status_update/status_update_cubit.dart';
import 'package:campus_incident_app/presentation/widgets/update_status_section.dart';
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
    when(() => authCubit.state).thenReturn(AuthState.authenticated(testStaff));
    when(
      () => repository.updateStatus(
        any(),
        any(),
        any(),
        comment: any(named: 'comment'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, IncidentStatus status) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider(create: (_) => StatusUpdateCubit(repository)),
            ],
            child: SingleChildScrollView(
              child: UpdateStatusSection(
                incident: buildIncident(status: status),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('moving forward sends the optional comment', (tester) async {
    await pump(tester, IncidentStatus.submitted);

    await tester.tap(find.text('Mark as In Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Comment (optional)'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'On it today');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    verify(
      () => repository.updateStatus(
        'incident-1',
        IncidentStatus.inProgress,
        testStaff,
        comment: 'On it today',
      ),
    ).called(1);
  });

  testWidgets('moving forward works without a comment', (tester) async {
    await pump(tester, IncidentStatus.submitted);

    await tester.tap(find.text('Mark as In Progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    verify(
      () => repository.updateStatus(
        'incident-1',
        IncidentStatus.inProgress,
        testStaff,
        comment: null,
      ),
    ).called(1);
  });

  testWidgets('rejecting requires a reason', (tester) async {
    await pump(tester, IncidentStatus.inProgress);

    await tester.tap(find.text('Reject Report'));
    await tester.pumpAndSettle();

    // Submitting empty keeps the dialog open with an error.
    await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
    await tester.pumpAndSettle();
    expect(find.text('Please give a reason'), findsOneWidget);
    verifyNever(
      () => repository.updateStatus(
        any(),
        any(),
        any(),
        comment: any(named: 'comment'),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Duplicate report');
    await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
    await tester.pumpAndSettle();

    verify(
      () => repository.updateStatus(
        'incident-1',
        IncidentStatus.rejected,
        testStaff,
        comment: 'Duplicate report',
      ),
    ).called(1);
  });

  testWidgets('a closed report has no controls', (tester) async {
    await pump(tester, IncidentStatus.rejected);

    expect(find.text('Reject Report'), findsNothing);
    expect(find.textContaining('Mark as'), findsNothing);
    expect(find.text('This report has been rejected.'), findsOneWidget);
  });
}
