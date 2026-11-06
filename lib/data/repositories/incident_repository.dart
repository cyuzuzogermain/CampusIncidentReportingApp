import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/incident_category.dart';
import '../../core/constants/incident_status.dart';
import '../../core/constants/storage_config.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/picked_image.dart';
import '../models/status_change.dart';
import 'app_exception.dart';

/// Reads and writes incidents in Firestore and their photos in Storage.
class IncidentRepository {
  /// [storage] defaults to the explicitly named bucket from [StorageConfig].
  /// `FirebaseStorage.instanceFor` returns the same cached instance that
  /// `main.dart` pointed at the emulator.
  IncidentRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage =
          storage ??
          FirebaseStorage.instanceFor(bucket: StorageConfig.bucketUrl);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection(AppConstants.incidentsCollection);

  /// Creates an incident and returns its id.
  ///
  /// If [image] is given, the photo is uploaded first to
  /// `incident_photos/{incidentId}.jpg`, then the document is written with its
  /// download URL and an initial `submitted` entry in `statusHistory`.
  Future<String> createIncident({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    required AppUser reporter,
    PickedImage? image,
  }) async {
    try {
      final docRef = _incidents.doc();
      String? imageUrl;

      if (image != null) {
        imageUrl = await _uploadPhoto(
          '${docRef.id}.jpg',
          image,
          ownerUid: reporter.uid,
        );
      }

      final initialEntry = StatusChange(
        status: IncidentStatus.submitted,
        changedBy: reporter.uid,
        changedByName: reporter.name,
        timestamp: DateTime.now(),
      );

      await docRef.set({
        'title': title.trim(),
        'description': description.trim(),
        'category': category.value,
        'location': location,
        'imageUrl': imageUrl,
        'status': IncidentStatus.submitted.value,
        'reporterId': reporter.uid,
        'reporterName': reporter.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': [initialEntry.toMap()],
        'affectedUserIds': <String>[],
      });

      return docRef.id;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Uploads [image] to `incident_photos/{fileName}`. The `ownerUid`
  /// metadata is what `storage.rules` checks before letting the reporter
  /// delete the photo later.
  Future<String> _uploadPhoto(
    String fileName,
    PickedImage image, {
    required String ownerUid,
  }) async {
    if (image.sizeInBytes > AppConstants.maxPhotoBytes) {
      throw const AppException('The photo must be smaller than 5 MB.');
    }
    final ref = _storage.ref(AppConstants.incidentPhotosFolder).child(fileName);
    // putData works on Android and the web (putFile needs dart:io).
    await ref.putData(
      image.bytes,
      SettableMetadata(
        contentType: image.contentType,
        customMetadata: {'ownerUid': ownerUid},
      ),
    );
    return ref.getDownloadURL();
  }

  /// Deletes a photo, ignoring failures: a leftover file is harmless, and
  /// photos uploaded before owner metadata existed can't be deleted.
  Future<void> _tryDeletePhoto(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _storage.refFromURL(StorageConfig.displayUrl(url)).delete();
    } catch (_) {}
  }

  /// Reads an incident inside [transaction] and checks that [reporterUid]
  /// filed it and that staff haven't started on it yet.
  Future<Map<String, dynamic>> _getChangeableByReporter(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> docRef,
    String reporterUid,
  ) async {
    final snapshot = await transaction.get(docRef);
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const AppException('This report no longer exists.');
    }
    if (data['reporterId'] != reporterUid) {
      throw const AppException(
        'Only the student who filed this report can '
        'change it.',
      );
    }
    if (IncidentStatus.fromValue(data['status'] as String?) !=
        IncidentStatus.submitted) {
      throw const AppException(
        'Staff have already started on this report, '
        'so it can no longer be changed.',
      );
    }
    return data;
  }

  /// Saves the reporter's changes to a report that is still `submitted`.
  ///
  /// [newImage] replaces the photo. Otherwise the photo is kept when
  /// [keepExistingImage] is true and removed when it's false. A new photo
  /// gets a new file name so cached copies of the old one aren't shown.
  Future<void> updateIncident({
    required String id,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    required AppUser reporter,
    PickedImage? newImage,
    bool keepExistingImage = true,
  }) async {
    String? uploadedUrl;
    try {
      if (newImage != null) {
        uploadedUrl = await _uploadPhoto(
          '${id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          newImage,
          ownerUid: reporter.uid,
        );
      }

      final docRef = _incidents.doc(id);
      final oldUrl = await _firestore.runTransaction((transaction) async {
        final data = await _getChangeableByReporter(
          transaction,
          docRef,
          reporter.uid,
        );
        final currentUrl = data['imageUrl'] as String?;
        final imageUrl = uploadedUrl ?? (keepExistingImage ? currentUrl : null);

        transaction.update(docRef, {
          'title': title.trim(),
          'description': description.trim(),
          'category': category.value,
          'location': location,
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return imageUrl == currentUrl ? null : currentUrl;
      });

      await _tryDeletePhoto(oldUrl);
    } catch (error) {
      await _tryDeletePhoto(uploadedUrl);
      throw AppException.from(error);
    }
  }

  /// Withdraws (deletes) a report. Only its reporter can, and only while it
  /// is still `submitted`.
  Future<void> withdrawIncident(String id, AppUser reporter) async {
    try {
      final docRef = _incidents.doc(id);
      final imageUrl = await _firestore.runTransaction((transaction) async {
        final data = await _getChangeableByReporter(
          transaction,
          docRef,
          reporter.uid,
        );
        transaction.delete(docRef);
        return data['imageUrl'] as String?;
      });
      await _tryDeletePhoto(imageUrl);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Adds or removes [student] from the students affected by an incident.
  Future<void> setAffected(
    String id,
    AppUser student, {
    required bool affected,
  }) async {
    try {
      await _incidents.doc(id).update({
        'affectedUserIds': affected
            ? FieldValue.arrayUnion([student.uid])
            : FieldValue.arrayRemove([student.uid]),
      });
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// The signed-in student's incidents, newest first.
  ///
  /// Sorting happens on the client, so this query doesn't need a composite
  /// index.
  Stream<List<Incident>> streamMyIncidents(String uid) {
    return _incidents
        .where('reporterId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final incidents = snapshot.docs.map(Incident.fromFirestore).toList();
          incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return incidents;
        })
        .transform(AppException.streamTransformer());
  }

  /// Every incident, newest first. Staff see it on their dashboard and
  /// students on the read-only Campus Reports tab.
  Stream<List<Incident>> streamAllIncidents() {
    return _incidents
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Incident.fromFirestore).toList())
        .transform(AppException.streamTransformer());
  }

  /// A single incident. Emits `null` if it doesn't exist.
  Stream<Incident?> streamIncident(String id) {
    return _incidents
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Incident.fromFirestore(doc) : null)
        .transform(AppException.streamTransformer());
  }

  /// Moves an incident to [newStatus] and appends [staffUser], with their
  /// optional [comment], to its `statusHistory`.
  ///
  /// [newStatus] must be the next step in the flow, or `rejected` while the
  /// incident is still open. A rejection needs a [comment] with the reason.
  ///
  /// Runs in a transaction so that two staff members updating at once can't
  /// skip or repeat a step.
  Future<void> updateStatus(
    String id,
    IncidentStatus newStatus,
    AppUser staffUser, {
    String? comment,
  }) async {
    try {
      final note = comment?.trim();
      final hasNote = note != null && note.isNotEmpty;
      if (newStatus == IncidentStatus.rejected && !hasNote) {
        throw const AppException('Please give a reason for the rejection.');
      }
      if (hasNote && note.length > AppConstants.statusCommentMaxLength) {
        throw const AppException('The comment is too long.');
      }

      final docRef = _incidents.doc(id);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw const AppException('This report no longer exists.');
        }
        final current = IncidentStatus.fromValue(
          snapshot.data()?['status'] as String?,
        );
        final allowed = newStatus == IncidentStatus.rejected
            ? current.canBeRejected
            : current.next == newStatus;
        if (!allowed) {
          throw const AppException(
            'This report was already updated. Please refresh and try again.',
          );
        }

        final entry = StatusChange(
          status: newStatus,
          changedBy: staffUser.uid,
          changedByName: staffUser.name,
          timestamp: DateTime.now(),
          comment: hasNote ? note : null,
        );

        transaction.update(docRef, {
          'status': newStatus.value,
          'updatedAt': FieldValue.serverTimestamp(),
          'statusHistory': FieldValue.arrayUnion([entry.toMap()]),
        });
      });
    } catch (error) {
      throw AppException.from(error);
    }
  }
}
