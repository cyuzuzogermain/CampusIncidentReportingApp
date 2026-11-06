import 'package:bloc_test/bloc_test.dart';
import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/data/repositories/app_exception.dart';
import 'package:campus_incident_app/logic/cubits/incident_actions/incident_actions_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_helpers.dart';

void main() {
  late MockIncidentRepository repository;

  setUpAll(registerTestFallbacks);
  setUp(() {
    repository = MockIncidentRepository();
    when(
      () => repository.setAffected(
        any(),
        any(),
        affected: any(named: 'affected'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.withdrawIncident(any(), any()),
    ).thenAnswer((_) async {});
  });

  IncidentActionsCubit build() => IncidentActionsCubit(repository);

  // Filed by testStudent.
  final submitted = buildIncident();

  group('toggleAffected', () {
    blocTest<IncidentActionsCubit, IncidentActionsState>(
      'marks another student as affected',
      build: build,
      act: (cubit) =>
          cubit.toggleAffected(incident: submitted, user: otherStudent),
      expect: () => const [
        IncidentActionsState(
          status: IncidentActionStatus.working,
          action: IncidentAction.markAffected,
        ),
        IncidentActionsState(
          status: IncidentActionStatus.success,
          action: IncidentAction.markAffected,
        ),
      ],
      verify: (_) => verify(
        () =>
            repository.setAffected(submitted.id, otherStudent, affected: true),
      ).called(1),
    );

    blocTest<IncidentActionsCubit, IncidentActionsState>(
      'removes the mark when the student is already affected',
      build: build,
      act: (cubit) => cubit.toggleAffected(
        incident: buildIncident(affectedUserIds: [otherStudent.uid]),
        user: otherStudent,
      ),
      expect: () => const [
        IncidentActionsState(
          status: IncidentActionStatus.working,
          action: IncidentAction.unmarkAffected,
        ),
        IncidentActionsState(
          status: IncidentActionStatus.success,
          action: IncidentAction.unmarkAffected,
        ),
      ],
      verify: (_) => verify(
        () =>
            repository.setAffected(submitted.id, otherStudent, affected: false),
      ).called(1),
    );

    blocTest<IncidentActionsCubit, IncidentActionsState>(
      'the reporter cannot mark their own report',
      build: build,
      act: (cubit) =>
          cubit.toggleAffected(incident: submitted, user: testStudent),
      expect: () => const [
        IncidentActionsState(
          status: IncidentActionStatus.failure,
          action: IncidentAction.markAffected,
          errorMessage: 'You reported this issue yourself.',
        ),
      ],
      verify: (_) => verifyNever(
        () => repository.setAffected(
          any(),
          any(),
          affected: any(named: 'affected'),
        ),
      ),
    );

    blocTest<IncidentActionsCubit, IncidentActionsState>(
      'cannot join a resolved issue',
      build: build,
      act: (cubit) => cubit.toggleAffected(
        incident: buildIncident(status: IncidentStatus.resolved),
        user: otherStudent,
      ),
      expect: () => const [
        IncidentActionsState(
          status: IncidentActionStatus.failure,
          action: IncidentAction.markAffected,
          errorMessage: 'This report is already resolved.',
        ),
      ],
    );

    blocTest<IncidentActionsCubit, IncidentActionsState>(
      'staff cannot mark themselves as affected',
      build: build,
      act: (cubit) =>
          cubit.toggleAffected(incident: submitted, user: testStaff),
      expect: () => const [
        IncidentActionsState(
          status: IncidentActionStatus.failure,
          action: IncidentAction.markAffected,
          errorMessage: 'Only students can mark themselves as affected.',
        ),
      ],
    );
  });

  group('withdraw', () {
    blocTest<IncidentActionsCubit, IncidentActionsState>(
      'the reporter withdraws a submitted report',
      build: build,
      act: (cubit) => cubit.withdraw(incident: submitted, user: testStudent),
      expect: () => const [
        IncidentActionsState(
          status: IncidentActionStatus.working,
          action: IncidentAction.withdraw,
        ),
        IncidentActionsState(
          status: IncidentActionStatus.success,
          action: IncidentAction.withdraw,
        ),
      ],
      verify: (_) => verify(
        () => repository.withdrawIncident(submitted.id, testStudent),
      ).called(1),
    );

    blocTest<IncidentActionsCubit, IncidentActionsState>(
      'another student cannot withdraw it',
      build: build,
      act: (cubit) => cubit.withdraw(incident: submitted, user: otherStudent),
      expect: () => const [
        IncidentActionsState(
          status: IncidentActionStatus.failure,
          action: IncidentAction.withdraw,
          errorMessage:
              'Only the student who filed this report can withdraw it.',
        ),
      ],
      verify: (_) =>
          verifyNever(() => repository.withdrawIncident(any(), any())),
    );

    blocTest<IncidentActionsCubit, IncidentActionsState>(
      'cannot withdraw once it is in progress',
      build: build,
      act: (cubit) => cubit.withdraw(
        incident: buildIncident(status: IncidentStatus.inProgress),
        user: testStudent,
      ),
      expect: () => const [
        IncidentActionsState(
          status: IncidentActionStatus.failure,
          action: IncidentAction.withdraw,
          errorMessage:
              'Staff have already started on this report, so it '
              'can no longer be withdrawn.',
        ),
      ],
      verify: (_) =>
          verifyNever(() => repository.withdrawIncident(any(), any())),
    );

    blocTest<IncidentActionsCubit, IncidentActionsState>(
      'shows the repository error',
      setUp: () => when(
        () => repository.withdrawIncident(any(), any()),
      ).thenThrow(const AppException('This report no longer exists.')),
      build: build,
      act: (cubit) => cubit.withdraw(incident: submitted, user: testStudent),
      expect: () => const [
        IncidentActionsState(
          status: IncidentActionStatus.working,
          action: IncidentAction.withdraw,
        ),
        IncidentActionsState(
          status: IncidentActionStatus.failure,
          action: IncidentAction.withdraw,
          errorMessage: 'This report no longer exists.',
        ),
      ],
    );
  });
}
