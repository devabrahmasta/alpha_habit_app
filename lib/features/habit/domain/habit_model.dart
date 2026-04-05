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
    this.repeatWeekdays = const [1, 2, 3, 4, 5, 6, 0], // all days
  });

  /// Whether this habit is completed for today.
  bool get isCompletedToday =>
      completionLog[AppDateUtils.todayKey] == true;

  /// Human-readable repeat summary, e.g. "Every day", "Every 2 weeks · Mon, Wed, Fri".
  String get repeatLabel {
    switch (repeatType) {
      case RepeatType.daily:
        if (repeatInterval == 1) return 'Every day';
        return 'Every $repeatInterval days';
      case RepeatType.weekly:
        final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
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

  /// Recalculates [currentStreak] and [longestStreak] from [completionLog].
  HabitModel recalculateStreak() {
    int streak = 0;
    DateTime day = AppDateUtils.stripTime(DateTime.now());

    // Walk backwards from today counting consecutive completed days.
    while (true) {
      final key = AppDateUtils.toDateKey(day);
      if (completionLog[key] == true) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
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
        (m['repeatWeekdays'] as List<dynamic>?) ?? [1, 2, 3, 4, 5, 6, 0],
      ),
    );
  }
}
