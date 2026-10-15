import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart' show AppThemeSetting;
import '../../../app/l10n.dart';
import '../../../core/music/note.dart';
import '../../guide/guide.dart';
import '../application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const version = '0.1.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final notation = ref.watch(notationProvider);
    final themeSetting = ref.watch(themeSettingProvider);
    final language = ref.watch(appLocaleProvider).languageCode;
    final sectionStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.languageSectionTitle, style: sectionStyle),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              key: const ValueKey('settings-language'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'it', label: Text(l10n.languageItalian)),
                ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
              ],
              selected: {language},
              onSelectionChanged: (selection) =>
                  ref.read(languageProvider.notifier).setLanguage(selection.first),
            ),
            const SizedBox(height: 8),
            Text(l10n.languageHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 28),
            Text(l10n.settingsAppearance, style: sectionStyle),
            const SizedBox(height: 12),
            SegmentedButton<AppThemeSetting>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: AppThemeSetting.system, label: Text(l10n.themeSystem)),
                ButtonSegment(value: AppThemeSetting.light, label: Text(l10n.themeLight)),
                ButtonSegment(value: AppThemeSetting.dark, label: Text(l10n.themeDark)),
                ButtonSegment(value: AppThemeSetting.neon, label: Text(l10n.themeNeon)),
              ],
              selected: {themeSetting},
              onSelectionChanged: (selection) =>
                  ref.read(themeSettingProvider.notifier).setThemeSetting(selection.first),
            ),
            const SizedBox(height: 28),
            Text(l10n.settingsNotation, style: sectionStyle),
            const SizedBox(height: 12),
            SegmentedButton<NoteNotation>(
              key: const ValueKey('settings-notation'),
              segments: [
                ButtonSegment(value: NoteNotation.italian, label: Text(l10n.notationItalian)),
                ButtonSegment(value: NoteNotation.english, label: Text(l10n.notationInternational)),
              ],
              selected: {notation},
              onSelectionChanged: (selection) =>
                  ref.read(notationProvider.notifier).setNotation(selection.first),
            ),
            const SizedBox(height: 28),
            ListTile(
              key: const ValueKey('settings-guide'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school_outlined),
              title: Text(l10n.guideTitle),
              subtitle: Text(l10n.guideOpenHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showGuide(context, appGuideSteps(l10n)),
            ),
            const SizedBox(height: 20),
            Text(l10n.settingsInfo, style: sectionStyle),
            const SizedBox(height: 8),
            Text('${l10n.settingsAbout(version)}\n${l10n.settingsSoundCredit}',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: version,
                ),
                icon: const Icon(Icons.description_outlined),
                label: Text(l10n.settingsLicenses),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
