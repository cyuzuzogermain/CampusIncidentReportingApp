import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/incident_category.dart';
import '../../../core/constants/incident_status.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/app_exception.dart';
import 'incident_list_state.dart';

/// Shared logic for a live, searchable, filterable list of incidents.
/// Subclasses only decide which stream to watch.
abstract class IncidentListCubit extends Cubit<IncidentListState> {
  IncidentListCubit() : super(const IncidentListState());

  StreamSubscription<List<Incident>>? _subscription;

  /// The incidents this list shows.
  Stream<List<Incident>> watchIncidents();

  /// Starts (or restarts) listening to the incidents stream.
  void start() {
    _subscription?.cancel();
    final loading = state.copyWith(
      status: IncidentListStatus.loading,
      errorMessage: () => null,
    );
    if (loading != state) emit(loading);
    _subscription = watchIncidents().listen(
      (incidents) => emit(
        state.copyWith(
          status: IncidentListStatus.loaded,
          incidents: incidents,
          errorMessage: () => null,
        ),
      ),
      onError: (Object error) => emit(
        state.copyWith(
          status: IncidentListStatus.failure,
          errorMessage: () => AppException.from(error).message,
        ),
      ),
    );
  }

  void searchChanged(String query) => emit(state.copyWith(query: query));

  void statusFilterChanged(IncidentStatus? status) =>
      emit(state.copyWith(statusFilter: () => status));

  void categoryFilterChanged(IncidentCategory? category) =>
      emit(state.copyWith(categoryFilter: () => category));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
