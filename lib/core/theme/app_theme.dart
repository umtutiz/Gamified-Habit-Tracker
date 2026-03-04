import 'package:flutter/material.dart';
import '../settings/settings_controller.dart';

class AppTheme {
  static Color seedFromPreset(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.graphite:
        return const Color(0xFF9E9E9E);
      case ThemePreset.midnight:
        return const Color(0xFF6C7DFE);
      case ThemePreset.emerald:
        return const Color(0xFF2ECC71);
    }
  }

  static ThemeData build({
    required Brightness brightness,
    required Color seed,
    required int backgroundArgb,
  }) {
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    final bg = Color(backgroundArgb);
    final cardBg = brightness == Brightness.dark
        ? const Color(0xFF171A21)
        : Colors.white;

    final divider = brightness == Brightness.dark
        ? const Color(0xFF2A2F3A)
        : const Color(0xFFE6E8EE);

    final text = brightness == Brightness.dark
        ? const Color(0xFFE8EAF0)
        : const Color(0xFF14161A);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: brightness,
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      dividerColor: divider,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: text,
      ),

      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),

      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: divider),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: text,
        textColor: text,
      ),
    );
  }
}