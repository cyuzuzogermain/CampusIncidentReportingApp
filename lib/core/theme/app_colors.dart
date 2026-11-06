import 'package:flutter/material.dart';

/// Every color used in the app. Widgets read from here (or from
/// `Theme.of(context)`) instead of hard-coding hex values.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF6C4CF1);
  static const Color primaryLight = Color(0xFFEDE8FF);
  static const Color primaryGradientEnd = Color(0xFF9B7BFF);

  // Surfaces
  static const Color background = Color(0xFFF6F5FB);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE9E7F2);
  static const Color inputBorder = Color(0xFFE3E0EE);

  // Text
  static const Color textPrimary = Color(0xFF1D1B2F);
  static const Color textSecondary = Color(0xFF6E6B85);
  static const Color textHint = Color(0xFFA3A0B7);
  static const Color onPrimary = Colors.white;

  // Feedback
  static const Color error = Color(0xFFE5484D);
  static const Color errorLight = Color(0xFFFDECEC);

  // Status badges
  static const Color submitted = Color(0xFFD98A00);
  static const Color submittedLight = Color(0xFFFFF4D9);
  static const Color inProgress = Color(0xFF4F63F0);
  static const Color inProgressLight = Color(0xFFE8EBFF);
  static const Color resolved = Color(0xFF1E9E5A);
  static const Color resolvedLight = Color(0xFFE2F6EA);
  static const Color rejected = error;
  static const Color rejectedLight = errorLight;
  static const Color pending = Color(0xFFD5D2E2);

  // Categories
  static const Color facilities = Color(0xFF6C4CF1);
  static const Color water = Color(0xFF2B8FE8);
  static const Color electricity = Color(0xFFE3A008);
  static const Color safety = Color(0xFFE5484D);
  static const Color sanitation = Color(0xFF12A594);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryGradientEnd],
  );
}
