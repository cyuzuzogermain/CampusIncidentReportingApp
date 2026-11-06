part of 'incident_details_cubit.dart';

enum IncidentDetailsStatus { loading, loaded, notFound, failure }

class IncidentDetailsState extends Equatable {
  const IncidentDetailsState({
    this.status = IncidentDetailsStatus.loading,
    this.incident,
    this.errorMessage,
  });

  final IncidentDetailsStatus status;
  final Incident? incident;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, incident, errorMessage];
}
