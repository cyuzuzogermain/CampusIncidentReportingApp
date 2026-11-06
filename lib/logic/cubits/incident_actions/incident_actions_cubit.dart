import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/app_exception.dart';
import '../../../data/repositories/incident_repository.dart';

part 'incident_actions_state.dart';

/// The student actions on Incident Details: marking yourself as affected by
/// someone else's report, and withdrawing your own report.
///
/// The UI only offers each action when it's allowed, and the Firestore rules
/// enforce the same conditions. These checks stop a bad call early with a
/// clear message.
class IncidentActionsCubit extends Cubit<IncidentActionsState> {
  IncidentActionsCubit(this._repository) : super(const IncidentActionsState());

  final IncidentRepository _repository;

  /// Marks [user] as affected, or removes the mark if they already are.
  Future<void> toggleAffected({
    required Incident incident,
    required AppUser? user,
  }) {
    final affected = user != null && incident.isAffected(user.uid);
    final action = affected
        ? IncidentAction.unmarkAffected
        : IncidentAction.markAffected;
    return _run(action, () {
      if (user == null || user.isStaff) {
        return 'Only students can mark themselves as affected.';
      }
      if (incident.isReportedBy(user.uid)) {
        return 'You reported this issue yourself.';
      }
      if (!affected && incident.status.isClosed) {
        return 'This report is already '
            '${incident.status.label.toLowerCase()}.';
      }
      return null;
    }, () => _repository.setAffected(incident.id, user!, affected: !affected));
  }

  /// Withdraws [incident]. Only its reporter can, before staff start on it.
  Future<void> withdraw({required Incident incident, required AppUser? user}) {
    return _run(
      IncidentAction.withdraw,
      () {
        if (user == null || !incident.isReportedBy(user.uid)) {
          return 'Only the student who filed this report can withdraw it.';
        }
        if (!incident.canBeChangedByReporter) {
          return 'Staff have already started on this report, so it can no '
              'longer be withdrawn.';
        }
        return null;
      },
      () => _repository.withdrawIncident(incident.id, user!),
    );
  }

  Future<void> _run(
    IncidentAction action,
    String? Function() check,
    Future<void> Function() perform,
  ) async {
    if (state.isWorking) return;

    final error = check();
    if (error != null) {
      emit(
        IncidentActionsState(
          status: IncidentActionStatus.failure,
          action: action,
          errorMessage: error,
        ),
      );
      return;
    }

    emit(
      IncidentActionsState(
        status: IncidentActionStatus.working,
        action: action,
      ),
    );
    try {
      await perform();
      if (isClosed) return;
      emit(
        IncidentActionsState(
          status: IncidentActionStatus.success,
          action: action,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        IncidentActionsState(
          status: IncidentActionStatus.failure,
          action: action,
          errorMessage: AppException.from(error).message,
        ),
      );
    }
  }
}
