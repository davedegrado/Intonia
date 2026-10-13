import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/features/home_widget/domain/widget_streak.dart';

void main() {
  group('WidgetStreakData.fromSessions', () {
    test('empty history', () {
      expect(WidgetStreakData.fromSessions(const []), WidgetStreakData.empty);
    });

    test('streak counted up to the last training day', () {
      final data = WidgetStreakData.fromSessions([
        DateTime(2026, 10, 10, 9),
        DateTime(2026, 10, 11, 20),
        DateTime(2026, 10, 12, 8),
        DateTime(2026, 10, 12, 21),
      ]);
      expect(data.lastTrainingDay, '2026-10-12');
      expect(data.streakAtLastTraining, 3);
    });

    test('a gap resets the streak', () {
      final data = WidgetStreakData.fromSessions([
        DateTime(2026, 10, 8),
        DateTime(2026, 10, 10),
        DateTime(2026, 10, 11),
      ]);
      expect(data.streakAtLastTraining, 2);
    });
  });

  group('WidgetView.of', () {
    const data = WidgetStreakData(lastTrainingDay: '2026-10-13', streakAtLastTraining: 3);

    test('trained today', () {
      final view = WidgetView.of(data, DateTime(2026, 10, 13, 22));
      expect(view.status, WidgetStatus.trainedToday);
      expect(view.title, '3 giorni di fila');
      expect(view.message, 'Fatto! Sei inarrestabile ✨');
      expect(view.week, [false, false, false, false, true, true, true]);
    });

    test('trained yesterday: keep the streak alive', () {
      final view = WidgetView.of(data, DateTime(2026, 10, 14, 7));
      expect(view.status, WidgetStatus.keepStreak);
      expect(view.streak, 3);
      expect(view.message, 'Allenati oggi: salva la serie! 🔥');
      expect(view.week, [false, false, false, true, true, true, false]);
    });

    test('streak lost after a missed day', () {
      final view = WidgetView.of(data, DateTime(2026, 10, 15));
      expect(view.status, WidgetStatus.start);
      expect(view.streak, 0);
      expect(view.title, 'Allena l\'orecchio');
      // I giorni allenati restano visibili anche a serie interrotta.
      expect(view.week, [false, false, true, true, true, false, false]);
    });

    test('no history', () {
      expect(
          WidgetView.of(WidgetStreakData.empty, DateTime(2026, 10, 13)).status, WidgetStatus.start);
    });

    test('singular title and month boundary', () {
      const one = WidgetStreakData(lastTrainingDay: '2026-09-30', streakAtLastTraining: 1);
      final view = WidgetView.of(one, DateTime(2026, 10, 1, 8));
      expect(view.status, WidgetStatus.keepStreak);
      expect(view.title, '1 giorno di fila');
      expect(view.week, [false, false, false, false, false, true, false]);
    });

    test('a long streak fills the whole week', () {
      const long = WidgetStreakData(lastTrainingDay: '2026-10-13', streakAtLastTraining: 40);
      expect(WidgetView.of(long, DateTime(2026, 10, 13, 9)).week, List.filled(7, true));
      expect(WidgetView.of(WidgetStreakData.empty, DateTime(2026, 10, 13)).week,
          List.filled(7, false));
    });
  });
}
