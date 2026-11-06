import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';
import 'incident_list_cubit.dart';

export 'incident_list_state.dart';

/// Every incident on campus, for the staff dashboard.
class AllIncidentsCubit extends IncidentListCubit {
  AllIncidentsCubit(this._repository);

  final IncidentRepository _repository;

  @override
  Stream<List<Incident>> watchIncidents() => _repository.streamAllIncidents();
}
