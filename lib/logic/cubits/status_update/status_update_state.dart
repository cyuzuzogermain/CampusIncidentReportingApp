part of 'status_update_cubit.dart';

enum StatusUpdateStatus { idle, updating, success, failure }

class StatusUpdateState extends Equatable {
  const StatusUpdateState({
    this.status = StatusUpdateStatus.idle,
    this.targetStatus,
    this.errorMessage,
  });

  final StatusUpdateStatus status;

  /// The status being (or just) applied.
  final IncidentStatus? targetStatus;
  final String? errorMessage;

  bool get isUpdating => status == StatusUpdateStatus.updating;

  @override
  List<Object?> get props => [status, targetStatus, errorMessage];
}
