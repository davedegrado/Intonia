import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/music/note.dart';
import '../../../core/pitch/pitch_detection_result.dart';
import '../../../core/pitch/pitch_recognition_config.dart';
import '../../../core/pitch/pitch_stabilizer.dart';
import '../../../core/session/range_record.dart';
import '../../../services/audio/piano_audio_service.dart';
import '../../../services/pitch/microphone_pitch_service.dart';
import '../../settings/application/settings_providers.dart';
import '../../trainer/domain/training_state_machine.dart';
import '../../trainer/presentation/controllers/trainer_controller.dart';
import 'range_providers.dart';

enum RangePhase {
  setup,

  /// Il cantante tiene una nota comoda: diventa la nota di partenza.
  findingStart,
  descending,
  ascending,
  done,
}

class RangeTestState {
  const RangeTestState({
    required this.phase,
    required this.startMidi,
    required this.targetMidi,
    required this.lowestMidi,
    required this.highestMidi,
    required this.skipsInRow,
    required this.isListening,
    required this.toleranceCents,
    required this.stabilityMs,
    this.detected,
    this.message,
    this.previousRecord,
    this.validatedCount = 0,
    this.skippedCount = 0,
    this.startHoldProgress = 0,
  });

  factory RangeTestState.initial() => const RangeTestState(
        phase: RangePhase.setup,
        startMidi: 60, // DO4
        targetMidi: 60,
        lowestMidi: null,
        highestMidi: null,
        skipsInRow: 0,
        isListening: false,
        toleranceCents: PitchRecognitionConfig.rangeTestToleranceCents,
        stabilityMs: 150,
      );

  final RangePhase phase;
  final int startMidi;
  final int targetMidi;
  final int? lowestMidi;
  final int? highestMidi;
  final int skipsInRow;
  final bool isListening;
  final int toleranceCents;
  final int stabilityMs;
  final PitchDetectionResult? detected;
  final String? message;

  /// Test precedente, per il confronto a fine esercizio.
  final RangeRecord? previousRecord;

  /// Note convalidate e note saltate nel test corrente: contatori di eventi
  /// usati dall'interfaccia (reazioni della mascotte).
  final int validatedCount;
  final int skippedCount;

  /// Avanzamento (0–1) della nota di partenza tenuta in [RangePhase.findingStart].
  final double startHoldProgress;

  MusicalNote get targetNote => MusicalNote.fromMidi(targetMidi);

  RangeTestState copyWith({
    RangePhase? phase,
    int? startMidi,
    int? targetMidi,
    int? Function()? lowestMidi,
    int? Function()? highestMidi,
    int? skipsInRow,
    bool? isListening,
    int? toleranceCents,
    int? stabilityMs,
    PitchDetectionResult? detected,
    String? message,
    bool clearMessage = false,
    RangeRecord? previousRecord,
    int? validatedCount,
    int? skippedCount,
    double? startHoldProgress,
    bool clearDetected = false,
  }) {
    return RangeTestState(
      phase: phase ?? this.phase,
      startMidi: startMidi ?? this.startMidi,
      targetMidi: targetMidi ?? this.targetMidi,
      lowestMidi: lowestMidi != null ? lowestMidi() : this.lowestMidi,
      highestMidi: highestMidi != null ? highestMidi() : this.highestMidi,
      skipsInRow: skipsInRow ?? this.skipsInRow,
      isListening: isListening ?? this.isListening,
      toleranceCents: toleranceCents ?? this.toleranceCents,
      stabilityMs: stabilityMs ?? this.stabilityMs,
      detected: clearDetected ? null : detected ?? this.detected,
      message: clearMessage ? null : message ?? this.message,
      previousRecord: previousRecord ?? this.previousRecord,
      validatedCount: validatedCount ?? this.validatedCount,
      skippedCount: skippedCount ?? this.skippedCount,
      startHoldProgress: startHoldProgress ?? this.startHoldProgress,
    );
  }
}

final rangeTestControllerProvider =
    NotifierProvider.autoDispose<RangeTestController, RangeTestState>(
  RangeTestController.new,
);

class RangeTestController extends Notifier<RangeTestState> {
  static const _minMidi = 24; // DO1 (~32.7 Hz, raggiungibile in fry)
  static const _maxMidi = 88; // MI6
  static const _maxSkipsInRow = 3;
  static const _guideNoteDuration = Duration(milliseconds: 650);
  static const _detectionMuteTail = Duration(milliseconds: 450);

  /// Per quanto il cantante deve tenere la nota comoda perché diventi la nota
  /// di partenza: abbastanza da escludere un attacco o una nota di passaggio.
  static const startHold = Duration(milliseconds: 800);

  /// Riconoscimento della nota di partenza (vibrato e cadute brevi inclusi).
  final _startStabilizer = PitchStabilizer();
  MusicalNote? _startCandidate;
  DateTime? _startCandidateSince;

  StreamSubscription<PitchDetectionResult>? _subscription;
  late TrainingStateMachine _machine;
  DateTime _ignoreDetectionUntil = DateTime.fromMillisecondsSinceEpoch(0);
  late MicrophonePitchService _microphone;
  late PianoAudioService _audio;

  /// Incrementato da avvio, annullamento, fine test e dispose: un avvio del
  /// microfono ancora in corso non deve proseguire dopo uno di questi eventi.
  int _generation = 0;

  /// Generazione dell'ultimo avvio richiesto.
  int _latestStart = 0;

  @override
  RangeTestState build() {
    _machine = TrainingStateMachine(
      toleranceCents: PitchRecognitionConfig.rangeTestToleranceCents,
      stabilityMs: 150,
    );
    _microphone = ref.read(microphonePitchServiceProvider);
    _audio = ref.read(pianoAudioServiceProvider);
    // In onDispose non si possono usare ref né state: si rilasciano solo
    // le risorse catturate.
    ref.onDispose(() {
      _generation++;
      unawaited(_subscription?.cancel());
      _subscription = null;
      unawaited(_microphone.stop());
      unawaited(_audio.stopAll());
    });
    final previous = ref.read(rangeHistoryProvider).value ?? const [];
    return RangeTestState.initial().copyWith(
      previousRecord: previous.isNotEmpty ? previous.last : null,
    );
  }

  void setTolerance(int cents) {
    if (state.phase == RangePhase.setup || state.phase == RangePhase.done) {
      state = state.copyWith(toleranceCents: cents);
    }
  }

  void setStability(int milliseconds) {
    if (state.phase == RangePhase.setup || state.phase == RangePhase.done) {
      state = state.copyWith(stabilityMs: milliseconds);
    }
  }

  /// Avvia il test: il cantante tiene una nota comoda, che diventa la nota
  /// di partenza; poi si scende verso il grave e si sale verso l'acuto.
  Future<void> start() async {
    final generation = ++_generation;
    _latestStart = generation;
    _machine = TrainingStateMachine(
      toleranceCents: state.toleranceCents,
      stabilityMs: state.stabilityMs,
    );
    _startStabilizer.reset();
    _startCandidate = null;
    _startCandidateSince = null;
    _ignoreDetectionUntil = DateTime.fromMillisecondsSinceEpoch(0);
    state = state.copyWith(
      phase: RangePhase.findingStart,
      lowestMidi: () => null,
      highestMidi: () => null,
      skipsInRow: 0,
      isListening: true,
      clearMessage: true,
      clearDetected: true,
      validatedCount: 0,
      skippedCount: 0,
      startHoldProgress: 0,
    );
    try {
      final started = await _microphone.start();
      if (generation != _generation) {
        // Test annullato o schermata chiusa mentre il microfono si avviava.
        // Se nel frattempo è partito un nuovo test, il microfono è suo.
        if (_latestStart == generation) {
          await _microphone.stop();
        }
        return;
      }
      if (!started) {
        state = state.copyWith(
          phase: RangePhase.setup,
          isListening: false,
          message: ref.read(l10nProvider).rangeMicDenied,
        );
        return;
      }
      _subscription = _microphone.pitchStream.listen(_handlePitch);
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        phase: RangePhase.setup,
        isListening: false,
        message: ref.read(l10nProvider).rangeAudioInitFailed,
      );
    }
  }

  /// Nota comoda: quando resta la stessa per [startHold] diventa la nota di
  /// partenza (già convalidata) e il test scende dal semitono sotto.
  void _handleStartPitch(PitchDetectionResult detection, DateTime now) {
    final recognized = _startStabilizer.process(detection, now);
    final current = _startStabilizer.current;
    if (!recognized.isStable) {
      if (current == null) {
        // Silenzio: si ricomincia ad aspettare la nota.
        _startCandidate = null;
        _startCandidateSince = null;
        state = state.copyWith(startHoldProgress: 0, clearDetected: true);
      }
      return;
    }
    if (_startCandidate != recognized.note) {
      _startCandidate = recognized.note;
      _startCandidateSince = now;
    }
    final held = now.difference(_startCandidateSince!);
    final progress = (held.inMilliseconds / startHold.inMilliseconds).clamp(0.0, 1.0);
    state = state.copyWith(detected: recognized, startHoldProgress: progress);
    if (held >= startHold) {
      _beginFrom(recognized.note);
    }
  }

  void _beginFrom(MusicalNote note) {
    final midi = note.midiNumber.clamp(_minMidi, _maxMidi);
    _machine.reset();
    state = state.copyWith(
      phase: RangePhase.descending,
      startMidi: midi,
      targetMidi: midi,
      lowestMidi: () => midi,
      highestMidi: () => midi,
      validatedCount: state.validatedCount + 1,
      startHoldProgress: 1,
    );
    _advanceTarget();
  }

  Future<void> replayTarget() => _playGuideNote(state.targetNote);

  /// "Salta questa nota": prova comunque la successiva. Dopo
  /// [_maxSkipsInRow] salti consecutivi senza successi, il limite è trovato.
  void skipNote() {
    if (!_isTesting) {
      return;
    }
    final skips = state.skipsInRow + 1;
    state = state.copyWith(skippedCount: state.skippedCount + 1);
    if (skips >= _maxSkipsInRow) {
      endPhase();
      return;
    }
    state = state.copyWith(skipsInRow: skips);
    _advanceTarget();
  }

  /// "Limite raggiunto": chiude la fase corrente.
  void endPhase() {
    if (!_isTesting) {
      return;
    }
    if (state.phase == RangePhase.descending) {
      _startAscending();
    } else {
      unawaited(_finish());
    }
  }

  Future<void> cancel() async {
    await _stopAudio();
    state = state.copyWith(phase: RangePhase.setup, isListening: false, clearMessage: true);
  }

  bool get _isTesting =>
      state.phase == RangePhase.descending || state.phase == RangePhase.ascending;

  void _handlePitch(PitchDetectionResult detection) {
    if (state.phase == RangePhase.findingStart) {
      _handleStartPitch(detection, DateTime.now());
      return;
    }
    if (!_isTesting) {
      return;
    }
    if (DateTime.now().isBefore(_ignoreDetectionUntil)) {
      return;
    }

    final output = _machine.evaluate(
      target: state.targetNote,
      detected: detection,
      now: DateTime.now(),
    );
    final recognized = output.detected ?? detection;

    if (output.event == TrainingValidationEvent.correct) {
      final midi = state.targetMidi;
      state = state.copyWith(
        lowestMidi: () =>
            state.lowestMidi == null || midi < state.lowestMidi! ? midi : state.lowestMidi,
        highestMidi: () =>
            state.highestMidi == null || midi > state.highestMidi! ? midi : state.highestMidi,
        skipsInRow: 0,
        detected: recognized,
        validatedCount: state.validatedCount + 1,
      );
      _advanceTarget();
      return;
    }

    state = state.copyWith(detected: recognized);
  }

  void _advanceTarget() {
    final next = state.phase == RangePhase.descending ? state.targetMidi - 1 : state.targetMidi + 1;
    if (next < _minMidi || next > _maxMidi) {
      endPhase();
      return;
    }
    _machine.reset();
    state = state.copyWith(targetMidi: next, clearMessage: true);
    unawaited(_playGuideNote(MusicalNote.fromMidi(next)));
  }

  void _startAscending() {
    _machine.reset();
    // Si riparte dal semitono sopra la nota più alta già convalidata
    // (o sopra la nota di partenza se la discesa non ha convalidato nulla).
    final from = (state.highestMidi ?? state.startMidi) + 1;
    state = state.copyWith(
      phase: RangePhase.ascending,
      targetMidi: from.clamp(_minMidi, _maxMidi),
      skipsInRow: 0,
      clearMessage: true,
    );
    unawaited(_playGuideNote(state.targetNote));
  }

  Future<void> _finish() async {
    await _stopAudio();
    final lowest = state.lowestMidi;
    final highest = state.highestMidi;
    if (lowest != null && highest != null) {
      unawaited(ref.read(rangeHistoryProvider.notifier).add(RangeRecord(
            timestamp: DateTime.now(),
            minMidi: lowest,
            maxMidi: highest,
          )));
    }
    state = state.copyWith(
      phase: RangePhase.done,
      isListening: false,
      message: lowest == null ? ref.read(l10nProvider).rangeNothingValidated : null,
    );
  }

  Future<void> _stopAudio() async {
    _generation++;
    await _subscription?.cancel();
    _subscription = null;
    await _microphone.stop();
    await _audio.stopAll();
  }

  Future<void> _playGuideNote(MusicalNote note) async {
    _ignoreDetectionUntil = DateTime.now().add(_guideNoteDuration + _detectionMuteTail);
    await _audio.playNote(note, duration: _guideNoteDuration);
  }
}
