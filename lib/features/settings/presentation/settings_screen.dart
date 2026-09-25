import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart' show AppThemeSetting;
import '../../../core/music/note.dart';
import '../application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notation = ref.watch(notationProvider);
    final themeSetting = ref.watch(themeSettingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Aspetto', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SegmentedButton<AppThemeSetting>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: AppThemeSetting.system, label: Text('Sistema')),
                ButtonSegment(value: AppThemeSetting.light, label: Text('Chiaro')),
                ButtonSegment(value: AppThemeSetting.dark, label: Text('Scuro')),
                ButtonSegment(value: AppThemeSetting.neon, label: Text('Neon')),
              ],
              selected: {themeSetting},
              onSelectionChanged: (selection) =>
                  ref.read(themeSettingProvider.notifier).setThemeSetting(selection.first),
            ),
            const SizedBox(height: 28),
            Text('Notazione delle note',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SegmentedButton<NoteNotation>(
              segments: const [
                ButtonSegment(value: NoteNotation.italian, label: Text('DO RE MI')),
                ButtonSegment(value: NoteNotation.english, label: Text('C D E')),
              ],
              selected: {notation},
              onSelectionChanged: (selection) =>
                  ref.read(notationProvider.notifier).setNotation(selection.first),
            ),
            const SizedBox(height: 28),
            Text('Lingua', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Italiano. La localizzazione inglese arriverà con l\'apertura al pubblico.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Text('Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Intonia 0.1.0 — allenamento di intonazione offline.\n'
                'Audio: SoundFont piano.sf2 (verifica la licenza prima della pubblicazione).',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
