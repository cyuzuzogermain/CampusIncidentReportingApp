part of 'incident_actions_cubit.dart';

/// What a student can do to someone else's report or their own one.
enum IncidentAction { markAffected, unmarkAffected, withdraw }

enum IncidentActionStatus { idle, working, success, failure }

class IncidentActionsState extends Equatable {
  const IncidentActionsState({
    this.status = IncidentActionStatus.idle,
    this.action,
    this.errorMessage,
  });

  final IncidentActionStatus status;

  /// The action being (or just) carried out.
  final IncidentAction? action;
  final String? errorMessage;

  bool get isWorking => status == IncidentActionStatus.working;

  bool isWorkingOn(IncidentAction target) => isWorking && action == target;

  @override
  List<Object?> get props => [status, action, errorMessage];
}
