import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/session/session_record.dart';
import 'package:vocal_scale_trainer/features/mascot/domain/mascot_mood.dart';
import 'package:vocal_scale_trainer/l10n/app_localizations.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/session_result.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/screens/session_result_screen.dart';

SessionRecord _record({required int correct, required int errors}) => SessionRecord(
      timestamp: DateTime(2026, 10, 14),
      exerciseId: 'major_scale',
      exerciseName: 'Scala maggiore',
      correct: correct,
      errors: errors,
      durationSeconds: 75,
      perNote: const {},
    );

final _it = lookupAppLocalizations(const Locale('it'));
final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  test('tiers follow the accuracy percentage', () {
    expect(ResultTier.of(100), ResultTier.perfect);
    expect(ResultTier.of(99), ResultTier.great);
    expect(ResultTier.of(80), ResultTier.great);
    expect(ResultTier.of(79), ResultTier.good);
    expect(ResultTier.of(50), ResultTier.good);
    expect(ResultTier.of(49), ResultTier.retry);
    expect(ResultTier.perfect.mood, MascotMood.success);
    expect(ResultTier.retry.mood, MascotMood.retry);
    expect(ResultTier.great.celebrates, isTrue);
    expect(ResultTier.good.celebrates, isFalse);
  });

  test('the percentage is the same one shown in the profile', () {
    // 7 corrette su 8 tentativi = 87,5% → 88%.
    final record = _record(correct: 7, errors: 1);
    expect(record.accuracyPercent, 88);
  });

  Future<SessionResultAction?> showResult(WidgetTester tester, SessionRecord record,
      {bool reduceMotion = false, String? tapLabel, Locale locale = const Locale('it')}) async {
    SessionResultAction? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async =>
                  result = await Navigator.of(context).push(SessionResultScreen.route(record)),
              child: const Text('apri'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('apri'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    if (tapLabel != null) {
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text(tapLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    return result;
  }

  testWidgets('counts up to the session accuracy with the matching message', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.reset);
    await showResult(tester, _record(correct: 7, errors: 1));

    // All'inizio la percentuale parte da zero e sale.
    final early = tester.widget<Text>(find.byKey(const ValueKey('result-percent'))).data;
    expect(early, isNot('88%'));

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('88%'), findsOneWidget);
    expect(find.text(ResultTier.great.title(_it)), findsOneWidget);
    expect(find.text('Ottimo lavoro!'), findsOneWidget);
    expect(find.text('Corrette'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('1:15'), findsOneWidget);
  });

  testWidgets('shows the final result at once when animations are disabled', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.reset);
    await showResult(tester, _record(correct: 1, errors: 3), reduceMotion: true);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text(ResultTier.retry.title(_it)), findsOneWidget);
  });

  testWidgets('continue and repeat report the choice', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.reset);
    expect(await showResult(tester, _record(correct: 8, errors: 0), tapLabel: 'Continua'),
        SessionResultAction.done);
    expect(await showResult(tester, _record(correct: 8, errors: 0), tapLabel: 'Ripeti esercizio'),
        SessionResultAction.repeat);
  });

  testWidgets('is fully translated in English', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.reset);
    await showResult(tester, _record(correct: 7, errors: 1),
        reduceMotion: true, locale: const Locale('en'));
    expect(find.text('Great job!'), findsOneWidget);
    expect(find.text(ResultTier.great.message(_en)), findsOneWidget);
    expect(find.text('accuracy'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Errors'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Repeat exercise'), findsOneWidget);
    expect(find.bySemanticsLabel('Accuracy 88 percent'), findsOneWidget);
    expect(find.bySemanticsLabel('Intonia mascot'), findsOneWidget);

    await tester.tap(find.text('Repeat exercise'));
    await tester.pumpAndSettle();
    expect(find.text('apri'), findsOneWidget);
  });
}
