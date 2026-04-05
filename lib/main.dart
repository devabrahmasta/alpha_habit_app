import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alpha/core/theme/app_theme.dart';
import 'package:alpha/core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Initialize Firebase when integrating:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  runApp(const ProviderScope(child: StreakApp()));
}

class StreakApp extends ConsumerWidget {
  const StreakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Streak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
