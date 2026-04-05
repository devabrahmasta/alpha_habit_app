import 'package:flutter/material.dart';

import 'package:alpha/core/theme/app_colors.dart';

/// Renders a strikethrough line that draws from left → right through a child.
///
/// [progress] goes from 0.0 (no line) to 1.0 (full width).
class StrikethroughText extends StatelessWidget {
  const StrikethroughText({
    super.key,
    required this.progress,
    required this.child,
  });

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _StrikethroughPainter(progress: progress),
      child: child,
    );
  }
}

class _StrikethroughPainter extends CustomPainter {
  _StrikethroughPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width * progress, y), paint);
  }

  @override
  bool shouldRepaint(_StrikethroughPainter old) => progress != old.progress;
}
