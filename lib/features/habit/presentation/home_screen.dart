import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alpha/core/theme/app_colors.dart';
import 'package:alpha/core/theme/app_theme.dart';
import 'package:alpha/core/providers.dart';
import 'package:alpha/core/utils/date_utils.dart';
import 'package:alpha/features/habit/domain/habit_model.dart';
import 'package:alpha/features/habit/presentation/add_habit_sheet.dart';
import 'package:alpha/features/habit/presentation/habit_detail_sheet.dart';
import 'package:alpha/features/habit/presentation/widgets/habit_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Midnight streak reset check on app launch.
    Future.microtask(() {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        ref.read(habitRepoProvider).checkAndResetStreaks(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  void _toggleHabit(HabitModel habit) {
    final todayKey = AppDateUtils.todayKey;
    ref.read(habitRepoProvider).toggleCompletion(
      habit.userId,
      habit.id,
      todayKey,
    );
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddHabitSheet(),
    );
  }

  void _openDetailSheet(HabitModel habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitDetailSheet(habit: habit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final target = ref.watch(targetStreamProvider).valueOrNull;
    final maxStreak = ref.watch(maxStreakProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        top: true,
        child: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (habits) {
            final unchecked =
                habits.where((h) => !h.isCompletedToday).toList();
            final checked =
                habits.where((h) => h.isCompletedToday).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // ── HEADER ──────────────────────────────
                  _buildHeader(tt, target, maxStreak),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // ── HABIT SECTION ───────────────────────
                  Text('HABIT', style: tt.labelSmall),
                  const SizedBox(height: AppSpacing.md),

                  if (unchecked.isEmpty && checked.isEmpty)
                    _buildEmptyState(tt),

                  // Staggered cards
                  ...List.generate(unchecked.length, (i) {
                    return _StaggeredFadeIn(
                      controller: _staggerCtrl,
                      index: i,
                      totalItems: unchecked.length + checked.length,
                      child: HabitCard(
                        key: ValueKey(unchecked[i].id),
                        habit: unchecked[i],
                        onToggle: () => _toggleHabit(unchecked[i]),
                        onTap: () => _openDetailSheet(unchecked[i]),
                      ),
                    );
                  }),

                  // ── COMPLETED SECTION ───────────────────
                  if (checked.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('COMPLETED', style: tt.labelSmall),
                    const SizedBox(height: AppSpacing.md),
                    ...List.generate(checked.length, (i) {
                      final idx = unchecked.length + i;
                      return _StaggeredFadeIn(
                        controller: _staggerCtrl,
                        index: idx,
                        totalItems: unchecked.length + checked.length,
                        child: HabitCard(
                          key: ValueKey(checked[i].id),
                          habit: checked[i],
                          onToggle: () => _toggleHabit(checked[i]),
                          onTap: () => _openDetailSheet(checked[i]),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 100), // FAB clearance
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildHeader(TextTheme tt, dynamic target, int maxStreak) {
    final dayElapsed = target?.dayElapsed ?? 1;
    final totalDays = target?.totalDays ?? 90;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Day counter
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Day $dayElapsed', style: tt.displayLarge),
              Text(
                '/$totalDays',
                style: tt.titleMedium,
              ),
            ],
          ),
        ),

        // Streak pill
        if (maxStreak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.streakOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.streakOrange,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '$maxStreak',
                  style: tt.titleSmall?.copyWith(
                    color: AppColors.streakOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(TextTheme tt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.add_task_rounded, size: 40, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No habits yet',
            style: tt.titleSmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to create your first habit',
            style: tt.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Fades and slides in a child with a staggered delay based on [index].
class _StaggeredFadeIn extends StatelessWidget {
  const _StaggeredFadeIn({
    required this.controller,
    required this.index,
    required this.totalItems,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final int totalItems;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.06).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(start, 1.0);

    final opacity = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ));

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }
}
