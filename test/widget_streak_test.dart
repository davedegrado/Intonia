import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/session/session_record.dart';
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
      expect(view.streak, 3);
      expect(view.label, 'giorni\ndi fila');
      expect(view.message, 'Continua così, sei sulla strada giusta!');
    });

    test('first day of a streak, done today', () {
      const one = WidgetStreakData(lastTrainingDay: '2026-10-13', streakAtLastTraining: 1);
      final view = WidgetView.of(one, DateTime(2026, 10, 13, 8));
      expect(view.status, WidgetStatus.firstDay);
      expect(view.label, 'giorno\ndi fila');
      expect(view.message, 'Primo giorno: ottimo inizio!');
    });

    test('trained yesterday: keep the streak alive', () {
      final view = WidgetView.of(data, DateTime(2026, 10, 14, 7));
      expect(view.status, WidgetStatus.keepStreak);
      expect(view.streak, 3);
      expect(view.message, 'Allenati oggi per non perdere la serie!');
    });

    test('streak lost after a missed day', () {
      final view = WidgetView.of(data, DateTime(2026, 10, 15));
      expect(view.status, WidgetStatus.start);
      expect(view.streak, 0);
      expect(view.message, 'Inizia oggi la tua serie!');
    });

    test('no history', () {
      final view = WidgetView.of(WidgetStreakData.empty, DateTime(2026, 10, 13));
      expect(view.status, WidgetStatus.start);
      expect(view.streak, 0);
    });

    test('month boundary', () {
      const one = WidgetStreakData(lastTrainingDay: '2026-09-30', streakAtLastTraining: 1);
      final view = WidgetView.of(one, DateTime(2026, 10, 1, 8));
      expect(view.status, WidgetStatus.keepStreak);
      expect(view.streak, 1);
      expect(view.label, 'giorno\ndi fila');
    });

    test('same count as the app (computeStreak)', () {
      final sessions = [
        DateTime(2026, 10, 11, 9),
        DateTime(2026, 10, 12, 9),
        DateTime(2026, 10, 13)
      ];
      final now = DateTime(2026, 10, 13, 20);
      expect(WidgetView.of(WidgetStreakData.fromSessions(sessions), now).streak,
          computeStreak(sessions, now));
    });
  });
}
