import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alpha/core/services/mock_auth_service.dart';
import 'package:alpha/features/habit/data/habit_repository.dart';
import 'package:alpha/features/habit/domain/habit_model.dart';
import 'package:alpha/features/target/data/target_repository.dart';
import 'package:alpha/features/target/domain/target_model.dart';

// ──────────────────────────────────────────────
//  SERVICE SINGLETONS
// ──────────────────────────────────────────────

final authServiceProvider = Provider<MockAuthService>((_) => MockAuthService.instance);
final habitRepoProvider = Provider<HabitRepository>((_) => HabitRepository.instance);
final targetRepoProvider = Provider<TargetRepository>((_) => TargetRepository.instance);

// ──────────────────────────────────────────────
//  AUTH
// ──────────────────────────────────────────────

final authStateProvider = StreamProvider<MockUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ──────────────────────────────────────────────
//  HABITS
// ──────────────────────────────────────────────

final habitsStreamProvider = StreamProvider<List<HabitModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(habitRepoProvider).watchHabits(user.uid);
});

/// Maximum current streak across all habits.
final maxStreakProvider = Provider<int>((ref) {
  final habits = ref.watch(habitsStreamProvider).valueOrNull ?? [];
  if (habits.isEmpty) return 0;
  return habits.fold<int>(0, (max, h) => h.currentStreak > max ? h.currentStreak : max);
});

// ──────────────────────────────────────────────
//  TARGET
// ──────────────────────────────────────────────

final targetStreamProvider = StreamProvider<TargetModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(targetRepoProvider).watchTarget(user.uid);
});

// ──────────────────────────────────────────────
//  ONBOARDING
// ──────────────────────────────────────────────

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
});
