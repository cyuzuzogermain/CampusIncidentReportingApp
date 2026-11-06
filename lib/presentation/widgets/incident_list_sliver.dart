import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/cubits/incident_list/incident_list_state.dart';
import 'empty_state.dart';
import 'incident_card.dart';

/// The filtered incident list as a sliver, with loading, error and empty
/// states. Used by My Reports, Campus Reports and the staff dashboard.
class IncidentListSliver extends StatelessWidget {
  const IncidentListSliver({
    super.key,
    required this.state,
    required this.onRetry,
    this.showReporter = false,
    this.emptyTitle = 'No reports yet',
    this.emptyMessage = 'Reports will appear here once they are submitted.',
  });

  final IncidentListState state;
  final VoidCallback onRetry;
  final bool showReporter;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case IncidentListStatus.loading:
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      case IncidentListStatus.failure:
        return SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load reports",
            message: state.errorMessage ?? 'Please try again.',
            action: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ),
        );
      case IncidentListStatus.loaded:
        break;
    }

    final incidents = state.filtered;
    if (incidents.isEmpty) {
      return SliverToBoxAdapter(
        child: state.incidents.isEmpty
            ? EmptyState(
                icon: Icons.inbox_outlined,
                title: emptyTitle,
                message: emptyMessage,
              )
            : const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching reports',
                message: 'Try a different search or clear the filters.',
              ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      sliver: SliverList.separated(
        itemCount: incidents.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final incident = incidents[index];
          return IncidentCard(
            incident: incident,
            showReporter: showReporter,
            onTap: () => context.push(AppRoutes.incidentDetails(incident.id)),
          );
        },
      ),
    );
  }
}
