import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/app_theme.dart';
import 'package:vocal_scale_trainer/app/l10n.dart';
import 'package:vocal_scale_trainer/core/session/session_record.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/features/mascot/presentation/intonia_mascot.dart';
import 'package:vocal_scale_trainer/features/profile/application/history_providers.dart';
import 'package:vocal_scale_trainer/features/progress/domain/progress_summary.dart';
import 'package:vocal_scale_trainer/features/progress/presentation/progress_cards.dart';
import 'package:vocal_scale_trainer/services/storage/session_history_repository.dart';

class _MemorySessions extends SessionHistoryRepository {
  _MemorySessions(this.items);
  List<SessionRecord> items;
  @override
  Future<List<SessionRecord>> load() async => items;
  @override
  Future<void> save(List<SessionRecord> records) async => items = records;
}

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

/// Mercoledì 14 ottobre 2026, mezzogiorno: la settimana va da lunedì 12 a
/// domenica 18.
final _now = DateTime(2026, 10, 14, 12);
DateTime _day(int offset, [int hour = 10]) => DateTime(2026, 10, 14 + offset, hour);

void main() {
  group('weekly precision', () {
    test('no sessions: no percent, past days empty, today empty, future days future', () {
      final week = WeeklyPrecision.from(const [], _now);
      expect(week.percent, isNull);
      expect(week.hasData, isFalse);
      expect(week.days, hasLength(7));
      expect(week.days.first.day, DateTime(2026, 10, 12));
      expect(week.days.last.day, DateTime(2026, 10, 18));
      expect([
        for (final d in week.days) d.status
      ], [
        DayStatus.empty,
        DayStatus.empty,
        DayStatus.empty,
        DayStatus.future,
        DayStatus.future,
        DayStatus.future,
        DayStatus.future,
      ]);
      expect(
          [for (final d in week.days) d.isToday], [false, false, true, false, false, false, false]);
    });

    test('the average weighs every note, not every session', () {
      final week = WeeklyPrecision.from([
        _session(_day(-2), correct: 9, errors: 1), // lunedì 90%
        _session(_day(0), correct: 1, errors: 1), // oggi 50% su due note
      ], _now);
      // (9 + 1) / (10 + 2) = 83,3% — non la media delle sessioni (70%).
      expect(week.percent, 83);
      expect(week.days[0].status, DayStatus.measured);
      expect(week.days[0].percent, 90);
      expect(week.days[1].status, DayStatus.empty);
      expect(week.days[2].status, DayStatus.measured);
      expect(week.days[2].percent, 50);
    });

    test('a session without scored notes is activity, not precision', () {
      final week = WeeklyPrecision.from([_session(_day(-1), correct: 0, errors: 0)], _now);
      expect(week.days[1].status, DayStatus.activityOnly);
      expect(week.days[1].percent, isNull);
      expect(week.percent, isNull, reason: 'nessuna precisione inventata');
    });

    test('a session saved twice counts once', () {
      final session = _session(_day(0), correct: 6, errors: 4);
      final week = WeeklyPrecision.from([session, session], _now);
      expect(week.attempts, 10);
      expect(week.percent, 60);
    });

    test('previous week and future sessions stay out of the week', () {
      final week = WeeklyPrecision.from([
        _session(DateTime(2026, 10, 11, 23, 59), correct: 1, errors: 9), // domenica prima
        _session(_day(2), correct: 0, errors: 10), // venerdì: futuro (orologio sbagliato)
        _session(DateTime(2026, 10, 12, 0, 1), correct: 7, errors: 3), // lunedì appena iniziato
      ], _now);
      expect(week.percent, 70);
      expect(week.previousPercent, 10);
      expect(week.improved, isTrue);
      expect(week.days[4].status, DayStatus.future);
    });

    test('a week across the new year starts on Monday 28 December', () {
      final now = DateTime(2027, 1, 1, 9); // venerdì
      final week = WeeklyPrecision.from([_session(DateTime(2026, 12, 28, 20))], now);
      expect(week.days.first.day, DateTime(2026, 12, 28));
      expect(week.days.last.day, DateTime(2027, 1, 3));
      expect(week.days[0].status, DayStatus.measured);
      expect(week.days[4].isToday, isTrue);
    });

    test('on Sunday every day of the week is in the past or today', () {
      final week = WeeklyPrecision.from(const [], DateTime(2026, 10, 18, 23, 30));
      expect(week.days.where((d) => d.status == DayStatus.future), isEmpty);
      expect(week.days.last.isToday, isTrue);
    });

    test('improved only when both weeks are measured', () {
      expect(WeeklyPrecision.from([_session(_day(0))], _now).improved, isFalse);
      final worse = WeeklyPrecision.from([
        _session(_day(-7), correct: 9, errors: 1),
        _session(_day(0), correct: 5, errors: 5),
      ], _now);
      expect(worse.improved, isFalse);
    });
  });

  group('streak summary', () {
    test('uses the same count as computeStreak', () {
      final sessions = [_session(_day(-2)), _session(_day(-1)), _session(_day(0))];
      final summary = StreakSummary.from(sessions, _now);
      expect(summary.days, computeStreak(sessions.map((s) => s.timestamp), _now));
      expect(summary.days, 3);
      expect(summary.phase, StreakPhase.active);
    });

    test('phases: none, started today, alive but not yet today', () {
      expect(StreakSummary.from(const [], _now).phase, StreakPhase.none);
      expect(StreakSummary.from([_session(_day(-3))], _now).phase, StreakPhase.none);
      final started = StreakSummary.from([_session(_day(0))], _now);
      expect((started.days, started.phase), (1, StreakPhase.started));
      final keepGoing = StreakSummary.from([_session(_day(-2)), _session(_day(-1))], _now);
      expect((keepGoing.days, keepGoing.phase), (2, StreakPhase.keepGoing));
    });
  });

  group('cards', () {
    Future<void> pump(
      WidgetTester tester,
      Widget card, {
      List<SessionRecord> sessions = const [],
      double width = 390,
      Locale locale = const Locale('it'),
      double textScale = 1,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      // Un ProviderScope nuovo a ogni chiamata, con le sue sessioni.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => _now),
          sessionHistoryRepositoryProvider.overrideWithValue(_MemorySessions([...sessions])),
        ],
        child: MaterialApp(
          theme: buildDarkTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(padding: const EdgeInsets.all(16), child: card),
            ),
          ),
        ),
      ));
      // La mascotte è animata: niente pumpAndSettle.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    String text(WidgetTester tester, String key) =>
        tester.widget<Text>(find.byKey(ValueKey(key))).data!;

    testWidgets('streak 0: the original mascot and an invitation to start', (tester) async {
      await pump(tester, const StreakCard());
      expect(find.byKey(const ValueKey('home-streak-mascot')), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('home-streak')), matching: find.byType(IntoniaMascot)),
          findsOneWidget);
      expect(text(tester, 'home-streak-days'), '0');
      expect(text(tester, 'home-streak-message'), 'Inizia oggi la tua serie!');
      expect(find.textContaining('%'), findsNothing, reason: 'niente percentuali nella serie');
    });

    testWidgets('streak active and keep-going messages come from real sessions', (tester) async {
      await pump(tester, const StreakCard(),
          sessions: [_session(_day(-2)), _session(_day(-1)), _session(_day(0))]);
      expect(text(tester, 'home-streak-days'), '3');
      expect(find.text('giorni\ndi fila'), findsOneWidget);
      expect(text(tester, 'home-streak-message'), 'Continua così, sei sulla strada giusta!');

      await pump(tester, const StreakCard(), sessions: [_session(_day(-1))]);
      expect(text(tester, 'home-streak-days'), '1');
      expect(find.text('giorno\ndi fila'), findsOneWidget);
      expect(text(tester, 'home-streak-message'), 'Allenati oggi per non perdere la serie!');
    });

    testWidgets('precision empty state: no invented percentage', (tester) async {
      await pump(tester, const WeeklyPrecisionCard());
      expect(text(tester, 'precision-card-percent'), '—');
      expect(find.text('Fai un esercizio per misurarla'), findsOneWidget);
      expect(find.byKey(const ValueKey('precision-day-0-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('precision-day-2-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('precision-day-3-future')), findsOneWidget);
    });

    testWidgets('precision shows every day state with its own label for screen readers',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const WeeklyPrecisionCard(), sessions: [
        _session(_day(-7), correct: 5, errors: 5), // settimana scorsa 50%
        _session(_day(-2), correct: 9, errors: 1),
        _session(_day(-1), correct: 0, errors: 0),
      ]);
      expect(text(tester, 'precision-card-percent'), '90%');
      expect(find.text('Voce sempre più intonata!'), findsOneWidget);
      expect(find.byKey(const ValueKey('precision-day-0-measured')), findsOneWidget);
      expect(find.byKey(const ValueKey('precision-day-1-activityOnly')), findsOneWidget);
      expect(find.byKey(const ValueKey('precision-day-2-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('precision-day-6-future')), findsOneWidget);
      expect(find.bySemanticsLabel('Lun: precisione 90 per cento'), findsOneWidget);
      expect(find.bySemanticsLabel('Mar: allenamento senza note valutate'), findsOneWidget);
      expect(find.bySemanticsLabel('Mer: nessun allenamento'), findsOneWidget);
      expect(find.bySemanticsLabel('Dom: non ancora arrivato'), findsOneWidget);
      expect(
          find.bySemanticsLabel('Precisione media della settimana: 90 per cento'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('both cards fit narrow and wide screens, large text and English', (tester) async {
      final sessions = [_session(_day(-1)), _session(_day(0), correct: 3, errors: 7)];
      for (final (width, scale, locale) in [
        (320.0, 1.0, const Locale('it')),
        (360.0, 1.3, const Locale('it')),
        (390.0, 1.0, const Locale('en')),
        (800.0, 1.0, const Locale('it')),
        (1200.0, 1.3, const Locale('en')),
      ]) {
        for (final card in const [StreakCard(), WeeklyPrecisionCard()]) {
          await pump(tester, card,
              sessions: sessions, width: width, locale: locale, textScale: scale);
          expect(tester.takeException(), isNull, reason: '$card $width $scale $locale');
        }
      }
      // In inglese i giorni partono comunque dal lunedì.
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });
  });
}
