import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/home_widget/domain/widget_precision.dart';
import '../../features/home_widget/domain/widget_streak.dart';

/// Pubblica i dati della serie, della precisione settimanale e la lingua
/// dell'app per i widget nativi e chiede di aggiornarli.
class HomeWidgetService {
  /// App Group condiviso tra app e widget su iOS.
  static const appGroupId = 'group.io.github.davedegrado.intonia';
  static const iOSWidgetKind = 'IntoniaWidget';
  static const androidProvider = 'io.github.davedegrado.intonia.IntoniaWidgetProvider';
  static const iOSPrecisionWidgetKind = 'IntoniaPrecisionWidget';
  static const androidPrecisionProvider =
      'io.github.davedegrado.intonia.IntoniaPrecisionWidgetProvider';

  static const keyLastTrainingDay = 'intonia_last_training_day';
  static const keyStreak = 'intonia_streak_at_last_training';

  /// Totali per giorno ([WidgetPrecisionData.encode]).
  static const keyPrecisionDays = 'intonia_precision_days';

  /// Lingua attiva dell'app ("it", "en"): il widget usa la stessa.
  static const keyLanguage = 'intonia_language';

  ({WidgetStreakData data, WidgetPrecisionData precision, String languageCode})? _lastSent;

  Future<void> publish(
    WidgetStreakData data, {
    required WidgetPrecisionData precision,
    required String languageCode,
  }) async {
    final payload = (data: data, precision: precision, languageCode: languageCode);
    if (payload == _lastSent) {
      return;
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
      // Stringhe: stesso tipo letto da Kotlin (SharedPreferences) e Swift
      // (UserDefaults), senza ambiguità Int/Long.
      await HomeWidget.saveWidgetData<String>(keyLastTrainingDay, data.lastTrainingDay);
      await HomeWidget.saveWidgetData<String>(keyStreak, '${data.streakAtLastTraining}');
      await HomeWidget.saveWidgetData<String>(keyPrecisionDays, precision.encode());
      await HomeWidget.saveWidgetData<String>(keyLanguage, languageCode);
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetKind,
        qualifiedAndroidName: androidProvider,
      );
      await HomeWidget.updateWidget(
        iOSName: iOSPrecisionWidgetKind,
        qualifiedAndroidName: androidPrecisionProvider,
      );
      _lastSent = payload;
    } catch (error) {
      // Widget non disponibile (test, piattaforma non supportata, nessun
      // widget installato): non deve mai bloccare l'app.
      debugPrint('Aggiornamento widget non riuscito: $error');
    }
  }
}
