import 'package:bloc_test/bloc_test.dart';
import 'dart:typed_data';

import 'package:campus_incident_app/core/constants/incident_category.dart';
import 'package:campus_incident_app/data/models/picked_image.dart';
import 'package:campus_incident_app/data/repositories/app_exception.dart';
import 'package:campus_incident_app/logic/cubits/report_form/report_form_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_helpers.dart';

void main() {
  late MockIncidentRepository repository;

  setUpAll(registerTestFallbacks);
  setUp(() => repository = MockIncidentRepository());

  void stubCreate(Future<String> Function() answer) {
    when(
      () => repository.createIncident(
        title: any(named: 'title'),
        description: any(named: 'description'),
        category: any(named: 'category'),
        location: any(named: 'location'),
        reporter: any(named: 'reporter'),
        image: any(named: 'image'),
      ),
    ).thenAnswer((_) => answer());
  }

  final photo = PickedImage(
    bytes: Uint8List.fromList([1, 2, 3]),
    name: 'photo.jpg',
  );
  final otherPhoto = PickedImage(
    bytes: Uint8List.fromList([4, 5, 6]),
    name: 'a.png',
  );
  final filled = ReportFormState(
    category: IncidentCategory.water,
    location: 'Library',
    image: photo,
  );

  group('ReportFormCubit', () {
    blocTest<ReportFormCubit, ReportFormState>(
      'updates category, location and photo',
      build: () => ReportFormCubit(repository),
      act: (cubit) => cubit
        ..selectCategory(IncidentCategory.safety)
        ..selectLocation('Cafeteria')
        ..setImage(otherPhoto)
        ..removeImage(),
      expect: () => [
        const ReportFormState(category: IncidentCategory.safety),
        const ReportFormState(
          category: IncidentCategory.safety,
          location: 'Cafeteria',
        ),
        ReportFormState(
          category: IncidentCategory.safety,
          location: 'Cafeteria',
          image: otherPhoto,
        ),
        const ReportFormState(
          category: IncidentCategory.safety,
          location: 'Cafeteria',
        ),
      ],
    );

    blocTest<ReportFormCubit, ReportFormState>(
      'success: emits submitting then success with the new incident id',
      setUp: () => stubCreate(() async => 'new-id'),
      build: () => ReportFormCubit(repository),
      seed: () => filled,
      act: (cubit) => cubit.submit(
        title: 'Leaking tap',
        description: 'Water leaking under the sink.',
        reporter: testStudent,
      ),
      expect: () => [
        filled.copyWith(status: ReportFormStatus.submitting),
        filled.copyWith(
          status: ReportFormStatus.success,
          incidentId: () => 'new-id',
        ),
      ],
      verify: (_) => verify(
        () => repository.createIncident(
          title: 'Leaking tap',
          description: 'Water leaking under the sink.',
          category: IncidentCategory.water,
          location: 'Library',
          reporter: testStudent,
          image: photo,
        ),
      ).called(1),
    );

    blocTest<ReportFormCubit, ReportFormState>(
      'failure: emits the repository error message',
      setUp: () => stubCreate(
        () async => throw const AppException('Upload failed. Try again.'),
      ),
      build: () => ReportFormCubit(repository),
      seed: () => filled,
      act: (cubit) => cubit.submit(
        title: 'Leaking tap',
        description: 'Water leaking under the sink.',
        reporter: testStudent,
      ),
      expect: () => [
        filled.copyWith(status: ReportFormStatus.submitting),
        filled.copyWith(
          status: ReportFormStatus.failure,
          errorMessage: () => 'Upload failed. Try again.',
        ),
      ],
    );

    blocTest<ReportFormCubit, ReportFormState>(
      'invalid form: fails without calling the repository',
      build: () => ReportFormCubit(repository),
      act: (cubit) => cubit.submit(
        title: 'Leaking tap',
        description: 'Water leaking under the sink.',
        reporter: testStudent,
      ),
      expect: () => const [
        ReportFormState(
          status: ReportFormStatus.failure,
          errorMessage: 'Please select a category',
        ),
      ],
      verify: (_) => verifyNever(
        () => repository.createIncident(
          title: any(named: 'title'),
          description: any(named: 'description'),
          category: any(named: 'category'),
          location: any(named: 'location'),
          reporter: any(named: 'reporter'),
          image: any(named: 'image'),
        ),
      ),
    );

    group('editing', () {
      final existing = buildIncident(
        category: IncidentCategory.electricity,
        location: 'Library',
        imageUrl: 'https://example.com/old.jpg',
      );

      void stubUpdate() {
        when(
          () => repository.updateIncident(
            id: any(named: 'id'),
            title: any(named: 'title'),
            description: any(named: 'description'),
            category: any(named: 'category'),
            location: any(named: 'location'),
            reporter: any(named: 'reporter'),
            newImage: any(named: 'newImage'),
            keepExistingImage: any(named: 'keepExistingImage'),
          ),
        ).thenAnswer((_) async {});
      }

      test('starts from the report being edited', () {
        final cubit = ReportFormCubit(repository, editing: existing);
        expect(cubit.isEditing, isTrue);
        expect(
          cubit.state,
          const ReportFormState(
            category: IncidentCategory.electricity,
            location: 'Library',
            existingImageUrl: 'https://example.com/old.jpg',
          ),
        );
        cubit.close();
      });

      blocTest<ReportFormCubit, ReportFormState>(
        'saves changes and keeps the existing photo',
        setUp: stubUpdate,
        build: () => ReportFormCubit(repository, editing: existing),
        act: (cubit) => cubit
          ..selectCategory(IncidentCategory.safety)
          ..submit(
            title: 'Broken light, now sparking',
            description: 'The light is sparking near the stairs.',
            reporter: testStudent,
          ),
        skip: 2,
        expect: () => [
          isA<ReportFormState>()
              .having((s) => s.status, 'status', ReportFormStatus.success)
              .having((s) => s.incidentId, 'incidentId', existing.id),
        ],
        verify: (_) {
          verify(
            () => repository.updateIncident(
              id: existing.id,
              title: 'Broken light, now sparking',
              description: 'The light is sparking near the stairs.',
              category: IncidentCategory.safety,
              location: 'Library',
              reporter: testStudent,
              newImage: null,
              keepExistingImage: true,
            ),
          ).called(1);
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
        },
      );

      blocTest<ReportFormCubit, ReportFormState>(
        'removing the existing photo asks the repository to drop it',
        setUp: stubUpdate,
        build: () => ReportFormCubit(repository, editing: existing),
        act: (cubit) => cubit
          ..removeImage()
          ..submit(
            title: existing.title,
            description: existing.description,
            reporter: testStudent,
          ),
        verify: (cubit) {
          expect(cubit.state.existingImageUrl, isNull);
          verify(
            () => repository.updateIncident(
              id: existing.id,
              title: existing.title,
              description: existing.description,
              category: existing.category,
              location: existing.location,
              reporter: testStudent,
              newImage: null,
              keepExistingImage: false,
            ),
          ).called(1);
        },
      );
    });

    blocTest<ReportFormCubit, ReportFormState>(
      'short description is rejected',
      build: () => ReportFormCubit(repository),
      seed: () => filled,
      act: (cubit) => cubit.submit(
        title: 'Leak',
        description: 'short',
        reporter: testStudent,
      ),
      expect: () => [
        filled.copyWith(
          status: ReportFormStatus.failure,
          errorMessage: () => 'Description must be at least 10 characters',
        ),
      ],
    );
  });
}
