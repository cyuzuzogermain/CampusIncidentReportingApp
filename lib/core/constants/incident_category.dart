import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The categories a student can file an incident under.
enum IncidentCategory {
  facilities(
    'facilities',
    'Facilities',
    Icons.apartment_rounded,
    AppColors.facilities,
  ),
  water('water', 'Water', Icons.water_drop_rounded, AppColors.water),
  electricity(
    'electricity',
    'Electricity',
    Icons.bolt_rounded,
    AppColors.electricity,
  ),
  safety('safety', 'Safety', Icons.shield_rounded, AppColors.safety),
  sanitation(
    'sanitation',
    'Sanitation',
    Icons.cleaning_services_rounded,
    AppColors.sanitation,
  );

  const IncidentCategory(this.value, this.label, this.icon, this.color);

  /// The string stored in Firestore.
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  /// Parses a Firestore value. Unknown values fall back to [facilities] so an
  /// unexpected document never crashes the UI.
  static IncidentCategory fromValue(String? value) {
    return IncidentCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => IncidentCategory.facilities,
    );
  }
}
