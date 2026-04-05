import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:alpha/core/providers.dart';
import 'package:alpha/features/habit/presentation/home_screen.dart';
import 'package:alpha/features/onboarding/onboarding_screen.dart';

/// A [ChangeNotifier] that fires whenever the auth or onboarding state changes.
/// GoRouter listens to this and re-runs its redirect — without
/// creating a new router instance.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (prev, next) => notifyListeners());
    _ref.listen(onboardingCompleteProvider, (prev, next) => notifyListeners());
  }

  final Ref _ref;
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

/// Single GoRouter instance — never recreated.
/// Redirect is re-evaluated via [refreshListenable] when auth/onboarding changes.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final onboardingDone =
          ref.read(onboardingCompleteProvider).valueOrNull ?? false;
      final isSignedIn = ref.read(authStateProvider).valueOrNull != null;
      final loc = state.matchedLocation;

      // Still loading — stay put
      if (ref.read(onboardingCompleteProvider).isLoading ||
          ref.read(authStateProvider).isLoading) {
        return null;
      }

      // Not onboarded → onboarding
      if (!onboardingDone) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      // Onboarded but not signed in → onboarding (page 2)
      if (!isSignedIn) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      // Signed in + still on onboarding → go home
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
