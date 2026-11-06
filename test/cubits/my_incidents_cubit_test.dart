import 'package:bloc_test/bloc_test.dart';
import 'package:campus_incident_app/core/constants/incident_category.dart';
import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/data/repositories/app_exception.dart';
import 'package:campus_incident_app/logic/cubits/incident_list/all_incidents_cubit.dart';
import 'package:campus_incident_app/logic/cubits/incident_list/my_incidents_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_helpers.dart';

void main() {
  late MockIncidentRepository repository;

  final light = buildIncident(
    id: 'a',
    title: 'Broken light',
    description: 'Flickering bulb in the hallway.',
    category: IncidentCategory.electricity,
    location: 'Library',
  );
  final tap = buildIncident(
    id: 'b',
    title: 'Leaking tap',
    description: 'Water everywhere near the sinks.',
    category: IncidentCategory.water,
    location: 'Cafeteria',
    status: IncidentStatus.inProgress,
  );
  final door = buildIncident(
    id: 'c',
    title: 'Door lock',
    description: 'The lab door does not lock.',
    category: IncidentCategory.safety,
    location: 'Block B — Room 204',
    status: IncidentStatus.resolved,
  );
  final all = [light, tap, door];

  setUp(() {
    repository = MockIncidentRepository();
    when(
      () => repository.streamMyIncidents(testStudent.uid),
    ).thenAnswer((_) => Stream.value(all));
  });

  MyIncidentsCubit build() =>
      MyIncidentsCubit(repository, uid: testStudent.uid);

  group('MyIncidentsCubit', () {
    blocTest<MyIncidentsCubit, IncidentListState>(
      'start loads the student’s incidents',
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => [
        IncidentListState(status: IncidentListStatus.loaded, incidents: all),
      ],
      verify: (cubit) {
        verify(() => repository.streamMyIncidents(testStudent.uid)).called(1);
        expect(cubit.state.total, 3);
        expect(cubit.state.countFor(IncidentStatus.inProgress), 1);
        expect(cubit.state.countFor(IncidentStatus.resolved), 1);
      },
    );

    blocTest<MyIncidentsCubit, IncidentListState>(
      'searchChanged emits the new query',
      build: build,
      seed: () =>
          IncidentListState(status: IncidentListStatus.loaded, incidents: all),
      act: (cubit) => cubit.searchChanged('LIGHT'),
      expect: () => [
        IncidentListState(
          status: IncidentListStatus.loaded,
          incidents: all,
          query: 'LIGHT',
        ),
      ],
      verify: (cubit) => expect(cubit.state.filtered, [light]),
    );

    test(
      'search matches title, description and location (case-insensitive)',
      () async {
        final cubit = build()..start();
        await Future<void>.delayed(Duration.zero);

        cubit.searchChanged('LIGHT'); // title
        expect(cubit.state.filtered, [light]);
        cubit.searchChanged('water'); // description
        expect(cubit.state.filtered, [tap]);
        cubit.searchChanged('room 204'); // location
        expect(cubit.state.filtered, [door]);
        cubit.searchChanged('nothing matches');
        expect(cubit.state.filtered, isEmpty);
        cubit.searchChanged('');
        expect(cubit.state.filtered, all);
        await cubit.close();
      },
    );

    test('status filter', () async {
      final cubit = build()..start();
      await Future<void>.delayed(Duration.zero);

      cubit.statusFilterChanged(IncidentStatus.inProgress);
      expect(cubit.state.filtered, [tap]);
      cubit.statusFilterChanged(IncidentStatus.resolved);
      expect(cubit.state.filtered, [door]);
      cubit.statusFilterChanged(null);
      expect(cubit.state.filtered, all);
      // Counts ignore filters.
      expect(cubit.state.total, 3);
      await cubit.close();
    });

    test('category filter combined with search', () async {
      final cubit = build()..start();
      await Future<void>.delayed(Duration.zero);

      cubit
        ..categoryFilterChanged(IncidentCategory.safety)
        ..searchChanged('door');
      expect(cubit.state.filtered, [door]);
      expect(cubit.state.hasActiveFilters, isTrue);
      cubit.searchChanged('light');
      expect(cubit.state.filtered, isEmpty);
      cubit.categoryFilterChanged(null);
      expect(cubit.state.filtered, [light]);
      await cubit.close();
    });

    blocTest<MyIncidentsCubit, IncidentListState>(
      'stream errors become a failure state',
      setUp: () => when(
        () => repository.streamMyIncidents(any()),
      ).thenAnswer((_) => Stream.error(const AppException('No connection.'))),
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => const [
        IncidentListState(
          status: IncidentListStatus.failure,
          errorMessage: 'No connection.',
        ),
      ],
    );
  });

  group('AllIncidentsCubit', () {
    blocTest<AllIncidentsCubit, IncidentListState>(
      'start loads every incident',
      setUp: () => when(
        () => repository.streamAllIncidents(),
      ).thenAnswer((_) => Stream.value(all)),
      build: () => AllIncidentsCubit(repository),
      act: (cubit) => cubit.start(),
      expect: () => [
        IncidentListState(status: IncidentListStatus.loaded, incidents: all),
      ],
    );
  });
}
