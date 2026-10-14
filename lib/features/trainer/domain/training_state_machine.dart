import '../../../core/music/note.dart';
import '../../../core/pitch/pitch_detection_result.dart';
import '../../../core/pitch/pitch_recognition_config.dart';
import '../../../core/pitch/pitch_stabilizer.dart';

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
    PitchRecognitionConfig recognition = PitchRecognitionConfig.standard,
  }) : _stabilizer = PitchStabilizer(config: recognition);

  /// Distanza massima (in cent) dal centro della nota richiesta perché sia
  /// corretta. Valuta l'esercizio, non il riconoscimento della nota.
  final int toleranceCents;

  /// Tempo per cui la nota riconosciuta deve restare la stessa prima di
  /// essere valutata.
  final int stabilityMs;

  /// Millisecondi di segnale instabile/silenzio necessari perché uno stacco
  /// venga riconosciuto come "pausa": permette di riattaccare la STESSA nota
  /// (sequenze con note ripetute, prova di estensione, ecc.).
  final int breakMs;

  /// Riconoscimento della nota (mediana, vibrato, cadute brevi).
  final PitchStabilizer _stabilizer;

  TrainingValidationState _state = TrainingValidationState.waitNote;
  MusicalNote? _lastAcceptedNote;
  MusicalNote? _candidateNote;
  DateTime? _candidateSince;

  /// Altezze (in semitoni MIDI frazionari) cantate da quando la nota
  /// candidata è stabile: la valutazione usa la loro media, così il
  /// vibrato non fa fallire una nota intonata in media.
  final List<double> _candidateMidi = [];
  static const _maxCandidateFrames = 64;
  DateTime? _unstableSince;
  bool _breakSinceAccept = false;

  TrainingValidationState get state => _state;

  void reset() {
    _state = TrainingValidationState.waitNote;
    _lastAcceptedNote = null;
    _clearCandidate();
    _unstableSince = null;
    _breakSinceAccept = false;
    _stabilizer.reset();
  }

  /// Valuta un frame del rilevatore. `detected` nell'output è il risultato
  /// stabilizzato (nota riconosciuta e scostamento da questa); durante le
  /// cadute brevi l'ultima nota riconosciuta, in silenzio il frame grezzo.
  TrainingValidationOutput evaluate({
    required MusicalNote target,
    required PitchDetectionResult detected,
    required DateTime now,
  }) {
    // La soglia di confidenza è decisa dal rilevatore (isStable): quello
    // per la banda bassa/fry usa un gate più permissivo.
    final recognized = _stabilizer.process(detected, now);
    if (!recognized.isStable) {
      _unstableSince ??= now;
      final unstableMs = now.difference(_unstableSince!).inMilliseconds;
      // Una caduta breve (consonante, frame incerto) non azzera la nota in
      // corso; una più lunga sì, e oltre breakMs vale come stacco.
      if (unstableMs > _stabilizer.config.dropoutGraceMs) {
        _clearCandidate();
      }
      if (unstableMs >= breakMs) {
        _breakSinceAccept = true;
      }
      // Durante una caduta breve resta visibile l'ultima nota riconosciuta.
      return _output(TrainingValidationEvent.none, _stabilizer.current ?? recognized, false, false);
    }

    _unstableSince = null;

    final stableEnough = _isStableLongEnough(recognized, now);
    if (!stableEnough) {
      return _output(TrainingValidationEvent.none, recognized, false, false);
    }

    return switch (_state) {
      TrainingValidationState.waitNote => _handleWaitNote(target, recognized),
      TrainingValidationState.waitChange => _handleWaitChange(recognized),
      TrainingValidationState.waitRetry => _handleWaitRetry(target, recognized),
    };
  }

  void markAdvanced() {
    _state = TrainingValidationState.waitNote;
    _clearCandidate();
    _breakSinceAccept = false;
  }

  void _clearCandidate() {
    _candidateNote = null;
    _candidateSince = null;
    _candidateMidi.clear();
  }

  bool _isStableLongEnough(PitchDetectionResult recognized, DateTime now) {
    final midi = recognized.note.midiNumber + recognized.cents / 100;
    if (_candidateNote != recognized.note) {
      _clearCandidate();
      _candidateNote = recognized.note;
      _candidateSince = now;
      _candidateMidi.add(midi);
      return false;
    }

    _candidateMidi.add(midi);
    if (_candidateMidi.length > _maxCandidateFrames) {
      // Nota tenuta a lungo: basta la parte più recente.
      _candidateMidi.removeAt(0);
    }
    final since = _candidateSince;
    return since != null && now.difference(since).inMilliseconds >= stabilityMs;
  }

  /// Nota corretta: è quella richiesta e, in media sulla finestra di
  /// stabilità, l'altezza resta entro [toleranceCents] dal suo centro.
  bool _matchesTarget(MusicalNote target, PitchDetectionResult recognized) {
    if (recognized.note != target || _candidateMidi.isEmpty) {
      return false;
    }
    final mean = _candidateMidi.reduce((a, b) => a + b) / _candidateMidi.length;
    // Il margine di 1e-6 assorbe gli arrotondamenti: il confine è incluso.
    return ((mean - target.midiNumber) * 100).abs() <= toleranceCents + 1e-6;
  }

  TrainingValidationOutput _handleWaitNote(MusicalNote target, PitchDetectionResult detected) {
    final isCorrect = _matchesTarget(target, detected);
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
    final isCorrect = _matchesTarget(target, detected);
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
