import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/music/note.dart';
import '../../../core/pitch/pitch_detection_result.dart';
import '../../../core/session/range_record.dart';
import '../../trainer/domain/training_state_machine.dart';
import '../../trainer/presentation/controllers/trainer_controller.dart';
import 'range_providers.dart';

enum RangePhase { setup, descending, ascending, done }

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
  });

  factory RangeTestState.initial() => const RangeTestState(
        phase: RangePhase.setup,
        startMidi: 60, // DO4
        targetMidi: 60,
        lowestMidi: null,
        highestMidi: null,
        skipsInRow: 0,
        isListening: false,
        toleranceCents: 40,
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
      detected: detected ?? this.detected,
      message: clearMessage ? null : message ?? this.message,
      previousRecord: previousRecord ?? this.previousRecord,
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

  StreamSubscription<PitchDetectionResult>? _subscription;
  late TrainingStateMachine _machine;
  DateTime _ignoreDetectionUntil = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  RangeTestState build() {
    _machine = TrainingStateMachine(toleranceCents: 40, stabilityMs: 150);
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      unawaited(ref.read(microphonePitchServiceProvider).stop());
      unawaited(ref.read(pianoAudioServiceProvider).stopAll());
    });
    final previous = ref.read(rangeHistoryProvider).value ?? const [];
    return RangeTestState.initial().copyWith(
      previousRecord: previous.isNotEmpty ? previous.last : null,
    );
  }

  void setStartNote({PitchClass? key, int? octave}) {
    if (state.phase != RangePhase.setup) {
      return;
    }
    final current = MusicalNote.fromMidi(state.startMidi);
    final note = MusicalNote(
      pitchClass: key ?? current.pitchClass,
      octave: octave ?? current.octave,
    );
    state = state.copyWith(startMidi: note.midiNumber, targetMidi: note.midiNumber);
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

  /// Avvia il test: si parte dalla nota comoda e si scende.
  Future<void> start() async {
    _machine = TrainingStateMachine(
      toleranceCents: state.toleranceCents,
      stabilityMs: state.stabilityMs,
    );
    state = state.copyWith(
      phase: RangePhase.descending,
      targetMidi: state.startMidi,
      lowestMidi: () => null,
      highestMidi: () => null,
      skipsInRow: 0,
      isListening: true,
      clearMessage: true,
    );
    try {
      await _playGuideNote(state.targetNote);
      final microphone = ref.read(microphonePitchServiceProvider);
      await microphone.start();
      _subscription = microphone.pitchStream.listen(_handlePitch);
    } catch (_) {
      state = state.copyWith(
        phase: RangePhase.setup,
        isListening: false,
        message: 'Audio non inizializzato: verifica microfono e SoundFont.',
      );
    }
  }

  Future<void> replayTarget() => _playGuideNote(state.targetNote);

  /// "Salta questa nota": prova comunque la successiva. Dopo
  /// [_maxSkipsInRow] salti consecutivi senza successi, il limite è trovato.
  void skipNote() {
    if (!_isTesting) {
      return;
    }
    final skips = state.skipsInRow + 1;
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

    if (output.event == TrainingValidationEvent.correct) {
      final midi = state.targetMidi;
      state = state.copyWith(
        lowestMidi: () =>
            state.lowestMidi == null || midi < state.lowestMidi! ? midi : state.lowestMidi,
        highestMidi: () =>
            state.highestMidi == null || midi > state.highestMidi! ? midi : state.highestMidi,
        skipsInRow: 0,
        detected: detection,
      );
      _advanceTarget();
      return;
    }

    state = state.copyWith(detected: detection);
  }

  void _advanceTarget() {
    final next = state.phase == RangePhase.descending
        ? state.targetMidi - 1
        : state.targetMidi + 1;
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
      message: lowest == null
          ? 'Nessuna nota convalidata: il test non è stato salvato.'
          : null,
    );
  }

  Future<void> _stopAudio() async {
    await _subscription?.cancel();
    _subscription = null;
    await ref.read(microphonePitchServiceProvider).stop();
    await ref.read(pianoAudioServiceProvider).stopAll();
  }

  Future<void> _playGuideNote(MusicalNote note) async {
    _ignoreDetectionUntil = DateTime.now().add(_guideNoteDuration + _detectionMuteTail);
    await ref.read(pianoAudioServiceProvider).playNote(note, duration: _guideNoteDuration);
  }
}
