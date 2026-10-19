import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/music/note.dart';
import '../../../core/pitch/pitch_detection_result.dart';
import '../../../core/pitch/pitch_recognition_config.dart';
import '../../../core/pitch/pitch_stabilizer.dart';
import '../../../services/audio/piano_audio_service.dart';
import '../../../services/pitch/microphone_pitch_service.dart';
import '../../access/application/access_providers.dart';
import '../../range/application/range_providers.dart';
import '../../trainer/domain/training_state_machine.dart';
import '../../trainer/presentation/controllers/trainer_controller.dart';
import '../domain/tessitura.dart';
import 'tessitura_providers.dart';

enum TessituraPhase {
  intro,

  /// Senza un test di estensione: il cantante tiene una nota comoda, che
  /// diventa il centro della ricerca.
  findingStart,
  singing,

  /// Nota finale tenuta per misurare la tenuta.
  sustaining,

  /// "Quanto è stato comodo?"
  rating,
  done,
}

enum TessituraMessage { microphoneDenied, audioUnavailable }

class TessituraTestState {
  const TessituraTestState({
    required this.phase,
    required this.trials,
    this.rootMidi,
    this.noteIndex = 0,
    this.detected,
    this.startHoldProgress = 0,
    this.sustainProgress = 0,
    this.estimate,
    this.record,
    this.previous,
    this.message,
    this.hasRange = false,
  });

  final TessituraPhase phase;
  final List<TessituraTrial> trials;

  /// Nota di partenza della prova in corso.
  final int? rootMidi;

  /// Posizione nel frammento ([TessituraTrial.pattern]).
  final int noteIndex;
  final PitchDetectionResult? detected;
  final double startHoldProgress;
  final double sustainProgress;

  /// Stima e record salvato a fine test.
  final TessituraEstimate? estimate;
  final TessituraRecord? record;

  /// Test precedente, per il confronto.
  final TessituraRecord? previous;
  final TessituraMessage? message;

  /// C'è un test di estensione da usare come riferimento.
  final bool hasRange;

  int? get targetMidi => rootMidi == null ? null : rootMidi! + TessituraTrial.pattern[noteIndex];

  /// Numero della prova in corso (da 1).
  int get trialNumber => trials.length + 1;

  TessituraTestState copyWith({
    TessituraPhase? phase,
    List<TessituraTrial>? trials,
    int? rootMidi,
    int? noteIndex,
    PitchDetectionResult? detected,
    bool clearDetected = false,
    double? startHoldProgress,
    double? sustainProgress,
    TessituraEstimate? estimate,
    TessituraRecord? record,
    TessituraMessage? message,
    bool clearMessage = false,
  }) {
    return TessituraTestState(
      phase: phase ?? this.phase,
      trials: trials ?? this.trials,
      rootMidi: rootMidi ?? this.rootMidi,
      noteIndex: noteIndex ?? this.noteIndex,
      detected: clearDetected ? null : detected ?? this.detected,
      startHoldProgress: startHoldProgress ?? this.startHoldProgress,
      sustainProgress: sustainProgress ?? this.sustainProgress,
      estimate: estimate ?? this.estimate,
      record: record ?? this.record,
      previous: previous,
      message: clearMessage ? null : message ?? this.message,
      hasRange: hasRange,
    );
  }
}

final tessituraTestControllerProvider =
    NotifierProvider.autoDispose<TessituraTestController, TessituraTestState>(
  TessituraTestController.new,
);

/// Test guidato della zona comoda: brevi frammenti su e giù a partire da
/// note scelte da [TessituraPlanner]; dopo ogni prova l'utente dice quanto
/// è stato comodo. Riusa microfono, piano e convalida delle note del trainer.
class TessituraTestController extends Notifier<TessituraTestState> {
  static const _guideNoteDuration = Duration(milliseconds: 650);
  static const _detectionMuteTail = Duration(milliseconds: 450);

  /// Tempo massimo per una nota: poi la si considera non riuscita e si va avanti.
  static const noteTimeout = Duration(seconds: 8);

  /// Durata della nota tenuta a fine prova.
  static const sustainDuration = Duration(milliseconds: 1500);

  /// Nota comoda da tenere per partire senza test di estensione.
  static const startHold = Duration(milliseconds: 800);

  static const _toleranceCents = PitchRecognitionConfig.rangeTestToleranceCents;

  late MicrophonePitchService _microphone;
  late PianoAudioService _audio;
  late TrainingStateMachine _machine;
  StreamSubscription<PitchDetectionResult>? _subscription;
  TessituraPlanner? _planner;
  int? _rangeLow;
  int? _rangeHigh;

  /// Incrementato a ogni avvio, annullamento e dispose (avvii superati).
  int _generation = 0;
  DateTime _ignoreUntil = DateTime.fromMillisecondsSinceEpoch(0);

  // Misure della prova in corso.
  final _noteMeasures = <int, List<NoteMeasure>>{};
  final _cents = <double>[];
  int _wrong = 0;
  DateTime? _noteStartedAt;
  DateTime? _sustainStartedAt;
  int _sustainFrames = 0;
  int _sustainOnTarget = 0;

  // Ricerca della nota di partenza.
  final _startStabilizer = PitchStabilizer();
  MusicalNote? _startCandidate;
  DateTime? _startCandidateSince;

  DateTime get _now => ref.read(clockProvider)();

  @override
  TessituraTestState build() {
    _microphone = ref.read(microphonePitchServiceProvider);
    _audio = ref.read(pianoAudioServiceProvider);
    _machine = _newMachine();
    ref.onDispose(() {
      _generation++;
      unawaited(_subscription?.cancel());
      _subscription = null;
      unawaited(_microphone.stop());
      unawaited(_audio.stopAll());
    });
    final ranges = ref.read(rangeHistoryProvider).value ?? const [];
    final history = ref.read(tessituraHistoryProvider).value ?? const [];
    final range = ranges.isNotEmpty ? ranges.last : null;
    _rangeLow = range?.minMidi;
    _rangeHigh = range?.maxMidi;
    return TessituraTestState(
      phase: TessituraPhase.intro,
      trials: const [],
      previous: history.isNotEmpty ? history.last : null,
      hasRange: range != null && range.spanSemitones >= 7,
    );
  }

  TrainingStateMachine _newMachine() =>
      TrainingStateMachine(toleranceCents: _toleranceCents, stabilityMs: 150);

  /// Avvia il test: con un test di estensione parte dal suo terzo inferiore
  /// (dove la voce di solito è comoda), altrimenti da una nota comoda tenuta.
  Future<void> start() async {
    final generation = ++_generation;
    state = TessituraTestState(
      phase: state.hasRange ? TessituraPhase.singing : TessituraPhase.findingStart,
      trials: const [],
      previous: state.previous,
      hasRange: state.hasRange,
    );
    _startStabilizer.reset();
    _startCandidate = null;
    _startCandidateSince = null;
    try {
      final started = await _microphone.start();
      if (generation != _generation) {
        return;
      }
      if (!started) {
        state =
            state.copyWith(phase: TessituraPhase.intro, message: TessituraMessage.microphoneDenied);
        return;
      }
      _subscription = _microphone.pitchStream.listen(_handlePitch);
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state =
          state.copyWith(phase: TessituraPhase.intro, message: TessituraMessage.audioUnavailable);
      return;
    }
    if (state.hasRange) {
      final low = _rangeLow!;
      final high = _rangeHigh!;
      _beginSearch(low + ((high - low) * 0.4).round(), low, high);
    }
  }

  void _beginSearch(int center, int low, int high) {
    _planner = TessituraPlanner(centerMidi: center, lowMidi: low, highMidi: high);
    _startTrial(_planner!.next(const [])!);
  }

  void _startTrial(int root) {
    _noteMeasures.clear();
    state = state.copyWith(
      phase: TessituraPhase.singing,
      rootMidi: root,
      noteIndex: 0,
      clearDetected: true,
      sustainProgress: 0,
    );
    _startNote();
  }

  void _startNote() {
    _machine.reset();
    _cents.clear();
    _wrong = 0;
    _noteStartedAt = _now;
    unawaited(_playGuide(MusicalNote.fromMidi(state.targetMidi!)));
  }

  Future<void> replayNote() async {
    final target = state.targetMidi;
    if (target != null) {
      await _playGuide(MusicalNote.fromMidi(target));
    }
  }

  Future<void> _playGuide(MusicalNote note) async {
    _ignoreUntil = _now.add(_guideNoteDuration + _detectionMuteTail);
    await _audio.playNote(note, duration: _guideNoteDuration);
  }

  void _handlePitch(PitchDetectionResult detection) {
    final now = _now;
    switch (state.phase) {
      case TessituraPhase.findingStart:
        _handleStart(detection, now);
      case TessituraPhase.singing:
        _handleSinging(detection, now);
      case TessituraPhase.sustaining:
        _handleSustain(detection, now);
      default:
        break;
    }
  }

  void _handleStart(PitchDetectionResult detection, DateTime now) {
    final recognized = _startStabilizer.process(detection, now);
    if (!recognized.isStable) {
      if (_startStabilizer.current == null) {
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
    state = state.copyWith(
      detected: recognized,
      startHoldProgress: (held.inMilliseconds / startHold.inMilliseconds).clamp(0.0, 1.0),
    );
    if (held >= startHold) {
      final center = recognized.note.midiNumber;
      // Senza estensione nota si cerca entro un'ottava e mezza attorno.
      _beginSearch(center, center - 14, center + 14);
    }
  }

  void _handleSinging(PitchDetectionResult detection, DateTime now) {
    if (now.isBefore(_ignoreUntil)) {
      return;
    }
    final target = MusicalNote.fromMidi(state.targetMidi!);
    final output = _machine.evaluate(target: target, detected: detection, now: now);
    final recognized = output.detected;
    if (recognized != null && recognized.isStable && recognized.note == target) {
      _cents.add(recognized.cents);
    }
    if (output.event == TrainingValidationEvent.wrong) {
      _wrong++;
    }
    state = state.copyWith(detected: recognized ?? detection);
    if (output.event == TrainingValidationEvent.correct) {
      _completeNote(validated: true);
      return;
    }
    if (now.difference(_noteStartedAt ?? now) >= noteTimeout) {
      _completeNote(validated: false);
    }
  }

  /// "Salta nota": la nota conta come non riuscita.
  void skipNote() {
    if (state.phase == TessituraPhase.singing) {
      _completeNote(validated: false);
    } else if (state.phase == TessituraPhase.sustaining) {
      _endSustain();
    }
  }

  void _completeNote({required bool validated}) {
    final mean = _cents.isEmpty ? 0.0 : _cents.reduce((a, b) => a + b) / _cents.length;
    final spread = _cents.length < 2
        ? 0.0
        : math.sqrt(
            _cents.map((c) => (c - mean) * (c - mean)).reduce((a, b) => a + b) / _cents.length);
    _noteMeasures.putIfAbsent(state.targetMidi!, () => []).add(NoteMeasure(
          validated: validated,
          meanCents: mean,
          spreadCents: spread,
          wrongAttempts: _wrong,
        ));
    final isLast = state.noteIndex == TessituraTrial.pattern.length - 1;
    if (isLast && validated) {
      // L'ultima nota si tiene: misura la tenuta.
      _sustainStartedAt = _now;
      _sustainFrames = 0;
      _sustainOnTarget = 0;
      state = state.copyWith(phase: TessituraPhase.sustaining, sustainProgress: 0);
      return;
    }
    if (isLast) {
      _endTrial();
      return;
    }
    state = state.copyWith(noteIndex: state.noteIndex + 1, clearDetected: true);
    _startNote();
  }

  void _handleSustain(PitchDetectionResult detection, DateTime now) {
    final target = MusicalNote.fromMidi(state.targetMidi!);
    final output = _machine.evaluate(target: target, detected: detection, now: now);
    final recognized = output.detected;
    _sustainFrames++;
    if (recognized != null &&
        recognized.isStable &&
        recognized.note == target &&
        recognized.cents.abs() <= _toleranceCents) {
      _sustainOnTarget++;
    }
    final elapsed = now.difference(_sustainStartedAt ?? now);
    state = state.copyWith(
      detected: recognized ?? detection,
      sustainProgress: (elapsed.inMilliseconds / sustainDuration.inMilliseconds).clamp(0.0, 1.0),
    );
    if (elapsed >= sustainDuration) {
      _endSustain();
    }
  }

  void _endSustain() {
    final ratio = _sustainFrames == 0 ? 0.0 : _sustainOnTarget / _sustainFrames;
    final last = _noteMeasures[state.targetMidi!]!;
    final measure = last.removeLast();
    last.add(NoteMeasure(
      validated: measure.validated,
      meanCents: measure.meanCents,
      spreadCents: measure.spreadCents,
      wrongAttempts: measure.wrongAttempts,
      sustainRatio: ratio,
    ));
    _endTrial();
  }

  void _endTrial() {
    state = state.copyWith(phase: TessituraPhase.rating, clearDetected: true);
  }

  /// Comfort della prova appena cantata; null = "non ci sono riuscito".
  Future<void> rate(ComfortRating? comfort) async {
    if (state.phase != TessituraPhase.rating) {
      return;
    }
    final trial = TessituraTrial(
      rootMidi: state.rootMidi!,
      measures: {
        for (final entry in _noteMeasures.entries) entry.key: _merge(entry.value),
      },
      comfort: comfort,
    );
    final trials = [...state.trials, trial];
    state = state.copyWith(trials: trials);
    final next = _planner?.next(trials);
    if (next == null) {
      await finish();
    } else {
      _startTrial(next);
    }
  }

  /// Unisce le misure di una nota cantata più volte nella stessa prova.
  static NoteMeasure _merge(List<NoteMeasure> measures) {
    if (measures.length == 1) {
      return measures.single;
    }
    double average(double Function(NoteMeasure m) value) =>
        measures.map(value).reduce((a, b) => a + b) / measures.length;
    final sustain = measures.map((m) => m.sustainRatio).whereType<double>();
    return NoteMeasure(
      validated: measures.every((m) => m.validated),
      meanCents: average((m) => m.meanCents),
      spreadCents: measures.map((m) => m.spreadCents).reduce(math.max),
      wrongAttempts: measures.map((m) => m.wrongAttempts).reduce((a, b) => a + b),
      sustainRatio: sustain.isEmpty ? null : sustain.first,
    );
  }

  /// Chiude il test con le prove fatte finora e salva il risultato (anche
  /// provvisorio). Senza prove non salva nulla.
  Future<void> finish() async {
    final trials = state.trials;
    if (trials.isEmpty) {
      state = state.copyWith(phase: TessituraPhase.intro);
      await _stopAudio();
      return;
    }
    final estimate = TessituraEstimate.from(trials);
    final validated = [
      for (final trial in trials)
        for (final entry in trial.measures.entries)
          if (entry.value.validated) entry.key,
    ];
    final record = TessituraRecord.fromEstimate(
      timestamp: _now,
      estimate: estimate,
      rangeLow: _rangeLow ?? (validated.isEmpty ? null : validated.reduce(math.min)),
      rangeHigh: _rangeHigh ?? (validated.isEmpty ? null : validated.reduce(math.max)),
    );
    // Prima il risultato (e il salvataggio), poi il rilascio di microfono e
    // piano: un rilascio lento non deve far perdere il test.
    state = state.copyWith(phase: TessituraPhase.done, estimate: estimate, record: record);
    await ref.read(tessituraHistoryProvider.notifier).add(record);
    await _stopAudio();
  }

  /// Annulla senza salvare.
  Future<void> cancel() async {
    await _stopAudio();
    if (!ref.mounted) {
      return;
    }
    state = TessituraTestState(
      phase: TessituraPhase.intro,
      trials: const [],
      previous: state.previous,
      hasRange: state.hasRange,
    );
  }

  Future<void> _stopAudio() async {
    _generation++;
    await _subscription?.cancel();
    _subscription = null;
    await _microphone.stop();
    await _audio.stopAll();
  }
}
