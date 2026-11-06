import 'package:bloc_test/bloc_test.dart';
import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/data/repositories/app_exception.dart';
import 'package:campus_incident_app/logic/cubits/status_update/status_update_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_helpers.dart';

void main() {
  late MockIncidentRepository repository;

  setUpAll(registerTestFallbacks);
  setUp(() => repository = MockIncidentRepository());

  group('StatusUpdateCubit', () {
    blocTest<StatusUpdateCubit, StatusUpdateState>(
      'staff move Submitted → In Progress and are recorded',
      setUp: () => when(
        () => repository.updateStatus(any(), any(), any()),
      ).thenAnswer((_) async {}),
      build: () => StatusUpdateCubit(repository),
      act: (cubit) =>
          cubit.advanceStatus(incident: buildIncident(), user: testStaff),
      expect: () => const [
        StatusUpdateState(
          status: StatusUpdateStatus.updating,
          targetStatus: IncidentStatus.inProgress,
        ),
        StatusUpdateState(
          status: StatusUpdateStatus.success,
          targetStatus: IncidentStatus.inProgress,
        ),
      ],
      verify: (_) => verify(
        () => repository.updateStatus(
          'incident-1',
          IncidentStatus.inProgress,
          testStaff,
        ),
      ).called(1),
    );

    blocTest<StatusUpdateCubit, StatusUpdateState>(
      'staff move In Progress → Resolved',
      setUp: () => when(
        () => repository.updateStatus(any(), any(), any()),
      ).thenAnswer((_) async {}),
      build: () => StatusUpdateCubit(repository),
      act: (cubit) => cubit.advanceStatus(
        incident: buildIncident(status: IncidentStatus.inProgress),
        user: testStaff,
      ),
      verify: (cubit) {
        expect(cubit.state.status, StatusUpdateStatus.success);
        verify(
          () => repository.updateStatus(
            'incident-1',
            IncidentStatus.resolved,
            testStaff,
          ),
        ).called(1);
      },
    );

    blocTest<StatusUpdateCubit, StatusUpdateState>(
      'students are blocked and the repository is never called',
      build: () => StatusUpdateCubit(repository),
      act: (cubit) =>
          cubit.advanceStatus(incident: buildIncident(), user: testStudent),
      expect: () => const [
        StatusUpdateState(
          status: StatusUpdateStatus.failure,
          errorMessage: 'Only staff members can update a report’s status.',
        ),
      ],
      verify: (_) =>
          verifyNever(() => repository.updateStatus(any(), any(), any())),
    );

    blocTest<StatusUpdateCubit, StatusUpdateState>(
      'a resolved report cannot move further',
      build: () => StatusUpdateCubit(repository),
      act: (cubit) => cubit.advanceStatus(
        incident: buildIncident(status: IncidentStatus.resolved),
        user: testStaff,
      ),
      expect: () => const [
        StatusUpdateState(
          status: StatusUpdateStatus.failure,
          errorMessage: 'This report is already resolved.',
        ),
      ],
      verify: (_) =>
          verifyNever(() => repository.updateStatus(any(), any(), any())),
    );

    blocTest<StatusUpdateCubit, StatusUpdateState>(
      'repository errors become a failure message',
      setUp: () => when(
        () => repository.updateStatus(any(), any(), any()),
      ).thenThrow(const AppException('You do not have permission to do that.')),
      build: () => StatusUpdateCubit(repository),
      act: (cubit) =>
          cubit.advanceStatus(incident: buildIncident(), user: testStaff),
      expect: () => const [
        StatusUpdateState(
          status: StatusUpdateStatus.updating,
          targetStatus: IncidentStatus.inProgress,
        ),
        StatusUpdateState(
          status: StatusUpdateStatus.failure,
          targetStatus: IncidentStatus.inProgress,
          errorMessage: 'You do not have permission to do that.',
        ),
      ],
    );

    blocTest<StatusUpdateCubit, StatusUpdateState>(
      'passes an optional comment, trimmed',
      setUp: () => when(
        () => repository.updateStatus(
          any(),
          any(),
          any(),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async {}),
      build: () => StatusUpdateCubit(repository),
      act: (cubit) => cubit.advanceStatus(
        incident: buildIncident(),
        user: testStaff,
        comment: '  Technician booked for Monday  ',
      ),
      verify: (_) => verify(
        () => repository.updateStatus(
          'incident-1',
          IncidentStatus.inProgress,
          testStaff,
          comment: 'Technician booked for Monday',
        ),
      ).called(1),
    );

    blocTest<StatusUpdateCubit, StatusUpdateState>(
      'a blank comment is sent as no comment',
      setUp: () => when(
        () => repository.updateStatus(
          any(),
          any(),
          any(),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async {}),
      build: () => StatusUpdateCubit(repository),
      act: (cubit) => cubit.advanceStatus(
        incident: buildIncident(),
        user: testStaff,
        comment: '   ',
      ),
      verify: (_) => verify(
        () => repository.updateStatus(
          'incident-1',
          IncidentStatus.inProgress,
          testStaff,
          comment: null,
        ),
      ).called(1),
    );
  });

  group('reject', () {
    setUp(
      () => when(
        () => repository.updateStatus(
          any(),
          any(),
          any(),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async {}),
    );

    for (final from in [IncidentStatus.submitted, IncidentStatus.inProgress]) {
      blocTest<StatusUpdateCubit, StatusUpdateState>(
        'staff reject a ${from.label} report with a reason',
        build: () => StatusUpdateCubit(repository),
        act: (cubit) => cubit.reject(
          incident: buildIncident(status: from),
          user: testStaff,
          reason: 'Duplicate of an existing report',
        ),
        expect: () => const [
          StatusUpdateState(
            status: StatusUpdateStatus.updating,
            targetStatus: IncidentStatus.rejected,
          ),
          StatusUpdateState(
            status: StatusUpdateStatus.success,
            targetStatus: IncidentStatus.rejected,
          ),
        ],
        verify: (_) => verify(
          () => repository.updateStatus(
            'incident-1',
            IncidentStatus.rejected,
            testStaff,
            comment: 'Duplicate of an existing report',
          ),
        ).called(1),
      );
    }

    blocTest<StatusUpdateCubit, StatusUpdateState>(
      'a reason is required',
      build: () => StatusUpdateCubit(repository),
      act: (cubit) => cubit.reject(
        incident: buildIncident(),
        user: testStaff,
        reason: '   ',
      ),
      expect: () => const [
        StatusUpdateState(
          status: StatusUpdateStatus.failure,
          targetStatus: IncidentStatus.rejected,
          errorMessage: 'Please give a reason for the rejection.',
        ),
      ],
      verify: (_) => verifyNever(
        () => repository.updateStatus(
          any(),
          any(),
          any(),
          comment: any(named: 'comment'),
        ),
      ),
    );

    blocTest<StatusUpdateCubit, StatusUpdateState>(
      'a resolved report cannot be rejected',
      build: () => StatusUpdateCubit(repository),
      act: (cubit) => cubit.reject(
        incident: buildIncident(status: IncidentStatus.resolved),
        user: testStaff,
        reason: 'Too late',
      ),
      expect: () => const [
        StatusUpdateState(
          status: StatusUpdateStatus.failure,
          errorMessage: 'This report is already resolved.',
        ),
      ],
    );

    blocTest<StatusUpdateCubit, StatusUpdateState>(
      'students cannot reject',
      build: () => StatusUpdateCubit(repository),
      act: (cubit) => cubit.reject(
        incident: buildIncident(),
        user: testStudent,
        reason: 'Spam',
      ),
      expect: () => const [
        StatusUpdateState(
          status: StatusUpdateStatus.failure,
          errorMessage: 'Only staff members can update a report’s status.',
        ),
      ],
    );
  });
}
