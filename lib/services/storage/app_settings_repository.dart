import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../app/app_theme.dart' show AppThemeSetting;
import '../../core/music/note.dart';

/// Preferenze globali dell'app persistite su JSON.
class AppSettingsRepository {
  AppSettingsRepository({Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  static const _fileName = 'app_settings.json';

  final Future<Directory> Function() _directoryProvider;

  Future<File> _file() async {
    final dir = await _directoryProvider();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<Map<String, dynamic>> _read() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return {};
      }
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(String key, Object? value) async {
    try {
      final json = await _read();
      json[key] = value;
      final file = await _file();
      await file.writeAsString(jsonEncode(json), flush: true);
    } catch (_) {
      // Preferenza non persistita: resta valida per la sessione corrente.
    }
  }

  Future<NoteNotation> loadNotation() async {
    final json = await _read();
    return json['notation'] == 'english' ? NoteNotation.english : NoteNotation.italian;
  }

  Future<void> saveNotation(NoteNotation notation) {
    return _write('notation', notation == NoteNotation.english ? 'english' : 'italian');
  }

  Future<AppThemeSetting> loadThemeSetting() async {
    final json = await _read();
    return switch (json['themeMode']) {
      'light' => AppThemeSetting.light,
      'dark' => AppThemeSetting.dark,
      'neon' => AppThemeSetting.neon,
      _ => AppThemeSetting.system,
    };
  }

  Future<void> saveThemeSetting(AppThemeSetting setting) {
    return _write('themeMode', switch (setting) {
      AppThemeSetting.light => 'light',
      AppThemeSetting.dark => 'dark',
      AppThemeSetting.neon => 'neon',
      AppThemeSetting.system => 'system',
    });
  }

  /// Soglia RMS di silenzio calibrata sul rumore ambientale (null = default).
  Future<double?> loadNoiseThreshold() async {
    final json = await _read();
    final value = json['noiseThreshold'];
    return value is num ? value.toDouble() : null;
  }

  Future<void> saveNoiseThreshold(double threshold) {
    return _write('noiseThreshold', threshold);
  }
}
