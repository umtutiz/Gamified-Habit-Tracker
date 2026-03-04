import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prefs_provider.dart';

enum ThemePreset { graphite, midnight, emerald }

class AppSettings {
  final Locale? locale; // null => system
  final Brightness brightness; // light/dark
  final ThemePreset preset; // seed palette
  final int backgroundArgb; // scaffold bg

  const AppSettings({
    required this.locale,
    required this.brightness,
    required this.preset,
    required this.backgroundArgb,
  });

  AppSettings copyWith({
    Locale? locale,
    bool localeTouched = false,
    Brightness? brightness,
    ThemePreset? preset,
    int? backgroundArgb,
  }) {
    return AppSettings(
      locale: localeTouched ? locale : this.locale,
      brightness: brightness ?? this.brightness,
      preset: preset ?? this.preset,
      backgroundArgb: backgroundArgb ?? this.backgroundArgb,
    );
  }

  static const defaults = AppSettings(
    locale: null, // system
    brightness: Brightness.dark,
    preset: ThemePreset.graphite,
    backgroundArgb: 0xFF0F1115,
  );
}

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController(ref);
});

class SettingsController extends StateNotifier<AppSettings> {
  final Ref ref;
  SettingsController(this.ref) : super(AppSettings.defaults) {
    _load();
  }

  static const _kLocale = 'locale';
  static const _kBrightness = 'brightness';
  static const _kPreset = 'preset';
  static const _kBg = 'background';

  Future<void> _load() async {
    final prefs = await ref.read(sharedPrefsProvider.future);

    final localeStr = prefs.getString(_kLocale); // 'tr'/'en'/null
    Locale? locale;
    if (localeStr == 'tr') locale = const Locale('tr');
    if (localeStr == 'en') locale = const Locale('en');

    final brightStr = prefs.getString(_kBrightness) ?? 'dark';
    final brightness =
        brightStr == 'light' ? Brightness.light : Brightness.dark;

    final presetStr = prefs.getString(_kPreset) ?? 'graphite';
    final preset = ThemePreset.values.firstWhere(
      (e) => e.name == presetStr,
      orElse: () => ThemePreset.graphite,
    );

    final bg = prefs.getInt(_kBg) ?? AppSettings.defaults.backgroundArgb;

    state = state.copyWith(
      locale: locale,
      localeTouched: true,
      brightness: brightness,
      preset: preset,
      backgroundArgb: bg,
    );
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    if (locale == null) {
      await prefs.remove(_kLocale);
    } else {
      await prefs.setString(_kLocale, locale.languageCode);
    }
    state = state.copyWith(locale: locale, localeTouched: true);
  }

  Future<void> setBrightness(Brightness b) async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setString(_kBrightness, b == Brightness.light ? 'light' : 'dark');
    state = state.copyWith(brightness: b);
  }

  Future<void> setPreset(ThemePreset p) async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setString(_kPreset, p.name);
    state = state.copyWith(preset: p);
  }

  Future<void> setBackground(int argb) async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setInt(_kBg, argb);
    state = state.copyWith(backgroundArgb: argb);
  }
}