import 'dart:math' as math;

// Test della tessitura: modello, analisi delle prove, pianificazione delle
// fasi e stima. Tutto deterministico e senza I/O.
//
// Cosa misura davvero il rilevatore (YinPitchDetector tramite
// MicrophonePitchService): un frame ogni ~23 ms (finestra di 2048 campioni a
// 44,1 kHz con sovrapposizione del 50%) con frequenza fondamentale,
// confidenza (1 − aperiodicità YIN) e un flag "stabile" (confidenza ≥ 0,82,
// o ≥ 0,60 nella banda bassa sotto i 250 Hz). Il silenzio arriva come frame
// a confidenza 0. Non sono disponibili volume (RMS), spettro o altre
// caratteristiche del timbro: precisione, stabilità, tenuta e qualità del
// segnale sono ricavate soltanto dalla sequenza di frequenze e confidenze, e
// il registro (voce piena, mista, falsetto) non è riconoscibile.

/// Fasi del test.
enum TessituraStage {
  /// Riscaldamento: una nota centrale da ripetere per verificare che il
  /// microfono senta bene la voce.
  calibration,

  /// Esplorazione per semitoni verso l'acuto e verso il grave.
  explore,

  /// Tenuta: alcune note mantenute per circa 6 secondi.
  hold,

  /// Ripetibilità: note vicino ai bordi cantate più volte.
  repeat,

  /// Verifica melodica facoltativa: una breve frase nella zona trovata.
  melodic,
}

/// Esito di una prova.
enum AttemptOutcome {
  /// Valida e riuscita: nota raggiunta, centrata, stabile e tenuta abbastanza.
  success,

  /// Valida ma non riuscita: il segnale era buono, la nota no.
  failed,

  /// Non valida: segnale insufficiente o inaffidabile (non si sa se la nota
  /// sia riuscita). Non conta mai come fallimento.
  invalid,

  /// Non completata: saltata o interrotta dall'utente.
  interrupted,
}

/// Sforzo percepito dichiarato dall'utente (1–5).
enum EffortRating {
  veryEasy(1),
  easy(2),
  moderate(3),
  hard(4),
  veryHard(5);

  const EffortRating(this.value);

  final int value;

  static EffortRating? fromValue(int? value) =>
      EffortRating.values.where((rating) => rating.value == value).firstOrNull;
}

/// Soglie dell'analisi, motivate dal comportamento del rilevatore. Tutte
/// configurabili; i valori predefiniti sono verificati dai test.
class TessituraThresholds {
  const TessituraThresholds({
    this.toleranceCents = 40,
    this.reachMs = 150,
    this.dropoutGraceMs = 120,
    this.minVoicedMs = 500,
    this.successHoldFraction = 0.6,
    this.maxCenterCents = 30,
    this.maxDriftCents = 15,
    this.smoothingMs = 200,
    this.notSustainedSpreadCents = 250,
    this.maxAnomalyRatio = 0.3,
    this.maxFrameGapMs = 60,
  });

  static const standard = TessituraThresholds();

  /// Distanza massima dalla nota richiesta: la stessa del test di estensione
  /// (PitchRecognitionConfig.rangeTestToleranceCents). Anche ben cantata, la
  /// voce oscilla di 20–30 cent.
  final int toleranceCents;

  /// Tempo continuo sulla nota perché sia "raggiunta" (≈ 6–7 frame): esclude
  /// il semplice passaggio durante una scivolata. Come stabilityMs del test
  /// di estensione.
  final int reachMs;

  /// Brevi cadute del segnale (consonanti, respiro, un frame a confidenza
  /// bassa) che non interrompono una tenuta. Poco sopra il
  /// PitchStabilizer (100 ms).
  final int dropoutGraceMs;

  /// Sotto mezzo secondo di frame con voce (≈ 20 frame) il rilevatore non ha
  /// sentito abbastanza: la prova non è valutabile.
  final int minVoicedMs;

  /// Frazione della durata richiesta da tenere sulla nota perché la prova
  /// riesca (3 s → 1,8 s; 6 s → 3,6 s): tiene conto di attacco e fine.
  final double successHoldFraction;

  /// Mediana dello scostamento entro cui la nota è centrata.
  final int maxCenterCents;

  /// Deviazione standard dell'altezza dopo una media mobile di
  /// [smoothingMs]: il vibrato naturale (5–7 Hz, periodo 140–200 ms) viene
  /// in gran parte assorbito dalla media (residuo ≈ 5 cent con ±60 cent di
  /// vibrato), restano le derive lente e le oscillazioni irregolari: 15 cent
  /// di deviazione corrispondono a una deriva di circa ±25 cent. È un'approssimazione: con un vibrato molto
  /// lento o ampio la stabilità risulta peggiore del reale.
  final int maxDriftCents;
  final int smoothingMs;

  /// Dispersione oltre la quale i frame con voce non descrivono una nota
  /// tenuta (parlato, rumore, scivolate continue): prova non valida, se la
  /// nota non è mai stata raggiunta.
  final int notSustainedSpreadCents;

  /// Frazione di frame a un'ottava esatta dalla nota (tipico errore d'ottava
  /// di YIN) oltre cui il rilevamento di quella nota è inaffidabile.
  final double maxAnomalyRatio;

  /// Durata massima attribuita a un singolo frame (il passo atteso è ~23 ms):
  /// un buco nei frame non diventa tempo cantato.
  final int maxFrameGapMs;
}

/// Un frame del rilevatore durante una prova, con il tempo dall'inizio
/// dell'ascolto.
class PitchFrame {
  const PitchFrame({
    required this.atMs,
    required this.frequency,
    required this.confidence,
    required this.voiced,
  });

  final int atMs;
  final double frequency;
  final double confidence;

  /// Frame stabile secondo il rilevatore (voce periodica).
  final bool voiced;
}

double midiOfFrequency(double frequency) => 69 + 12 * math.log(frequency / 440) / math.ln2;

/// Misure di una prova ricavate dai frame.
class AttemptMeasure {
  const AttemptMeasure({
    required this.voicedMs,
    required this.meanConfidence,
    required this.anomalyRatio,
    required this.spreadCents,
    required this.reached,
    required this.holdMs,
    this.medianCents,
    this.driftCents,
    this.sungMidi,
  });

  /// Tempo con voce rilevata.
  final int voicedMs;

  /// Confidenza media dei frame con voce (qualità del segnale).
  final double meanConfidence;

  /// Frazione di frame con voce a un'ottava dalla nota (errori d'ottava).
  final double anomalyRatio;

  /// Dispersione (deviazione standard, cent) dei frame con voce.
  final double spreadCents;

  /// Nota raggiunta per almeno [TessituraThresholds.reachMs].
  final bool reached;

  /// Tenuta più lunga sulla nota (entro la tolleranza, cadute brevi incluse).
  final int holdMs;

  /// Mediana dello scostamento (cent) durante la tenuta più lunga.
  final double? medianCents;

  /// Stabilità: deviazione standard dell'altezza smussata durante la tenuta.
  final double? driftCents;

  /// Nota cantata più spesso (MIDI), anche se diversa da quella richiesta.
  final int? sungMidi;

  static AttemptMeasure analyze(
    List<PitchFrame> frames,
    int targetMidi, {
    TessituraThresholds thresholds = TessituraThresholds.standard,
  }) {
    final t = thresholds;
    final voiced = [
      for (final frame in frames)
        if (frame.voiced && frame.frequency > 0) frame,
    ];
    int frameMs(int index, List<PitchFrame> list) {
      if (index + 1 < list.length) {
        return math.min(t.maxFrameGapMs, list[index + 1].atMs - list[index].atMs);
      }
      return 23;
    }

    var voicedMs = 0;
    for (var i = 0; i < voiced.length; i++) {
      voicedMs += frameMs(i, voiced);
    }
    if (voiced.isEmpty) {
      return AttemptMeasure(
        voicedMs: 0,
        meanConfidence: 0,
        anomalyRatio: 0,
        spreadCents: 0,
        reached: false,
        holdMs: 0,
      );
    }
    final cents = [for (final f in voiced) (midiOfFrequency(f.frequency) - targetMidi) * 100];
    final anomalies =
        cents.where((c) => (c.abs() - 1200).abs() <= 150 || (c.abs() - 2400).abs() <= 150).length;
    final mean = cents.reduce((a, b) => a + b) / cents.length;
    final spread =
        math.sqrt(cents.map((c) => (c - mean) * (c - mean)).reduce((a, b) => a + b) / cents.length);
    final rounded = <int, int>{};
    for (final c in cents) {
      final midi = targetMidi + (c / 100).round();
      rounded[midi] = (rounded[midi] ?? 0) + 1;
    }
    final sungMidi = rounded.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // Tratti sulla nota: frame entro la tolleranza; cadute brevi (frame
    // senza voce o fuori tolleranza per meno di dropoutGraceMs) li uniscono.
    var bestStart = -1;
    var bestEnd = -1;
    var bestMs = 0;
    int? runStart;
    int? lastOn;
    void close() {
      if (runStart != null && lastOn != null) {
        final ms = frames[lastOn!].atMs - frames[runStart!].atMs + 23;
        if (ms > bestMs) {
          bestMs = ms;
          bestStart = runStart!;
          bestEnd = lastOn!;
        }
      }
      runStart = null;
      lastOn = null;
    }

    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final on = frame.voiced &&
          frame.frequency > 0 &&
          ((midiOfFrequency(frame.frequency) - targetMidi) * 100).abs() <= t.toleranceCents;
      if (on) {
        if (runStart != null && frame.atMs - frames[lastOn!].atMs > t.dropoutGraceMs) {
          close();
        }
        runStart ??= i;
        lastOn = i;
      }
    }
    close();

    double? median;
    double? drift;
    if (bestStart >= 0) {
      final run = [
        for (var i = bestStart; i <= bestEnd; i++)
          if (frames[i].voiced && frames[i].frequency > 0)
            (
              at: frames[i].atMs,
              c: (midiOfFrequency(frames[i].frequency) - targetMidi) * 100,
            ),
      ];
      final inTolerance = [
        for (final p in run)
          if (p.c.abs() <= t.toleranceCents) p.c,
      ]..sort();
      median = inTolerance[inTolerance.length ~/ 2];
      // Media mobile su smoothingMs: assorbe il vibrato, restano le derive.
      final smoothed = <double>[];
      for (final p in run) {
        final window = run.where((q) => (q.at - p.at).abs() <= t.smoothingMs ~/ 2);
        smoothed.add(window.map((q) => q.c).reduce((a, b) => a + b) / window.length);
      }
      final m = smoothed.reduce((a, b) => a + b) / smoothed.length;
      drift = math
          .sqrt(smoothed.map((s) => (s - m) * (s - m)).reduce((a, b) => a + b) / smoothed.length);
    }

    return AttemptMeasure(
      voicedMs: voicedMs,
      meanConfidence: voiced.map((f) => f.confidence).reduce((a, b) => a + b) / voiced.length,
      anomalyRatio: anomalies / voiced.length,
      spreadCents: spread,
      reached: bestMs >= t.reachMs,
      holdMs: bestMs,
      medianCents: median,
      driftCents: drift,
      sungMidi: sungMidi,
    );
  }

  /// Classifica la prova: [required] è la durata richiesta della tenuta.
  AttemptOutcome classify(
    Duration required, {
    TessituraThresholds thresholds = TessituraThresholds.standard,
  }) {
    final t = thresholds;
    if (voicedMs < t.minVoicedMs) {
      return AttemptOutcome.invalid;
    }
    if (anomalyRatio > t.maxAnomalyRatio) {
      return AttemptOutcome.invalid;
    }
    if (!reached && spreadCents > t.notSustainedSpreadCents) {
      return AttemptOutcome.invalid;
    }
    final heldEnough = holdMs >= required.inMilliseconds * t.successHoldFraction;
    final centred = (medianCents?.abs() ?? 999) <= t.maxCenterCents;
    final stable = (driftCents ?? 999) <= t.maxDriftCents;
    return reached && heldEnough && centred && stable
        ? AttemptOutcome.success
        : AttemptOutcome.failed;
  }
}

/// Una prova del test.
class TessituraAttempt {
  const TessituraAttempt({
    required this.stage,
    required this.targetMidi,
    required this.outcome,
    this.direction = 0,
    this.measure,
    this.effort,
    this.registerShift = false,
    this.strain = false,
  });

  final TessituraStage stage;
  final int targetMidi;
  final AttemptOutcome outcome;

  /// +1 verso l'acuto, −1 verso il grave, 0 fuori dall'esplorazione.
  final int direction;
  final AttemptMeasure? measure;

  /// Sforzo dichiarato dopo la prova; null = non chiesto o saltato.
  final EffortRating? effort;

  /// L'utente ha segnalato di aver cambiato registro.
  final bool registerShift;

  /// L'utente ha segnalato sforzo eccessivo o fastidio (prova interrotta).
  final bool strain;

  bool get valid => outcome == AttemptOutcome.success || outcome == AttemptOutcome.failed;

  TessituraAttempt withEffort(EffortRating? rating) => TessituraAttempt(
        stage: stage,
        targetMidi: targetMidi,
        outcome: outcome,
        direction: direction,
        measure: measure,
        effort: rating,
        registerShift: registerShift,
        strain: strain,
      );
}

/// Perché si fa la prossima prova: guida il messaggio mostrato.
enum TessituraCue {
  calibrate,

  /// Nota di partenza spostata su quella che l'utente canta con naturalezza.
  recenter,
  notHeard,
  retry,
  stepUp,
  stepDown,

  /// La direzione precedente è finita: si riparte da note comode.
  backToComfort,
  hold,
  repeat,
  melodic,
}

/// Prossima prova proposta dal piano.
class TessituraStep {
  const TessituraStep({
    required this.stage,
    required this.midi,
    required this.cue,
    this.direction = 0,
    this.askEffort = false,
    this.repetition = 1,
    this.repetitions = 1,
  });

  final TessituraStage stage;
  final int midi;
  final TessituraCue cue;
  final int direction;

  /// Dopo la prova si chiede lo sforzo percepito (se la prova è valida).
  final bool askEffort;

  /// Ripetizione (da 1) su [repetitions], per la fase di ripetibilità.
  final int repetition;
  final int repetitions;

  /// Durata richiesta della nota.
  Duration get duration => switch (stage) {
        TessituraStage.hold => TessituraPlanner.holdDuration,
        TessituraStage.melodic => TessituraPlanner.melodicNoteDuration,
        _ => TessituraPlanner.noteDuration,
      };
}

enum PlanKind { attempt, offerMelodic, finished, cannotCalibrate }

class PlanResult {
  const PlanResult._(this.kind, [this.step]);

  const PlanResult.attempt(TessituraStep step) : this._(PlanKind.attempt, step);
  static const offerMelodic = PlanResult._(PlanKind.offerMelodic);
  static const finished = PlanResult._(PlanKind.finished);

  /// Il microfono non sente bene la voce nemmeno sulla nota di partenza.
  static const cannotCalibrate = PlanResult._(PlanKind.cannotCalibrate);

  final PlanKind kind;
  final TessituraStep? step;
}

/// Sceglie la prossima prova in base alle precedenti: calibrazione,
/// esplorazione verso l'acuto e verso il grave, tenuta, ripetibilità e,
/// se scelta, verifica melodica. Senza stato: ricalcola tutto dalle prove.
class TessituraPlanner {
  TessituraPlanner({required this.centerMidi, required this.lowMidi, required this.highMidi});

  /// Nota comoda di partenza.
  final int centerMidi;

  /// Limiti dell'esplorazione (estensione nota o un'ottava e mezza attorno).
  final int lowMidi;
  final int highMidi;

  static const noteDuration = Duration(seconds: 3);
  static const holdDuration = Duration(seconds: 6);
  static const melodicNoteDuration = Duration(milliseconds: 1200);

  /// Ripetizioni valide per nota nella fase di ripetibilità.
  static const repetitions = 3;

  /// Tentativi massimi della calibrazione prima di arrendersi.
  static const maxCalibrationAttempts = 4;

  /// Note massime esplorate per direzione e prove totali: il test resta
  /// entro 5–8 minuti.
  static const maxNotesPerDirection = 14;
  static const maxAttempts = 70;

  PlanResult next(List<TessituraAttempt> attempts, {bool? melodic}) {
    if (attempts.length >= maxAttempts) {
      return PlanResult.finished;
    }
    // A. Calibrazione.
    final calibration = [
      for (final a in attempts)
        if (a.stage == TessituraStage.calibration) a,
    ];
    final calibrated = calibration.where((a) => a.outcome == AttemptOutcome.success).firstOrNull;
    if (calibrated == null) {
      return _calibrate(calibration);
    }
    final center = calibrated.targetMidi;

    // B. Esplorazione: prima verso l'acuto, poi verso il grave.
    final up = _explore(attempts, center, 1);
    if (up.step != null) {
      return PlanResult.attempt(up.step!);
    }
    final down = _explore(attempts, center, -1);
    if (down.step != null) {
      return PlanResult.attempt(down.step!);
    }

    // C. Tenuta: centro e due note poco dentro le più estreme riuscite.
    final holds = holdNotes(center, up.highestSuccess, down.highestSuccess);
    for (final note in holds) {
      final mine = _stageAttempts(attempts, TessituraStage.hold, note);
      if (_needsAnother(mine, maxInvalid: 2, maxValid: 1)) {
        return PlanResult.attempt(TessituraStep(
          stage: TessituraStage.hold,
          midi: note,
          cue: mine.isEmpty ? TessituraCue.hold : TessituraCue.notHeard,
          askEffort: true,
        ));
      }
    }

    // D. Ripetibilità vicino ai bordi.
    for (final note in repeatNotes(attempts, center, up.highestSuccess, down.highestSuccess)) {
      final mine = _stageAttempts(attempts, TessituraStage.repeat, note);
      final valid = mine.where((a) => a.valid).length;
      if (mine.any((a) => a.strain) || valid >= repetitions || mine.length >= repetitions + 2) {
        continue;
      }
      return PlanResult.attempt(TessituraStep(
        stage: TessituraStage.repeat,
        midi: note,
        cue: mine.isNotEmpty && mine.last.outcome == AttemptOutcome.invalid
            ? TessituraCue.notHeard
            : TessituraCue.repeat,
        askEffort: valid == repetitions - 1,
        repetition: valid + 1,
        repetitions: repetitions,
      ));
    }

    // F. Verifica melodica facoltativa.
    if (melodic == null) {
      return PlanResult.offerMelodic;
    }
    if (melodic) {
      final phrase = melodicPhrase(attempts);
      final sung = attempts.where((a) => a.stage == TessituraStage.melodic).length;
      if (sung < phrase.length) {
        return PlanResult.attempt(TessituraStep(
          stage: TessituraStage.melodic,
          midi: phrase[sung],
          cue: TessituraCue.melodic,
          repetition: sung + 1,
          repetitions: phrase.length,
        ));
      }
    }
    return PlanResult.finished;
  }

  PlanResult _calibrate(List<TessituraAttempt> calibration) {
    if (calibration.isEmpty) {
      return PlanResult.attempt(TessituraStep(
          stage: TessituraStage.calibration, midi: centerMidi, cue: TessituraCue.calibrate));
    }
    if (calibration.length >= maxCalibrationAttempts) {
      return PlanResult.cannotCalibrate;
    }
    final last = calibration.last;
    final failed = calibration.where((a) => a.outcome == AttemptOutcome.failed).toList();
    final recentered = calibration.any((a) => a.targetMidi != centerMidi);
    // Due prove valide su un'altra nota: si parte da quella che l'utente
    // canta con naturalezza (una sola volta).
    final sung = last.measure?.sungMidi;
    if (failed.length >= 2 &&
        last.outcome == AttemptOutcome.failed &&
        !recentered &&
        sung != null) {
      return PlanResult.attempt(TessituraStep(
        stage: TessituraStage.calibration,
        midi: sung.clamp(lowMidi, highMidi),
        cue: TessituraCue.recenter,
      ));
    }
    return PlanResult.attempt(TessituraStep(
      stage: TessituraStage.calibration,
      midi: last.targetMidi,
      cue: last.outcome == AttemptOutcome.invalid ? TessituraCue.notHeard : TessituraCue.retry,
    ));
  }

  /// Esplorazione in una direzione. Regole:
  /// - nota riuscita → semitono successivo;
  /// - non riuscita → si ripete; due volte non riuscita = difficoltà;
  /// - due note difficili di fila → la direzione finisce (un errore isolato
  ///   non la ferma);
  /// - non valutabile (segnale insufficiente) due volte → si prosegue senza
  ///   contarla come difficoltà; due note così di fila → la direzione finisce;
  /// - sforzo eccessivo segnalato o nota saltata dall'utente → la direzione
  ///   finisce subito.
  ({TessituraStep? step, int highestSuccess}) _explore(
      List<TessituraAttempt> attempts, int center, int direction) {
    final list = [
      for (final a in attempts)
        if (a.stage == TessituraStage.explore && a.direction == direction) a,
    ];
    var best = center;
    var note = center + direction;
    var index = 0;
    var difficult = 0;
    var unknown = 0;
    var explored = 0;
    while (note >= lowMidi && note <= highMidi && explored < maxNotesPerDirection) {
      final mine = <TessituraAttempt>[];
      while (index < list.length && list[index].targetMidi == note) {
        mine.add(list[index++]);
      }
      explored++;
      if (mine.any((a) => a.outcome == AttemptOutcome.interrupted)) {
        break;
      }
      final success = mine.any((a) => a.outcome == AttemptOutcome.success);
      final failed = mine.where((a) => a.outcome == AttemptOutcome.failed).length;
      final invalid = mine.where((a) => a.outcome == AttemptOutcome.invalid).length;
      if (success) {
        best = note;
        difficult = 0;
        unknown = 0;
      } else if (failed >= 2) {
        if (++difficult >= 2) {
          break;
        }
        unknown = 0;
      } else if (invalid >= 2 && failed == 0) {
        if (++unknown >= 2) {
          break;
        }
      } else if (failed + invalid >= 3) {
        if (++difficult >= 2) {
          break;
        }
      } else {
        final TessituraCue cue;
        if (mine.isNotEmpty) {
          cue = mine.last.outcome == AttemptOutcome.invalid
              ? TessituraCue.notHeard
              : TessituraCue.retry;
        } else if (direction < 0 && note == center - 1) {
          cue = TessituraCue.backToComfort;
        } else {
          cue = direction > 0 ? TessituraCue.stepUp : TessituraCue.stepDown;
        }
        return (
          step: TessituraStep(
            stage: TessituraStage.explore,
            midi: note,
            cue: cue,
            direction: direction,
          ),
          highestSuccess: best,
        );
      }
      note += direction;
    }
    return (step: null, highestSuccess: best);
  }

  /// Note della fase di tenuta: il centro e, se l'esplorazione è andata
  /// abbastanza lontano, due semitoni dentro le note più estreme riuscite.
  static List<int> holdNotes(int center, int highest, int lowest) => [
        center,
        if (highest - 2 > center) highest - 2,
        if (lowest + 2 < center) lowest + 2,
      ];

  /// Note della fase di ripetibilità, una per lato: un semitono più in fuori
  /// della nota tenuta se la tenuta è riuscita ed è stata facile, altrimenti
  /// un semitono più dentro. Mai oltre le note riuscite in esplorazione.
  List<int> repeatNotes(List<TessituraAttempt> attempts, int center, int highest, int lowest) {
    int? side(int direction, int extreme) {
      final hold = extreme - 2 * direction;
      final holdOnSide = direction > 0 ? hold > center : hold < center;
      if (!holdOnSide) {
        // Esplorazione breve: si ripete la nota più estrema riuscita.
        return extreme != center ? extreme : null;
      }
      final held = _stageAttempts(attempts, TessituraStage.hold, hold);
      final good = held.any((a) =>
          a.outcome == AttemptOutcome.success &&
          a.effort != null &&
          a.effort!.value <= EffortRating.easy.value);
      final note = good ? hold + direction : hold - direction;
      return note == center ? null : note;
    }

    return {
      if (side(1, highest) case final note?) note,
      if (side(-1, lowest) case final note?) note,
    }.toList();
  }

  /// Frase della verifica melodica: cinque note che salgono attraverso la
  /// zona comoda stimata finora (o utilizzabile) e quattro che riscendono.
  List<int> melodicPhrase(List<TessituraAttempt> attempts) {
    final estimate = TessituraEstimate.from(attempts);
    final low = estimate.comfortLow ?? estimate.usableLow;
    final high = estimate.comfortHigh ?? estimate.usableHigh;
    if (low == null || high == null || high - low < 2) {
      return const [];
    }
    final up = [for (var i = 0; i < 5; i++) low + ((high - low) * i / 4).round()];
    return [...up, ...up.reversed.skip(1)];
  }

  static List<TessituraAttempt> _stageAttempts(
          List<TessituraAttempt> attempts, TessituraStage stage, int note) =>
      [
        for (final a in attempts)
          if (a.stage == stage && a.targetMidi == note) a,
      ];

  static bool _needsAnother(List<TessituraAttempt> mine,
      {required int maxInvalid, required int maxValid}) {
    if (mine.any((a) => a.outcome == AttemptOutcome.interrupted)) {
      return false;
    }
    final valid = mine.where((a) => a.valid).length;
    final invalid = mine.where((a) => a.outcome == AttemptOutcome.invalid).length;
    return valid < maxValid && invalid < maxInvalid;
  }
}

/// Stato di una nota nel risultato.
enum NoteZone {
  /// Nella zona comoda stimata.
  comfortable,

  /// Dati in contrasto o insufficienti: va verificata.
  toVerify,

  /// Prodotta, ma fuori dalla zona comoda (o con sforzo elevato).
  outside,
}

/// Attendibilità della stima: quanto sono solidi i dati, non quanto è ampia
/// la tessitura.
enum TessituraReliability { insufficient, low, medium, high }

/// Prove di una nota, riassunte.
class NoteEvidence {
  NoteEvidence(this.midi);

  final int midi;
  int successes = 0;
  int failures = 0;
  int invalid = 0;
  int interrupted = 0;
  bool reached = false;
  bool strain = false;
  bool registerShift = false;
  int holdTried = 0;
  int holdOk = 0;
  int repeatValid = 0;
  int repeatOk = 0;
  int melodicFailed = 0;
  final efforts = <EffortRating>[];

  int get valid => successes + failures;

  /// Riuscita almeno una volta e almeno nella metà delle prove valide.
  bool get usableCandidate => successes >= 1 && successes * 2 >= valid;

  /// Sforzo elevato dichiarato (4–5) o segnalato durante la prova.
  bool get strained => strain || efforts.any((e) => e.value >= EffortRating.hard.value);

  /// Sforzo dichiarato basso (1–2) e mai moderato o più.
  bool get ratedEasy =>
      efforts.isNotEmpty && efforts.every((e) => e.value <= EffortRating.easy.value);
}

/// Stima della tessitura dalle prove. Regole (nessun punteggio pesato):
///
/// 1. **Estensione osservata**: note raggiunte almeno una volta in una prova
///    valida (anche solo un attimo).
/// 2. **Estensione utilizzabile**: tratto continuo attorno alla nota di
///    partenza di note riuscite almeno nella metà delle prove valide. Una
///    singola nota non riuscita fra due riuscite non lo spezza (resta da
///    verificare); un estremo riuscito una sola volta in un'unica prova ne
///    resta fuori (da verificare).
/// 3. **Zona comoda**: dentro l'estensione utilizzabile, fra le due note più
///    distanti dichiarate facili (sforzo 1–2) senza note con sforzo elevato
///    in mezzo. Le note fra due note facili senza un giudizio proprio sono
///    comode per coerenza con le vicine; quelle oltre l'ultima nota facile
///    no (l'assenza di un giudizio non prova la comodità). Sforzo moderato,
///    tenuta non riuscita, ripetizioni poco affidabili, cambio di registro o
///    errori nella frase rendono la nota da verificare ma, isolati, non
///    restringono la zona. Servono almeno due note facili diverse.
class TessituraEstimate {
  const TessituraEstimate({
    required this.evidence,
    required this.zones,
    required this.observedLow,
    required this.observedHigh,
    required this.usableLow,
    required this.usableHigh,
    required this.comfortLow,
    required this.comfortHigh,
    required this.toVerify,
    required this.registerNotes,
    required this.reliability,
    required this.validAttempts,
    required this.invalidAttempts,
  });

  final Map<int, NoteEvidence> evidence;
  final Map<int, NoteZone> zones;
  final int? observedLow;
  final int? observedHigh;
  final int? usableLow;
  final int? usableHigh;
  final int? comfortLow;
  final int? comfortHigh;
  final List<int> toVerify;

  /// Note con un cambio di registro segnalato dall'utente.
  final List<int> registerNotes;
  final TessituraReliability reliability;
  final int validAttempts;
  final int invalidAttempts;

  bool get hasZone => comfortLow != null && comfortHigh != null;

  /// Frazione di prove non valide (rumore, segnale debole).
  double get invalidRatio {
    final total = validAttempts + invalidAttempts;
    return total == 0 ? 0 : invalidAttempts / total;
  }

  bool get provisional =>
      reliability == TessituraReliability.insufficient || reliability == TessituraReliability.low;

  static TessituraEstimate from(List<TessituraAttempt> attempts) {
    final evidence = <int, NoteEvidence>{};
    for (final a in attempts) {
      final e = evidence.putIfAbsent(a.targetMidi, () => NoteEvidence(a.targetMidi));
      switch (a.outcome) {
        case AttemptOutcome.success:
          e.successes++;
        case AttemptOutcome.failed:
          e.failures++;
        case AttemptOutcome.invalid:
          e.invalid++;
        case AttemptOutcome.interrupted:
          e.interrupted++;
      }
      if (a.valid && (a.measure?.reached ?? false)) {
        e.reached = true;
      }
      e.strain |= a.strain;
      e.registerShift |= a.registerShift;
      if (a.effort != null) {
        e.efforts.add(a.effort!);
      }
      if (a.valid && a.stage == TessituraStage.hold) {
        e.holdTried++;
        if (a.outcome == AttemptOutcome.success) {
          e.holdOk++;
        }
      }
      if (a.valid && a.stage == TessituraStage.repeat) {
        e.repeatValid++;
        if (a.outcome == AttemptOutcome.success) {
          e.repeatOk++;
        }
      }
      if (a.stage == TessituraStage.melodic && a.outcome == AttemptOutcome.failed) {
        e.melodicFailed++;
      }
    }
    final validAttempts = attempts.where((a) => a.valid).length;
    final invalidAttempts = attempts.where((a) => a.outcome == AttemptOutcome.invalid).length;

    final reachedNotes = [
      for (final e in evidence.values)
        if (e.reached) e.midi,
    ];
    final observedLow = reachedNotes.isEmpty ? null : reachedNotes.reduce(math.min);
    final observedHigh = reachedNotes.isEmpty ? null : reachedNotes.reduce(math.max);

    final toVerify = <int>{};
    final center = attempts
        .where((a) => a.stage == TessituraStage.calibration && a.outcome == AttemptOutcome.success)
        .firstOrNull
        ?.targetMidi;
    final usable = _usableRun(evidence, center, toVerify);

    int? comfortLow;
    int? comfortHigh;
    if (usable != null) {
      final zone = _comfortZone(evidence, usable, center, toVerify);
      comfortLow = zone?.$1;
      comfortHigh = zone?.$2;
    }
    final registerNotes = [
      for (final e in evidence.values)
        if (e.registerShift) e.midi,
    ]..sort();
    // Cambio di registro segnalato: la nota resta nell'estensione osservata
    // ma va verificata (non è mai un bordo della zona comoda).
    toVerify.addAll(registerNotes);

    final zones = <int, NoteZone>{};
    for (final e in evidence.values) {
      if (!e.reached && e.valid == 0) {
        continue;
      }
      final inZone = comfortLow != null && e.midi >= comfortLow && e.midi <= comfortHigh!;
      zones[e.midi] = toVerify.contains(e.midi)
          ? NoteZone.toVerify
          : inZone
              ? NoteZone.comfortable
              : NoteZone.outside;
    }

    final estimate = TessituraEstimate(
      evidence: evidence,
      zones: zones,
      observedLow: observedLow,
      observedHigh: observedHigh,
      usableLow: usable?.$1,
      usableHigh: usable?.$2,
      comfortLow: comfortLow,
      comfortHigh: comfortHigh,
      toVerify: toVerify.toList()..sort(),
      registerNotes: registerNotes,
      reliability: TessituraReliability.insufficient,
      validAttempts: validAttempts,
      invalidAttempts: invalidAttempts,
    );
    return estimate._withReliability();
  }

  /// Estensione utilizzabile (vedi regola 2).
  static (int, int)? _usableRun(Map<int, NoteEvidence> evidence, int? center, Set<int> toVerify) {
    bool candidate(int note) => evidence[note]?.usableCandidate ?? false;
    final candidates = evidence.keys.where(candidate).toList()..sort();
    if (candidates.isEmpty) {
      return null;
    }
    // Si parte dalla nota di partenza, o dalla candidata più vicina.
    final start = center != null && candidate(center)
        ? center
        : candidates
            .reduce((a, b) => (a - (center ?? a)).abs() <= (b - (center ?? b)).abs() ? a : b);
    int extend(int direction) {
      var end = start;
      while (true) {
        final next = end + direction;
        if (candidate(next)) {
          end = next;
          continue;
        }
        // Errore isolato: una sola nota non riuscita (o non valutabile), con
        // una nota riuscita subito oltre. Resta da verificare.
        final gap = evidence[next];
        final isolated = gap != null && !gap.strained;
        if (isolated && candidate(next + direction)) {
          toVerify.add(next);
          end = next + direction;
          continue;
        }
        return end;
      }
    }

    var low = extend(-1);
    var high = extend(1);
    // Un estremo riuscito una sola volta in un'unica prova resta fuori.
    bool once(int note) {
      final e = evidence[note]!;
      return e.successes == 1 && e.valid == 1;
    }

    if (high > start && once(high)) {
      toVerify.add(high);
      high--;
    }
    if (low < start && once(low)) {
      toVerify.add(low);
      low++;
    }
    return (low, high);
  }

  /// Zona comoda (vedi regola 3).
  static (int, int)? _comfortZone(
      Map<int, NoteEvidence> evidence, (int, int) usable, int? center, Set<int> toVerify) {
    final (low, high) = usable;
    for (var note = low; note <= high; note++) {
      final e = evidence[note];
      if (e == null) {
        continue;
      }
      final moderate = e.efforts.any((r) => r == EffortRating.moderate);
      final holdFailed = e.holdTried > 0 && e.holdOk == 0;
      final unreliable = e.repeatValid >= 3 && e.repeatOk * 3 < e.repeatValid * 2;
      if (!e.strained && (moderate || holdFailed || unreliable || e.melodicFailed > 0)) {
        toVerify.add(note);
      }
    }
    final easy = [
      for (var note = low; note <= high; note++)
        if ((evidence[note]?.ratedEasy ?? false) &&
            !evidence[note]!.registerShift &&
            !toVerify.contains(note))
          note,
    ];
    (int, int)? best;
    for (var i = 0; i < easy.length; i++) {
      for (var j = i + 1; j < easy.length; j++) {
        final a = easy[i];
        final b = easy[j];
        final blocked = [
          for (var note = a; note <= b; note++)
            if (evidence[note]?.strained ?? false) note,
        ].isNotEmpty;
        if (blocked) {
          break;
        }
        final containsCenter = center != null && a <= center && center <= b;
        final bestContains =
            best != null && center != null && best.$1 <= center && center <= best.$2;
        final wider = best == null || b - a > best.$2 - best.$1;
        if (best == null ||
            (containsCenter && !bestContains) ||
            (containsCenter == bestContains && wider)) {
          best = (a, b);
        }
      }
    }
    return best;
  }

  /// Attendibilità: criteri sui dati raccolti, indipendenti dall'ampiezza.
  TessituraEstimate _withReliability() {
    final value = !hasZone ? TessituraReliability.insufficient : _reliabilityLevel();
    return TessituraEstimate(
      evidence: evidence,
      zones: zones,
      observedLow: observedLow,
      observedHigh: observedHigh,
      usableLow: usableLow,
      usableHigh: usableHigh,
      comfortLow: comfortLow,
      comfortHigh: comfortHigh,
      toVerify: toVerify,
      registerNotes: registerNotes,
      reliability: value,
      validAttempts: validAttempts,
      invalidAttempts: invalidAttempts,
    );
  }

  /// Criteri soddisfatti (ognuno vale uno, nessun peso):
  /// - almeno 12 prove valide;
  /// - prove non valide non oltre il 25%;
  /// - entrambi i bordi della zona ripetuti (≥ 2 prove valide, ≥ 2/3 riuscite);
  /// - almeno 3 giudizi di sforzo;
  /// - al massimo 2 note da verificare;
  /// - dentro la zona al massimo una nota con una prova non riuscita.
  /// 5–6 = alta, 3–4 = media, altrimenti bassa; con oltre il 40% di prove
  /// non valide l'attendibilità resta bassa.
  TessituraReliability _reliabilityLevel() {
    bool repeatable(int note) {
      final e = evidence[note];
      return e != null && e.valid >= 2 && e.successes * 3 >= e.valid * 2;
    }

    final ratings = evidence.values.fold(0, (sum, e) => sum + e.efforts.length);
    final shaky = [
      for (var note = comfortLow!; note <= comfortHigh!; note++)
        if ((evidence[note]?.failures ?? 0) > 0) note,
    ];
    final met = [
      validAttempts >= 12,
      invalidRatio <= 0.25,
      repeatable(comfortLow!) && repeatable(comfortHigh!),
      ratings >= 3,
      toVerify.length <= 2,
      shaky.length <= 1,
    ].where((ok) => ok).length;
    if (invalidRatio > 0.4) {
      return TessituraReliability.low;
    }
    return met >= 5
        ? TessituraReliability.high
        : met >= 3
            ? TessituraReliability.medium
            : TessituraReliability.low;
  }
}

/// Risultato salvato di un test di tessitura.
class TessituraRecord {
  const TessituraRecord({
    required this.timestamp,
    required this.comfortLow,
    required this.comfortHigh,
    required this.rangeLow,
    required this.rangeHigh,
    required this.toVerify,
    required this.reliability,
    required this.provisional,
    required this.trials,
    this.usableLow,
    this.usableHigh,
    this.registerNotes = const [],
    this.invalidRatio,
  });

  factory TessituraRecord.fromEstimate({
    required DateTime timestamp,
    required TessituraEstimate estimate,
  }) {
    return TessituraRecord(
      timestamp: timestamp,
      comfortLow: estimate.comfortLow,
      comfortHigh: estimate.comfortHigh,
      rangeLow: estimate.observedLow,
      rangeHigh: estimate.observedHigh,
      usableLow: estimate.usableLow,
      usableHigh: estimate.usableHigh,
      toVerify: estimate.toVerify,
      registerNotes: estimate.registerNotes,
      reliability: estimate.reliability,
      provisional: estimate.provisional,
      trials: estimate.validAttempts,
      invalidRatio: estimate.invalidRatio,
    );
  }

  /// Legge anche i risultati delle versioni precedenti (senza estensione
  /// utilizzabile, registro e qualità del segnale).
  factory TessituraRecord.fromJson(Map<String, dynamic> json) {
    List<int> ints(Object? value) =>
        [for (final note in (value as List<dynamic>? ?? const [])) note as int];
    return TessituraRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      comfortLow: json['comfortLow'] as int?,
      comfortHigh: json['comfortHigh'] as int?,
      rangeLow: json['rangeLow'] as int?,
      rangeHigh: json['rangeHigh'] as int?,
      usableLow: json['usableLow'] as int?,
      usableHigh: json['usableHigh'] as int?,
      toVerify: ints(json['toVerify']),
      registerNotes: ints(json['registerNotes']),
      reliability:
          TessituraReliability.values.asNameMap()[json['reliability']] ?? TessituraReliability.low,
      provisional: json['provisional'] as bool? ?? true,
      trials: json['trials'] as int? ?? 0,
      invalidRatio: (json['invalidRatio'] as num?)?.toDouble(),
    );
  }

  final DateTime timestamp;

  /// Zona comoda stimata; null se i dati non bastavano.
  final int? comfortLow;
  final int? comfortHigh;

  /// Estensione massima osservata: note più grave e più acuta raggiunte nel
  /// test (nelle versioni precedenti, l'estensione nota al momento del test).
  final int? rangeLow;
  final int? rangeHigh;

  /// Estensione utilizzabile; null se i dati non bastavano o per i test
  /// delle versioni precedenti.
  final int? usableLow;
  final int? usableHigh;

  final List<int> toVerify;

  /// Note con un cambio di registro segnalato.
  final List<int> registerNotes;
  final TessituraReliability reliability;
  final bool provisional;

  /// Prove valide (nelle versioni precedenti, frammenti completati).
  final int trials;

  /// Frazione di prove non valide; null per i test precedenti.
  final double? invalidRatio;

  bool get hasZone => comfortLow != null && comfortHigh != null;
  bool get hasUsable => usableLow != null && usableHigh != null;

  /// Molte prove non valide: rumore o segnale debole.
  bool get signalIssues => (invalidRatio ?? 0) > 0.25;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'comfortLow': comfortLow,
        'comfortHigh': comfortHigh,
        'rangeLow': rangeLow,
        'rangeHigh': rangeHigh,
        'usableLow': usableLow,
        'usableHigh': usableHigh,
        'toVerify': toVerify,
        'registerNotes': registerNotes,
        'reliability': reliability.name,
        'provisional': provisional,
        'trials': trials,
        'invalidRatio': invalidRatio,
      };
}
