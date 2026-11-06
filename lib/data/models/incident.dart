import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/incident_category.dart';
import '../../core/constants/incident_status.dart';
import 'status_change.dart';
import 'timestamp_parser.dart';

/// A campus incident stored at `incidents/{id}`.
class Incident extends Equatable {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.imageUrl,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    required this.statusHistory,
    this.affectedUserIds = const [],
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;

  /// Download URL of the optional photo.
  final String? imageUrl;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusChange> statusHistory;

  /// Other students who marked themselves as affected by this issue.
  final List<String> affectedUserIds;

  int get affectedCount => affectedUserIds.length;

  bool isAffected(String uid) => affectedUserIds.contains(uid);

  bool isReportedBy(String uid) => reporterId == uid;

  /// Why staff rejected the report, or `null` if it wasn't rejected.
  String? get rejectionReason => status == IncidentStatus.rejected
      ? historyFor(IncidentStatus.rejected)?.comment
      : null;

  /// The reporter can edit or withdraw a report until staff start on it.
  bool get canBeChangedByReporter => status == IncidentStatus.submitted;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// The first time this incident reached [target], or `null` if it hasn't.
  StatusChange? historyFor(IncidentStatus target) {
    for (final change in statusHistory) {
      if (change.status == target) return change;
    }
    return null;
  }

  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    final rawHistory = map['statusHistory'];
    final history = rawHistory is List
        ? rawHistory
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (entry) =>
                    StatusChange.fromMap(Map<String, dynamic>.from(entry)),
              )
              .toList()
        : <StatusChange>[];
    history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final rawAffected = map['affectedUserIds'];

    return Incident(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: IncidentCategory.fromValue(map['category'] as String?),
      location: map['location'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      status: IncidentStatus.fromValue(map['status'] as String?),
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
      statusHistory: List.unmodifiable(history),
      affectedUserIds: rawAffected is List
          ? List.unmodifiable(rawAffected.whereType<String>())
          : const [],
    );
  }

  factory Incident.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Incident.fromMap(doc.id, doc.data() ?? const {});

  /// The document body. The id isn't stored in the document itself.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.value,
      'location': location,
      'imageUrl': imageUrl,
      'status': status.value,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'statusHistory': statusHistory.map((change) => change.toMap()).toList(),
      'affectedUserIds': affectedUserIds,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    location,
    imageUrl,
    status,
    reporterId,
    reporterName,
    createdAt,
    updatedAt,
    statusHistory,
    affectedUserIds,
  ];
}
