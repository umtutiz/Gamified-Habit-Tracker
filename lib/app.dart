import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/app_theme.dart';

class HabitStreakApp extends ConsumerWidget {
  const HabitStreakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildRouter();
    final settings = ref.watch(settingsProvider);

    final theme = AppTheme.build(
      brightness: settings.brightness,
      seed: AppTheme.seedFromPreset(settings.preset),
      backgroundArgb: settings.backgroundArgb,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Habit Streak',
      routerConfig: router,

      // ✅ localization fix
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
      locale: settings.locale, // null => system

      theme: theme,
    );
  }
}