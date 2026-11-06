import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The lifecycle of an incident: Submitted → In Progress → Resolved.
///
/// Staff can also reject a report that is Submitted or In Progress. Resolved
/// and Rejected are both final.
enum IncidentStatus {
  submitted(
    'submitted',
    'Submitted',
    Icons.schedule_rounded,
    AppColors.submitted,
    AppColors.submittedLight,
  ),
  inProgress(
    'in_progress',
    'In Progress',
    Icons.autorenew_rounded,
    AppColors.inProgress,
    AppColors.inProgressLight,
  ),
  resolved(
    'resolved',
    'Resolved',
    Icons.check_circle_rounded,
    AppColors.resolved,
    AppColors.resolvedLight,
  ),
  rejected(
    'rejected',
    'Rejected',
    Icons.cancel_rounded,
    AppColors.rejected,
    AppColors.rejectedLight,
  );

  /// The normal path, in order. Rejected is a side exit, not a step.
  static const List<IncidentStatus> flow = [submitted, inProgress, resolved];

  const IncidentStatus(
    this.value,
    this.label,
    this.icon,
    this.color,
    this.backgroundColor,
  );

  /// The string stored in Firestore.
  final String value;
  final String label;
  final IconData icon;

  /// Foreground color of the status badge.
  final Color color;

  /// Background color of the status badge.
  final Color backgroundColor;

  /// The next status in the flow, or `null` once the incident is closed.
  IncidentStatus? get next => switch (this) {
    IncidentStatus.submitted => IncidentStatus.inProgress,
    IncidentStatus.inProgress => IncidentStatus.resolved,
    IncidentStatus.resolved || IncidentStatus.rejected => null,
  };

  /// Resolved or rejected: nothing more happens to the incident.
  bool get isClosed => next == null;

  /// Staff can reject a report until it is closed.
  bool get canBeRejected => !isClosed;

  /// Whether this step of [flow] has been reached when the incident is at
  /// [current]. A rejected incident reaches no further steps.
  bool isReachedBy(IncidentStatus current) =>
      current != IncidentStatus.rejected &&
      flow.indexOf(current) >= flow.indexOf(this);

  static IncidentStatus fromValue(String? value) {
    return IncidentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => IncidentStatus.submitted,
    );
  }
}
