import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../access/application/access_providers.dart';
import '../../../access/domain/entitlement.dart';
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

final pianoAudioServiceProvider = Provider<PianoAudioService>((ref) {
  final service = PianoAudioService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});
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

  /// Identifica l'esecuzione corrente: incrementato da [play] e [stop].
  /// Le operazioni asincrone (avvio microfono, sequenza di ascolto) verificano
  /// di appartenere ancora all'esecuzione corrente prima di aggiornare lo
  /// stato, così uno Stop o l'uscita dalla schermata durante l'avvio non
  /// lasciano il microfono acceso o lo stato incoerente.
  int _runId = 0;

  /// Con la guida su ogni nota si avanza subito alla nota corretta (e la
  /// guida suona la successiva): la macchina a stati resta però in attesa di
  /// un cambio di nota, così la nota precedente ancora tenuta non conta come
  /// errore. Il primo evento `advanced` successivo serve solo a riallinearla.
  bool _advancedOnCorrect = false;

  /// Distingue le sessioni di questo controller da quelle di istanze
  /// precedenti negli identificativi di addebito delle cariche.
  final _instanceId = DateTime.now().microsecondsSinceEpoch;

  /// Run id dell'ultimo avvio del microfono richiesto.
  int _latestMicrophoneStart = 0;

  static const microphoneDeniedMessage =
      'Permesso microfono negato: abilitalo nelle impostazioni di sistema per allenarti.';

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
      _runId++;
      unawaited(_pitchSubscription?.cancel());
      unawaited(_microphone.stop());
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

  void updateTolerance(int cents) =>
      _updateSettings(state.settings.copyWith(toleranceCents: cents));

  void updateStability(int milliseconds) =>
      _updateSettings(state.settings.copyWith(stabilityMs: milliseconds));

  void updateMode(TrainerMode mode) => _updateSettings(state.settings.copyWith(mode: mode));

  void updateLoop(bool loop) => _updateSettings(state.settings.copyWith(loop: loop));

  void updateGuideEveryNote(bool value) =>
      _updateSettings(state.settings.copyWith(guideEveryNote: value));

  /// Avvia una sessione. In allenamento gli utenti Free hanno bisogno di una
  /// carica: se sono esaurite non parte nulla e ritorna false. La carica è
  /// consumata solo quando la sessione inizia davvero (microfono attivo): un
  /// errore prima dell'inizio non la fa perdere. L'ascolto della sequenza
  /// (modalità Ascolto) e delle singole note non consuma cariche.
  Future<bool> play() async {
    final training = state.settings.mode == TrainerMode.train;
    if (training && !await _hasExerciseAccess()) {
      return false;
    }
    await stop();
    state = _resetRunState(isPlaying: true, isListening: training);

    if (!training) {
      await _playListeningMode();
      return true;
    }
    return _startTrainingMode();
  }

  Future<bool> replay() => play();

  /// Pro, oppure Free con almeno una carica (aggiornata all'orologio attuale).
  Future<bool> _hasExerciseAccess() async {
    final entitlement = await ref.read(entitlementProvider.notifier).resolve();
    if (entitlement.allows(ProFeature.unlimitedExercises)) {
      return true;
    }
    final charges = await ref.read(chargesProvider.notifier).refresh();
    return charges.charges > 0;
  }

  /// Addebita la sessione [runId] (una sola volta) per gli utenti Free.
  Future<bool> _chargeSession(int runId) async {
    final entitlement = await ref.read(entitlementProvider.notifier).resolve();
    if (entitlement.allows(ProFeature.unlimitedExercises)) {
      return true;
    }
    return ref.read(chargesProvider.notifier).tryConsume('trainer-$_instanceId-$runId');
  }

  Future<void> stop() async {
    _runId++;
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

  /// Salva nello storico le sessioni di allenamento con almeno un tentativo
  /// e ritorna il riepilogo salvato.
  SessionRecord? _recordSession(SessionStats stats) {
    if (state.settings.mode != TrainerMode.train || stats.attempts.isEmpty) {
      return null;
    }
    final record = SessionRecord.fromStats(
      stats: stats,
      exerciseId: _exercise.id,
      exerciseName: _exercise.name,
    );
    unawaited(ref.read(sessionHistoryProvider.notifier).add(record));
    return record;
  }

  Future<void> listenCurrentNote() => listenNote(state.currentIndex);

  /// Suona la nota [index] della sequenza (per ritrovarla), anche senza la
  /// guida su ogni nota. Durante l'esercizio l'ascolto si sospende come per
  /// la guida, così il piano non viene convalidato come voce; l'esercizio
  /// non avanza.
  Future<void> listenNote(int index) async {
    if (index < 0 || index >= state.sequence.length) {
      return;
    }
    await _playGuideNote(state.sequence[index]);
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
    _advancedOnCorrect = false;
    state = TrainerState.initial(settings: settings, sequence: sequence);
  }

  TrainerState _resetRunState({required bool isPlaying, required bool isListening}) {
    final progress = [
      for (var i = 0; i < state.sequence.length; i++)
        i == 0 ? NoteProgressStatus.current : NoteProgressStatus.pending,
    ];
    _stateMachine.reset();
    _advancedOnCorrect = false;
    return state.copyWith(
      progress: progress,
      currentIndex: 0,
      isPlaying: isPlaying,
      isListening: isListening,
      validationState: TrainingValidationState.waitNote,
      sessionStats: SessionStats.started(),
      clearMessage: true,
      clearCompletedSession: true,
    );
  }

  Future<void> _playListeningMode() async {
    final runId = _runId;
    try {
      final completed = await _audio.playSequence(
        notes: state.sequence,
        bpm: state.settings.bpm,
        loop: state.settings.loop,
        onNote: (index) {
          if (runId == _runId) {
            _markCurrentIndex(index);
          }
        },
      );
      if (completed && runId == _runId) {
        state = state.copyWith(isPlaying: false, sessionStats: state.sessionStats.finish());
      }
    } catch (error) {
      if (runId == _runId) {
        state = state.copyWith(isPlaying: false, message: _friendlyAudioError(error));
      }
    }
  }

  /// Ritorna false solo se la sessione non è partita per cariche esaurite.
  Future<bool> _startTrainingMode() async {
    final runId = _runId;
    try {
      await _playGuideNote(state.currentNote);
      if (runId != _runId) {
        return true;
      }
      _latestMicrophoneStart = runId;
      final started = await _microphone.start();
      if (runId != _runId) {
        // Fermato (o schermata chiusa) mentre il microfono si avviava. Se nel
        // frattempo è partita una nuova esecuzione, il microfono è suo.
        if (_latestMicrophoneStart == runId) {
          await _microphone.stop();
        }
        return true;
      }
      if (!started) {
        state = state.copyWith(
          isPlaying: false,
          isListening: false,
          message: microphoneDeniedMessage,
        );
        return true;
      }
      // La sessione parte ora: per gli utenti Free costa una carica.
      final charged = await _chargeSession(runId);
      if (runId != _runId) {
        return true;
      }
      if (!charged) {
        await stop();
        return false;
      }
      _pitchSubscription = _microphone.pitchStream.listen(_handlePitch);
    } catch (error) {
      if (runId != _runId) {
        return true;
      }
      state = state.copyWith(
        isPlaying: false,
        isListening: false,
        message: _friendlyAudioError(error),
      );
    }
    return true;
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
    // Nota riconosciuta (stabilizzata), non il frame grezzo del rilevatore.
    final recognized = output.detected ?? detection;

    var progress = List<NoteProgressStatus>.from(state.progress);
    var stats = state.sessionStats;
    var currentIndex = state.currentIndex;

    if (output.event == TrainingValidationEvent.correct) {
      progress[currentIndex] = NoteProgressStatus.correct;
      stats = stats.addAttempt(
        NoteAttempt(
          target: state.currentNote,
          detected: recognized.note,
          cents: recognized.cents,
          correct: true,
          timestamp: DateTime.now(),
        ),
      );
      if (state.settings.guideEveryNote && currentIndex < state.sequence.length - 1) {
        currentIndex += 1;
        progress[currentIndex] = NoteProgressStatus.current;
        _advancedOnCorrect = true;
        unawaited(_playGuideNote(state.sequence[currentIndex]));
      }
    }

    if (output.event == TrainingValidationEvent.wrong) {
      progress[currentIndex] = NoteProgressStatus.error;
      stats = stats.addAttempt(
        NoteAttempt(
          target: state.currentNote,
          detected: recognized.note,
          cents: recognized.cents,
          correct: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    if (output.event == TrainingValidationEvent.advanced && _advancedOnCorrect) {
      // Già avanzati alla convalida: la nota è cambiata, la macchina torna a
      // valutare la nota corrente.
      _advancedOnCorrect = false;
      _stateMachine.markAdvanced();
    } else if (output.event == TrainingValidationEvent.advanced &&
        currentIndex < state.sequence.length - 1) {
      currentIndex += 1;
      progress[currentIndex] = NoteProgressStatus.current;
      _stateMachine.markAdvanced();
      if (state.settings.guideEveryNote) {
        unawaited(_playGuideNote(state.sequence[currentIndex]));
      }
    }

    final finished = currentIndex == state.sequence.length - 1 &&
        progress.every((status) => status == NoteProgressStatus.correct);

    final completed = finished ? _recordSession(stats.finish()) : null;

    state = state.copyWith(
      progress: progress,
      currentIndex: currentIndex,
      detectedPitch: recognized,
      validationState: _stateMachine.state,
      sessionStats: finished ? stats.finish() : stats,
      isPlaying: !finished,
      isListening: !finished,
      completedSession: completed,
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
