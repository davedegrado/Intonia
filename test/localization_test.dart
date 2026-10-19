import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/app_theme.dart';
import 'package:vocal_scale_trainer/app/l10n.dart';
import 'package:vocal_scale_trainer/app/vocal_scale_trainer_app.dart';
import 'package:vocal_scale_trainer/core/music/exercise.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_detection_result.dart';
import 'package:vocal_scale_trainer/core/session/range_record.dart';
import 'package:vocal_scale_trainer/core/session/session_record.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/features/library/application/exercise_providers.dart';
import 'package:vocal_scale_trainer/features/profile/application/history_providers.dart';
import 'package:vocal_scale_trainer/features/range/application/range_providers.dart';
import 'package:vocal_scale_trainer/features/settings/application/settings_providers.dart';
import 'package:vocal_scale_trainer/features/settings/presentation/settings_screen.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/controllers/trainer_controller.dart';
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

/// Preferenze in memoria che si comportano come una nuova installazione:
/// notazione C D E e nessuna lingua scelta, salvo diversa indicazione.
class _MemorySettings extends AppSettingsRepository {
  NoteNotation notation = NoteNotation.english;
  AppThemeSetting theme = AppThemeSetting.dark;
  String? language;
  @override
  Future<NoteNotation> loadNotation() async => notation;
  @override
  Future<void> saveNotation(NoteNotation value) async => notation = value;
  @override
  Future<AppThemeSetting> loadThemeSetting() async => theme;
  @override
  Future<void> saveThemeSetting(AppThemeSetting value) async => theme = value;
  @override
  Future<String?> loadLanguage() async => language;
  @override
  Future<void> saveLanguage(String? value) async => language = value;
  @override
  Future<double?> loadNoiseThreshold() async => null;
  @override
  Future<void> saveNoiseThreshold(double threshold) async {}
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
  _App(this.mic, this.settings);
  final FakeMicrophonePitchService mic;
  final _MemorySettings settings;
}

/// Avvia l'app completa (splash compreso) con archivi in memoria.
Future<_App> _launch(
  WidgetTester tester, {
  Locale device = const Locale('it'),
  _MemorySettings? settings,
  List<SessionRecord> sessions = const [],
  List<RangeRecord> ranges = const [],
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final app = _App(FakeMicrophonePitchService(), settings ?? _MemorySettings());
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

Finder _notationValue(String value) => find.descendant(
      of: find.byKey(const ValueKey('quick-notation')),
      matching: find.text(value),
    );

Finder _inSettings(String text) =>
    find.descendant(of: find.byType(SettingsScreen), matching: find.text(text));

/// Esce dal microfono: la chiusura dello stream avviene fuori dal tempo finto.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await _frames(tester, 3);
}

void main() {
  testWidgets('new user on an Italian device: Italian UI, C D E notation', (tester) async {
    final app = await _launch(tester);
    expect(find.text('Avvia ascolto'), findsOneWidget);
    expect(_tab('Esercizi'), findsOneWidget);
    expect(_notationValue('C D E'), findsOneWidget);
    expect(app.settings.language, isNull, reason: 'nessuna lingua salvata da sola');
  });

  testWidgets('new user on an English device: English UI, C D E notation', (tester) async {
    await _launch(tester, device: const Locale('en', 'US'));
    expect(find.text('Start listening'), findsOneWidget);
    expect(_tab('Exercises'), findsOneWidget);
    expect(find.text('Notation'), findsOneWidget);
    expect(_notationValue('C D E'), findsOneWidget);
  });

  testWidgets('unsupported device language falls back to English', (tester) async {
    await _launch(tester, device: const Locale('de'));
    expect(find.text('Start listening'), findsOneWidget);
    expect(_tab('Profile'), findsOneWidget);
  });

  testWidgets('choosing English in Settings switches live, persists and survives a relaunch',
      (tester) async {
    final app = await _launch(tester);
    await tester.tap(find.byKey(const ValueKey('quick-settings')));
    await _frames(tester, 5);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(_inSettings('Impostazioni'), findsOneWidget);
    expect(find.textContaining('La localizzazione inglese arriverà'), findsNothing);

    await tester.tap(find.text('English'));
    await _frames(tester, 5);
    expect(_inSettings('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Note names'), findsOneWidget);
    expect(app.settings.language, 'en');

    await tester.tap(find.byType(BackButton));
    await _frames(tester, 10);
    expect(find.text('Start listening'), findsOneWidget);
    expect(_tab('Range'), findsOneWidget);

    // Nuovo avvio con la scelta salvata, su un dispositivo italiano.
    await tester.pumpWidget(const SizedBox());
    final saved = _MemorySettings()..language = 'en';
    await _launch(tester, settings: saved);
    expect(find.text('Start listening'), findsOneWidget);

    // E ritorno all'italiano.
    await tester.tap(find.byKey(const ValueKey('quick-settings')));
    await _frames(tester, 5);
    await tester.tap(find.text('Italiano'));
    await _frames(tester, 5);
    expect(_inSettings('Impostazioni'), findsOneWidget);
    expect(saved.language, 'it');
  });

  testWidgets('notation is independent of the language', (tester) async {
    final app = await _launch(tester, device: const Locale('en'));
    await tester.tap(find.byKey(const ValueKey('quick-notation')));
    await _frames(tester, 2);
    expect(find.text('Start listening'), findsOneWidget);
    expect(_notationValue('DO RE MI'), findsOneWidget);
    expect(app.settings.notation, NoteNotation.italian);
    expect(app.settings.language, isNull);

    await tester.pumpWidget(const SizedBox());
    await _launch(tester);
    expect(find.text('Avvia ascolto'), findsOneWidget);
    expect(_notationValue('C D E'), findsOneWidget);
  });

  testWidgets('an existing user who chose DO RE MI keeps it', (tester) async {
    await _launch(tester, settings: _MemorySettings()..notation = NoteNotation.italian);
    expect(_notationValue('DO RE MI'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _launch(
      tester,
      device: const Locale('en'),
      settings: _MemorySettings()..notation = NoteNotation.italian,
    );
    expect(find.text('Start listening'), findsOneWidget);
    expect(_notationValue('DO RE MI'), findsOneWidget);
  });

  group('AppSettingsRepository on disk', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('intonia_settings'));
    tearDown(() => dir.deleteSync(recursive: true));

    AppSettingsRepository repository() => AppSettingsRepository(directoryProvider: () async => dir);

    test('no file: C D E and no language', () async {
      expect(await repository().loadNotation(), NoteNotation.english);
      expect(await repository().loadLanguage(), isNull);
    });

    test('a saved Italian notation is respected', () async {
      await repository().saveNotation(NoteNotation.italian);
      expect(await repository().loadNotation(), NoteNotation.italian);
      await repository().saveNotation(NoteNotation.english);
      expect(await repository().loadNotation(), NoteNotation.english);
    });

    test('the language round-trips without touching the notation', () async {
      await repository().saveNotation(NoteNotation.italian);
      await repository().saveLanguage('en');
      expect(await repository().loadLanguage(), 'en');
      expect(await repository().loadNotation(), NoteNotation.italian);
      await repository().saveLanguage('it');
      expect(await repository().loadLanguage(), 'it');
    });
  });

  group('home speech bubble', () {
    Rect bubble(WidgetTester tester) => tester.getRect(find.byKey(const ValueKey('home-bubble')));
    Rect mascot(WidgetTester tester) => tester.getRect(find.byKey(const ValueKey('home-mascot')));

    void expectShown(WidgetTester tester, String state) {
      final paragraphs = find.descendant(
        of: find.byKey(const ValueKey('home-bubble')),
        matching: find.byType(RichText),
      );
      expect(paragraphs, findsOneWidget, reason: state);
      final paragraph = tester.renderObject<RenderParagraph>(paragraphs);
      expect(paragraph.maxLines, 2, reason: state);
    }

    // Il font dei test ha glifi larghi quanto un quadrato: la misura reale delle
    // righe non si può verificare qui, quindi i messaggi restano brevi (circa
    // 30 caratteri per riga a 16 px su un telefono da 320 punti).
    test('every message is short enough for two lines', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        for (final message in [
          l10n.homeBubbleIdle,
          l10n.homeBubbleListening,
          l10n.homeBubbleInTune,
          l10n.homeBubbleAlmost,
          l10n.homeBubblePermissionDenied,
        ]) {
          expect(message.length, lessThanOrEqualTo(56), reason: message);
          expect(message, isNot(contains('\n')), reason: message);
        }
      }
    });

    for (final size in [const Size(390, 844), const Size(320, 568)]) {
      testWidgets('keeps the same size and the mascot never moves ($size)', (tester) async {
        Rect? bubbleRef;
        Rect? mascotRef;
        Future<void> check(String state) async {
          // Lascia finire la dissolvenza tra un messaggio e l'altro.
          await _frames(tester, 3);
          expectShown(tester, state);
          bubbleRef ??= bubble(tester);
          mascotRef ??= mascot(tester);
          expect(bubble(tester), bubbleRef, reason: state);
          expect(mascot(tester), mascotRef, reason: state);
        }

        for (final device in [const Locale('it'), const Locale('en')]) {
          final app = await _launch(tester, device: device, size: size);
          await check('$device idle');

          await tester.tap(find.byKey(const ValueKey('home-mic')));
          await _frames(tester, 3);
          expect(app.mic.isRecording, isTrue);
          await check('$device listening');

          final note = MusicalNote.fromMidi(57);
          for (final cents in [2.0, 30.0]) {
            for (var i = 0; i < 12; i++) {
              app.mic.emit(PitchDetectionResult(
                frequency: note.frequency,
                note: note,
                cents: cents,
                confidence: 1,
                isStable: true,
              ));
              await tester.pump(const Duration(milliseconds: 25));
            }
            await _frames(tester, 3);
            await check('$device cents $cents');
          }

          await tester.tap(find.byKey(const ValueKey('home-mic')));
          await _settle(tester);
          app.mic.permissionGranted = false;
          await tester.tap(find.byKey(const ValueKey('home-mic')));
          await _settle(tester);
          final denied =
              device.languageCode == 'it' ? 'Permesso microfono negato' : 'Microphone access';
          expect(find.textContaining(denied), findsOneWidget);
          await check('$device permission denied');

          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  });

  for (final size in [const Size(320, 568), const Size(360, 640)]) {
    testWidgets('English: no overflow on small screens ($size, text x1.3)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final now = DateTime.now();
      await _launch(
        tester,
        device: const Locale('en'),
        size: size,
        sessions: [_session(now, 'Three-part harmony in major', 7, 3)],
        ranges: [RangeRecord(timestamp: now, minMidi: 33, maxMidi: 83)],
      );
      for (final label in ['Exercises', 'Range', 'Profile', 'Home']) {
        await _openTab(tester, label);
        expect(tester.takeException(), isNull, reason: label);
      }
      expect(find.text('Start listening'), findsOneWidget);

      final settings = find.byKey(const ValueKey('quick-settings'));
      await tester.ensureVisible(settings);
      await _frames(tester, 2);
      await tester.tap(settings);
      await _frames(tester, 5);
      expect(_inSettings('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Settings');
    });
  }
}
