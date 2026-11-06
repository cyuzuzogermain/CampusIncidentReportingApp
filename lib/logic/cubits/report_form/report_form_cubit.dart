import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/incident_category.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/incident.dart';
import '../../../data/models/picked_image.dart';
import '../../../data/repositories/app_exception.dart';
import '../../../data/repositories/incident_repository.dart';

part 'report_form_state.dart';

/// Holds the "Report an Incident" form's selections and submits it.
///
/// Given an [editing] incident, the form starts from that report and
/// [submit] saves the changes instead of creating a new report.
///
/// The title and description live in the screen's text controllers and are
/// passed to [submit].
class ReportFormCubit extends Cubit<ReportFormState> {
  ReportFormCubit(this._repository, {this.editing})
    : super(
        editing == null
            ? const ReportFormState()
            : ReportFormState(
                category: editing.category,
                // Only pre-select a location the dropdown can show.
                location:
                    AppConstants.campusLocations.contains(editing.location)
                    ? editing.location
                    : null,
                existingImageUrl: editing.imageUrl,
              ),
      );

  final IncidentRepository _repository;

  /// The report being edited, or `null` when creating a new one.
  final Incident? editing;

  bool get isEditing => editing != null;

  void selectCategory(IncidentCategory category) =>
      emit(state.copyWith(category: category));

  void selectLocation(String location) =>
      emit(state.copyWith(location: location));

  void setImage(PickedImage image) => emit(state.copyWith(image: () => image));

  /// Removes the newly picked photo, or else the report's existing one.
  void removeImage() => emit(
    state.image != null
        ? state.copyWith(image: () => null)
        : state.copyWith(existingImageUrl: () => null),
  );

  Future<void> submit({
    required String title,
    required String description,
    required AppUser? reporter,
  }) async {
    if (state.isSubmitting) return;

    // The form validates in the UI too; this check stops invalid data from
    // reaching the repository even if it's called directly.
    final error =
        Validators.category(state.category) ??
        Validators.title(title) ??
        Validators.description(description) ??
        Validators.location(state.location);
    if (error != null) {
      emit(
        state.copyWith(
          status: ReportFormStatus.failure,
          errorMessage: () => error,
        ),
      );
      return;
    }
    if (reporter == null) {
      emit(
        state.copyWith(
          status: ReportFormStatus.failure,
          errorMessage: () => 'You need to be signed in to submit a report.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ReportFormStatus.submitting,
        errorMessage: () => null,
      ),
    );
    try {
      final existing = editing;
      final String id;
      if (existing == null) {
        id = await _repository.createIncident(
          title: title,
          description: description,
          category: state.category!,
          location: state.location!,
          reporter: reporter,
          image: state.image,
        );
      } else {
        await _repository.updateIncident(
          id: existing.id,
          title: title,
          description: description,
          category: state.category!,
          location: state.location!,
          reporter: reporter,
          newImage: state.image,
          keepExistingImage: state.existingImageUrl != null,
        );
        id = existing.id;
      }
      if (isClosed) return;
      emit(
        state.copyWith(status: ReportFormStatus.success, incidentId: () => id),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ReportFormStatus.failure,
          errorMessage: () => AppException.from(error).message,
        ),
      );
    }
  }
}
