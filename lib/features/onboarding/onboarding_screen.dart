import 'package:flutter/material.dart';
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
  bool _loading = false;

  Future<void> _startChallenge() {
    setState(() => _page = 1);
    return Future.value();
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();

      // Save target
      await ref.read(targetRepoProvider).createTarget(
            TargetModel(
              userId: user.uid,
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

class _PageOne extends StatelessWidget {
  const _PageOne({super.key, required this.onNext});
  final VoidCallback onNext;

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
          Text(
            '90',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 96,
              fontWeight: FontWeight.w800,
              letterSpacing: -3,
              color: AppColors.textPrimary,
            ),
          ),
          Text('days', style: tt.titleMedium),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onNext,
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
