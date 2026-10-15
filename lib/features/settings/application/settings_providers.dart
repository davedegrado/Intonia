import 'dart:async';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart' show AppThemeSetting;
import '../../../core/music/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/storage/app_settings_repository.dart';

final appSettingsRepositoryProvider =
    Provider<AppSettingsRepository>((ref) => AppSettingsRepository());

/// Notazione corrente (DO-RE-MI oppure C-D-E), persistita tra le sessioni.
final notationProvider = NotifierProvider<NotationNotifier, NoteNotation>(
  NotationNotifier.new,
);

class NotationNotifier extends Notifier<NoteNotation> {
  @override
  NoteNotation build() {
    unawaited(_load());
    // Default internazionale finché non si legge la preferenza salvata.
    return NoteNotation.english;
  }

  Future<void> _load() async {
    final loaded = await ref.read(appSettingsRepositoryProvider).loadNotation();
    state = loaded;
  }

  Future<void> setNotation(NoteNotation notation) async {
    state = notation;
    await ref.read(appSettingsRepositoryProvider).saveNotation(notation);
  }
}

/// Tema sistema/chiaro/scuro/neon, persistito tra le sessioni.
final themeSettingProvider = NotifierProvider<ThemeSettingNotifier, AppThemeSetting>(
  ThemeSettingNotifier.new,
);

class ThemeSettingNotifier extends Notifier<AppThemeSetting> {
  @override
  AppThemeSetting build() {
    unawaited(_load());
    return AppThemeSetting.system;
  }

  Future<void> _load() async {
    final loaded = await ref.read(appSettingsRepositoryProvider).loadThemeSetting();
    state = loaded;
  }

  Future<void> setThemeSetting(AppThemeSetting setting) async {
    state = setting;
    await ref.read(appSettingsRepositoryProvider).saveThemeSetting(setting);
  }
}

/// Lingua scelta a mano nelle impostazioni (es. "it"); null = lingua del
/// dispositivo. Persistita tra gli avvii.
final languageProvider = NotifierProvider<LanguageNotifier, String?>(LanguageNotifier.new);

class LanguageNotifier extends Notifier<String?> {
  @override
  String? build() {
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    final loaded = await ref.read(appSettingsRepositoryProvider).loadLanguage();
    if (ref.mounted && loaded != null) {
      state = loaded;
    }
  }

  Future<void> setLanguage(String languageCode) async {
    state = languageCode;
    await ref.read(appSettingsRepositoryProvider).saveLanguage(languageCode);
  }
}

/// Lingua del dispositivo (sostituibile nei test).
final deviceLocaleProvider = Provider<Locale>((ref) => PlatformDispatcher.instance.locale);

/// Lingua effettiva dell'interfaccia: la scelta manuale, altrimenti quella del
/// dispositivo se supportata, altrimenti l'inglese.
final appLocaleProvider = Provider<Locale>((ref) {
  return resolveAppLocale(ref.watch(languageProvider), ref.watch(deviceLocaleProvider));
});

/// Testi tradotti per chi non ha un BuildContext (controller, messaggi di stato).
final l10nProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(ref.watch(appLocaleProvider)),
);

Locale resolveAppLocale(String? chosen, Locale device) {
  final supported = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
  if (chosen != null && supported.contains(chosen)) {
    return Locale(chosen);
  }
  if (supported.contains(device.languageCode)) {
    return Locale(device.languageCode);
  }
  return const Locale('en');
}
