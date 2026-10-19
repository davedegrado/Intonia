import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/app_theme.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/session/session_record.dart';
import 'package:vocal_scale_trainer/features/home_widget/application/home_widget_sync.dart';
import 'package:vocal_scale_trainer/features/home_widget/domain/widget_precision.dart';
import 'package:vocal_scale_trainer/features/home_widget/domain/widget_streak.dart';
import 'package:vocal_scale_trainer/features/profile/application/history_providers.dart';
import 'package:vocal_scale_trainer/features/settings/application/settings_providers.dart';
import 'package:vocal_scale_trainer/services/storage/app_settings_repository.dart';
import 'package:vocal_scale_trainer/services/storage/session_history_repository.dart';
import 'package:vocal_scale_trainer/services/widget/home_widget_service.dart';

class _RecordingWidgetService extends HomeWidgetService {
  final published =
      <({WidgetStreakData data, WidgetPrecisionData precision, String languageCode})>[];

  @override
  Future<void> publish(
    WidgetStreakData data, {
    required WidgetPrecisionData precision,
    required String languageCode,
  }) async {
    published.add((data: data, precision: precision, languageCode: languageCode));
  }
}

class _MemorySessions extends SessionHistoryRepository {
  @override
  Future<List<SessionRecord>> load() async => const [];
  @override
  Future<void> save(List<SessionRecord> records) async {}
}

class _MemorySettings extends AppSettingsRepository {
  _MemorySettings(this.language);
  String? language;
  @override
  Future<String?> loadLanguage() async => language;
  @override
  Future<void> saveLanguage(String? languageCode) async => language = languageCode;
  @override
  Future<NoteNotation> loadNotation() async => NoteNotation.english;
  @override
  Future<AppThemeSetting> loadThemeSetting() async => AppThemeSetting.system;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  ProviderContainer container(_RecordingWidgetService service, {String? saved, Locale? device}) {
    final c = ProviderContainer(overrides: [
      homeWidgetServiceProvider.overrideWithValue(service),
      sessionHistoryRepositoryProvider.overrideWithValue(_MemorySessions()),
      appSettingsRepositoryProvider.overrideWithValue(_MemorySettings(saved)),
      deviceLocaleProvider.overrideWithValue(device ?? const Locale('it')),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('the widget receives the app language and follows a manual change', () async {
    final service = _RecordingWidgetService();
    final c = container(service);
    // Come nell'app (che lo osserva): un provider senza ascoltatori è in pausa.
    c.listen(homeWidgetSyncProvider, (_, __) {});
    await _settle();
    await _settle();
    expect(service.published.last.languageCode, 'it');

    await c.read(languageProvider.notifier).setLanguage('en');
    await _settle();
    expect(service.published.last.languageCode, 'en',
        reason: "il widget segue la lingua scelta nell'app, non quella del telefono");
  });

  test('a saved app language wins over the device language for the widget', () async {
    final service = _RecordingWidgetService();
    final c = container(service, saved: 'en', device: const Locale('it'));
    // Come nell'app (che lo osserva): un provider senza ascoltatori è in pausa.
    c.listen(homeWidgetSyncProvider, (_, __) {});
    for (var i = 0; i < 4; i++) {
      await _settle();
    }
    expect(service.published.last.languageCode, 'en');
  });

  test('unsupported device languages give the widget English', () async {
    final service = _RecordingWidgetService();
    final c = container(service, device: const Locale('de'));
    // Come nell'app (che lo osserva): un provider senza ascoltatori è in pausa.
    c.listen(homeWidgetSyncProvider, (_, __) {});
    await _settle();
    await _settle();
    expect(service.published.last.languageCode, 'en');
  });
}
