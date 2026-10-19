import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/session/session_record.dart';
import 'package:vocal_scale_trainer/features/home_widget/domain/widget_precision.dart';

SessionRecord _session(DateTime at, {int correct = 8, int errors = 2, String id = 'scale'}) =>
    SessionRecord(
      timestamp: at,
      exerciseId: id,
      exerciseName: id,
      correct: correct,
      errors: errors,
      durationSeconds: 60,
      perNote: const {},
    );

/// Mercoledì 14 ottobre 2026: la settimana va da lunedì 12 a domenica 18.
final _now = DateTime(2026, 10, 14, 12);
DateTime _day(int offset, [int hour = 10]) => DateTime(2026, 10, 14 + offset, hour);

PrecisionWidgetView _view(List<SessionRecord> sessions, [DateTime? at]) => PrecisionWidgetView.of(
    WidgetPrecisionData.decode(WidgetPrecisionData.fromSessions(sessions, _now).encode()),
    at ?? _now);

void main() {
  group('WidgetPrecisionData', () {
    test('daily totals from the previous Monday to today, duplicates counted once', () {
      final twice = _session(_day(0), correct: 6, errors: 4);
      final data = WidgetPrecisionData.fromSessions([
        twice,
        twice,
        _session(_day(0, 18), correct: 0, errors: 0),
        _session(DateTime(2026, 10, 5, 9)), // lunedì della settimana scorsa: incluso
        _session(DateTime(2026, 10, 4, 9)), // domenica prima: escluso
        _session(_day(1)), // domani (orologio sbagliato): escluso
      ], _now);
      expect(data.days.keys.toList()..sort(), ['2026-10-05', '2026-10-14']);
      expect(data.days['2026-10-14'], const DayTotals(correct: 6, attempts: 10, sessions: 2));
    });

    test('encode and decode round trip; broken entries are ignored', () {
      final data = WidgetPrecisionData.fromSessions([_session(_day(-2)), _session(_day(0))], _now);
      expect(data.encode(), '2026-10-12:8:10:1;2026-10-14:8:10:1');
      expect(WidgetPrecisionData.decode(data.encode()), data);
      expect(WidgetPrecisionData.decode(null), WidgetPrecisionData.empty);
      expect(WidgetPrecisionData.decode('x;2026-10-14:a:1:1;2026-10-13:1:2:1').days.keys,
          ['2026-10-13']);
    });
  });

  group('PrecisionWidgetView', () {
    test('no data: no percent, past days empty, future days future', () {
      final view = _view(const []);
      expect(view.percent, isNull);
      expect(view.message, PrecisionMessage.empty);
      expect(view.todayIndex, 2);
      expect(view.days, [
        PrecisionDayStatus.empty,
        PrecisionDayStatus.empty,
        PrecisionDayStatus.empty,
        PrecisionDayStatus.future,
        PrecisionDayStatus.future,
        PrecisionDayStatus.future,
        PrecisionDayStatus.future,
      ]);
    });

    test('every note weighs the same; activity without notes is not precision', () {
      final view = _view([
        _session(_day(-2), correct: 9, errors: 1),
        _session(_day(-1), correct: 0, errors: 0),
        _session(_day(0), correct: 1, errors: 1),
      ]);
      // (9 + 1) / (10 + 2) = 83%, non la media delle sessioni (70%).
      expect(view.percent, 83);
      expect(view.days.take(3), [
        PrecisionDayStatus.measured,
        PrecisionDayStatus.activityOnly,
        PrecisionDayStatus.measured,
      ]);
      expect(view.dayPercents.take(3), [90, null, 50]);
      expect(view.message, PrecisionMessage.high);
    });

    test('only activity without notes: still no percentage', () {
      final view = _view([_session(_day(0), correct: 0, errors: 0)]);
      expect(view.percent, isNull);
      expect(view.days[2], PrecisionDayStatus.activityOnly);
      expect(view.message, PrecisionMessage.empty);
    });

    test('improved over last week, otherwise by level', () {
      expect(
          _view([
            _session(_day(-7), correct: 5, errors: 5),
            _session(_day(0), correct: 6, errors: 4)
          ]).message,
          PrecisionMessage.improved);
      expect(_view([_session(_day(0), correct: 6, errors: 4)]).message, PrecisionMessage.mid);
      expect(_view([_session(_day(0), correct: 3, errors: 7)]).message, PrecisionMessage.low);
      final worse = _view(
          [_session(_day(-7), correct: 9, errors: 1), _session(_day(0), correct: 8, errors: 2)]);
      expect(
          (worse.previousPercent, worse.percent, worse.message), (90, 80, PrecisionMessage.high));
    });

    test('next Monday the widget starts a new week on its own (app closed)', () {
      final view = _view([_session(_day(0), correct: 9, errors: 1)], DateTime(2026, 10, 19, 8));
      expect(view.todayIndex, 0);
      expect(view.percent, isNull, reason: 'settimana nuova, ancora nessun dato');
      expect(view.previousPercent, 90);
      expect(view.days.first, PrecisionDayStatus.empty);
    });

    test('a week across the new year starts on Monday 28 December', () {
      final now = DateTime(2027, 1, 1, 9); // venerdì
      final data = WidgetPrecisionData.fromSessions([_session(DateTime(2026, 12, 28, 20))], now);
      final view = PrecisionWidgetView.of(data, now);
      expect(view.todayIndex, 4);
      expect(view.days.first, PrecisionDayStatus.measured);
      expect(view.days[5], PrecisionDayStatus.future);
    });

    test('on Sunday no day is in the future', () {
      final view = _view(const [], DateTime(2026, 10, 18, 23, 30));
      expect(view.todayIndex, 6);
      expect(view.days, isNot(contains(PrecisionDayStatus.future)));
    });
  });
}
