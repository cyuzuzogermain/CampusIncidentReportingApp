import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';
import 'incident_list_cubit.dart';

export 'incident_list_state.dart';

/// The signed-in student's own reports.
class MyIncidentsCubit extends IncidentListCubit {
  MyIncidentsCubit(this._repository, {required this.uid});

  final IncidentRepository _repository;
  final String uid;

  @override
  Stream<List<Incident>> watchIncidents() => _repository.streamMyIncidents(uid);
}
