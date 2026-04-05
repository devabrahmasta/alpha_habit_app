import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alpha/core/theme/app_colors.dart';
import 'package:alpha/core/theme/app_theme.dart';
import 'package:alpha/core/providers.dart';
import 'package:alpha/features/habit/domain/habit_model.dart';
import 'package:alpha/features/habit/presentation/widgets/contribution_grid.dart';

class HabitDetailSheet extends ConsumerStatefulWidget {
  const HabitDetailSheet({super.key, required this.habit});

  final HabitModel habit;

  @override
  ConsumerState<HabitDetailSheet> createState() => _HabitDetailSheetState();
}

class _HabitDetailSheetState extends ConsumerState<HabitDetailSheet> {
  late HabitModel _habit;
  bool _editing = false;
  late TextEditingController _nameCtrl;
  TimeOfDay? _editTime;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _nameCtrl = TextEditingController(text: _habit.name);
    if (_habit.timeLabel != null) {
      final parts = _habit.timeLabel!.split(':');
      _editTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String? get _timeLabelString {
    if (_editTime == null) return null;
    final h = _editTime!.hour.toString().padLeft(2, '0');
    final m = _editTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _saveEdits() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final updated = _habit.copyWith(name: name, timeLabel: _timeLabelString);
    await ref.read(habitRepoProvider).updateHabit(updated);
    setState(() {
      _habit = updated;
      _editing = false;
    });
  }

  Future<void> _deleteHabit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Remove "${_habit.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(habitRepoProvider).deleteHabit(_habit.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _toggleDay(String dateKey) {
    ref.read(habitRepoProvider).toggleCompletion(_habit.id, dateKey).then((h) {
      if (h != null && mounted) setState(() => _habit = h);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Handle
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
            const SizedBox(height: 24),

            // Title + Edit button
            Row(
              children: [
                Expanded(
                  child: _editing
                      ? TextField(
                          controller: _nameCtrl,
                          style: tt.headlineMedium,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(_habit.name, style: tt.headlineMedium),
                ),
                TextButton(
                  onPressed: _editing ? _saveEdits : () => setState(() => _editing = true),
                  child: Text(
                    _editing ? 'Save' : 'Edit',
                    style: tt.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if (_editing)
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _editTime ?? const TimeOfDay(hour: 20, minute: 0),
                  );
                  if (picked != null) setState(() => _editTime = picked);
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _timeLabelString ?? 'Set time',
                        style: tt.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else if (_habit.timeLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_habit.timeLabel!, style: tt.bodyMedium),
              ),

            const SizedBox(height: AppSpacing.xl),

            // Streak info
            Row(
              children: [
                _StatChip(label: 'Current', value: '${_habit.currentStreak}'),
                const SizedBox(width: 12),
                _StatChip(label: 'Longest', value: '${_habit.longestStreak}'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Grid label
            Text('THIS MONTH', style: tt.labelSmall),
            const SizedBox(height: AppSpacing.md),

            ContributionGrid(
              completionLog: _habit.completionLog,
              onDayToggled: _toggleDay,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Delete
            Center(
              child: TextButton(
                onPressed: _deleteHabit,
                child: Text(
                  'Delete Habit',
                  style: tt.bodySmall?.copyWith(color: AppColors.destructive),
                ),
              ),
            ),

            SizedBox(height: AppSpacing.lg + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.completedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: tt.labelSmall?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
