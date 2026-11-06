import 'dart:typed_data';

import 'package:campus_incident_app/core/constants/storage_config.dart';
import 'package:campus_incident_app/data/models/picked_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageConfig.displayUrl', () {
    const path = '/v0/b/bucket/o/incident_photos%2Fa.jpg?alt=media&token=t';

    test('rewrites emulator URLs to this platform’s emulator host', () {
      for (final host in ['10.0.2.2', '127.0.0.1', 'localhost']) {
        final url = StorageConfig.displayUrl('http://$host:9199$path');
        expect(Uri.parse(url).host, StorageConfig.emulatorHost, reason: host);
        expect(url, endsWith(path));
      }
    });

    test('leaves cloud and other URLs unchanged', () {
      const cloud =
          'https://firebasestorage.googleapis.com/v0/b/x/o/a.jpg?alt=media';
      expect(StorageConfig.displayUrl(cloud), cloud);
      expect(
        StorageConfig.displayUrl('http://10.0.2.2:8080/a.jpg'),
        'http://10.0.2.2:8080/a.jpg',
      );
    });
  });

  group('PickedImage.contentType', () {
    PickedImage image(String name, [String? mime]) =>
        PickedImage(bytes: Uint8List(1), name: name, mimeType: mime);

    test('prefers the reported image MIME type', () {
      expect(image('x.bin', 'image/webp').contentType, 'image/webp');
    });

    test('falls back to the file extension, then JPEG', () {
      expect(image('photo.PNG').contentType, 'image/png');
      expect(image('photo.jpg').contentType, 'image/jpeg');
      expect(
        image('blob', 'application/octet-stream').contentType,
        'image/jpeg',
      );
    });
  });
}
