import 'package:equatable/equatable.dart';

import '../../../core/constants/incident_category.dart';
import '../../../core/constants/incident_status.dart';
import '../../../data/models/incident.dart';

enum IncidentListStatus { loading, loaded, failure }

/// State shared by [MyIncidentsCubit] and [AllIncidentsCubit]: the incidents
/// from the stream plus the client-side search and filters.
class IncidentListState extends Equatable {
  const IncidentListState({
    this.status = IncidentListStatus.loading,
    this.incidents = const [],
    this.query = '',
    this.statusFilter,
    this.categoryFilter,
    this.errorMessage,
  });

  final IncidentListStatus status;

  /// Every incident from the stream, newest first.
  final List<Incident> incidents;
  final String query;

  /// `null` means "All".
  final IncidentStatus? statusFilter;

  /// `null` means every category.
  final IncidentCategory? categoryFilter;
  final String? errorMessage;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty || statusFilter != null || categoryFilter != null;

  /// [incidents] after applying the search text and filters.
  List<Incident> get filtered {
    final needle = query.trim().toLowerCase();
    return incidents.where((incident) {
      if (statusFilter != null && incident.status != statusFilter) {
        return false;
      }
      if (categoryFilter != null && incident.category != categoryFilter) {
        return false;
      }
      if (needle.isEmpty) return true;
      return incident.title.toLowerCase().contains(needle) ||
          incident.description.toLowerCase().contains(needle) ||
          incident.location.toLowerCase().contains(needle);
    }).toList();
  }

  int get total => incidents.length;

  /// How many incidents (ignoring filters) are at [status].
  int countFor(IncidentStatus status) =>
      incidents.where((incident) => incident.status == status).length;

  IncidentListState copyWith({
    IncidentListStatus? status,
    List<Incident>? incidents,
    String? query,
    IncidentStatus? Function()? statusFilter,
    IncidentCategory? Function()? categoryFilter,
    String? Function()? errorMessage,
  }) {
    return IncidentListState(
      status: status ?? this.status,
      incidents: incidents ?? this.incidents,
      query: query ?? this.query,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      categoryFilter: categoryFilter != null
          ? categoryFilter()
          : this.categoryFilter,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    incidents,
    query,
    statusFilter,
    categoryFilter,
    errorMessage,
  ];
}
