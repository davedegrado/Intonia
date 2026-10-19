import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/music/note.dart';
import '../../../core/pitch/pitch_detection_result.dart';
import '../../../core/pitch/pitch_stabilizer.dart';
import '../../../services/audio/piano_audio_service.dart';
import '../../../services/pitch/microphone_pitch_service.dart';
import '../../access/application/access_providers.dart';
import '../../range/application/range_providers.dart';
import '../../trainer/presentation/controllers/trainer_controller.dart';
import '../domain/tessitura.dart';
import 'tessitura_providers.dart';

enum TessituraPhase {
  intro,

  /// Senza un test di estensione: il cantante tiene una nota comoda, che
  /// diventa il centro della ricerca.
  findingStart,

  /// Una prova: pausa, nota guida, attesa della voce, canto.
  attempt,

  /// "Quanto sforzo ti è costato?" (1–5, si può saltare).
  rating,

  /// Sforzo eccessivo segnalato: tornare a note comode o terminare.
  strainChoice,

  /// Proposta della verifica melodica facoltativa.
  melodicOffer,
  done,
}

/// Momenti di una prova.
enum AttemptStep {
  /// Breve pausa per respirare e leggere l'istruzione.
  ready,

  /// Suona la nota di riferimento (il microfono non la valuta).
  guide,

  /// In attesa che l'utente inizi a cantare.
  waiting,
  singing,
}

enum TessituraMessage {
  microphoneDenied,
  audioUnavailable,

  /// Nemmeno sulla nota di partenza la voce è stata sentita bene.
  cannotCalibrate,

  /// Il microfono si è interrotto durante il test.
  interrupted,
}

class TessituraTestState {
  const TessituraTestState({
    required this.phase,
    required this.attempts,
    this.step,
    this.attemptStep = AttemptStep.ready,
    this.progress = 0,
    this.detected,
    this.startHoldProgress = 0,
    this.registerShift = false,
    this.lastOutcome,
    this.estimate,
    this.record,
    this.previous,
    this.message,
    this.hasRange = false,
  });

  final TessituraPhase phase;
  final List<TessituraAttempt> attempts;

  /// Prova in corso (o appena cantata, durante la valutazione dello sforzo).
  final TessituraStep? step;
  final AttemptStep attemptStep;

  /// Avanzamento (0–1) del canto della prova in corso.
  final double progress;
  final PitchDetectionResult? detected;
  final double startHoldProgress;

  /// Cambio di registro segnalato per la prova in corso.
  final bool registerShift;

  /// Esito della prova precedente, per il riscontro immediato.
  final AttemptOutcome? lastOutcome;

  /// Stima e record salvato a fine test (record null se non c'erano dati).
  final TessituraEstimate? estimate;
  final TessituraRecord? record;

  /// Test precedente, per il confronto.
  final TessituraRecord? previous;
  final TessituraMessage? message;

  /// C'è un test di estensione da usare come riferimento.
  final bool hasRange;

  int? get targetMidi => step?.midi;

  TessituraTestState copyWith({
    TessituraPhase? phase,
    List<TessituraAttempt>? attempts,
    TessituraStep? step,
    AttemptStep? attemptStep,
    double? progress,
    PitchDetectionResult? detected,
    bool clearDetected = false,
    double? startHoldProgress,
    bool? registerShift,
    AttemptOutcome? lastOutcome,
    TessituraEstimate? estimate,
    TessituraRecord? record,
    TessituraMessage? message,
    bool clearMessage = false,
  }) {
    return TessituraTestState(
      phase: phase ?? this.phase,
      attempts: attempts ?? this.attempts,
      step: step ?? this.step,
      attemptStep: attemptStep ?? this.attemptStep,
      progress: progress ?? this.progress,
      detected: clearDetected ? null : detected ?? this.detected,
      startHoldProgress: startHoldProgress ?? this.startHoldProgress,
      registerShift: registerShift ?? this.registerShift,
      lastOutcome: lastOutcome ?? this.lastOutcome,
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

/// Test guidato della tessitura (vedi [TessituraPlanner] e
/// [TessituraEstimate]): una nota alla volta, con la nota di riferimento del
/// piano, l'ascolto dei frame validati del microfono e, dopo alcune prove, la
/// domanda sullo sforzo percepito. Riusa microfono e piano dell'app.
class TessituraTestController extends Notifier<TessituraTestState> {
  static const _guideNoteDuration = Duration(milliseconds: 650);
  static const _detectionMuteTail = Duration(milliseconds: 450);

  /// Pausa prima di ogni prova (respiro, lettura dell'istruzione).
  static const readyPause = Duration(milliseconds: 700);

  /// Attesa massima della voce dopo la nota guida: poi la prova non è
  /// valutabile (non "non riuscita").
  static const voiceTimeout = Duration(seconds: 4);

  /// Silenzio dopo l'attacco che chiude la prova prima del tempo.
  static const endSilence = Duration(milliseconds: 1500);

  /// Nota comoda da tenere per partire senza test di estensione.
  static const startHold = Duration(milliseconds: 800);

  late MicrophonePitchService _microphone;
  late PianoAudioService _audio;
  StreamSubscription<PitchDetectionResult>? _subscription;
  TessituraPlanner? _planner;
  int? _rangeLow;
  int? _rangeHigh;
  bool? _melodic;

  /// Incrementato a ogni avvio, annullamento e dispose (avvii superati).
  int _generation = 0;

  // Prova in corso.
  DateTime _phaseUntil = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _waitingSince;
  DateTime? _onset;
  DateTime? _lastVoiced;
  final _frames = <PitchFrame>[];

  /// Validazione temporale dei frame (stessa di esercizi e accordatore).
  final _validator = PitchStabilizer();
  TessituraAttempt? _pending;

  // Ricerca della nota di partenza.
  final _startStabilizer = PitchStabilizer();
  MusicalNote? _startCandidate;
  DateTime? _startCandidateSince;

  DateTime get _now => ref.read(clockProvider)();

  @override
  TessituraTestState build() {
    _microphone = ref.read(microphonePitchServiceProvider);
    _audio = ref.read(pianoAudioServiceProvider);
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
      attempts: const [],
      previous: history.isNotEmpty ? history.last : null,
      hasRange: range != null && range.spanSemitones >= 7,
    );
  }

  /// Avvia il test: con un test di estensione parte dal suo terzo inferiore
  /// (dove la voce di solito è comoda), altrimenti da una nota comoda tenuta.
  Future<void> start() async {
    final generation = ++_generation;
    _melodic = null;
    _pending = null;
    state = TessituraTestState(
      phase: state.hasRange ? TessituraPhase.attempt : TessituraPhase.findingStart,
      attempts: const [],
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
      _subscription = _microphone.pitchStream.listen(_handlePitch, onError: _onAudioError);
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
    _advance();
  }

  /// Chiede al piano la prossima prova.
  void _advance() {
    final planner = _planner;
    if (planner == null) {
      return;
    }
    final plan = planner.next(state.attempts, melodic: _melodic);
    switch (plan.kind) {
      case PlanKind.attempt:
        _startAttempt(plan.step!);
      case PlanKind.offerMelodic:
        state = state.copyWith(phase: TessituraPhase.melodicOffer, clearDetected: true);
      case PlanKind.finished:
        unawaited(finish());
      case PlanKind.cannotCalibrate:
        // Dati non affidabili: non si salva nulla.
        unawaited(_abort(TessituraMessage.cannotCalibrate));
    }
  }

  void _startAttempt(TessituraStep step) {
    _frames.clear();
    _validator.reset();
    _waitingSince = null;
    _onset = null;
    _lastVoiced = null;
    final pause = step.stage == TessituraStage.melodic ? Duration.zero : readyPause;
    _phaseUntil = _now.add(pause);
    state = state.copyWith(
      phase: TessituraPhase.attempt,
      step: step,
      attemptStep: AttemptStep.ready,
      progress: 0,
      registerShift: false,
      clearDetected: true,
    );
    if (pause == Duration.zero) {
      _playGuide();
    }
  }

  void _playGuide() {
    _phaseUntil = _now.add(_guideNoteDuration + _detectionMuteTail);
    state = state.copyWith(attemptStep: AttemptStep.guide);
    unawaited(
        _audio.playNote(MusicalNote.fromMidi(state.targetMidi!), duration: _guideNoteDuration));
  }

  /// Riascolta la nota di riferimento (solo prima di iniziare a cantare).
  void replayNote() {
    if (state.phase == TessituraPhase.attempt && state.attemptStep == AttemptStep.waiting) {
      _frames.clear();
      _playGuide();
    }
  }

  void _handlePitch(PitchDetectionResult detection) {
    final now = _now;
    switch (state.phase) {
      case TessituraPhase.findingStart:
        _handleStart(detection, now);
      case TessituraPhase.attempt:
        _handleAttempt(detection, now);
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
      _beginSearch(center, center - 18, center + 18);
    }
  }

  void _handleAttempt(PitchDetectionResult detection, DateTime now) {
    switch (state.attemptStep) {
      case AttemptStep.ready:
        if (!now.isBefore(_phaseUntil)) {
          _playGuide();
        }
      case AttemptStep.guide:
        if (!now.isBefore(_phaseUntil)) {
          _waitingSince = now;
          _frames.clear();
          state = state.copyWith(attemptStep: AttemptStep.waiting);
        }
      case AttemptStep.waiting:
        final validated = _record(detection, now);
        if (_isVoiced(validated)) {
          _onset = now;
          _lastVoiced = now;
          state = state.copyWith(attemptStep: AttemptStep.singing);
        } else if (now.difference(_waitingSince!) >= voiceTimeout) {
          _completeAttempt();
        }
      case AttemptStep.singing:
        final validated = _record(detection, now);
        if (_isVoiced(validated)) {
          _lastVoiced = now;
        }
        final elapsed = now.difference(_onset!);
        final duration = state.step!.duration;
        state = state.copyWith(
          progress: (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0),
        );
        if (elapsed >= duration || now.difference(_lastVoiced!) >= endSilence) {
          _completeAttempt();
        }
    }
  }

  static bool _isVoiced(PitchDetectionResult detection) =>
      detection.isStable && detection.frequency > 0;

  /// Registra il frame già validato dalla pipeline comune (rilevatore con
  /// verifica dell'ottava + stabilizzatore): un errore d'ottava isolato non
  /// entra nelle misure della prova. Ritorna il frame validato.
  PitchDetectionResult _record(PitchDetectionResult detection, DateTime now) {
    final validated = _validator.process(detection, now);
    // Tempo in frame (uno ogni ~23 ms, silenzio compreso): i frame arrivano
    // a gruppi e l'orologio sottostimerebbe le durate.
    _frames.add(PitchFrame(
      atMs: (_frames.length * MicrophonePitchService.hopMs).round(),
      frequency: validated.frequency,
      confidence: validated.confidence,
      voiced: _isVoiced(validated),
    ));
    state = state.copyWith(
        detected: validated.isStable ? validated : null, clearDetected: !validated.isStable);
    return validated;
  }

  /// Fine della nota tenuta prima del tempo ("Basta così").
  void endNote() {
    if (state.phase == TessituraPhase.attempt && state.attemptStep == AttemptStep.singing) {
      _completeAttempt();
    }
  }

  void _completeAttempt() {
    final step = state.step!;
    final measure = AttemptMeasure.analyze(_frames, step.midi);
    final attempt = TessituraAttempt(
      stage: step.stage,
      targetMidi: step.midi,
      direction: step.direction,
      outcome: measure.classify(step.duration),
      measure: measure,
      registerShift: state.registerShift,
    );
    if (step.askEffort && attempt.valid) {
      _pending = attempt;
      state = state.copyWith(
          phase: TessituraPhase.rating, lastOutcome: attempt.outcome, clearDetected: true);
      return;
    }
    _commit(attempt);
  }

  void _commit(TessituraAttempt attempt) {
    state = state.copyWith(attempts: [...state.attempts, attempt], lastOutcome: attempt.outcome);
    _advance();
  }

  /// Sforzo percepito della prova appena cantata; null = saltato.
  void rate(EffortRating? effort) {
    final pending = _pending;
    if (state.phase != TessituraPhase.rating || pending == null) {
      return;
    }
    _pending = null;
    _commit(pending.withEffort(effort));
  }

  /// "Salta nota": la prova non è completata (non conta come fallita).
  void skipNote() {
    final step = state.step;
    if (state.phase != TessituraPhase.attempt || step == null) {
      return;
    }
    _commit(TessituraAttempt(
      stage: step.stage,
      targetMidi: step.midi,
      direction: step.direction,
      outcome: AttemptOutcome.interrupted,
    ));
  }

  /// Sforzo eccessivo o fastidio: la prova si interrompe, la direzione (o la
  /// nota) non si prosegue e si propone di tornare a note comode o finire.
  void reportStrain() {
    final step = state.step;
    if (state.phase != TessituraPhase.attempt || step == null) {
      return;
    }
    state = state.copyWith(
      attempts: [
        ...state.attempts,
        TessituraAttempt(
          stage: step.stage,
          targetMidi: step.midi,
          direction: step.direction,
          outcome: AttemptOutcome.interrupted,
          effort: EffortRating.veryHard,
          registerShift: state.registerShift,
          strain: true,
        ),
      ],
      phase: TessituraPhase.strainChoice,
      lastOutcome: AttemptOutcome.interrupted,
      clearDetected: true,
    );
  }

  /// Dopo lo sforzo eccessivo: si continua da note comode.
  void continueAfterStrain() {
    if (state.phase == TessituraPhase.strainChoice) {
      _advance();
    }
  }

  /// Cambio di registro percepito durante la prova in corso.
  void toggleRegisterShift() {
    if (state.phase == TessituraPhase.attempt) {
      state = state.copyWith(registerShift: !state.registerShift);
    }
  }

  /// Risposta alla proposta della verifica melodica.
  void chooseMelodic(bool accepted) {
    if (state.phase != TessituraPhase.melodicOffer) {
      return;
    }
    _melodic = accepted;
    _advance();
  }

  /// Chiude il test con le prove fatte finora. Salva il risultato se c'è
  /// almeno una prova valida (anche se la stima è insufficiente).
  Future<void> finish() async {
    if (state.phase == TessituraPhase.intro || state.phase == TessituraPhase.done) {
      return;
    }
    final estimate = TessituraEstimate.from(state.attempts);
    if (estimate.validAttempts == 0) {
      state = state.copyWith(phase: TessituraPhase.done, estimate: estimate, clearDetected: true);
      await _stopAudio();
      return;
    }
    final record = TessituraRecord.fromEstimate(timestamp: _now, estimate: estimate);
    // Prima il risultato (e il salvataggio), poi il rilascio di microfono e
    // piano: un rilascio lento non deve far perdere il test.
    state = state.copyWith(
        phase: TessituraPhase.done, estimate: estimate, record: record, clearDetected: true);
    await ref.read(tessituraHistoryProvider.notifier).add(record);
    await _stopAudio();
  }

  /// Microfono perso durante il test: si chiude con i dati raccolti.
  void _onAudioError(Object error) {
    if (state.phase == TessituraPhase.intro || state.phase == TessituraPhase.done) {
      return;
    }
    state = state.copyWith(message: TessituraMessage.interrupted);
    unawaited(finish());
  }

  Future<void> _abort(TessituraMessage message) async {
    await _stopAudio();
    if (!ref.mounted) {
      return;
    }
    state = TessituraTestState(
      phase: TessituraPhase.intro,
      attempts: const [],
      previous: state.previous,
      hasRange: state.hasRange,
      message: message,
    );
  }

  /// Annulla senza salvare.
  Future<void> cancel() async {
    await _stopAudio();
    if (!ref.mounted) {
      return;
    }
    state = TessituraTestState(
      phase: TessituraPhase.intro,
      attempts: const [],
      previous: state.previous,
      hasRange: state.hasRange,
    );
  }

  Future<void> _stopAudio() async {
    _generation++;
    _planner = null;
    _pending = null;
    // Prima microfono e piano: le risorse si rilasciano subito, anche se la
    // chiusura dell'ascolto tarda.
    final subscription = _subscription;
    _subscription = null;
    await _microphone.stop();
    await _audio.stopAll();
    await subscription?.cancel();
  }
}
