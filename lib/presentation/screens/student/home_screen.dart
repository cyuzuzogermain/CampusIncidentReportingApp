import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/incident_status.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/incident_list/my_incidents_cubit.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/summary_stat_card.dart';
import '../../widgets/user_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.screenPadding,
            16,
            AppDimens.screenPadding,
            32,
          ),
          children: const [
            _Greeting(),
            SizedBox(height: 20),
            _ReportBanner(),
            SizedBox(height: 24),
            Text('Report Summary', style: AppTextStyles.sectionTitle),
            SizedBox(height: 12),
            _Summary(),
            SizedBox(height: 24),
            _RecentReportsHeader(),
            SizedBox(height: 8),
            _RecentReports(),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (previous, current) => previous.user != current.user,
      builder: (context, state) {
        final user = state.user;
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${user?.firstName ?? 'there'} 👋',
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Help make our campus safer',
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            ),
            if (user != null) UserAvatar(initial: user.initial),
          ],
        );
      },
    );
  }
}

class _ReportBanner extends StatelessWidget {
  const _ReportBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'See an issue on campus?',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Report it in a few taps and track its progress.',
                  style: TextStyle(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.reportIncident),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: const Text('Report an Issue'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.campaign_rounded,
            size: 72,
            color: AppColors.onPrimary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyIncidentsCubit, IncidentListState>(
      buildWhen: (previous, current) => previous.incidents != current.incidents,
      builder: (context, state) {
        return SummaryStatRow(
          cards: [
            SummaryStatCard(
              label: 'My Reports',
              count: state.total,
              icon: Icons.description_rounded,
              color: AppColors.primary,
            ),
            SummaryStatCard(
              label: IncidentStatus.inProgress.label,
              count: state.countFor(IncidentStatus.inProgress),
              icon: IncidentStatus.inProgress.icon,
              color: IncidentStatus.inProgress.color,
            ),
            SummaryStatCard(
              label: IncidentStatus.resolved.label,
              count: state.countFor(IncidentStatus.resolved),
              icon: IncidentStatus.resolved.icon,
              color: IncidentStatus.resolved.color,
            ),
            SummaryStatCard(
              label: IncidentStatus.submitted.label,
              count: state.countFor(IncidentStatus.submitted),
              icon: IncidentStatus.submitted.icon,
              color: IncidentStatus.submitted.color,
            ),
          ],
        );
      },
    );
  }
}

class _RecentReportsHeader extends StatelessWidget {
  const _RecentReportsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text('Recent Reports', style: AppTextStyles.sectionTitle),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.reports),
          child: const Text('See all'),
        ),
      ],
    );
  }
}

class _RecentReports extends StatelessWidget {
  const _RecentReports();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyIncidentsCubit, IncidentListState>(
      builder: (context, state) {
        switch (state.status) {
          case IncidentListStatus.loading:
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          case IncidentListStatus.failure:
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              title: "Couldn't load reports",
              message: state.errorMessage ?? 'Please try again.',
            );
          case IncidentListStatus.loaded:
            break;
        }

        if (state.incidents.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No reports yet',
            message: 'Tap the + button to report your first issue.',
          );
        }

        final recent = state.incidents.take(3).toList();
        return Column(
          children: [
            for (final incident in recent) ...[
              IncidentCard(
                incident: incident,
                onTap: () =>
                    context.push(AppRoutes.incidentDetails(incident.id)),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}
