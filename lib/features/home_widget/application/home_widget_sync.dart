import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/widget/home_widget_service.dart';
import '../../profile/application/history_providers.dart';
import '../domain/widget_streak.dart';

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) => HomeWidgetService());

/// Tiene aggiornato il widget nativo: pubblica la serie all'avvio (appena lo
/// storico è caricato) e a ogni nuova sessione salvata.
final homeWidgetSyncProvider = Provider<void>((ref) {
  ref.listen(
    sessionHistoryProvider,
    (previous, next) {
      final sessions = next.value;
      if (sessions == null) {
        return;
      }
      final data = WidgetStreakData.fromSessions(sessions.map((s) => s.timestamp));
      unawaited(ref.read(homeWidgetServiceProvider).publish(data));
    },
    fireImmediately: true,
  );
});
