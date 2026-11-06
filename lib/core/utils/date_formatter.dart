import 'package:intl/intl.dart';

/// Date formatting helpers built on `intl`.
abstract final class DateFormatter {
  static final DateFormat _date = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTime = DateFormat('MMM d, yyyy • h:mm a');

  /// e.g. "Nov 3, 2026"
  static String date(DateTime value) => _date.format(value);

  /// e.g. "Nov 3, 2026 • 2:45 PM"
  static String dateTime(DateTime value) => _dateTime.format(value);
}
