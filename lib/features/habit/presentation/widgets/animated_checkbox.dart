import 'package:flutter/material.dart';

import 'package:alpha/core/theme/app_colors.dart';

/// Custom animated checkbox with a draw-in checkmark.
///
/// Uses [CustomPainter] + [AnimationController] to draw:
/// 1. Rounded-square border
/// 2. Fill overlay (opacity animated)
/// 3. Checkmark path (length animated via PathMetrics)
class AnimatedCheckbox extends StatefulWidget {
  const AnimatedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 24,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fill;
  late final Animation<double> _check;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fill = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    );

    _check = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );

    if (widget.value) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant AnimatedCheckbox old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      widget.value ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8), // expand touch target to 40x40
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              size: Size.square(widget.size),
              painter: _CheckboxPainter(
                fillProgress: _fill.value,
                checkProgress: _check.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckboxPainter extends CustomPainter {
  _CheckboxPainter({
    required this.fillProgress,
    required this.checkProgress,
  });

  final double fillProgress;
  final double checkProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(6));

    // Border — lerps from muted to accent as fill progresses.
    final borderPaint = Paint()
      ..color = Color.lerp(AppColors.textMuted, AppColors.accent, fillProgress)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    // Fill
    if (fillProgress > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = AppColors.accent.withValues(alpha: fillProgress)
          ..style = PaintingStyle.fill,
      );
    }

    // Checkmark path — drawn progressively via PathMetrics.
    if (checkProgress > 0) {
      final path = Path()
        ..moveTo(size.width * 0.22, size.height * 0.50)
        ..lineTo(size.width * 0.42, size.height * 0.70)
        ..lineTo(size.width * 0.78, size.height * 0.30);

      final metric = path.computeMetrics().first;
      final draw = metric.extractPath(0, metric.length * checkProgress);

      canvas.drawPath(
        draw,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckboxPainter old) =>
      fillProgress != old.fillProgress || checkProgress != old.checkProgress;
}
