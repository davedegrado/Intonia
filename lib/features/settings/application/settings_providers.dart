import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart' show AppThemeSetting;
import '../../../core/music/note.dart';
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
    return NoteNotation.italian;
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
