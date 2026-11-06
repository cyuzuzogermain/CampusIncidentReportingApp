import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/incident_status.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/app_exception.dart';
import '../../../data/repositories/incident_repository.dart';

part 'status_update_state.dart';

/// Staff status changes: move an incident one step forward (Submitted →
/// In Progress → Resolved) with an optional comment, or reject it with a
/// required reason. Each change records the staff member in `statusHistory`.
class StatusUpdateCubit extends Cubit<StatusUpdateState> {
  StatusUpdateCubit(this._repository) : super(const StatusUpdateState());

  final IncidentRepository _repository;

  /// Moves [incident] to its next status. [comment] is optional.
  Future<void> advanceStatus({
    required Incident incident,
    required AppUser? user,
    String? comment,
  }) {
    final next = incident.status.next;
    return _change(
      incident: incident,
      user: user,
      target: next,
      comment: comment,
      closedMessage:
          'This report is already ${incident.status.label.toLowerCase()}.',
    );
  }

  /// Rejects [incident]. A non-empty [reason] is required.
  Future<void> reject({
    required Incident incident,
    required AppUser? user,
    required String reason,
  }) {
    return _change(
      incident: incident,
      user: user,
      target: incident.status.canBeRejected ? IncidentStatus.rejected : null,
      comment: reason,
      commentRequired: true,
      closedMessage:
          'This report is already ${incident.status.label.toLowerCase()}.',
    );
  }

  Future<void> _change({
    required Incident incident,
    required AppUser? user,
    required IncidentStatus? target,
    required String? comment,
    required String closedMessage,
    bool commentRequired = false,
  }) async {
    if (state.isUpdating) return;

    // The controls are only shown to staff, and the Firestore rules reject
    // students anyway. This check is a third line of defence.
    if (user == null || !user.isStaff) {
      emit(
        const StatusUpdateState(
          status: StatusUpdateStatus.failure,
          errorMessage: 'Only staff members can update a report’s status.',
        ),
      );
      return;
    }

    if (target == null) {
      emit(
        StatusUpdateState(
          status: StatusUpdateStatus.failure,
          errorMessage: closedMessage,
        ),
      );
      return;
    }

    final note = comment?.trim() ?? '';
    if (commentRequired && note.isEmpty) {
      emit(
        StatusUpdateState(
          status: StatusUpdateStatus.failure,
          targetStatus: target,
          errorMessage: 'Please give a reason for the rejection.',
        ),
      );
      return;
    }

    emit(
      StatusUpdateState(
        status: StatusUpdateStatus.updating,
        targetStatus: target,
      ),
    );
    try {
      await _repository.updateStatus(
        incident.id,
        target,
        user,
        comment: note.isEmpty ? null : note,
      );
      if (isClosed) return;
      emit(
        StatusUpdateState(
          status: StatusUpdateStatus.success,
          targetStatus: target,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        StatusUpdateState(
          status: StatusUpdateStatus.failure,
          targetStatus: target,
          errorMessage: AppException.from(error).message,
        ),
      );
    }
  }
}
