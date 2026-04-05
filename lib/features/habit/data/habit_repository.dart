import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:alpha/core/utils/date_utils.dart';
import 'package:alpha/features/habit/domain/habit_model.dart';

/// Firestore-backed habit repository with real-time streams.
class HabitRepository {
  HabitRepository._();
  static final instance = HabitRepository._();

  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _habitsCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('habits');

  /// Real-time stream of habits for [userId], ordered by createdAt desc.
  Stream<List<HabitModel>> watchHabits(String userId) {
    return _habitsCol(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => HabitModel.fromMap(doc.id, userId, doc.data()))
            .toList());
  }

  Future<void> addHabit(HabitModel habit) async {
    await _habitsCol(habit.userId).doc(habit.id).set(habit.toMap());
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _habitsCol(habit.userId).doc(habit.id).update(habit.toMap());
  }

  Future<void> deleteHabit(String userId, String habitId) async {
    await _habitsCol(userId).doc(habitId).delete();
  }

  /// Toggle completion for [habitId] on [dateKey].
  /// Validates the date is scheduled before toggling.
  /// Returns the updated [HabitModel] with recalculated streak, or null on error.
  Future<HabitModel?> toggleCompletion(
    String userId,
    String habitId,
    String dateKey,
  ) async {
    final docRef = _habitsCol(userId).doc(habitId);

    try {
      final snap = await docRef.get();
      if (!snap.exists) return null;

      final habit = HabitModel.fromMap(habitId, userId, snap.data()!);

      // Validate schedule
      final date = AppDateUtils.parseDateKey(dateKey);
      if (!habit.isScheduledForDate(date)) return null;

      // Toggle
      final log = Map<String, bool>.from(habit.completionLog);
      if (log[dateKey] == true) {
        log.remove(dateKey);
      } else {
        log[dateKey] = true;
      }

      final updated = habit.copyWith(completionLog: log).recalculateStreak();
      await docRef.update(updated.toMap());
      return updated;
    } catch (e) {
      debugPrint('Error toggling habit: $e');
      return null;
    }
  }

  /// Midnight streak reset — call on app launch.
  /// Only resets if yesterday was **scheduled** but not completed.
  Future<void> checkAndResetStreaks(String userId) async {
    final snap = await _habitsCol(userId).get();
    final yesterday = AppDateUtils.yesterdayKey;
    final yesterdayDate = AppDateUtils.stripTime(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final batch = _firestore.batch();
    bool hasChanges = false;

    for (final doc in snap.docs) {
      final habit = HabitModel.fromMap(doc.id, userId, doc.data());
      final wasScheduled = habit.isScheduledForDate(yesterdayDate);
      final completed = habit.completionLog[yesterday] == true;

      if (wasScheduled && !completed && habit.currentStreak > 0) {
        batch.update(doc.reference, {'currentStreak': 0});
        hasChanges = true;
      }
    }

    if (hasChanges) await batch.commit();
  }
}
