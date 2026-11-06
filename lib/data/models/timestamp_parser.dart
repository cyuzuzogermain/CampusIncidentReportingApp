import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts a Firestore date field to a [DateTime].
///
/// A `serverTimestamp()` that hasn't reached the server yet shows up as
/// `null` in local snapshots, so we fall back to the current time instead of
/// crashing.
DateTime parseTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.now();
}
