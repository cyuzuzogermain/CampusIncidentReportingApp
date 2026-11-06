import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A purple gradient circle showing the user's initial.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.initial, this.size = 48});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.onPrimary,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
