import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/l10n.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/features/range/presentation/range_result_screen.dart';

void main() {
  test('comparison with the previous test', () {
    expect(RangeComparison.of(24, null), RangeComparison.first);
    expect(RangeComparison.of(25, 24), RangeComparison.better);
    expect(RangeComparison.of(24, 24), RangeComparison.same);
    expect(RangeComparison.of(20, 24), RangeComparison.worse);
    expect(RangeComparison.better.celebrates, isTrue);
    expect(RangeComparison.worse.celebrates, isFalse);
  });

  Future<RangeResultAction?> open(WidgetTester tester,
      {int? previousSpan,
      bool reduceMotion = false,
      String? tap,
      Locale locale = const Locale('it')}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.reset);
    RangeResultAction? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await Navigator.of(context).push(
            RangeResultScreen.route(RangeResultScreen(
              lowestMidi: 45, // LA2
              highestMidi: 74, // RE5
              startMidi: 57,
              notation: NoteNotation.italian,
              previousSpan: previousSpan,
            )),
          ),
          child: const Text('apri'),
        ),
      ),
    ));
    await tester.tap(find.text('apri'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    if (tap != null) {
      await tester.tap(find.text(tap));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    return result;
  }

  testWidgets('opens the range from the starting note to the result', (tester) async {
    await open(tester, previousSpan: 26);
    expect(find.text('Nuovo record!'), findsOneWidget);
    expect(find.text('2 ottave + 5 semitoni (29 semitoni)'), findsOneWidget);
    expect(find.text("+3 semitoni rispetto all'ultimo test"), findsOneWidget);
  });

  testWidgets('shows the final range at once when animations are disabled', (tester) async {
    await open(tester, reduceMotion: true);
    expect(find.text('Ecco la tua estensione!'), findsOneWidget);
    expect(find.text('2 ottave + 5 semitoni (29 semitoni)'), findsOneWidget);
  });

  testWidgets('a smaller range is reported kindly', (tester) async {
    await open(tester, previousSpan: 30);
    expect(find.text('Ecco la tua estensione di oggi'), findsOneWidget);
    expect(
      find.text("-1 semitono rispetto all'ultimo test: capita, la voce cambia di giorno in giorno"),
      findsOneWidget,
    );
  });

  testWidgets('speaks English when the app is in English', (tester) async {
    await open(tester, previousSpan: 26, locale: const Locale('en'));
    expect(find.text('New record!'), findsOneWidget);
    expect(find.text('2 octaves + 5 semitones (29 semitones)'), findsOneWidget);
    expect(find.text('+3 semitones compared to your last test'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Retry the test'), findsOneWidget);
  });

  testWidgets('English titles for first and same span', (tester) async {
    await open(tester, reduceMotion: true, locale: const Locale('en'));
    expect(find.text("Here's your vocal range!"), findsOneWidget);
  });

  testWidgets('continue and retry report the choice', (tester) async {
    expect(await open(tester, tap: 'Continua'), RangeResultAction.done);
    expect(await open(tester, tap: 'Riprova il test'), RangeResultAction.retry);
  });
}
