import 'package:flutter/material.dart';

import 'package:alpha/core/theme/app_colors.dart';
import 'package:alpha/core/theme/app_theme.dart';
import 'package:alpha/core/utils/date_utils.dart';

/// GitHub-style 1-month contribution grid.
///
/// Shows the last 30 days in a 7-column layout (Mon→Sun).
/// - Completed day: filled black
/// - Miss: light gray
/// - Today: outlined if not done, filled if done
/// - Only the last [editableDays] are tappable.
class ContributionGrid extends StatelessWidget {
  const ContributionGrid({
    super.key,
    required this.completionLog,
    this.editableDays = 3,
    this.onDayToggled,
  });

  final Map<String, bool> completionLog;
  final int editableDays;
  final ValueChanged<String>? onDayToggled;

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.stripTime(DateTime.now());
    // Build 35 days of data (5 full weeks) ending today.
    final days = List.generate(35, (i) {
      return today.subtract(Duration(days: 34 - i));
    });

    // Weekday headers
    const headers = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Find the first Monday on or before days.first
    final firstDay = days.first;
    final startPadding = (firstDay.weekday - 1) % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: headers
              .map((h) => Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              letterSpacing: 0,
                            ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Grid
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            // Empty cells for alignment
            for (int i = 0; i < startPadding; i++)
              SizedBox(width: _cellSize(context), height: _cellSize(context)),

            // Day cells
            for (final day in days) _DayCell(
              day: day,
              isToday: day == today,
              isCompleted: completionLog[AppDateUtils.toDateKey(day)] == true,
              isFuture: day.isAfter(today),
              isEditable: !day.isAfter(today) &&
                  today.difference(day).inDays < editableDays,
              onTap: onDayToggled != null
                  ? () => onDayToggled!(AppDateUtils.toDateKey(day))
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  double _cellSize(BuildContext context) {
    // Responsive: fill ~7 columns with spacing
    final width = MediaQuery.of(context).size.width - 2 * AppSpacing.lg - 48;
    return ((width - 6 * 4) / 7).clamp(28.0, 36.0);
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isCompleted,
    required this.isFuture,
    required this.isEditable,
    this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isCompleted;
  final bool isFuture;
  final bool isEditable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = _calculateSize(context);

    Color bg;
    Border? border;

    if (isFuture) {
      bg = AppColors.border.withValues(alpha: 0.3);
    } else if (isCompleted) {
      bg = AppColors.accent;
    } else {
      bg = AppColors.border;
    }

    if (isToday && !isCompleted) {
      border = Border.all(color: AppColors.accent, width: 2);
    }

    return GestureDetector(
      onTap: isEditable ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: border,
        ),
      ),
    );
  }

  double _calculateSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 2 * AppSpacing.lg - 48;
    return ((width - 6 * 4) / 7).clamp(28.0, 36.0);
  }
}
