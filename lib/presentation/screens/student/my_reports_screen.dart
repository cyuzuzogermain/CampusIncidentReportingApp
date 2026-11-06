import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/incident_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/incident_list/my_incidents_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/incident_list_sliver.dart';
import '../../widgets/search_and_filter_bar.dart';
import '../../widgets/user_avatar.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: BlocBuilder<MyIncidentsCubit, IncidentListState>(
        builder: (context, state) {
          final cubit = context.read<MyIncidentsCubit>();
          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.screenPadding,
                  8,
                  AppDimens.screenPadding,
                  16,
                ),
                sliver: SliverList.list(
                  children: [
                    _ProfileHeaderCard(state: state),
                    const SizedBox(height: 20),
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
                emptyMessage: 'Tap the + button to report your first issue.',
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

/// The student's name and department with their report counts.
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.state});

  final IncidentListState state;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (previous, current) => previous.user != current.user,
      builder: (context, auth) {
        final user = auth.user;
        return AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  UserAvatar(initial: user?.initial ?? '?', size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '',
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.department ?? '',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Stat(
                    label: 'Total',
                    value: state.total,
                    color: AppColors.primary,
                  ),
                  _Stat(
                    label: IncidentStatus.inProgress.label,
                    value: state.countFor(IncidentStatus.inProgress),
                    color: IncidentStatus.inProgress.color,
                  ),
                  _Stat(
                    label: IncidentStatus.resolved.label,
                    value: state.countFor(IncidentStatus.resolved),
                    color: IncidentStatus.resolved.color,
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTextStyles.statNumber.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
