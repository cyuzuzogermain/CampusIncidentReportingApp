import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/incident_status.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/incident_list/all_incidents_cubit.dart';
import '../../widgets/incident_list_sliver.dart';
import '../../widgets/search_and_filter_bar.dart';
import '../../widgets/summary_stat_card.dart';
import '../../widgets/user_avatar.dart';

/// Staff overview: counts across every incident and the full list with the
/// same search and filters students get.
class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AllIncidentsCubit, IncidentListState>(
          builder: (context, state) {
            final cubit = context.read<AllIncidentsCubit>();
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.screenPadding,
                    16,
                    AppDimens.screenPadding,
                    16,
                  ),
                  sliver: SliverList.list(
                    children: [
                      const _Header(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Overview',
                              style: AppTextStyles.sectionTitle,
                            ),
                          ),
                          Text(
                            '${state.total} total',
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // The total is in the heading so the four status
                      // cards fit on a phone.
                      SummaryStatRow(
                        cards: [
                          for (final status in IncidentStatus.values)
                            SummaryStatCard(
                              label: status.label,
                              count: state.countFor(status),
                              icon: status.icon,
                              color: status.color,
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'All Reports',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 12),
                      SearchAndFilterBar(
                        query: state.query,
                        statusFilter: state.statusFilter,
                        categoryFilter: state.categoryFilter,
                        onQueryChanged: cubit.searchChanged,
                        onStatusChanged: cubit.statusFilterChanged,
                        onCategoryChanged: cubit.categoryFilterChanged,
                      ),
                    ],
                  ),
                ),
                IncidentListSliver(
                  state: state,
                  onRetry: cubit.start,
                  showReporter: true,
                  emptyMessage: 'No one has reported an issue yet.',
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
                    'Review and resolve campus reports',
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
