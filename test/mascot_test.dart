import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/features/mascot/domain/mascot_mood.dart';
import 'package:vocal_scale_trainer/features/mascot/presentation/intonia_mascot.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/note_progress.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/trainer_mascot_mood.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/trainer_state.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/training_settings.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.dark, bool reduceMotion = false}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

MascotPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(IntoniaMascot), matching: find.byType(CustomPaint)),
  );
  return paint.painter! as MascotPainter;
}

TrainerState _trainer({
  bool isPlaying = false,
  bool isListening = false,
  List<NoteProgressStatus>? progress,
  int currentIndex = 0,
}) {
  const notes = [
    MusicalNote(pitchClass: PitchClass.c, octave: 4),
    MusicalNote(pitchClass: PitchClass.e, octave: 4),
  ];
  final initial = TrainerState.initial(settings: TrainingSettings.defaults(), sequence: notes);
  return initial.copyWith(
    isPlaying: isPlaying,
    isListening: isListening,
    progress: progress,
    currentIndex: currentIndex,
  );
}

void main() {
  group('MascotPose', () {
    test('each mood has its distinctive traits', () {
      final idle = MascotPose.of(MascotMood.idle, 0.25);
      final listening = MascotPose.of(MascotMood.listening, 0.25);
      final success = MascotPose.of(MascotMood.success, 0.25);
      final retry = MascotPose.of(MascotMood.retry, 0.25);

      expect(idle.waves, 0);
      expect(idle.sparkles, 0);
      expect(listening.waves, 1);
      expect(listening.glow, greaterThan(idle.glow));
      expect(success.happyEyes, 1);
      expect(success.sparkles, 1);
      expect(success.glow, 1);
      expect(success.smile, greaterThan(idle.smile));
      expect(success.leftArm, greaterThan(1), reason: 'braccia alzate');
      expect(retry.tilt, lessThan(-0.1), reason: 'inclinazione');
      expect(retry.rightArm, greaterThan(retry.leftArm), reason: 'gesto incoraggiante');
    });

    test('listening makes the tines vibrate over the loop', () {
      final samples = [
        for (var i = 0; i < 40; i++) MascotPose.of(MascotMood.listening, i / 40).jitter
      ];
      expect(samples.any((j) => j > 0.5), isTrue);
      expect(samples.any((j) => j < -0.5), isTrue);
    });

    test('lerp interpolates between poses', () {
      final a = MascotPose.of(MascotMood.idle, 0);
      final b = MascotPose.of(MascotMood.success, 0);
      final mid = MascotPose.lerp(a, b, 0.5);

      expect(mid.smile, closeTo((a.smile + b.smile) / 2, 1e-9));
      expect(MascotPose.lerp(a, b, 1).sparkles, b.sparkles);
    });
  });

  group('IntoniaMascot widget', () {
    testWidgets('paints every mood on dark and light themes', (tester) async {
      for (final brightness in Brightness.values) {
        for (final mood in MascotMood.values) {
          await tester.pumpWidget(_host(IntoniaMascot(mood: mood), brightness: brightness));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(_painter(tester).mood, mood);
          expect(_painter(tester).onDark, brightness == Brightness.dark);
        }
      }
    });

    testWidgets('mood changes are interpolated from the previous pose', (tester) async {
      await tester.pumpWidget(_host(const IntoniaMascot(mood: MascotMood.idle)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_host(const IntoniaMascot(mood: MascotMood.success)));
      await tester.pump(const Duration(milliseconds: 100));

      final during = _painter(tester).pose;
      expect(_painter(tester).previousMood, MascotMood.idle);
      expect(during.sparkles, inExclusiveRange(0, 1), reason: 'transizione in corso');

      await tester.pump(const Duration(milliseconds: 700));
      expect(_painter(tester).pose.sparkles, 1);
    });

    testWidgets('controllers are disposed with the widget', (tester) async {
      await tester.pumpWidget(_host(const IntoniaMascot(mood: MascotMood.listening)));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(_host(const SizedBox()));
      // Un AnimationController non rilasciato farebbe fallire il test
      // ("A Ticker was active when the widget was disposed").
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nessun ticker ancora attivo');
    });

    testWidgets('stays still when the system disables animations', (tester) async {
      await tester.pumpWidget(
        _host(const IntoniaMascot(mood: MascotMood.listening), reduceMotion: true),
      );
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(_painter(tester).pose.waves, 1, reason: 'posa dello stato, senza movimento');
    });

    testWidgets('is decorative unless a semantic label is given', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const IntoniaMascot(semanticLabel: 'Mascotte di Intonia')));
      expect(find.bySemanticsLabel('Mascotte di Intonia'), findsOneWidget);
      handle.dispose();
    });
  });

  group('mascotMoodForTrainer', () {
    test('idle when nothing is running', () {
      expect(mascotMoodForTrainer(_trainer()), MascotMood.idle);
    });

    test('listening while the microphone listens or the guide plays', () {
      expect(
          mascotMoodForTrainer(_trainer(isPlaying: true, isListening: true)), MascotMood.listening);
      expect(mascotMoodForTrainer(_trainer(isPlaying: true)), MascotMood.listening);
    });

    test('success when the current note was validated', () {
      final state = _trainer(
        isPlaying: true,
        isListening: true,
        progress: const [NoteProgressStatus.correct, NoteProgressStatus.pending],
      );
      expect(mascotMoodForTrainer(state), MascotMood.success);
    });

    test('retry when the current note was marked wrong', () {
      final state = _trainer(
        isPlaying: true,
        isListening: true,
        progress: const [NoteProgressStatus.error, NoteProgressStatus.pending],
      );
      expect(mascotMoodForTrainer(state), MascotMood.retry);
    });

    test('success when the exercise is completed, even after stopping', () {
      final state = _trainer(
        progress: const [NoteProgressStatus.correct, NoteProgressStatus.correct],
        currentIndex: 1,
      );
      expect(mascotMoodForTrainer(state), MascotMood.success);
    });
  });
}
