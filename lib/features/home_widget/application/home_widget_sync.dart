import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/widget/home_widget_service.dart';
import '../../profile/application/history_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../domain/widget_streak.dart';

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) => HomeWidgetService());

/// Tiene aggiornato il widget nativo: pubblica la serie all'avvio (appena lo
/// storico è caricato), a ogni nuova sessione salvata e a ogni cambio della
/// lingua dell'app, così il widget parla la stessa lingua dell'app.
final homeWidgetSyncProvider = Provider<void>((ref) {
  void push() {
    final sessions = ref.read(sessionHistoryProvider).value;
    if (sessions == null) {
      return;
    }
    final data = WidgetStreakData.fromSessions(sessions.map((s) => s.timestamp));
    final languageCode = ref.read(appLocaleProvider).languageCode;
    unawaited(ref.read(homeWidgetServiceProvider).publish(data, languageCode: languageCode));
  }

  ref.listen(sessionHistoryProvider, (_, __) => push(), fireImmediately: true);
  ref.listen(appLocaleProvider, (_, __) => push());
});
