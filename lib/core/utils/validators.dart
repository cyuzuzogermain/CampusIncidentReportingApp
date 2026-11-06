import '../constants/app_constants.dart';
import '../constants/incident_category.dart';

/// Form validators. Each returns an error message, or `null` when valid, so
/// they plug straight into `TextFormField.validator`.
abstract final class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[\w.+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$',
  );

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? name(String? value) => required(value, field: 'Name');

  static String? department(String? value) =>
      required(value, field: 'Department');

  static String? email(String? value) {
    final missing = required(value, field: 'Email');
    if (missing != null) return missing;
    if (!_emailRegExp.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < AppConstants.passwordMinLength) {
      return 'Password must be at least '
          '${AppConstants.passwordMinLength} characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? title(String? value) {
    final missing = required(value, field: 'Title');
    if (missing != null) return missing;
    if (value!.trim().length > AppConstants.titleMaxLength) {
      return 'Title must be at most ${AppConstants.titleMaxLength} characters';
    }
    return null;
  }

  static String? description(String? value) {
    if (value == null ||
        value.trim().length < AppConstants.descriptionMinLength) {
      return 'Description must be at least '
          '${AppConstants.descriptionMinLength} characters';
    }
    return null;
  }

  static String? location(String? value) {
    if (value == null || value.isEmpty) return 'Please select a location';
    return null;
  }

  static String? category(IncidentCategory? value) {
    if (value == null) return 'Please select a category';
    return null;
  }
}
