import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A photo the user picked, held in memory.
///
/// Raw bytes (rather than a file path) work the same on Android and the web,
/// where there is no file system: they're previewed with `Image.memory` and
/// uploaded with `putData`.
class PickedImage extends Equatable {
  const PickedImage({required this.bytes, required this.name, this.mimeType});

  final Uint8List bytes;

  /// Original file name, used only to work out the content type.
  final String name;

  /// MIME type reported by the picker, if any (often null on Android).
  final String? mimeType;

  int get sizeInBytes => bytes.lengthInBytes;

  /// The content type sent to Storage. It must start with `image/` to pass
  /// `storage.rules`.
  String get contentType {
    final reported = mimeType;
    if (reported != null && reported.startsWith('image/')) return reported;
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  @override
  List<Object?> get props => [name, mimeType, bytes];
}
