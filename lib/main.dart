import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/constants/storage_config.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/incident_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Always name the bucket explicitly: Storage was never enabled in the cloud
  // project, so the default bucket can't be relied on.
  final storage = FirebaseStorage.instanceFor(bucket: StorageConfig.bucketUrl);

  // Only Storage uses the emulator. Auth and Firestore stay on the real cloud
  // project. This must run before the first Storage call.
  if (StorageConfig.useEmulator) {
    await storage.useStorageEmulator(
      StorageConfig.emulatorHost,
      StorageConfig.emulatorPort,
    );
  }

  runApp(
    CampusIncidentApp(
      authRepository: AuthRepository(),
      incidentRepository: IncidentRepository(storage: storage),
    ),
  );
}
