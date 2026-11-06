import 'package:flutter/foundation.dart' show kIsWeb;

/// Where incident photos are stored.
///
/// New Firebase projects need the paid Blaze plan for Cloud Storage, so during
/// development photos go to the official Firebase Storage Emulator running on
/// the laptop. Auth and Firestore always use the real cloud project.
///
/// To switch to the real cloud bucket, set [useEmulator] to `false`. Nothing
/// else needs to change.
abstract final class StorageConfig {
  /// `true`: photos go to the local Storage Emulator.
  /// `false`: photos go to the cloud bucket.
  static const bool useEmulator = true;

  /// Where the app reaches the emulator:
  /// - web (`flutter run -d web-server`): the browser runs on the laptop, so
  ///   it uses `127.0.0.1`, the address `firebase.json` binds the emulator to.
  /// - Android emulator: `10.0.2.2`, its alias for the laptop's localhost.
  static const String emulatorHost = kIsWeb ? '127.0.0.1' : '10.0.2.2';

  /// Hosts the emulator can appear under in saved download URLs.
  static const Set<String> _emulatorUrlHosts = {
    '10.0.2.2',
    '127.0.0.1',
    'localhost',
  };

  /// Must match `emulators.storage.port` in `firebase.json`.
  static const int emulatorPort = 9199;

  /// Bucket name used with the emulator. The emulator accepts any name; this
  /// one matches the `firebase emulators:start --project` id.
  static const String emulatorBucket = 'campus-incident-app-aedd3.appspot.com';

  /// The project's real Cloud Storage bucket (see `firebase_options.dart`).
  static const String cloudBucket =
      'campus-incident-app-aedd3.firebasestorage.app';

  /// The bucket every `FirebaseStorage` instance in the app uses.
  static const String bucket = useEmulator ? emulatorBucket : cloudBucket;

  /// The `gs://` URL form of [bucket].
  static const String bucketUrl = 'gs://$bucket';

  /// Rewrites an emulator download URL so it loads on the current platform.
  ///
  /// The URL saved in Firestore includes the host of whoever uploaded the
  /// photo: `10.0.2.2` from Android, `127.0.0.1` from the web. Swapping in
  /// [emulatorHost] lets photos uploaded on one platform display on the
  /// other. Cloud URLs are returned unchanged.
  static String displayUrl(String url) {
    if (!useEmulator) return url;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.port != emulatorPort ||
        !_emulatorUrlHosts.contains(uri.host)) {
      return url;
    }
    return uri.replace(host: emulatorHost).toString();
  }
}
