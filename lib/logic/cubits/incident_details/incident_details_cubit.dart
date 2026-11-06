import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/incident.dart';
import '../../../data/repositories/app_exception.dart';
import '../../../data/repositories/incident_repository.dart';

part 'incident_details_state.dart';

/// Streams a single incident so its details update live, for example when
/// staff change its status.
class IncidentDetailsCubit extends Cubit<IncidentDetailsState> {
  IncidentDetailsCubit(this._repository) : super(const IncidentDetailsState());

  final IncidentRepository _repository;
  StreamSubscription<Incident?>? _subscription;

  void watch(String incidentId) {
    _subscription?.cancel();
    emit(const IncidentDetailsState());
    _subscription = _repository
        .streamIncident(incidentId)
        .listen(
          (incident) => emit(
            incident == null
                ? const IncidentDetailsState(
                    status: IncidentDetailsStatus.notFound,
                  )
                : IncidentDetailsState(
                    status: IncidentDetailsStatus.loaded,
                    incident: incident,
                  ),
          ),
          onError: (Object error) => emit(
            IncidentDetailsState(
              status: IncidentDetailsStatus.failure,
              incident: state.incident,
              errorMessage: AppException.from(error).message,
            ),
          ),
        );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
