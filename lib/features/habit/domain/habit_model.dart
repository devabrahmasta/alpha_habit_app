import 'package:alpha/core/utils/date_utils.dart';

/// How often a habit repeats.
enum RepeatType { daily, weekly, monthly }

class HabitModel {
  final String id;
  final String userId;
  final String name;
  final String? timeLabel;
  final DateTime createdAt;
  final int currentStreak;
  final int longestStreak;
  final Map<String, bool> completionLog;

  /// Repeat configuration
  final RepeatType repeatType;
  final int repeatInterval;       // every N days/weeks/months
  final List<int> repeatWeekdays; // 0=Sun … 6=Sat (used when weekly)

  const HabitModel({
    required this.id,
    required this.userId,
    required this.name,
    this.timeLabel,
    required this.createdAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completionLog = const {},
    this.repeatType = RepeatType.daily,
    this.repeatInterval = 1,
    this.repeatWeekdays = const [0, 1, 2, 3, 4, 5, 6], // all days
  });

  /// Whether this habit is completed for today.
  bool get isCompletedToday =>
      completionLog[AppDateUtils.todayKey] == true;

  /// Checks if this habit is **scheduled** for [date].
  ///
  /// - Daily: always scheduled
  /// - Weekly: only on matching weekdays in [repeatWeekdays]
  /// - Monthly: only on the same day-of-month as [createdAt]
  bool isScheduledForDate(DateTime date) {
    switch (repeatType) {
      case RepeatType.daily:
        return true;

      case RepeatType.weekly:
        // DateTime.weekday: 1=Mon … 7=Sun
        // Our model:        0=Sun … 6=Sat
        final normalized = date.weekday == 7 ? 0 : date.weekday;
        return repeatWeekdays.contains(normalized);

      case RepeatType.monthly:
        return date.day == createdAt.day;
    }
  }

  /// Human-readable repeat summary.
  String get repeatLabel {
    switch (repeatType) {
      case RepeatType.daily:
        if (repeatInterval == 1) return 'Every day';
        return 'Every $repeatInterval days';
      case RepeatType.weekly:
        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        final selected = repeatWeekdays.map((d) => dayNames[d]).join(', ');
        final prefix = repeatInterval == 1
            ? 'Every week'
            : 'Every $repeatInterval weeks';
        return '$prefix · $selected';
      case RepeatType.monthly:
        if (repeatInterval == 1) return 'Every month';
        return 'Every $repeatInterval months';
    }
  }

  HabitModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? timeLabel,
    DateTime? createdAt,
    int? currentStreak,
    int? longestStreak,
    Map<String, bool>? completionLog,
    RepeatType? repeatType,
    int? repeatInterval,
    List<int>? repeatWeekdays,
  }) {
    return HabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      timeLabel: timeLabel ?? this.timeLabel,
      createdAt: createdAt ?? this.createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      completionLog: completionLog ?? this.completionLog,
      repeatType: repeatType ?? this.repeatType,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
    );
  }

  /// Recalculates [currentStreak] and [longestStreak] from [completionLog],
  /// **respecting the repeat schedule**.
  ///
  /// Walks backwards from today:
  /// - Scheduled + completed → streak++
  /// - Scheduled + NOT completed → BREAK
  /// - Not scheduled → skip (don't break, don't increment)
  HabitModel recalculateStreak() {
    int streak = 0;
    DateTime day = AppDateUtils.stripTime(DateTime.now());
    final earliest = AppDateUtils.stripTime(createdAt).subtract(const Duration(days: 1));

    while (day.isAfter(earliest)) {
      final key = AppDateUtils.toDateKey(day);
      final scheduled = isScheduledForDate(day);
      final completed = completionLog[key] == true;

      if (scheduled) {
        if (completed) {
          streak++;
        } else {
          break; // scheduled but missed → streak broken
        }
      }
      // not scheduled → skip silently

      day = day.subtract(const Duration(days: 1));
    }

    final newLongest = streak > longestStreak ? streak : longestStreak;
    return copyWith(currentStreak: streak, longestStreak: newLongest);
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'timeLabel': timeLabel,
        'createdAt': createdAt.toIso8601String(),
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'completionLog': completionLog,
        'repeatType': repeatType.name,
        'repeatInterval': repeatInterval,
        'repeatWeekdays': repeatWeekdays,
      };

  factory HabitModel.fromMap(String id, String userId, Map<String, dynamic> m) {
    return HabitModel(
      id: id,
      userId: userId,
      name: m['name'] as String,
      timeLabel: m['timeLabel'] as String?,
      createdAt: DateTime.parse(m['createdAt'] as String),
      currentStreak: (m['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (m['longestStreak'] as num?)?.toInt() ?? 0,
      completionLog: Map<String, bool>.from(
        (m['completionLog'] as Map<String, dynamic>?) ?? {},
      ),
      repeatType: RepeatType.values.firstWhere(
        (e) => e.name == (m['repeatType'] as String?),
        orElse: () => RepeatType.daily,
      ),
      repeatInterval: (m['repeatInterval'] as num?)?.toInt() ?? 1,
      repeatWeekdays: List<int>.from(
        (m['repeatWeekdays'] as List<dynamic>?) ?? [0, 1, 2, 3, 4, 5, 6],
      ),
    );
  }
}
