import 'package:flutter/material.dart';

import '../../core/constants/incident_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/incident.dart';

/// Vertical Submitted → In Progress → Resolved timeline. Reached steps get a
/// checkmark, the time and person from `statusHistory`, and any staff
/// comment. A rejected report shows the steps it reached, then Rejected.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.incident});

  final Incident incident;

  bool _reached(IncidentStatus step) =>
      step.isReachedBy(incident.status) ||
      (incident.status == IncidentStatus.rejected &&
          (step == IncidentStatus.submitted ||
              step == IncidentStatus.rejected ||
              incident.historyFor(step) != null));

  @override
  Widget build(BuildContext context) {
    final steps = incident.status == IncidentStatus.rejected
        ? [...IncidentStatus.flow.where(_reached), IncidentStatus.rejected]
        : IncidentStatus.flow;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(
            step: steps[i],
            incident: incident,
            reached: _reached(steps[i]),
            isLast: i == steps.length - 1,
            nextReached: i < steps.length - 1 && _reached(steps[i + 1]),
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.incident,
    required this.reached,
    required this.isLast,
    required this.nextReached,
  });

  final IncidentStatus step;
  final Incident incident;
  final bool reached;
  final bool isLast;
  final bool nextReached;

  @override
  Widget build(BuildContext context) {
    final entry = incident.historyFor(step);

    final String subtitle;
    if (entry != null) {
      subtitle =
          '${DateFormatter.dateTime(entry.timestamp)}'
          '${entry.changedByName.isNotEmpty ? '\nby ${entry.changedByName}' : ''}';
    } else {
      subtitle = reached ? 'Completed' : 'Pending';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: reached ? step.color : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: reached ? step.color : AppColors.pending,
                      width: 2,
                    ),
                  ),
                  child: reached
                      ? Icon(
                          step == IncidentStatus.rejected
                              ? Icons.close_rounded
                              : Icons.check_rounded,
                          size: 16,
                          color: AppColors.onPrimary,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: nextReached ? step.color : AppColors.pending,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: AppTextStyles.label.copyWith(
                      color: reached
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                  if (entry != null && entry.hasComment) ...[
                    const SizedBox(height: 8),
                    _Comment(text: entry.comment!, color: step.color),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A staff comment under a timeline step.
class _Comment extends StatelessWidget {
  const _Comment({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
