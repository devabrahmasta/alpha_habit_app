import 'package:flutter/material.dart';

import 'package:alpha/core/theme/app_colors.dart';
import 'package:alpha/core/theme/app_theme.dart';
import 'package:alpha/features/habit/domain/habit_model.dart';
import 'package:alpha/features/habit/presentation/widgets/animated_checkbox.dart';
import 'package:alpha/features/habit/presentation/widgets/strikethrough_text.dart';

/// A single habit card with the full animation sequence:
///
/// **Check** (200-350 ms):
/// 1. Checkmark path draw (200 ms, easeOutCubic)
/// 2. Card background white → completedBg (250 ms, easeInOut)
/// 3. Strikethrough left → right (300 ms, linear)
/// 4. Text opacity fades to 0.5
///
/// After the internal animations finish, [onToggle] is called after a
/// 400 ms delay to let the home screen reorder the list.
class HabitCard extends StatefulWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onTap,
  });

  final HabitModel habit;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bgAnimation;
  late final Animation<double> _strikeAnimation;
  late final Animation<double> _opacityAnimation;

  bool _localChecked = false;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _localChecked = widget.habit.isCompletedToday;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _bgAnimation = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.71, curve: Curves.easeInOut),
    );

    _strikeAnimation = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.86, curve: Curves.linear),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (_localChecked) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant HabitCard old) {
    super.didUpdateWidget(old);
    if (widget.habit.isCompletedToday != _localChecked && !_animating) {
      _localChecked = widget.habit.isCompletedToday;
      _localChecked ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleToggle() {
    if (_animating) return;
    _animating = true;

    setState(() => _localChecked = !_localChecked);

    if (_localChecked) {
      _ctrl.forward();
      // Delay before notifying parent to allow visual completion.
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          widget.onToggle();
          _animating = false;
        }
      });
    } else {
      _ctrl.reverse().then((_) {
        if (mounted) {
          widget.onToggle();
          _animating = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final bgColor = Color.lerp(
            AppColors.surface,
            AppColors.completedBg,
            _bgAnimation.value,
          )!;

          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.cardPadding,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Title + time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Strikethrough text
                        Opacity(
                          opacity: _opacityAnimation.value,
                          child: StrikethroughText(
                            progress: _strikeAnimation.value,
                            child: Text(
                              widget.habit.name,
                              style: tt.titleSmall,
                            ),
                          ),
                        ),
                        if (widget.habit.timeLabel != null) ...[
                          const SizedBox(height: 2),
                          Opacity(
                            opacity: _opacityAnimation.value,
                            child: Text(
                              widget.habit.timeLabel!,
                              style: tt.bodyMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Checkbox
                  AnimatedCheckbox(
                    value: _localChecked,
                    onChanged: (_) => _handleToggle(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
