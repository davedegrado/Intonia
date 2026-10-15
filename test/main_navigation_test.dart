import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/app_theme.dart';
import 'package:vocal_scale_trainer/app/vocal_scale_trainer_app.dart';
import 'package:vocal_scale_trainer/core/music/exercise.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_detection_result.dart';
import 'package:vocal_scale_trainer/core/session/range_record.dart';
import 'package:vocal_scale_trainer/core/session/session_record.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/features/library/application/exercise_providers.dart';
import 'package:vocal_scale_trainer/features/library/presentation/exercises_screen.dart';
import 'package:vocal_scale_trainer/features/library/presentation/home_screen.dart';
import 'package:vocal_scale_trainer/features/profile/application/history_providers.dart';
import 'package:vocal_scale_trainer/features/range/application/range_providers.dart';
import 'package:vocal_scale_trainer/features/range/presentation/range_test_screen.dart';
import 'package:vocal_scale_trainer/features/settings/application/settings_providers.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/controllers/trainer_controller.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/screens/trainer_screen.dart';
import 'package:vocal_scale_trainer/features/tuner/application/tuner_controller.dart';
import 'package:vocal_scale_trainer/services/audio/piano_audio_service.dart';
import 'package:vocal_scale_trainer/services/storage/app_settings_repository.dart';
import 'package:vocal_scale_trainer/services/storage/custom_exercise_repository.dart';
import 'package:vocal_scale_trainer/services/storage/range_history_repository.dart';
import 'package:vocal_scale_trainer/services/storage/session_history_repository.dart';

import 'support/access_fakes.dart';
import 'support/audio_fakes.dart';

class _MemorySessions extends SessionHistoryRepository {
  _MemorySessions(this.items);
  List<SessionRecord> items;
  @override
  Future<List<SessionRecord>> load() async => items;
  @override
  Future<void> save(List<SessionRecord> records) async => items = records;
}

class _MemoryRanges extends RangeHistoryRepository {
  _MemoryRanges(this.items);
  List<RangeRecord> items;
  @override
  Future<List<RangeRecord>> load() async => items;
  @override
  Future<void> save(List<RangeRecord> records) async => items = records;
}

class _MemoryCustom extends CustomExerciseRepository {
  @override
  Future<List<ExerciseDefinition>> load() async => const [];
  @override
  Future<void> save(List<ExerciseDefinition> exercises) async {}
}

class _MemorySettings extends AppSettingsRepository {
  NoteNotation notation = NoteNotation.italian;
  AppThemeSetting theme = AppThemeSetting.dark;
  @override
  Future<NoteNotation> loadNotation() async => notation;
  @override
  Future<void> saveNotation(NoteNotation value) async => notation = value;
  @override
  Future<AppThemeSetting> loadThemeSetting() async => theme;
  @override
  Future<void> saveThemeSetting(AppThemeSetting value) async => theme = value;
  String? language = 'it';
  @override
  Future<String?> loadLanguage() async => language;
  @override
  Future<void> saveLanguage(String? value) async => language = value;
  @override
  Future<double?> loadNoiseThreshold() async => null;
  @override
  Future<void> saveNoiseThreshold(double threshold) async {}
  // La guida del primo avvio è già stata vista, salvo nei test dedicati.
  bool guideSeen = true;
  @override
  Future<bool?> loadGuideSeen() async => guideSeen;
  @override
  Future<void> saveGuideSeen() async => guideSeen = true;
}

SessionRecord _session(DateTime when, String name, int correct, int errors) => SessionRecord(
      timestamp: when,
      exerciseId: name,
      exerciseName: name,
      correct: correct,
      errors: errors,
      durationSeconds: 120,
      perNote: {
        60: [correct, errors],
      },
      minCorrectMidi: 55,
      maxCorrectMidi: 72,
    );

class _App {
  _App(this.mic);
  final FakeMicrophonePitchService mic;
  final settings = _MemorySettings();
}

/// Avvia l'app completa (splash compreso) con archivi in memoria.
Future<_App> _launch(
  WidgetTester tester, {
  List<SessionRecord> sessions = const [],
  List<RangeRecord> ranges = const [],
  Size size = const Size(390, 844),
  AppThemeSetting theme = AppThemeSetting.dark,
  Locale device = const Locale('it'),
  bool guideSeen = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final app = _App(FakeMicrophonePitchService());
  app.settings.theme = theme;
  app.settings.guideSeen = guideSeen;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      microphonePitchServiceProvider.overrideWithValue(app.mic),
      pianoAudioServiceProvider.overrideWithValue(PianoAudioService(midiPro: FakeMidiPro())),
      chargesRepositoryProvider.overrideWithValue(InMemoryChargesRepository()),
      sessionHistoryRepositoryProvider.overrideWithValue(_MemorySessions([...sessions])),
      rangeHistoryRepositoryProvider.overrideWithValue(_MemoryRanges([...ranges])),
      customExerciseRepositoryProvider.overrideWithValue(_MemoryCustom()),
      appSettingsRepositoryProvider.overrideWithValue(app.settings),
      deviceLocaleProvider.overrideWithValue(device),
    ],
    child: const VocalScaleTrainerApp(),
  ));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await _frames(tester);
  return app;
}

/// La mascotte è sempre animata: niente pumpAndSettle.
Future<void> _frames(WidgetTester tester, [int count = 10]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(_tab(label));
  await _frames(tester, 5);
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(NavigationBar)));

void main() {
  testWidgets('bottom bar: four sections, each keeps its state', (tester) async {
    await _launch(tester);

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    for (final label in ['Home', 'Esercizi', 'Estensione', 'Profilo']) {
      expect(_tab(label), findsOneWidget);
    }
    expect(find.text('Avvia ascolto'), findsOneWidget);

    await _openTab(tester, 'Esercizi');
    expect(find.text('Crea la tua sequenza'), findsOneWidget);
    await tester.tap(find.text('Triadi'));
    await _frames(tester, 5);
    expect(find.text('Triade maggiore'), findsOneWidget);

    await _openTab(tester, 'Estensione');
    expect(find.text('Scopri la tua estensione vocale'), findsOneWidget);

    await _openTab(tester, 'Profilo');
    expect(find.text('Nessuna sessione ancora'), findsOneWidget);

    // Tornando agli esercizi la categoria aperta è ancora aperta.
    await _openTab(tester, 'Esercizi');
    expect(find.text('Triade maggiore'), findsOneWidget);

    await _openTab(tester, 'Home');
    expect(find.text('Avvia ascolto'), findsOneWidget);
  });

  testWidgets('home microphone starts the existing recognition; leaving the tab stops it',
      (tester) async {
    final app = await _launch(tester);

    await tester.tap(find.byKey(const ValueKey('home-mic')));
    await _frames(tester, 2);
    expect(app.mic.isRecording, isTrue);
    expect(_container(tester).read(tunerControllerProvider).active, isTrue);
    expect(find.text('Ferma ascolto'), findsOneWidget);

    final note = MusicalNote.fromMidi(57);
    for (var i = 0; i < 12; i++) {
      app.mic.emit(PitchDetectionResult(
        frequency: note.frequency,
        note: note,
        cents: 3,
        confidence: 1,
        isStable: true,
      ));
      await tester.pump(const Duration(milliseconds: 25));
    }
    await _frames(tester, 2);
    expect(find.text('Nota rilevata'), findsOneWidget);
    expect(find.textContaining(' cent'), findsOneWidget);

    await _openTab(tester, 'Esercizi');
    // La chiusura dello stream del microfono si completa fuori dal tempo finto.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await _frames(tester, 2);
    expect(app.mic.isRecording, isFalse);
    expect(_container(tester).read(tunerControllerProvider).active, isFalse);

    // Tornando alla Home resta l'ultima nota riconosciuta.
    await _openTab(tester, 'Home');
    expect(find.text('Ultima nota'), findsOneWidget);
    expect(find.text('Avvia ascolto'), findsOneWidget);
  });

  testWidgets('every category opens the right exercise, without the bottom bar', (tester) async {
    await _launch(tester, size: const Size(390, 1400));
    await _openTab(tester, 'Esercizi');
    final library = _container(tester).read(exerciseLibraryProvider);
    final list =
        find.descendant(of: find.byType(ExercisesScreen), matching: find.byType(Scrollable)).first;

    for (final category in ExerciseCategory.values) {
      final exercises = library.builtIn.where((e) => e.category == category).toList();
      if (exercises.isEmpty) {
        continue;
      }
      final header = find.text(category.label);
      await tester.scrollUntilVisible(header, 150, scrollable: list);
      await tester.tap(header);
      await _frames(tester, 4);

      final exercise = exercises.last;
      final tile = find.widgetWithText(ListTile, exercise.name);
      await tester.scrollUntilVisible(tile, 150, scrollable: list);
      await tester.tap(tile);
      await _frames(tester, 5);

      expect(find.byType(TrainerScreen), findsOneWidget);
      expect(find.byType(NavigationBar).hitTestable(), findsNothing,
          reason: 'barra nascosta in allenamento');
      final trainer = tester.widget<TrainerScreen>(find.byType(TrainerScreen));
      expect(trainer.exercise.id, exercise.id, reason: category.label);
      expect(find.text(exercise.name), findsWidgets);

      await tester.tap(find.byType(BackButton));
      await _frames(tester, 10);
      expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);

      // Richiude la categoria per la successiva.
      await tester.scrollUntilVisible(header, -150, scrollable: list);
      await tester.tap(header);
      await _frames(tester, 4);
    }
  });

  testWidgets('range section shows the saved results and opens the full-screen test',
      (tester) async {
    await _launch(tester, ranges: [
      RangeRecord(timestamp: DateTime(2026, 10, 1, 9), minMidi: 45, maxMidi: 69),
      RangeRecord(timestamp: DateTime(2026, 10, 14, 17, 23), minMidi: 33, maxMidi: 83),
    ]);
    await _openTab(tester, 'Estensione');

    expect(find.byKey(const ValueKey('range-latest')), findsOneWidget);
    expect(find.text('4 ottave + 2 semitoni (50 semitoni)'), findsOneWidget);
    expect(find.text('14/10 17:23'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('01/10 09:00'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Test precedenti'), findsOneWidget);
    expect(find.text('01/10 09:00'), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const ValueKey('range-start')), -150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('range-start')));
    await _frames(tester, 5);
    expect(find.byType(RangeTestScreen), findsOneWidget);
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);
    expect(find.text('Inizia il test'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await _frames(tester, 10);
    expect(find.byKey(const ValueKey('range-start')), findsOneWidget);
    expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
  });

  testWidgets('range section without tests invents no result', (tester) async {
    await _launch(tester);
    await _openTab(tester, 'Estensione');
    expect(find.byKey(const ValueKey('range-latest')), findsNothing);
    expect(find.text('Nessun test ancora: il tuo risultato comparirà qui.'), findsOneWidget);
    expect(find.text('Avvia test'), findsOneWidget);
  });

  testWidgets('profile shows the real stored data and opens the settings', (tester) async {
    final now = DateTime.now();
    await _launch(tester, sessions: [
      _session(now.subtract(const Duration(days: 1)), 'Scala maggiore', 9, 1),
      _session(now, 'Triade maggiore', 7, 3),
    ]);
    await _openTab(tester, 'Profilo');

    expect(find.text('2 giorni di fila'), findsOneWidget);
    expect(find.text('Sessioni'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('80%'), findsWidgets, reason: '16 corrette su 20');
    expect(find.text('Triade maggiore'), findsOneWidget);
    expect(find.text('Scala maggiore'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-settings')));
    await _frames(tester, 5);
    expect(find.text('Impostazioni'), findsOneWidget);
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);
  });

  testWidgets('quick actions change theme and notation through the existing settings',
      (tester) async {
    final app = await _launch(tester);
    final home = find.byType(HomeScreen);
    expect(Theme.of(tester.element(home)).brightness, Brightness.dark);

    await tester.tap(find.byKey(const ValueKey('quick-theme')));
    await _frames(tester, 5);
    await tester.tap(find.widgetWithText(ListTile, 'Chiaro'));
    await _frames(tester, 5);
    expect(app.settings.theme, AppThemeSetting.light);
    expect(Theme.of(tester.element(home)).brightness, Brightness.light);

    await tester.tap(find.byKey(const ValueKey('quick-theme')));
    await _frames(tester, 5);
    await tester.tap(find.widgetWithText(ListTile, 'Neon'));
    await _frames(tester, 5);
    expect(Theme.of(tester.element(home)).scaffoldBackgroundColor, const Color(0xFF0B0B1C));

    await tester.tap(find.byKey(const ValueKey('quick-notation')));
    await _frames(tester, 2);
    expect(app.settings.notation, NoteNotation.english);
    expect(find.text('C D E'), findsOneWidget);
  });

  testWidgets('ambient decorations exist only in the Neon theme', (tester) async {
    for (final theme in AppThemeSetting.values) {
      final now = DateTime.now();
      await _launch(tester,
          theme: theme, ranges: [RangeRecord(timestamp: now, minMidi: 40, maxMidi: 70)]);
      final neon = theme == AppThemeSetting.neon;
      for (final label in ['Home', 'Esercizi', 'Estensione', 'Profilo']) {
        await _openTab(tester, label);
        expect(find.byKey(const ValueKey('neon-scene')), neon ? findsOneWidget : findsNothing,
            reason: '$theme $label');
        if (label == 'Home' || label == 'Estensione') {
          expect(find.byKey(const ValueKey('mascot-halo')), neon ? findsOneWidget : findsNothing,
              reason: '$theme $label');
        }
      }
      // Nuova app per il tema successivo.
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('the layout is identical in every theme', (tester) async {
    const keys = {
      'Home': ['home-bubble', 'home-mascot', 'home-mic', 'home-note-card', 'quick-theme'],
      'Esercizi': ['create-sequence'],
      'Estensione': ['range-start', 'range-latest'],
      'Profilo': ['streak-card'],
    };
    Map<String, Rect>? reference;
    for (final theme in AppThemeSetting.values) {
      final now = DateTime.now();
      await _launch(
        tester,
        theme: theme,
        sessions: [_session(now, 'Triade maggiore', 8, 2)],
        ranges: [RangeRecord(timestamp: now, minMidi: 40, maxMidi: 70)],
      );
      final rects = <String, Rect>{};
      for (final entry in keys.entries) {
        await _openTab(tester, entry.key);
        for (final key in entry.value) {
          rects[key] = tester.getRect(find.byKey(ValueKey(key)));
        }
      }
      if (reference == null) {
        reference = rects;
      } else {
        expect(rects, reference, reason: '$theme');
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('history shows the saved key, octave and mode, and nothing invented for old sessions',
      (tester) async {
    final now = DateTime.now();
    await _launch(tester, sessions: [
      _session(now.subtract(const Duration(days: 1)), 'Vecchia sessione', 5, 5),
      SessionRecord(
        timestamp: now,
        exerciseId: 'major',
        exerciseName: 'Scala maggiore',
        correct: 9,
        errors: 1,
        durationSeconds: 60,
        perNote: const {},
        keySemitone: 2,
        octave: 3,
        direction: 'complete',
      ),
    ]);
    await _openTab(tester, 'Profilo');
    await tester.scrollUntilVisible(find.text('Vecchia sessione'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('RE · Ottava 3 · Completo'), findsOneWidget);
    expect(find.textContaining('Ottava'), findsOneWidget, reason: 'la sessione vecchia non ne ha');
  });

  testWidgets('first launch: the mascot guide shows once, can be navigated and skipped',
      (tester) async {
    final app = await _launch(tester, guideSeen: false);
    expect(find.byKey(const ValueKey('guide-sheet')), findsOneWidget);
    expect(find.text('1 di 6'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guide-next')));
    await _frames(tester, 3);
    expect(find.text('2 di 6'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guide-back')));
    await _frames(tester, 3);
    expect(find.text('1 di 6'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guide-skip')));
    await _frames(tester, 5);
    expect(find.byKey(const ValueKey('guide-sheet')), findsNothing);
    expect(app.settings.guideSeen, isTrue);
    expect(app.settings.theme, AppThemeSetting.dark, reason: 'altre preferenze intatte');
  });

  testWidgets('the guide does not come back once seen and reopens from Settings', (tester) async {
    await _launch(tester);
    expect(find.byKey(const ValueKey('guide-sheet')), findsNothing);
    await _openTab(tester, 'Profilo');
    await tester.tap(find.byKey(const ValueKey('profile-settings')));
    await _frames(tester, 5);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('settings-guide')), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('settings-guide')));
    await _frames(tester, 5);
    expect(find.byKey(const ValueKey('guide-sheet')), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('guide-next')));
      await _frames(tester, 2);
    }
    expect(find.text('6 di 6'), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-skip')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('guide-next')));
    await _frames(tester, 5);
    expect(find.byKey(const ValueKey('guide-sheet')), findsNothing);
  });

  testWidgets('the exercise guide explains only the controls on screen', (tester) async {
    await _launch(tester);
    await _openTab(tester, 'Esercizi');
    await tester.tap(find.text('Triadi'));
    await _frames(tester, 5);
    await tester.tap(find.widgetWithText(ListTile, 'Triade maggiore'));
    await _frames(tester, 5);
    expect(find.byKey(const ValueKey('trainer-direction')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('trainer-guide')));
    await _frames(tester, 5);
    // Tonalità, ottava, modalità e vertice (la triade in Completo ha un vertice).
    expect(find.text('1 di 4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guide-close')));
    await _frames(tester, 5);

    // In modalità Dritto il vertice non si ripete: niente spiegazione.
    await tester.tap(find.text('Dritto'));
    await _frames(tester, 2);
    expect(find.byKey(const ValueKey('trainer-repeat-top')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('trainer-guide')));
    await _frames(tester, 5);
    expect(find.text('1 di 3'), findsOneWidget);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(360, 640), 1.3),
  ]) {
    testWidgets('no overflow on small screens ($size, text x$scale)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final now = DateTime.now();
      await _launch(
        tester,
        size: size,
        sessions: [_session(now, 'Armonizzazione a tre voci in maggiore', 7, 3)],
        ranges: [RangeRecord(timestamp: now, minMidi: 33, maxMidi: 83)],
      );
      for (final label in ['Esercizi', 'Estensione', 'Profilo', 'Home']) {
        await _openTab(tester, label);
        expect(tester.takeException(), isNull, reason: label);
      }
    });
  }
}
