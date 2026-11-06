import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/incident_status.dart';
import 'timestamp_parser.dart';

/// One entry in an incident's `statusHistory`: who moved it to which status,
/// when, and an optional staff comment (required for a rejection).
class StatusChange extends Equatable {
  const StatusChange({
    required this.status,
    required this.changedBy,
    required this.changedByName,
    required this.timestamp,
    this.comment,
  });

  final IncidentStatus status;

  /// UID of the user who made the change.
  final String changedBy;
  final String changedByName;
  final DateTime timestamp;

  /// The staff member's note, or `null` if they didn't add one.
  final String? comment;

  bool get hasComment => comment != null && comment!.isNotEmpty;

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    return StatusChange(
      status: IncidentStatus.fromValue(map['status'] as String?),
      changedBy: map['changedBy'] as String? ?? '',
      changedByName: map['changedByName'] as String? ?? '',
      timestamp: parseTimestamp(map['timestamp']),
      comment: map['comment'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'changedBy': changedBy,
      'changedByName': changedByName,
      'timestamp': Timestamp.fromDate(timestamp),
      if (comment != null) 'comment': comment,
    };
  }

  @override
  List<Object?> get props => [
    status,
    changedBy,
    changedByName,
    timestamp,
    comment,
  ];
}
