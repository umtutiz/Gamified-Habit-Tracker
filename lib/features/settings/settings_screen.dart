import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(settings.locale?.languageCode == 'tr' ? 'Ayarlar' : 'Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, settings, 'Dil', 'Language'),
          Card(
            child: Column(
              children: [
                RadioListTile<Locale?>(
                  title: const Text('Sistem / System'),
                  value: null,
                  groupValue: settings.locale,
                  onChanged: (v) => ctrl.setLocale(v),
                ),
                RadioListTile<Locale?>(
                  title: const Text('Türkçe'),
                  value: const Locale('tr'),
                  groupValue: settings.locale,
                  onChanged: (v) => ctrl.setLocale(v),
                ),
                RadioListTile<Locale?>(
                  title: const Text('English'),
                  value: const Locale('en'),
                  groupValue: settings.locale,
                  onChanged: (v) => ctrl.setLocale(v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _sectionTitle(context, settings, 'Tema', 'Theme'),
          Card(
            child: Column(
              children: [
                RadioListTile<Brightness>(
                  title: const Text('Koyu / Dark'),
                  value: Brightness.dark,
                  groupValue: settings.brightness,
                  onChanged: (v) => ctrl.setBrightness(v!),
                ),
                RadioListTile<Brightness>(
                  title: const Text('Açık / Light'),
                  value: Brightness.light,
                  groupValue: settings.brightness,
                  onChanged: (v) => ctrl.setBrightness(v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _sectionTitle(context, settings, 'Vurgu rengi', 'Accent'),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemePreset>(
                  title: const Text('Gri (Graphite)'),
                  value: ThemePreset.graphite,
                  groupValue: settings.preset,
                  onChanged: (v) => ctrl.setPreset(v!),
                ),
                RadioListTile<ThemePreset>(
                  title: const Text('Gece (Midnight)'),
                  value: ThemePreset.midnight,
                  groupValue: settings.preset,
                  onChanged: (v) => ctrl.setPreset(v!),
                ),
                RadioListTile<ThemePreset>(
                  title: const Text('Zümrüt (Emerald)'),
                  value: ThemePreset.emerald,
                  groupValue: settings.preset,
                  onChanged: (v) => ctrl.setPreset(v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _sectionTitle(context, settings, 'Arkaplan', 'Background'),
          Card(
            child: Column(
              children: [
                _bgTile(
                  label: 'Default',
                  argb: 0xFF0F1115,
                  current: settings.backgroundArgb,
                  onTap: () => ctrl.setBackground(0xFF0F1115),
                ),
                _bgTile(
                  label: 'Teal dark',
                  argb: 0xFF001B1F,
                  current: settings.backgroundArgb,
                  onTap: () => ctrl.setBackground(0xFF001B1F),
                ),
                _bgTile(
                  label: 'Pure black',
                  argb: 0xFF000000,
                  current: settings.backgroundArgb,
                  onTap: () => ctrl.setBackground(0xFF000000),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, AppSettings s, String tr, String en) {
    final isTr = s.locale?.languageCode == 'tr' || (s.locale == null && Localizations.localeOf(context).languageCode == 'tr');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        isTr ? tr : en,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _bgTile({
    required String label,
    required int argb,
    required int current,
    required VoidCallback onTap,
  }) {
    final selected = argb == current;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(backgroundColor: Color(argb)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: selected ? const Icon(Icons.check_circle) : const Icon(Icons.circle_outlined),
    );
  }
}