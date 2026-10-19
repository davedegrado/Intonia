import 'dart:math' as math;

/// Quanto è stato comodo cantare una prova, dichiarato dall'utente.
enum ComfortRating {
  easy,
  effort,
  hard;

  /// Peso del comfort dichiarato nella stima (0–1).
  double get score => switch (this) {
        easy => 1,
        effort => 0.55,
        hard => 0.1,
      };
}

/// Misure di una nota cantata in una prova.
class NoteMeasure {
  const NoteMeasure({
    required this.validated,
    this.meanCents = 0,
    this.spreadCents = 0,
    this.wrongAttempts = 0,
    this.sustainRatio,
  });

  /// Nota riconosciuta e intonata entro la tolleranza.
  final bool validated;

  /// Scostamento medio (cent) mentre la nota era riconosciuta.
  final double meanCents;

  /// Dispersione (deviazione standard, cent): misura la stabilità.
  final double spreadCents;

  /// Tentativi su una nota diversa prima della convalida.
  final int wrongAttempts;

  /// Solo per la nota tenuta a fine prova: frazione (0–1) della tenuta
  /// passata sulla nota giusta.
  final double? sustainRatio;

  /// Prestazione misurata (0–1): convalida, centratura, stabilità e
  /// tenuta. Da sola NON dice se la nota è comoda.
  double get performance {
    if (!validated) {
      return 0;
    }
    final centred = 1 - (meanCents.abs() / 40).clamp(0.0, 1.0);
    final stable = 1 - (spreadCents / 40).clamp(0.0, 1.0);
    final clean = wrongAttempts == 0 ? 1.0 : (wrongAttempts == 1 ? 0.6 : 0.3);
    var value = 0.35 + 0.25 * centred + 0.25 * stable + 0.15 * clean;
    final sustain = sustainRatio;
    if (sustain != null) {
      value = 0.75 * value + 0.25 * sustain.clamp(0.0, 1.0);
    }
    return value.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'v': validated,
        'c': meanCents,
        's': spreadCents,
        'w': wrongAttempts,
        if (sustainRatio != null) 'h': sustainRatio,
      };
}

/// Una prova: un frammento breve (salita e discesa) a partire da [rootMidi].
class TessituraTrial {
  const TessituraTrial({
    required this.rootMidi,
    required this.measures,
    required this.comfort,
  });

  /// Frammento cantato in ogni prova: due toni su e ritorno (es. DO RE MI RE DO).
  static const pattern = [0, 2, 4, 2, 0];

  final int rootMidi;

  /// Misure per nota (MIDI). Le note ripetute nel frammento sono unite.
  final Map<int, NoteMeasure> measures;

  /// Comfort dichiarato; null = "non ci sono riuscito" o prova saltata.
  final ComfortRating? comfort;

  int get topMidi => rootMidi + pattern.reduce(math.max);

  bool get failed => comfort == null;

  /// Prova riuscita e non faticosa: la zona può continuare in quella direzione.
  bool get keepsGoing => comfort == ComfortRating.easy || comfort == ComfortRating.effort;

  Iterable<int> get notes => measures.keys;
}

/// Sceglie la prossima prova in base ai risultati: prima verso l'acuto dal
/// centro, poi verso il grave, poi ripete le prove ai bordi della zona
/// comoda per verificarne la ripetibilità. Deterministico e senza I/O.
class TessituraPlanner {
  TessituraPlanner({required this.centerMidi, required this.lowMidi, required this.highMidi});

  /// Nota attorno a cui parte la ricerca (comoda per l'utente).
  final int centerMidi;

  /// Limiti oltre cui non si propongono prove (estensione nota o stimata).
  final int lowMidi;
  final int highMidi;

  /// Distanza tra le note di partenza di due prove consecutive: con il
  /// frammento da due toni le prove vicine condividono una nota.
  static const step = 3;

  /// Massimo numero di prove: il test resta nei 3–5 minuti.
  static const maxTrials = 12;

  int get _firstRoot => centerMidi - 2;

  /// Prossima nota di partenza, o null se il test è finito.
  int? next(List<TessituraTrial> trials) {
    if (trials.length >= maxTrials) {
      return null;
    }
    if (trials.isEmpty) {
      return _clampRoot(_firstRoot);
    }
    final first = trials.first;
    final up = <TessituraTrial>[first];
    var index = 1;
    // Salita: continua finché le prove restano comode e c'è estensione.
    while (index < trials.length && trials[index].rootMidi == up.last.rootMidi + step) {
      up.add(trials[index]);
      index++;
    }
    final upEnded = !up.last.keepsGoing || up.last.rootMidi + step + 4 > highMidi;
    if (index == trials.length && !upEnded) {
      return up.last.rootMidi + step;
    }
    // Discesa dalla prima prova.
    final down = <TessituraTrial>[];
    while (index < trials.length &&
        trials[index].rootMidi == (down.isEmpty ? first : down.last).rootMidi - step) {
      down.add(trials[index]);
      index++;
    }
    final lastDown = down.isEmpty ? first : down.last;
    final downEnded =
        (down.isNotEmpty && !lastDown.keepsGoing) || lastDown.rootMidi - step < lowMidi;
    if (index == trials.length && !downEnded) {
      return lastDown.rootMidi - step;
    }
    // Verifica: si ripetono le prove comode più estreme (una per lato).
    final checks = _verificationRoots(trials.sublist(0, index));
    final done = trials.length - index;
    return done < checks.length ? checks[done] : null;
  }

  /// Note di partenza delle prove comode più alta e più bassa (senza doppioni).
  List<int> _verificationRoots(List<TessituraTrial> explored) {
    final comfortable = explored.where((trial) => trial.keepsGoing).map((t) => t.rootMidi);
    if (comfortable.isEmpty) {
      return const [];
    }
    final highest = comfortable.reduce(math.max);
    final lowest = comfortable.reduce(math.min);
    return highest == lowest ? [highest] : [highest, lowest];
  }

  int _clampRoot(int root) => root.clamp(lowMidi, math.max(lowMidi, highMidi - 4));
}

/// Stato di una nota nella mappa.
enum NoteZone { comfortable, toVerify, outside }

/// Affidabilità indicativa della stima.
enum TessituraReliability { low, medium, high }

/// Stima della zona comoda a partire dalle prove.
class TessituraEstimate {
  const TessituraEstimate({
    required this.zones,
    required this.scores,
    required this.comfortLow,
    required this.comfortHigh,
    required this.reliability,
    required this.completedTrials,
  });

  /// Stato di ogni nota misurata.
  final Map<int, NoteZone> zones;

  /// Punteggio (0–1) di ogni nota misurata.
  final Map<int, double> scores;

  /// Zona comoda stimata (estremi inclusi); null se i dati non bastano.
  final int? comfortLow;
  final int? comfortHigh;

  final TessituraReliability reliability;
  final int completedTrials;

  /// Stima provvisoria: dati scarsi o poco coerenti.
  bool get provisional =>
      comfortLow == null || reliability == TessituraReliability.low || completedTrials < 4;

  List<int> get toVerify => [
        for (final entry in zones.entries)
          if (entry.value == NoteZone.toVerify) entry.key,
      ]..sort();

  /// Combina comfort dichiarato (peso maggiore), prestazione misurata e
  /// ripetibilità. La sola precisione non rende comoda una nota: una nota
  /// intonata ma dichiarata difficile resta fuori dalla zona comoda.
  static TessituraEstimate from(List<TessituraTrial> trials) {
    final samples = <int, List<double>>{};
    final comforts = <int, List<ComfortRating?>>{};
    final coveredBy = <int, Set<int>>{};
    for (final trial in trials) {
      for (final note in trial.notes) {
        coveredBy.putIfAbsent(note, () => {}).add(trial.rootMidi);
      }
    }
    // Un frammento faticoso o non riuscito lo è per la nota più esterna
    // (verso cui si stava andando): le note interne, se cantate anche in
    // frammenti che partono da altre note, non vengono penalizzate da questo
    // giudizio (le ripetizioni dello stesso frammento contano sempre).
    final center = trials.isEmpty ? 0 : trials.first.rootMidi + 2;
    final uncertain = <int>{};
    for (final trial in trials) {
      final outer = trial.rootMidi + 2 >= center ? trial.topMidi : trial.rootMidi;
      for (final entry in trial.measures.entries) {
        if (!trial.keepsGoing && entry.key != outer) {
          if (coveredBy[entry.key]!.length > 1) {
            continue;
          }
          // Cantata solo qui: non si sa se fosse lei la nota difficile.
          uncertain.add(entry.key);
        }
        final comfort = trial.comfort?.score ?? 0;
        final score = 0.6 * comfort + 0.4 * entry.value.performance;
        samples.putIfAbsent(entry.key, () => []).add(score);
        comforts.putIfAbsent(entry.key, () => []).add(trial.comfort);
      }
    }

    final scores = <int, double>{};
    final zones = <int, NoteZone>{};
    for (final note in samples.keys) {
      final values = samples[note]!;
      final mean = values.reduce((a, b) => a + b) / values.length;
      final consistent =
          values.length < 2 || values.reduce(math.max) - values.reduce(math.min) <= 0.4;
      bool comfortable(ComfortRating? comfort) =>
          comfort == ComfortRating.easy || comfort == ComfortRating.effort;
      final ratings = comforts[note]!;
      scores[note] = mean;
      // Comoda: dichiarata comoda ogni volta, cantata bene e in modo coerente.
      // Fuori: mai dichiarata comoda, anche se intonata. Il resto (giudizi e
      // misure in contrasto) va verificato.
      zones[note] = mean >= 0.65 && ratings.every(comfortable) && consistent
          ? NoteZone.comfortable
          : !ratings.any(comfortable) && !uncertain.contains(note)
              ? NoteZone.outside
              : NoteZone.toVerify;
    }

    final zone = _widestComfortableRun(zones, scores);
    final completed = trials.where((trial) => !trial.failed).length;
    return TessituraEstimate(
      zones: zones,
      scores: scores,
      comfortLow: zone?.$1,
      comfortHigh: zone?.$2,
      reliability: _reliability(trials, zones, zone, samples),
      completedTrials: completed,
    );
  }

  /// Tratto di note comode consecutive (fra due note comode distanti al
  /// massimo un tono, quelle non misurate o da verificare non lo spezzano) più ampio; a
  /// parità, quello col punteggio medio più alto.
  static (int, int)? _widestComfortableRun(Map<int, NoteZone> zones, Map<int, double> scores) {
    final comfortable = [
      for (final entry in zones.entries)
        if (entry.value == NoteZone.comfortable) entry.key,
    ]..sort();
    if (comfortable.isEmpty) {
      return null;
    }
    (int, int)? best;
    var bestScore = -1.0;
    var start = comfortable.first;
    for (var i = 0; i < comfortable.length; i++) {
      final isLast = i == comfortable.length - 1;
      final gap = isLast ? 99 : comfortable[i + 1] - comfortable[i];
      // Solo una nota misurata fuori zona interrompe il tratto; una da
      // verificare in mezzo resta segnalata ma non lo spezza.
      final interrupted = !isLast &&
          zones.keys.any((note) =>
              note > comfortable[i] &&
              note < comfortable[i + 1] &&
              zones[note] == NoteZone.outside);
      if (gap > 2 || interrupted || isLast) {
        final end = comfortable[i];
        final run = comfortable.where((note) => note >= start && note <= end);
        final mean = run.map((note) => scores[note]!).reduce((a, b) => a + b) / run.length;
        final width = end - start;
        final bestWidth = best == null ? -1 : best.$2 - best.$1;
        if (width > bestWidth || (width == bestWidth && mean > bestScore)) {
          best = (start, end);
          bestScore = mean;
        }
        if (!isLast) {
          start = comfortable[i + 1];
        }
      }
    }
    return best;
  }

  static TessituraReliability _reliability(
    List<TessituraTrial> trials,
    Map<int, NoteZone> zones,
    (int, int)? zone,
    Map<int, List<double>> samples,
  ) {
    if (zone == null) {
      return TessituraReliability.low;
    }
    var points = 0;
    if (trials.where((trial) => !trial.failed).length >= 6) {
      points++;
    }
    // Bordi della zona misurati almeno due volte (ripetibilità).
    if ((samples[zone.$1]?.length ?? 0) >= 2 && (samples[zone.$2]?.length ?? 0) >= 2) {
      points++;
    }
    if (zone.$2 - zone.$1 >= 4) {
      points++;
    }
    if (zones.values.where((value) => value == NoteZone.toVerify).length <= 2) {
      points++;
    }
    return points >= 4
        ? TessituraReliability.high
        : points >= 2
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
  });

  factory TessituraRecord.fromEstimate({
    required DateTime timestamp,
    required TessituraEstimate estimate,
    required int? rangeLow,
    required int? rangeHigh,
  }) {
    return TessituraRecord(
      timestamp: timestamp,
      comfortLow: estimate.comfortLow,
      comfortHigh: estimate.comfortHigh,
      rangeLow: rangeLow,
      rangeHigh: rangeHigh,
      toVerify: estimate.toVerify,
      reliability: estimate.reliability,
      provisional: estimate.provisional,
      trials: estimate.completedTrials,
    );
  }

  factory TessituraRecord.fromJson(Map<String, dynamic> json) {
    return TessituraRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      comfortLow: json['comfortLow'] as int?,
      comfortHigh: json['comfortHigh'] as int?,
      rangeLow: json['rangeLow'] as int?,
      rangeHigh: json['rangeHigh'] as int?,
      toVerify: [for (final note in (json['toVerify'] as List<dynamic>? ?? const [])) note as int],
      reliability:
          TessituraReliability.values.asNameMap()[json['reliability']] ?? TessituraReliability.low,
      provisional: json['provisional'] as bool? ?? true,
      trials: json['trials'] as int? ?? 0,
    );
  }

  final DateTime timestamp;

  /// Zona comoda stimata; null se i dati non bastavano.
  final int? comfortLow;
  final int? comfortHigh;

  /// Estensione massima nota al momento del test (test di estensione o note
  /// convalidate in questo test).
  final int? rangeLow;
  final int? rangeHigh;

  final List<int> toVerify;
  final TessituraReliability reliability;
  final bool provisional;

  /// Prove completate.
  final int trials;

  bool get hasZone => comfortLow != null && comfortHigh != null;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'comfortLow': comfortLow,
        'comfortHigh': comfortHigh,
        'rangeLow': rangeLow,
        'rangeHigh': rangeHigh,
        'toVerify': toVerify,
        'reliability': reliability.name,
        'provisional': provisional,
        'trials': trials,
      };
}
