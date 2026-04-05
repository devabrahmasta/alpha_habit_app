import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alpha/core/theme/app_colors.dart';
import 'package:alpha/core/theme/app_theme.dart';
import 'package:alpha/core/providers.dart';
import 'package:alpha/features/habit/domain/habit_model.dart';

class AddHabitSheet extends ConsumerStatefulWidget {
  const AddHabitSheet({super.key});

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  TimeOfDay? _selectedTime;
  bool _loading = false;

  // ── Repeat state ──────────────────────────────
  RepeatType _repeatType = RepeatType.daily;
  int _repeatInterval = 1;
  // 0=Sun,1=Mon…6=Sat — default all selected
  final Set<int> _selectedDays = {0, 1, 2, 3, 4, 5, 6};

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String? get _timeLabel {
    if (_selectedTime == null) return null;
    final h = _selectedTime!.hour.toString().padLeft(2, '0');
    final m = _selectedTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _intervalUnit {
    switch (_repeatType) {
      case RepeatType.daily:
        return _repeatInterval == 1 ? 'day' : 'days';
      case RepeatType.weekly:
        return _repeatInterval == 1 ? 'week' : 'weeks';
      case RepeatType.monthly:
        return _repeatInterval == 1 ? 'month' : 'months';
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _createHabit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final habit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      name: name,
      timeLabel: _timeLabel,
      createdAt: DateTime.now(),
      repeatType: _repeatType,
      repeatInterval: _repeatInterval,
      repeatWeekdays: _selectedDays.toList()..sort(),
    );

    await ref.read(habitRepoProvider).addHabit(habit);
    if (mounted) Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title row ───────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 24),
                ),
                const SizedBox(width: 12),
                Text('New Habit', style: tt.headlineMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── NAME ────────────────────────────
            Text('NAME', style: tt.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameCtrl,
              style: tt.titleSmall?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "What's your habit?",
                hintStyle: tt.titleSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── REPEAT ──────────────────────────
            Text('REPEAT', style: tt.labelSmall),
            const SizedBox(height: AppSpacing.md),
            _buildRepeatSection(tt),
            const SizedBox(height: AppSpacing.lg),

            // ── REMINDER ────────────────────────
            Text('REMINDER', style: tt.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeLabel ?? 'Set time',
                      style: tt.bodyMedium?.copyWith(
                        color: _timeLabel != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── CREATE BUTTON ───────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _createHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : Text('Create Habit', style: tt.labelLarge),
              ),
            ),
            SizedBox(
              height: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  REPEAT SECTION
  // ──────────────────────────────────────────────

  Widget _buildRepeatSection(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // ── Segmented toggle: Daily / Weekly / Monthly ──
          _buildSegmentedToggle(tt),
          const SizedBox(height: AppSpacing.md),

          // ── "Every N <unit>" row ──
          _buildIntervalRow(tt),

          // ── Day-of-week circles (only for Weekly) ──
          if (_repeatType == RepeatType.weekly) ...[
            const SizedBox(height: AppSpacing.md),
            _buildWeekdaySelector(tt),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentedToggle(TextTheme tt) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: RepeatType.values.map((type) {
          final isSelected = _repeatType == type;
          final label = switch (type) {
            RepeatType.daily => 'Daily',
            RepeatType.weekly => 'Weekly',
            RepeatType.monthly => 'Monthly',
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _repeatType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(3),
                child: Text(
                  label,
                  style: tt.bodyMedium?.copyWith(
                    color: isSelected ? AppColors.surface : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIntervalRow(TextTheme tt) {
    return Row(
      children: [
        Text(
          'Every',
          style: tt.bodyMedium?.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(width: 12),

        // Number stepper
        Container(
          width: 64,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease
              GestureDetector(
                onTap: _repeatInterval > 1
                    ? () => setState(() => _repeatInterval--)
                    : null,
                child: Icon(
                  Icons.remove,
                  size: 14,
                  color: _repeatInterval > 1
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$_repeatInterval',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              // Increase
              GestureDetector(
                onTap: () => setState(() => _repeatInterval++),
                child: Icon(
                  Icons.add,
                  size: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),
        Text(
          _intervalUnit,
          style: tt.bodyMedium?.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildWeekdaySelector(TextTheme tt) {
    // Labels indexed 0–6 matching Sun–Sat
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected && _selectedDays.length > 1) {
                _selectedDays.remove(index);
              } else {
                _selectedDays.add(index);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surface,
              shape: BoxShape.circle,
              border: isSelected
                  ? null
                  : Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Text(
              dayLabels[index],
              style: tt.bodyMedium?.copyWith(
                color: isSelected ? AppColors.surface : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }
}
