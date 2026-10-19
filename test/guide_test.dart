import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/features/guide/guide.dart';
import 'package:vocal_scale_trainer/features/guide/guide_tour.dart';
import 'package:vocal_scale_trainer/l10n/app_localizations.dart';

final _it = lookupAppLocalizations(const Locale('it'));

void main() {
  group('steps and targets', () {
    test('every step of the app guide points to an element in its section', () {
      final steps = appGuideSteps(_it);
      expect([
        for (final s in steps) (s.target, s.section)
      ], [
        (GuideTarget.homeMic, '/'),
        (GuideTarget.dailyWorkout, '/'),
        (GuideTarget.homeStatus, '/'),
        (GuideTarget.navExercises, '/'),
        (GuideTarget.customSequences, '/exercises'),
        (GuideTarget.exerciseCategories, '/exercises'),
        (GuideTarget.exerciseCategories, '/exercises'),
        (GuideTarget.firstExercise, '/exercises'),
        (GuideTarget.trainerKey, '/trainer'),
        (GuideTarget.trainerOctave, '/trainer'),
        (GuideTarget.trainerDirection, '/trainer'),
        (GuideTarget.trainerRepeatTop, '/trainer'),
        (GuideTarget.trainerMode, '/trainer'),
        (GuideTarget.trainerAdvanced, '/trainer'),
        (GuideTarget.trainerHelp, '/trainer'),
        (GuideTarget.trainerBack, '/trainer'),
        (GuideTarget.navRange, '/exercises'),
        (GuideTarget.rangeTest, '/range'),
        (GuideTarget.tessitura, '/range'),
        (GuideTarget.navProfile, '/range'),
        (GuideTarget.profileStats, '/profile'),
        (GuideTarget.profileAchievements, '/profile'),
        (GuideTarget.profileHistory, '/profile'),
        (GuideTarget.profileSettings, '/profile'),
        (GuideTarget.settingsLanguage, '/settings'),
        (GuideTarget.settingsTheme, '/settings'),
        (GuideTarget.settingsNotation, '/settings'),
        (GuideTarget.settingsGuide, '/settings'),
      ]);
      for (final step in steps) {
        expect(step.title, isNotEmpty);
        expect(step.text, isNotEmpty);
      }
    });

    test('the user moves between sections: each change of page waits for a tap', () {
      final steps = appGuideSteps(_it);
      for (var i = 1; i < steps.length; i++) {
        final previous = steps[i - 1];
        final step = steps[i];
        if (step.section != previous.section) {
          // Si arriva in una nuova sezione solo dopo un passaggio da toccare
          // che porta proprio lì.
          expect(previous.awaitRoute, step.section, reason: '${step.title} (${i + 1})');
        }
      }
      final interactive = [
        for (final s in steps)
          if (s.interactive) s
      ];
      expect([
        for (final s in interactive) s.awaitRoute ?? s.awaitTarget
      ], [
        '/exercises',
        GuideTarget.firstExercise,
        '/trainer',
        '/exercises',
        '/range',
        '/profile',
        '/settings',
      ]);
      // Le voci della barra: "Vai a Esercizi" / "Tocca «Esercizi»…".
      expect(steps[3].title, 'Vai a Esercizi');
      expect(steps[3].text, contains('«Esercizi»'));
      expect(interactive.every((s) => s.skipIfMissing), isTrue);
    });

    test('the exercise guide stays on the exercise and lists only the controls on screen', () {
      final full = exerciseGuideSteps(_it, hasKeyAndOctave: true, hasRepeatTop: true);
      expect([
        for (final s in full) s.target
      ], [
        GuideTarget.trainerKey,
        GuideTarget.trainerOctave,
        GuideTarget.trainerDirection,
        GuideTarget.trainerRepeatTop,
        GuideTarget.trainerMode,
        GuideTarget.trainerAdvanced,
      ]);
      expect(full.every((s) => s.section == null && !s.interactive), isTrue);
      final fixed = exerciseGuideSteps(_it, hasKeyAndOctave: false, hasRepeatTop: false);
      expect([
        for (final s in fixed) s.target
      ], [
        GuideTarget.trainerDirection,
        GuideTarget.trainerMode,
        GuideTarget.trainerAdvanced,
      ]);
    });
  });

  group('GuideTourController', () {
    test('next, back and close; the future completes when the guide ends', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final tour = container.read(guideTourProvider.notifier);
      final steps = appGuideSteps(_it).take(3).toList();
      var ended = false;
      final done = tour.start(steps).then((_) => ended = true);

      expect(container.read(guideTourProvider)!.index, 0);
      tour.back();
      expect(container.read(guideTourProvider)!.index, 0, reason: 'già al primo');
      tour.next();
      tour.next();
      expect(container.read(guideTourProvider)!.isLast, isTrue);
      tour.back();
      expect(container.read(guideTourProvider)!.index, 1);
      tour.next();
      tour.next(); // "Fine" sull'ultimo
      await done;
      expect(ended, isTrue);
      expect(container.read(guideTourProvider), isNull);
      // Comandi a guida chiusa: nessun effetto.
      tour.next();
      tour.back();
      expect(container.read(guideTourProvider), isNull);
    });

    test('a step that cannot be shown is skipped in the direction of travel', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final tour = container.read(guideTourProvider.notifier);
      final done = tour.start(appGuideSteps(_it).take(4).toList());
      tour.skip(); // avanti dal primo
      expect(container.read(guideTourProvider)!.index, 1);
      tour.next();
      tour.back();
      expect(container.read(guideTourProvider)!.forward, isFalse);
      tour.skip(); // si tornava indietro: si continua indietro
      expect(container.read(guideTourProvider)!.index, 0);
      tour.skip(); // al primo non si può tornare oltre: si va avanti
      expect(container.read(guideTourProvider)!.index, 1);
      expect(container.read(guideTourProvider)!.forward, isTrue);
      tour.next();
      tour.next();
      tour.skip(); // oltre l'ultimo: la guida finisce
      await done;
      expect(container.read(guideTourProvider), isNull);
    });

    test('skip or close end the guide at any step', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final tour = container.read(guideTourProvider.notifier);
      final done = tour.start(appGuideSteps(_it));
      tour.next();
      tour.close();
      await done;
      expect(container.read(guideTourProvider), isNull);
    });

    test('an empty guide does not open; a new guide replaces the previous one', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final tour = container.read(guideTourProvider.notifier);
      await tour.start(const []);
      expect(container.read(guideTourProvider), isNull);

      var firstEnded = false;
      tour.start(appGuideSteps(_it)).then((_) => firstEnded = true);
      final second =
          tour.start(exerciseGuideSteps(_it, hasKeyAndOctave: true, hasRepeatTop: false));
      await Future<void>.delayed(Duration.zero);
      expect(firstEnded, isTrue);
      expect(container.read(guideTourProvider)!.steps, hasLength(5));
      tour.close();
      await second;
    });
  });

  testWidgets('anchors register only what is mounted; closing leaves no guide open',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: const Scaffold(
          body: Column(children: [
            GuideAnchor(
                target: GuideTarget.trainerDirection, child: SizedBox(height: 40, width: 200)),
          ]),
        ),
      ),
    ));
    // Il livello della guida senza router: solo passaggi senza sezione.
    final steps = exerciseGuideSteps(_it, hasKeyAndOctave: true, hasRepeatTop: false);
    final element = tester.element(find.byType(Scaffold));
    showGuide(element, steps);
    await tester.pump();
    expect(container.read(guideTourProvider)!.step.target, GuideTarget.trainerKey);
    // Senza GuideTourLayer non c'è overlay: chiudere non lascia nulla.
    container.read(guideTourProvider.notifier).close();
    await tester.pump();
    expect(container.read(guideTourProvider), isNull);
    expect(GuideAnchor.contextOf(GuideTarget.trainerKey), isNull);
    expect(GuideAnchor.contextOf(GuideTarget.trainerDirection), isNotNull);
  });
}
