import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alpha/core/theme/app_colors.dart';
import 'package:alpha/core/theme/app_theme.dart';
import 'package:alpha/core/providers.dart';
import 'package:alpha/features/target/domain/target_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _page = 0;
  int _totalDays = 90;
  bool _loading = false;

  void _startChallenge(int totalDays) {
    setState(() {
      _totalDays = totalDays;
      _page = 1;
    });
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();

      // Save target with user-chosen totalDays
      await ref.read(targetRepoProvider).createOrUpdateTarget(
            TargetModel(
              userId: user.uid,
              totalDays: _totalDays,
              startDate: DateTime.now(),
            ),
          );

      // Mark onboarding complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      // Invalidate onboarding provider so router re-evaluates
      ref.invalidate(onboardingCompleteProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: _page == 0
            ? _PageOne(key: const ValueKey(0), onNext: _startChallenge)
            : _PageTwo(
                key: const ValueKey(1),
                onSignIn: _signIn,
                loading: _loading,
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  PAGE ONE — Editable day picker (1–999)
// ──────────────────────────────────────────────

class _PageOne extends StatefulWidget {
  const _PageOne({super.key, required this.onNext});
  final ValueChanged<int> onNext;

  @override
  State<_PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<_PageOne> {
  late final TextEditingController _daysCtrl;
  int _days = 90;

  @override
  void initState() {
    super.initState();
    _daysCtrl = TextEditingController(text: '90');
  }

  @override
  void dispose() {
    _daysCtrl.dispose();
    super.dispose();
  }

  void _updateDays(int value) {
    final clamped = value.clamp(1, 999);
    setState(() {
      _days = clamped;
      _daysCtrl.text = '$clamped';
      _daysCtrl.selection = TextSelection.collapsed(offset: '$clamped'.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          Text(
            'How many days\nis your challenge?',
            style: tt.headlineMedium?.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Editable number input ──────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease
              _RoundButton(
                icon: Icons.remove,
                onTap: _days > 1 ? () => _updateDays(_days - 1) : null,
              ),
              const SizedBox(width: AppSpacing.lg),

              // Number field
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _daysCtrl,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    color: AppColors.textPrimary,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ClampFormatter(1, 999),
                  ],
                  onChanged: (val) {
                    if (val.isNotEmpty) {
                      _days = int.parse(val).clamp(1, 999);
                    }
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Increase
              _RoundButton(
                icon: Icons.add,
                onTap: _days < 999 ? () => _updateDays(_days + 1) : null,
              ),
            ],
          ),

          Text('days', style: tt.titleMedium),
          const Spacer(flex: 3),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => widget.onNext(_days),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start', style: tt.labelLarge),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  PAGE TWO — Sign-in
// ──────────────────────────────────────────────

class _PageTwo extends StatelessWidget {
  const _PageTwo({
    super.key,
    required this.onSignIn,
    required this.loading,
  });
  final VoidCallback onSignIn;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          Icon(
            Icons.person_outline_rounded,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sign in to\nsave your progress',
            style: tt.headlineMedium?.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your data syncs across devices',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: loading ? null : onSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text('Sign in with Google', style: tt.labelLarge),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  HELPERS
// ──────────────────────────────────────────────

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: enabled ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Clamps input to [min]–[max].
class _ClampFormatter extends TextInputFormatter {
  _ClampFormatter(this.min, this.max);
  final int min;
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null) return oldValue;
    final clamped = n.clamp(min, max);
    return TextEditingValue(
      text: '$clamped',
      selection: TextSelection.collapsed(offset: '$clamped'.length),
    );
  }
}
