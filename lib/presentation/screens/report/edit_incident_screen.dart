import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/incident_repository.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/incident_details/incident_details_cubit.dart';
import '../../../logic/cubits/report_form/report_form_cubit.dart';
import '../../widgets/empty_state.dart';
import 'report_incident_screen.dart';

/// Lets the reporter edit their report while it is still Submitted. Loads
/// the report, then shows the report form filled in with it.
class EditIncidentScreen extends StatelessWidget {
  const EditIncidentScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<IncidentRepository>();
    return BlocProvider(
      create: (_) => IncidentDetailsCubit(repository)..watch(incidentId),
      child: BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
        // Build the form once, from the first loaded copy, so later live
        // updates don't wipe what the student is typing.
        buildWhen: (previous, current) => previous.incident == null,
        builder: (context, state) {
          final incident = state.incident;
          if (incident == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Report')),
              body: state.status == IncidentDetailsStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: "Couldn't open this report",
                        message:
                            state.errorMessage ?? 'It may have been withdrawn.',
                      ),
                    ),
            );
          }

          final uid = context.read<AuthCubit>().state.user?.uid ?? '';
          if (!incident.isReportedBy(uid) || !incident.canBeChangedByReporter) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Report')),
              body: Center(
                child: EmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: "This report can't be edited",
                  message:
                      'Only the student who filed a report can edit '
                      'it, and only before staff start working on it.',
                  action: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ),
              ),
            );
          }

          return BlocProvider(
            create: (_) => ReportFormCubit(repository, editing: incident),
            child: const ReportIncidentView(),
          );
        },
      ),
    );
  }
}
