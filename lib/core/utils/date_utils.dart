import 'package:intl/intl.dart';

/// Date helpers — prefixed "App" to avoid clash with Flutter's [DateUtils].
abstract final class AppDateUtils {
  static final _keyFormat = DateFormat('yyyy-MM-dd');

  /// Converts [date] to a Firestore-compatible key like `"2025-01-15"`.
  static String toDateKey(DateTime date) => _keyFormat.format(date);

  /// Today's date key.
  static String get todayKey => toDateKey(DateTime.now());

  /// Yesterday's date key.
  static String get yesterdayKey =>
      toDateKey(DateTime.now().subtract(const Duration(days: 1)));

  /// Date key for [n] days ago.
  static String daysAgoKey(int n) =>
      toDateKey(DateTime.now().subtract(Duration(days: n)));

  /// Whether [dateKey] is within the last [n] days (inclusive of today).
  static bool isWithinLastNDays(String dateKey, int n) {
    final date = _keyFormat.parseStrict(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(date.year, date.month, date.day)).inDays;
    return diff >= 0 && diff < n;
  }

  /// Whether [dateKey] represents today.
  static bool isToday(String dateKey) => dateKey == todayKey;

  /// Strips time from a [DateTime], leaving only the date.
  static DateTime stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
