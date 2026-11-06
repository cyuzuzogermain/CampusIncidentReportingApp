import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The rounded purple badge shown on the splash and auth screens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.campaign_rounded,
        color: AppColors.onPrimary,
        size: size * 0.5,
      ),
    );
  }
}
