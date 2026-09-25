import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/music/exercise.dart';
import '../../../../core/music/note.dart';
import '../../../../core/pitch/pitch_detection_result.dart';
import '../../../../core/session/session_record.dart';
import '../../../../core/session/session_stats.dart';
import '../../../../services/audio/piano_audio_service.dart';
import '../../../../services/pitch/microphone_pitch_service.dart';
import '../../../profile/application/history_providers.dart';
import '../../../settings/application/settings_providers.dart';
import '../../domain/note_progress.dart';
import '../../domain/trainer_state.dart';
import '../../domain/training_settings.dart';
import '../../domain/training_state_machine.dart';

final pianoAudioServiceProvider = Provider<PianoAudioService>((ref) => PianoAudioService());
final microphonePitchServiceProvider = Provider<MicrophonePitchService>((ref) {
  final service = MicrophonePitchService();
  // Applica la soglia di rumore calibrata in precedenza, se presente.
  unawaited(ref.read(appSettingsRepositoryProvider).loadNoiseThreshold().then((threshold) {
    if (threshold != null) {
      service.setSilenceThreshold(threshold);
    }
  }));
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final trainerControllerProvider = NotifierProvider<TrainerController, TrainerState>(
  TrainerController.new,
);

class TrainerController extends Notifier<TrainerState> {
  StreamSubscription<PitchDetectionResult>? _pitchSubscription;
  late TrainingStateMachine _stateMachine;
  late final PianoAudioService _audio;
  late final MicrophonePitchService _microphone;
  ExerciseDefinition _exercise = const ExerciseLibrary().builtIn.first;

  /// Fino a questo istante le rilevazioni del mic vengono ignorate:
  /// evita che il piano della guida venga scambiato per la voce.
  DateTime _ignoreDetectionUntil = DateTime.fromMillisecondsSinceEpoch(0);

  static const _guideNoteDuration = Duration(milliseconds: 650);

  /// Coda di mute dopo la nota guida: copre la finestra di analisi lunga
  /// (~93 ms), il buffering del microfono su Android e la coda di rilascio
  /// del piano, per non convalidare il suono dell'app come voce.
  static const _detectionMuteTail = Duration(milliseconds: 450);

  ExerciseDefinition get exercise => _exercise;

  @override
  TrainerState build() {
    _audio = ref.read(pianoAudioServiceProvider);
    _microphone = ref.read(microphonePitchServiceProvider);

    final settings = TrainingSettings.defaults();
    final sequence = _buildSequence(settings);
    _stateMachine = TrainingStateMachine(
      toleranceCents: settings.toleranceCents,
      stabilityMs: settings.stabilityMs,
    );
    ref.onDispose(() {
      unawaited(_pitchSubscription?.cancel());
      unawaited(_audio.stopAll());
    });
    return TrainerState.initial(settings: settings, sequence: sequence);
  }

  /// Imposta l'esercizio corrente (chiamato aprendo il Trainer dalla Home).
  /// Per le sequenze custom con nota di partenza salvata, tonalità e ottava
  /// vengono inizializzate su quella nota.
  Future<void> selectExercise(ExerciseDefinition exercise) async {
    await stop();
    _exercise = exercise;
    var settings = state.settings;
    final rootMidi = exercise.rootMidi;
    if (rootMidi != null) {
      // Le custom partono ESATTAMENTE dalla nota con cui sono state create.
      final root = MusicalNote.fromMidi(rootMidi);
      settings = settings.copyWith(key: root.pitchClass, octave: root.octave);
    }
    _updateSettings(settings);
  }

  void updateKey(PitchClass key) => _updateSettings(state.settings.copyWith(key: key));

  void updateOctave(int octave) => _updateSettings(state.settings.copyWith(octave: octave));

  void updateBpm(int bpm) => _updateSettings(state.settings.copyWith(bpm: bpm));

  void updateTolerance(int cents) => _updateSettings(state.settings.copyWith(toleranceCents: cents));

  void updateStability(int milliseconds) => _updateSettings(state.settings.copyWith(stabilityMs: milliseconds));

  void updateMode(TrainerMode mode) => _updateSettings(state.settings.copyWith(mode: mode));

  void updateLoop(bool loop) => _updateSettings(state.settings.copyWith(loop: loop));

  void updateGuideEveryNote(bool value) =>
      _updateSettings(state.settings.copyWith(guideEveryNote: value));

  Future<void> play() async {
    await stop();
    state = _resetRunState(isPlaying: true, isListening: state.settings.mode == TrainerMode.train);

    if (state.settings.mode == TrainerMode.listen) {
      await _playListeningMode();
    } else {
      await _startTrainingMode();
    }
  }

  Future<void> replay() async {
    await play();
  }

  Future<void> stop() async {
    await _pitchSubscription?.cancel();
    _pitchSubscription = null;
    await _microphone.stop();
    await _audio.stopAll();
    if (state.isPlaying || state.isListening) {
      final finished = state.sessionStats.finish();
      _recordSession(finished);
      state = state.copyWith(
        isPlaying: false,
        isListening: false,
        sessionStats: finished,
      );
    }
  }

  /// Salva nello storico le sessioni di allenamento con almeno un tentativo.
  void _recordSession(SessionStats stats) {
    if (state.settings.mode != TrainerMode.train || stats.attempts.isEmpty) {
      return;
    }
    unawaited(ref.read(sessionHistoryProvider.notifier).add(
          SessionRecord.fromStats(
            stats: stats,
            exerciseId: _exercise.id,
            exerciseName: _exercise.name,
          ),
        ));
  }

  Future<void> listenCurrentNote() async {
    await _playGuideNote(state.currentNote);
  }

  /// Suona una nota guida ignorando il microfono per la sua durata,
  /// così il suono dell'app non viene convalidato come voce dell'utente.
  Future<void> _playGuideNote(MusicalNote note) async {
    _ignoreDetectionUntil = DateTime.now().add(_guideNoteDuration + _detectionMuteTail);
    await _audio.playNote(note, duration: _guideNoteDuration);
  }

  /// Calibrazione del rumore di fondo: misura l'ambiente per [duration]
  /// (in silenzio!) e imposta la soglia sotto cui il segnale è "silenzio".
  /// Ritorna la nuova soglia, o null se la misura non è riuscita.
  Future<double?> calibrateNoise({Duration duration = const Duration(seconds: 3)}) async {
    if (state.isPlaying || state.isListening) {
      return null;
    }
    try {
      final ambient = await _microphone.measureAmbientRms(duration: duration);
      final threshold = (ambient * 2.5).clamp(0.008, 0.12).toDouble();
      _microphone.setSilenceThreshold(threshold);
      unawaited(ref.read(appSettingsRepositoryProvider).saveNoiseThreshold(threshold));
      return threshold;
    } catch (_) {
      return null;
    }
  }

  List<MusicalNote> _buildSequence(TrainingSettings settings) {
    return _exercise.buildSequence(key: settings.key, octave: settings.octave);
  }

  void _updateSettings(TrainingSettings settings) {
    final sequence = _buildSequence(settings);
    _stateMachine = TrainingStateMachine(
      toleranceCents: settings.toleranceCents,
      stabilityMs: settings.stabilityMs,
    );
    state = TrainerState.initial(settings: settings, sequence: sequence);
  }

  TrainerState _resetRunState({required bool isPlaying, required bool isListening}) {
    final progress = [
      for (var i = 0; i < state.sequence.length; i++)
        i == 0 ? NoteProgressStatus.current : NoteProgressStatus.pending,
    ];
    _stateMachine.reset();
    return state.copyWith(
      progress: progress,
      currentIndex: 0,
      isPlaying: isPlaying,
      isListening: isListening,
      validationState: TrainingValidationState.waitNote,
      sessionStats: SessionStats.started(),
      clearMessage: true,
    );
  }

  Future<void> _playListeningMode() async {
    try {
      await _audio.playSequence(
        notes: state.sequence,
        bpm: state.settings.bpm,
        loop: state.settings.loop,
        onNote: _markCurrentIndex,
      );
      state = state.copyWith(isPlaying: false, sessionStats: state.sessionStats.finish());
    } catch (error) {
      state = state.copyWith(isPlaying: false, message: _friendlyAudioError(error));
    }
  }

  Future<void> _startTrainingMode() async {
    try {
      await _playGuideNote(state.currentNote);
      await _microphone.start();
      _pitchSubscription = _microphone.pitchStream.listen(_handlePitch);
    } catch (error) {
      state = state.copyWith(
        isPlaying: false,
        isListening: false,
        message: _friendlyAudioError(error),
      );
    }
  }

  void _handlePitch(PitchDetectionResult detection) {
    if (!state.isPlaying || state.settings.mode != TrainerMode.train) {
      return;
    }
    // Guida in riproduzione: il suono captato non è la voce dell'utente.
    if (DateTime.now().isBefore(_ignoreDetectionUntil)) {
      return;
    }

    final output = _stateMachine.evaluate(
      target: state.currentNote,
      detected: detection,
      now: DateTime.now(),
    );

    var progress = List<NoteProgressStatus>.from(state.progress);
    var stats = state.sessionStats;
    var currentIndex = state.currentIndex;

    if (output.event == TrainingValidationEvent.correct) {
      progress[currentIndex] = NoteProgressStatus.correct;
      stats = stats.addAttempt(
        NoteAttempt(
          target: state.currentNote,
          detected: detection.note,
          cents: detection.cents,
          correct: true,
          timestamp: DateTime.now(),
        ),
      );
    }

    if (output.event == TrainingValidationEvent.wrong) {
      progress[currentIndex] = NoteProgressStatus.error;
      stats = stats.addAttempt(
        NoteAttempt(
          target: state.currentNote,
          detected: detection.note,
          cents: detection.cents,
          correct: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    if (output.event == TrainingValidationEvent.advanced && currentIndex < state.sequence.length - 1) {
      currentIndex += 1;
      progress[currentIndex] = NoteProgressStatus.current;
      _stateMachine.markAdvanced();
      if (state.settings.guideEveryNote) {
        unawaited(_playGuideNote(state.sequence[currentIndex]));
      }
    }

    final finished = currentIndex == state.sequence.length - 1 &&
        progress.every((status) => status == NoteProgressStatus.correct);

    if (finished) {
      _recordSession(stats.finish());
    }

    state = state.copyWith(
      progress: progress,
      currentIndex: currentIndex,
      detectedPitch: detection,
      validationState: _stateMachine.state,
      sessionStats: finished ? stats.finish() : stats,
      isPlaying: !finished,
      isListening: !finished,
    );

    if (finished) {
      unawaited(stop());
    }
  }

  void _markCurrentIndex(int index) {
    final progress = [
      for (var i = 0; i < state.sequence.length; i++)
        if (i < index)
          NoteProgressStatus.correct
        else if (i == index)
          NoteProgressStatus.current
        else
          NoteProgressStatus.pending,
    ];
    state = state.copyWith(progress: progress, currentIndex: index);
  }

  String _friendlyAudioError(Object error) {
    return 'Audio non inizializzato: verifica microfono e SoundFont piano.sf2.';
  }
}
