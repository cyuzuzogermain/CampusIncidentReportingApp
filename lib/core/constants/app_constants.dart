/// App-wide constant values.
abstract final class AppConstants {
  static const String appName = 'Campus Incidents';

  // Firestore collections and Storage folders.
  static const String usersCollection = 'users';
  static const String incidentsCollection = 'incidents';
  static const String incidentPhotosFolder = 'incident_photos';

  // Validation limits.
  static const int titleMaxLength = 60;
  static const int descriptionMinLength = 10;
  static const int passwordMinLength = 6;

  /// Longest staff comment on a status change. Must match `firestore.rules`.
  static const int statusCommentMaxLength = 500;

  /// Must match the size limit in `storage.rules`.
  static const int maxPhotoBytes = 5 * 1024 * 1024;

  /// The fixed list of campus locations a student can choose from.
  static const List<String> campusLocations = [
    'Block A',
    'Block B — Room 204',
    'Student Residence',
    'Cafeteria',
    'Library',
    'Sports Field',
  ];
}
