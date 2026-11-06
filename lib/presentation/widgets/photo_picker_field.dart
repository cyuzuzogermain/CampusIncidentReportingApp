import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/storage_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/picked_image.dart';

/// Optional photo input: a dashed placeholder that opens a camera/gallery
/// sheet, then a preview with a remove button.
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.image,
    required this.onPicked,
    required this.onRemoved,
    this.imageUrl,
    this.enabled = true,
  });

  final PickedImage? image;

  /// An already uploaded photo, shown when no new [image] is picked (for
  /// example when editing a report).
  final String? imageUrl;
  final ValueChanged<PickedImage> onPicked;
  final VoidCallback onRemoved;
  final bool enabled;

  Future<void> _choose(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      // Read the bytes here so the rest of the app works the same on the
      // web, where picked files have no usable path.
      final bytes = await file.readAsBytes();
      onPicked(
        PickedImage(bytes: bytes, name: file.name, mimeType: file.mimeType),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final picked = image;
    final url = imageUrl;
    if (picked != null || url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (picked != null)
              Image.memory(
                picked.bytes,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Image.network(
                StorageConfig.displayUrl(url!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 200,
                  child: ColoredBox(
                    color: AppColors.primaryLight,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Remove photo',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.onPrimary,
                  ),
                  onPressed: enabled ? onRemoved : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: enabled ? () => _choose(context) : null,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: const SizedBox(
          height: 140,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 10),
              Text('Add a photo', style: AppTextStyles.label),
              SizedBox(height: 2),
              Text(
                'Take one or choose from your gallery',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  static const double _dash = 6;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }

    canvas.drawRRect(
      rect,
      Paint()..color = AppColors.primary.withValues(alpha: 0.04),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
