import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/incident_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/incident.dart';
import '../../logic/cubits/auth/auth_cubit.dart';
import '../../logic/cubits/status_update/status_update_cubit.dart';
import 'app_card.dart';
import 'primary_button.dart';
import 'status_badge.dart';

/// Staff-only card that moves an incident's status forward, or rejects it,
/// after a confirmation dialog. Moving forward takes an optional comment;
/// rejecting needs a reason. Expects a [StatusUpdateCubit] above it.
class UpdateStatusSection extends StatelessWidget {
  const UpdateStatusSection({super.key, required this.incident});

  final Incident incident;

  Future<void> _confirmAndAdvance(
    BuildContext context,
    IncidentStatus next,
  ) async {
    final comment = await showDialog<String>(
      context: context,
      builder: (_) => StatusCommentDialog(
        title: 'Update status?',
        message:
            'Move "${incident.title}" from ${incident.status.label} '
            'to ${next.label}? This can’t be undone.',
        fieldLabel: 'Comment (optional)',
        hint: 'e.g. A technician is on the way',
        confirmLabel: 'Confirm',
      ),
    );
    if (comment == null || !context.mounted) return;

    await context.read<StatusUpdateCubit>().advanceStatus(
      incident: incident,
      user: context.read<AuthCubit>().state.user,
      comment: comment,
    );
  }

  Future<void> _confirmAndReject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => StatusCommentDialog(
        title: 'Reject report?',
        message:
            'The student will see your reason. A rejected report is '
            'closed and can’t be reopened.',
        fieldLabel: 'Reason for rejection',
        hint: 'e.g. Duplicate of an existing report',
        confirmLabel: 'Reject',
        required: true,
        destructive: true,
      ),
    );
    if (reason == null || !context.mounted) return;

    await context.read<StatusUpdateCubit>().reject(
      incident: incident,
      user: context.read<AuthCubit>().state.user,
      reason: reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = incident.status;
    final next = status.next;

    return BlocConsumer<StatusUpdateCubit, StatusUpdateState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
        if (state.status == StatusUpdateStatus.success) {
          final target = state.targetStatus!;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                target == IncidentStatus.rejected
                    ? 'Report rejected.'
                    : 'Status updated to ${target.label}.',
              ),
            ),
          );
        } else if (state.status == StatusUpdateStatus.failure) {
          messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final rejecting =
            state.isUpdating && state.targetStatus == IncidentStatus.rejected;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Status', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Current status',
                    style: AppTextStyles.bodySecondary,
                  ),
                  const Spacer(),
                  StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 16),
              if (status.isClosed)
                Row(
                  children: [
                    Icon(status.icon, color: status.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This report has been ${status.label.toLowerCase()}.',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                )
              else ...[
                PrimaryButton(
                  label: 'Mark as ${next!.label}',
                  icon: next.icon,
                  isLoading: state.isUpdating && !rejecting,
                  onPressed: state.isUpdating
                      ? null
                      : () => _confirmAndAdvance(context, next),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: state.isUpdating
                      ? null
                      : () => _confirmAndReject(context),
                  icon: rejecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      : const Icon(Icons.block_rounded, size: 20),
                  label: const Text('Reject Report'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Confirmation dialog with a comment field. Pops the trimmed comment (an
/// empty string when an optional one is left blank), or `null` on Cancel.
class StatusCommentDialog extends StatefulWidget {
  const StatusCommentDialog({
    super.key,
    required this.title,
    required this.message,
    required this.fieldLabel,
    required this.hint,
    required this.confirmLabel,
    this.required = false,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String fieldLabel;
  final String hint;
  final String confirmLabel;

  /// Whether the comment must be filled in (a rejection reason).
  final bool required;

  /// Shows the confirm button in the error color.
  final bool destructive;

  @override
  State<StatusCommentDialog> createState() => _StatusCommentDialogState();
}

class _StatusCommentDialogState extends State<StatusCommentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.message),
              const SizedBox(height: 16),
              Text(widget.fieldLabel, style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                autofocus: widget.required,
                minLines: 2,
                maxLines: 4,
                maxLength: AppConstants.statusCommentMaxLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: widget.hint),
                validator: (value) =>
                    widget.required && (value == null || value.trim().isEmpty)
                    ? 'Please give a reason'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: widget.destructive ? AppColors.error : null,
          ),
          onPressed: _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
