import 'package:flutter/material.dart';

/// Strict monochrome palette — light mode only for MVP.
/// [streakOrange] is the ONLY pop of color (streak fire icon).
abstract final class AppColors {
  static const Color background = Color(0xFFF5F5F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E8E6);
  static const Color textPrimary = Color(0xFF0D0D0D);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFFC2C2C2);
  static const Color accent = Color(0xFF0D0D0D);
  static const Color completedBg = Color(0xFFF0F0EE);
  static const Color streakOrange = Color(0xFFFF6B35);
  static const Color destructive = Color(0xFFE53935);
}
