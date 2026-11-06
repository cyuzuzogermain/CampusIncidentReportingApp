import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/incident.dart';
import '../../logic/cubits/auth/auth_cubit.dart';
import '../../logic/cubits/incident_actions/incident_actions_cubit.dart';
import 'app_card.dart';
import 'primary_button.dart';

/// Shown to the student who filed [incident]: Edit and Withdraw while it is
/// still Submitted, otherwise a note that it's locked. Expects an
/// [IncidentActionsCubit] above it.
class ReporterActionsSection extends StatelessWidget {
  const ReporterActionsSection({super.key, required this.incident});

  final Incident incident;

  Future<void> _confirmAndWithdraw(BuildContext context) async {
    final others = incident.affectedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw report?'),
        content: Text(
          '"${incident.title}" will be removed for everyone'
          '${others > 0 ? ', including the $others '
                    '${others == 1 ? 'student' : 'students'} who said they are '
                    'affected' : ''}. This can’t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<IncidentActionsCubit>().withdraw(
      incident: incident,
      user: context.read<AuthCubit>().state.user,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!incident.canBeChangedByReporter) {
      final reason = incident.status.isClosed
          ? 'This report is ${incident.status.label.toLowerCase()}'
          : 'Staff are working on this report';
      return AppCard(
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$reason, so it can no longer be edited or withdrawn.',
                style: AppTextStyles.bodySecondary,
              ),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<IncidentActionsCubit, IncidentActionsState>(
      builder: (context, state) {
        final withdrawing = state.isWorkingOn(IncidentAction.withdraw);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Manage Report', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 6),
              const Text(
                'You can edit or withdraw this report until staff start '
                'working on it.',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isWorking
                          ? null
                          : () => context.push(
                              AppRoutes.editIncident(incident.id),
                            ),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: state.isWorking
                          ? null
                          : () => _confirmAndWithdraw(context),
                      icon: withdrawing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          : const Icon(Icons.undo_rounded, size: 20),
                      label: const Text('Withdraw'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shown to other students: how many are affected and a button to add or
/// remove themselves. Expects an [IncidentActionsCubit] above it.
class AffectedSection extends StatelessWidget {
  const AffectedSection({super.key, required this.incident, required this.uid});

  final Incident incident;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final affected = incident.isAffected(uid);
    final closed = incident.status.isClosed;
    final count = incident.affectedCount;

    final String summary;
    if (affected) {
      summary = count == 1
          ? 'You said this issue affects you too.'
          : 'You and ${count - 1} other '
                '${count - 1 == 1 ? 'student' : 'students'} are affected.';
    } else if (count == 0) {
      summary = 'No other students have said they are affected yet.';
    } else {
      summary =
          '$count other ${count == 1 ? 'student is' : 'students are'} '
          'affected by this issue.';
    }

    return BlocBuilder<IncidentActionsCubit, IncidentActionsState>(
      builder: (context, state) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Affected Students',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 6),
              Text(summary, style: AppTextStyles.bodySecondary),
              if (affected || !closed) ...[
                const SizedBox(height: 16),
                if (affected)
                  OutlinedButton.icon(
                    onPressed: state.isWorking ? null : () => _toggle(context),
                    icon: state.isWorkingOn(IncidentAction.unmarkAffected)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 20,
                          ),
                    label: const Text('I’m no longer affected'),
                  )
                else
                  PrimaryButton(
                    label: 'This affects me too',
                    icon: Icons.group_add_outlined,
                    isLoading: state.isWorkingOn(IncidentAction.markAffected),
                    onPressed: state.isWorking ? null : () => _toggle(context),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _toggle(BuildContext context) {
    context.read<IncidentActionsCubit>().toggleAffected(
      incident: incident,
      user: context.read<AuthCubit>().state.user,
    );
  }
}
