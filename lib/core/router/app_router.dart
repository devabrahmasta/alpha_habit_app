import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:alpha/core/providers.dart';
import 'package:alpha/features/habit/presentation/home_screen.dart';
import 'package:alpha/features/onboarding/onboarding_screen.dart';

/// The router provider — rebuilds when auth or onboarding state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingDone = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isOnboardingDone = onboardingDone.valueOrNull ?? false;
      final isSignedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;

      // Still loading
      if (onboardingDone.isLoading || authState.isLoading) return null;

      // Not onboarded → onboarding
      if (!isOnboardingDone) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      // Onboarded but not signed in → onboarding page 2 (sign in)
      if (!isSignedIn) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      // Signed in at onboarding → go home
      if (loc == '/onboarding') return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
    ],
  );
});

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}
