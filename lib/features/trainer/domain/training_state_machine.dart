import '../../../core/music/note.dart';
import '../../../core/pitch/pitch_detection_result.dart';

enum TrainingValidationState { waitNote, waitChange, waitRetry }

enum TrainingValidationEvent { none, correct, wrong, advanced }

class TrainingValidationOutput {
  const TrainingValidationOutput({
    required this.state,
    required this.event,
    required this.detected,
    required this.isCorrect,
    required this.canAdvance,
  });

  final TrainingValidationState state;
  final TrainingValidationEvent event;
  final PitchDetectionResult? detected;
  final bool isCorrect;
  final bool canAdvance;
}

class TrainingStateMachine {
  TrainingStateMachine({
    required this.toleranceCents,
    required this.stabilityMs,
    this.breakMs = 150,
  });

  final int toleranceCents;
  final int stabilityMs;

  /// Millisecondi di segnale instabile/silenzio necessari perché uno stacco
  /// venga riconosciuto come "pausa": permette di riattaccare la STESSA nota
  /// (sequenze con note ripetute, prova di estensione, ecc.).
  final int breakMs;

  TrainingValidationState _state = TrainingValidationState.waitNote;
  MusicalNote? _lastAcceptedNote;
  MusicalNote? _candidateNote;
  DateTime? _candidateSince;
  DateTime? _unstableSince;
  bool _breakSinceAccept = false;

  TrainingValidationState get state => _state;

  void reset() {
    _state = TrainingValidationState.waitNote;
    _lastAcceptedNote = null;
    _candidateNote = null;
    _candidateSince = null;
    _unstableSince = null;
    _breakSinceAccept = false;
  }

  TrainingValidationOutput evaluate({
    required MusicalNote target,
    required PitchDetectionResult detected,
    required DateTime now,
  }) {
    // La soglia di confidenza è decisa dal rilevatore (isStable): quello
    // per la banda bassa/fry usa un gate più permissivo.
    if (!detected.isStable) {
      _candidateNote = null;
      _candidateSince = null;
      _unstableSince ??= now;
      if (now.difference(_unstableSince!).inMilliseconds >= breakMs) {
        _breakSinceAccept = true;
      }
      return _output(TrainingValidationEvent.none, detected, false, false);
    }

    _unstableSince = null;

    final stableEnough = _isStableLongEnough(detected.note, now);
    if (!stableEnough) {
      return _output(TrainingValidationEvent.none, detected, false, false);
    }

    return switch (_state) {
      TrainingValidationState.waitNote => _handleWaitNote(target, detected),
      TrainingValidationState.waitChange => _handleWaitChange(detected),
      TrainingValidationState.waitRetry => _handleWaitRetry(target, detected),
    };
  }

  void markAdvanced() {
    _state = TrainingValidationState.waitNote;
    _candidateNote = null;
    _candidateSince = null;
    _breakSinceAccept = false;
  }

  bool _isStableLongEnough(MusicalNote note, DateTime now) {
    if (_candidateNote != note) {
      _candidateNote = note;
      _candidateSince = now;
      return false;
    }

    final since = _candidateSince;
    return since != null && now.difference(since).inMilliseconds >= stabilityMs;
  }

  TrainingValidationOutput _handleWaitNote(MusicalNote target, PitchDetectionResult detected) {
    final isCorrect = detected.note == target && detected.cents.abs() <= toleranceCents;
    if (isCorrect) {
      _lastAcceptedNote = detected.note;
      _state = TrainingValidationState.waitChange;
      _breakSinceAccept = false;
      return _output(TrainingValidationEvent.correct, detected, true, true);
    }

    _lastAcceptedNote = detected.note;
    _state = TrainingValidationState.waitRetry;
    _breakSinceAccept = false;
    return _output(TrainingValidationEvent.wrong, detected, false, false);
  }

  TrainingValidationOutput _handleWaitChange(PitchDetectionResult detected) {
    // Si avanza cambiando nota, oppure riattaccando la STESSA nota dopo
    // una pausa (respiro/stacco): serve per le sequenze con note ripetute.
    if (detected.note == _lastAcceptedNote && !_breakSinceAccept) {
      return _output(TrainingValidationEvent.none, detected, true, false);
    }

    _lastAcceptedNote = detected.note;
    _breakSinceAccept = false;
    return _output(TrainingValidationEvent.advanced, detected, true, true);
  }

  TrainingValidationOutput _handleWaitRetry(MusicalNote target, PitchDetectionResult detected) {
    if (detected.note == _lastAcceptedNote && !_breakSinceAccept) {
      return _output(TrainingValidationEvent.none, detected, false, false);
    }

    _state = TrainingValidationState.waitNote;
    _lastAcceptedNote = detected.note;
    _breakSinceAccept = false;
    final isCorrect = detected.note == target && detected.cents.abs() <= toleranceCents;
    if (isCorrect) {
      _state = TrainingValidationState.waitChange;
      return _output(TrainingValidationEvent.correct, detected, true, true);
    }

    _state = TrainingValidationState.waitRetry;
    return _output(TrainingValidationEvent.wrong, detected, false, false);
  }

  TrainingValidationOutput _output(
    TrainingValidationEvent event,
    PitchDetectionResult? detected,
    bool isCorrect,
    bool canAdvance,
  ) {
    return TrainingValidationOutput(
      state: _state,
      event: event,
      detected: detected,
      isCorrect: isCorrect,
      canAdvance: canAdvance,
    );
  }
}
