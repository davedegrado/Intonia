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
        (GuideTarget.exerciseCategories, '/exercises'),
        (GuideTarget.customSequences, '/exercises'),
        (GuideTarget.rangeTest, '/range'),
        (GuideTarget.tessitura, '/range'),
        (GuideTarget.profileStats, '/profile'),
        (GuideTarget.profileAchievements, '/profile'),
        (GuideTarget.profileHistory, '/profile'),
        (GuideTarget.settingsLanguage, '/settings'),
        (GuideTarget.settingsTheme, '/settings'),
        (GuideTarget.settingsNotation, '/settings'),
        (GuideTarget.settingsGuide, '/settings'),
      ]);
      // Sezioni raggruppate: la guida non salta avanti e indietro.
      final sections = [for (final s in steps) s.section];
      final order = <String?>[];
      for (final section in sections) {
        if (order.isEmpty || order.last != section) {
          order.add(section);
        }
      }
      expect(order.toSet(), hasLength(order.length));
      for (final step in steps) {
        expect(step.title, isNotEmpty);
        expect(step.text, isNotEmpty);
      }
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
      ]);
      expect(full.every((s) => s.section == null), isTrue);
      final fixed = exerciseGuideSteps(_it, hasKeyAndOctave: false, hasRepeatTop: false);
      expect([for (final s in fixed) s.target], [GuideTarget.trainerDirection]);
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
      expect(container.read(guideTourProvider)!.steps, hasLength(3));
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
