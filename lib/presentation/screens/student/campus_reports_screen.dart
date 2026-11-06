import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../logic/cubits/incident_list/all_incidents_cubit.dart';
import '../../widgets/incident_list_sliver.dart';
import '../../widgets/search_and_filter_bar.dart';

/// Every report on campus, read-only for students. Opening one lets a
/// student mark themselves as affected by the same issue.
class CampusReportsScreen extends StatelessWidget {
  const CampusReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Reports')),
      body: BlocBuilder<AllIncidentsCubit, IncidentListState>(
        builder: (context, state) {
          final cubit = context.read<AllIncidentsCubit>();
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
                    const Text(
                      'Issues reported by students across campus. Affected by '
                      'one too? Open it and add yourself.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 16),
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
    );
  }
}
