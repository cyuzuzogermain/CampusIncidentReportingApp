import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/storage_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/incident_actions/incident_actions_cubit.dart';
import '../../../logic/cubits/incident_details/incident_details_cubit.dart';
import '../../../logic/cubits/status_update/status_update_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/status_timeline.dart';
import '../../widgets/student_incident_actions.dart';
import '../../widgets/update_status_section.dart';

class IncidentDetailsScreen extends StatelessWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<IncidentRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => IncidentDetailsCubit(repository)..watch(incidentId),
        ),
        BlocProvider(create: (_) => StatusUpdateCubit(repository)),
        BlocProvider(create: (_) => IncidentActionsCubit(repository)),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Report Details')),
        body: BlocListener<IncidentActionsCubit, IncidentActionsState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _onActionChanged,
          child: BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
            builder: (context, state) {
              switch (state.status) {
                case IncidentDetailsStatus.loading:
                  return const Center(child: CircularProgressIndicator());
                case IncidentDetailsStatus.notFound:
                  // The report disappears as soon as the student withdraws it;
                  // the listener then closes this screen.
                  if (context.read<IncidentActionsCubit>().state.action ==
                      IncidentAction.withdraw) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Center(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Report not found',
                      message: 'It may have been removed.',
                      action: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Go back'),
                      ),
                    ),
                  );
                case IncidentDetailsStatus.failure:
                  if (state.incident == null) {
                    return Center(
                      child: EmptyState(
                        icon: Icons.lock_outline_rounded,
                        title: "Couldn't open this report",
                        message: state.errorMessage ?? 'Please try again.',
                      ),
                    );
                  }
                case IncidentDetailsStatus.loaded:
                  break;
              }
              return _DetailsBody(incident: state.incident!);
            },
          ),
        ),
      ),
    );
  }

  void _onActionChanged(BuildContext context, IncidentActionsState state) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (state.status == IncidentActionStatus.failure) {
      messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      return;
    }
    if (state.status != IncidentActionStatus.success) return;
    switch (state.action!) {
      case IncidentAction.withdraw:
        messenger.showSnackBar(
          const SnackBar(content: Text('Your report was withdrawn.')),
        );
        context.pop();
      case IncidentAction.markAffected:
        messenger.showSnackBar(
          const SnackBar(content: Text('Thanks! You were added as affected.')),
        );
      case IncidentAction.unmarkAffected:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('You were removed from the affected students.'),
          ),
        );
    }
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final category = incident.category;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.screenPadding,
        8,
        AppDimens.screenPadding,
        32,
      ),
      children: [
        _HeaderImage(incident: incident),
        const SizedBox(height: 16),
        Row(
          children: [
            StatusBadge(status: incident.status),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(category.icon, size: 14, color: category.color),
                  const SizedBox(width: 4),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: category.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(incident.title, style: AppTextStyles.title),
        const SizedBox(height: 16),
        if (incident.rejectionReason != null) ...[
          _RejectionCard(reason: incident.rejectionReason!),
          const SizedBox(height: 16),
        ],
        AppCard(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: incident.location,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Submitted',
                value: DateFormatter.dateTime(incident.createdAt),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Reported by',
                value: incident.reporterName,
              ),
              if (incident.affectedCount > 0) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.groups_outlined,
                  label: 'Also affected',
                  value: incident.affectedCount == 1
                      ? '1 other student'
                      : '${incident.affectedCount} other students',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status Timeline', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 16),
              StatusTimeline(incident: incident),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                Text(incident.description, style: AppTextStyles.body),
              ],
            ),
          ),
        ),
        if (incident.hasImage) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Photo', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _NetworkImage(
                    url: incident.imageUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Staff get the status controls. Students get Edit/Withdraw on
        // their own report, or "affects me too" on someone else's.
        BlocBuilder<AuthCubit, AuthState>(
          buildWhen: (previous, current) => previous.user != current.user,
          builder: (context, auth) {
            final user = auth.user;
            if (user == null) return const SizedBox.shrink();
            final Widget section;
            if (user.isStaff) {
              section = UpdateStatusSection(incident: incident);
            } else if (incident.isReportedBy(user.uid)) {
              section = ReporterActionsSection(incident: incident);
            } else {
              section = AffectedSection(incident: incident, uid: user.uid);
            }
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: section,
            );
          },
        ),
      ],
    );
  }
}

/// Why staff rejected the report, shown near the top for everyone.
class _RejectionCard extends StatelessWidget {
  const _RejectionCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.rejectedLight,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: AppColors.rejected.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.rejected),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This report was rejected',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.rejected,
                  ),
                ),
                const SizedBox(height: 4),
                Text(reason, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final category = incident.category;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: incident.hasImage
            ? _NetworkImage(url: incident.imageUrl!, fit: BoxFit.cover)
            : ColoredBox(
                color: category.color.withValues(alpha: 0.12),
                child: Icon(category.icon, size: 64, color: category.color),
              ),
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url, required this.fit});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      StorageConfig.displayUrl(url),
      fit: fit,
      width: double.infinity,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const SizedBox(
              height: 190,
              child: Center(child: CircularProgressIndicator()),
            ),
      errorBuilder: (context, error, stackTrace) => const SizedBox(
        height: 190,
        child: ColoredBox(
          color: AppColors.primaryLight,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.primary,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.label),
            ],
          ),
        ),
      ],
    );
  }
}
