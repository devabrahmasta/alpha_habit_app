import 'dart:async';

import 'package:alpha/core/utils/date_utils.dart';
import 'package:alpha/features/habit/domain/habit_model.dart';

/// In-memory habit repository — swap for Firestore later.
class HabitRepository {
  HabitRepository._();
  static final instance = HabitRepository._();

  final Map<String, HabitModel> _store = {};
  final _controller = StreamController<List<HabitModel>>.broadcast();

  void _emit() {
    final sorted = _store.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(sorted);
  }

  /// Real-time stream of habits for [userId].
  Stream<List<HabitModel>> watchHabits(String userId) async* {
    // Emit current snapshot immediately.
    final current = _store.values
        .where((h) => h.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield current;
    yield* _controller.stream
        .map((all) => all.where((h) => h.userId == userId).toList());
  }

  Future<void> addHabit(HabitModel habit) async {
    _store[habit.id] = habit;
    _emit();
  }

  Future<void> updateHabit(HabitModel habit) async {
    _store[habit.id] = habit;
    _emit();
  }

  Future<void> deleteHabit(String habitId) async {
    _store.remove(habitId);
    _emit();
  }

  /// Toggles the completion for [habitId] on [dateKey].
  /// Recalculates streaks after toggling.
  Future<HabitModel?> toggleCompletion(String habitId, String dateKey) async {
    final habit = _store[habitId];
    if (habit == null) return null;

    final log = Map<String, bool>.from(habit.completionLog);
    final wasCompleted = log[dateKey] == true;
    if (wasCompleted) {
      log.remove(dateKey);
    } else {
      log[dateKey] = true;
    }

    final updated = habit.copyWith(completionLog: log).recalculateStreak();
    _store[habitId] = updated;
    _emit();
    return updated;
  }

  /// Midnight streak reset — call on app launch.
  Future<void> checkAndResetStreaks(String userId) async {
    final yesterday = AppDateUtils.yesterdayKey;
    for (final entry in _store.entries.toList()) {
      final habit = entry.value;
      if (habit.userId != userId) continue;
      final completedYesterday = habit.completionLog[yesterday] == true;
      if (!completedYesterday && habit.currentStreak > 0) {
        _store[entry.key] = habit.copyWith(currentStreak: 0);
      }
    }
    _emit();
  }
}
