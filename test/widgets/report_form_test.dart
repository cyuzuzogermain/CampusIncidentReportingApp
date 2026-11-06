import 'package:campus_incident_app/logic/cubits/auth/auth_cubit.dart';
import 'package:campus_incident_app/logic/cubits/report_form/report_form_cubit.dart';
import 'package:campus_incident_app/presentation/screens/report/report_incident_screen.dart';
import 'package:campus_incident_app/presentation/widgets/category_tile.dart';
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
    ).thenReturn(AuthState.authenticated(testStudent));
  });

  Future<void> pumpForm(WidgetTester tester) async {
    // A tall surface so the whole form, including the submit button, is
    // laid out at once.
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider(create: (_) => ReportFormCubit(repository)),
          ],
          child: const ReportIncidentView(),
        ),
      ),
    );
  }

  testWidgets('shows the form fields', (tester) async {
    await pumpForm(tester);

    expect(find.text('Report an Incident'), findsOneWidget);
    expect(find.byType(CategoryTile), findsNWidgets(5));
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Add a photo'), findsOneWidget);
  });

  testWidgets('empty submit shows every validation error', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Submit Report'));
    await tester.pump();

    expect(find.text('Please select a category'), findsOneWidget);
    expect(find.text('Title is required'), findsOneWidget);
    expect(
      find.text('Description must be at least 10 characters'),
      findsOneWidget,
    );
    expect(find.text('Please select a location'), findsOneWidget);

    verifyNever(
      () => repository.createIncident(
        title: any(named: 'title'),
        description: any(named: 'description'),
        category: any(named: 'category'),
        location: any(named: 'location'),
        reporter: any(named: 'reporter'),
        image: any(named: 'image'),
      ),
    );
  });

  testWidgets('selecting a category fills its tile and clears the error', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text('Submit Report'));
    await tester.pump();
    expect(find.text('Please select a category'), findsOneWidget);

    await tester.tap(find.text('Water'));
    await tester.pump();

    expect(find.text('Please select a category'), findsNothing);
    final tile = tester.widget<CategoryTile>(
      find.ancestor(
        of: find.text('Water'),
        matching: find.byType(CategoryTile),
      ),
    );
    expect(tile.selected, isTrue);
  });
}
