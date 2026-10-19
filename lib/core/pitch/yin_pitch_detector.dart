import 'dart:math' as math;

import '../music/note.dart';
import 'pitch_detection_result.dart';

/// Esito completo di un'analisi YIN: il risultato e i dati intermedi
/// (funzione di differenza normalizzata) riutilizzabili da chi deve
/// confrontare più ipotesi senza ricalcolarli.
class YinAnalysis {
  const YinAnalysis({
    required this.result,
    required this.cmndf,
    required this.bestTau,
    required this.minTau,
    required this.maxTau,
    this.aboveRange = false,
  });

  static const silent = YinAnalysis(
    result: PitchDetectionResult.silence,
    cmndf: [],
    bestTau: null,
    minTau: 0,
    maxTau: 0,
  );

  final PitchDetectionResult result;

  /// Funzione di differenza cumulativa normalizzata (indice = ritardo τ).
  final List<double> cmndf;

  /// Periodo scelto (campioni, con interpolazione); null senza periodicità.
  final double? bestTau;
  final int minTau;
  final int maxTau;

  /// La voce è periodica ma oltre la frequenza massima del rilevatore: non
  /// va cercata altrove (es. nella banda bassa).
  final bool aboveRange;

  /// Profondità (0 = periodicità perfetta) del minimo più vicino a [tau].
  double? depthNear(double tau) =>
      YinPitchDetector.localMinimumNear(cmndf, tau, minTau, maxTau)?.$2;
}

class YinPitchDetector {
  YinPitchDetector({
    required this.sampleRate,
    this.threshold = 0.12,
    // 55 Hz ≈ LA1: consente di rilevare anche note molto gravi (es. DO2 a 65 Hz).
    this.minFrequency = 55,
    this.maxFrequency = 1100,
    this.rmsSilenceThreshold = 0.015,
    this.stableConfidence = 0.82,
  });

  final int sampleRate;
  final double threshold;
  final double minFrequency;
  final double maxFrequency;

  /// Soglia RMS sotto la quale il segnale è considerato silenzio.
  /// Modificabile tramite la calibrazione del rumore di fondo.
  double rmsSilenceThreshold;

  /// Confidenza minima perché il risultato sia marcato stabile.
  /// Il vocal fry è quasi-periodico: il rilevatore per la banda bassa
  /// usa un valore più permissivo.
  final double stableConfidence;

  /// Verifica dell'ottava: il doppio del periodo scelto (un'ottava sotto)
  /// sostituisce quello scelto solo se il suo minimo è nettamente più
  /// profondo (al massimo [octaveDownRatio] e più basso di almeno
  /// [octaveMargin]). Succede quando la seconda armonica è più forte della
  /// fondamentale e le armoniche dispari sono deboli: il primo minimo sotto
  /// soglia è a metà periodo.
  static const octaveDownRatio = 0.5;

  /// Differenza minima di profondità perché un'ipotesi d'ottava prevalga:
  /// sotto questo valore le differenze sono rumore numerico.
  static const octaveMargin = 0.01;

  /// Un minimo a metà del periodo scelto (un'ottava sopra) sostituisce
  /// quello scelto solo se è profondo quanto lui (entro [octaveMargin]) e
  /// sotto [upperMaxDepth]: a parità di periodicità vale il periodo più
  /// corto (principio di YIN).
  static const upperMaxDepth = 0.18;

  /// Tolleranza di profondità per preferire un sottomultiplo del periodo:
  /// col rumore i minimi dei multipli oscillano di qualche centesimo.
  static const submultipleMargin = 0.02;

  /// Fra le due soglie l'ottava è ambigua: il frame è segnato incerto.
  static const ambiguousRatio = 0.92;

  PitchDetectionResult detect(List<double> samples) => analyze(samples).result;

  YinAnalysis analyze(List<double> samples) {
    if (samples.length < 512 || _rms(samples) < rmsSilenceThreshold) {
      return YinAnalysis.silent;
    }

    final minTau = (sampleRate / maxFrequency).floor().clamp(2, samples.length ~/ 2);
    final maxTau = (sampleRate / minFrequency).ceil().clamp(minTau + 1, samples.length ~/ 2);
    // Finestra d'integrazione fissa per tutti i ritardi (YIN standard): con
    // una finestra che si accorcia al crescere di τ la differenza cala
    // artificialmente sui periodi lunghi, che nel rumore vincono
    // (errori di una o più ottave verso il basso).
    final window = samples.length - maxTau;
    final difference = List<double>.filled(maxTau + 1, 0);
    for (var tau = 1; tau <= maxTau; tau++) {
      var sum = 0.0;
      for (var i = 0; i < window; i++) {
        final delta = samples[i] - samples[i + tau];
        sum += delta * delta;
      }
      difference[tau] = sum;
    }

    final cumulative = List<double>.filled(maxTau + 1, 1);
    var runningSum = 0.0;
    for (var tau = 1; tau <= maxTau; tau++) {
      runningSum += difference[tau];
      cumulative[tau] = runningSum == 0 ? 1 : difference[tau] * tau / runningSum;
    }

    var tauEstimate = -1;
    var skippedEdge = false;
    for (var tau = minTau; tau <= maxTau; tau++) {
      if (cumulative[tau] < threshold) {
        while (tau + 1 <= maxTau && cumulative[tau + 1] < cumulative[tau]) {
          tau++;
        }
        // Coda di un minimo che sta sotto il periodo minimo (una frequenza
        // oltre il limite, es. la seconda armonica di un RE5): non è un
        // candidato, si cerca il prossimo minimo.
        if (tau == minTau && cumulative[minTau - 1] <= cumulative[minTau]) {
          skippedEdge = true;
          while (tau + 1 <= maxTau && cumulative[tau] < threshold) {
            tau++;
          }
          continue;
        }
        tauEstimate = tau;
        break;
      }
    }
    if (tauEstimate == -1 && skippedEdge) {
      // Solo la coda di un minimo oltre il limite: voce troppo acuta.
      return YinAnalysis(
        result: PitchDetectionResult.silence,
        cmndf: cumulative,
        bestTau: null,
        minTau: minTau,
        maxTau: maxTau,
        aboveRange: true,
      );
    }
    if (tauEstimate == -1) {
      // Nessun minimo sotto soglia (segnale rumoroso): come in YIN si usa il
      // minimo globale, preferendo il periodo più corto fra quelli profondi
      // quasi quanto lui. La confidenza resta bassa e decide la stabilità.
      var global = minTau;
      for (var t = minTau + 1; t <= maxTau; t++) {
        if (cumulative[t] < cumulative[global]) {
          global = t;
        }
      }
      for (var t = minTau + 1; t < global; t++) {
        final isMinimum = cumulative[t] <= cumulative[t - 1] && cumulative[t] <= cumulative[t + 1];
        if (isMinimum && cumulative[t] <= cumulative[global] + submultipleMargin) {
          global = t;
          break;
        }
      }
      if (global <= minTau || global >= maxTau) {
        return YinAnalysis(
          result: PitchDetectionResult.silence,
          cmndf: cumulative,
          bestTau: null,
          minTau: minTau,
          maxTau: maxTau,
        );
      }
      tauEstimate = global;
    }

    var tau = _parabolicInterpolation(cumulative, tauEstimate);
    var uncertain = false;
    final check = _checkOctave(cumulative, tau, minTau, maxTau);
    tau = check.$1;
    uncertain = check.$2;
    // Il minimo saltato sul bordo era la voce stessa (frequenza oltre il
    // limite), non un'armonica: il periodo trovato ne è un multiplo, che
    // darebbe un'ottava sbagliata. Meglio nessuna nota.
    if (skippedEdge && _periodicBelowRange(cumulative, tau, minTau)) {
      return YinAnalysis(
        result: PitchDetectionResult.silence,
        cmndf: cumulative,
        bestTau: null,
        minTau: minTau,
        maxTau: maxTau,
        aboveRange: true,
      );
    }
    if (tau <= 0) {
      return YinAnalysis(
        result: PitchDetectionResult.silence,
        cmndf: cumulative,
        bestTau: null,
        minTau: minTau,
        maxTau: maxTau,
      );
    }

    final frequency = sampleRate / tau;
    if (frequency < minFrequency || frequency > maxFrequency) {
      return YinAnalysis(
        result: PitchDetectionResult.silence,
        cmndf: cumulative,
        bestTau: null,
        minTau: minTau,
        maxTau: maxTau,
      );
    }

    final note = MusicalNote.fromFrequency(frequency);
    final cents = note.centsFromFrequency(frequency);
    final depth = localMinimumNear(cumulative, tau, minTau, maxTau)?.$2 ?? cumulative[tau.round()];
    final confidence = (1 - depth).clamp(0.0, 1.0);

    final stable = !uncertain && confidence >= stableConfidence && cents.abs() <= 50;
    return YinAnalysis(
      // Per chi consuma i risultati un frame non stabile resta silenzio
      // (frequenza 0): l'ipotesi scartata resta in [bestTau] per i controlli
      // del servizio; un'ottava ambigua è segnalata come incerta.
      result: stable
          ? PitchDetectionResult(
              frequency: frequency,
              note: note,
              cents: cents,
              confidence: confidence,
              isStable: true,
            )
          : uncertain
              ? PitchDetectionResult.uncertainFrame
              : PitchDetectionResult.silence,
      cmndf: cumulative,
      bestTau: tau,
      minTau: minTau,
      maxTau: maxTau,
    );
  }

  /// Confronta il periodo scelto con il doppio (ottava sotto) e la metà
  /// (ottava sopra), solo se entrambi cadono nell'intervallo valido del
  /// rilevatore. Ritorna il periodo da usare e se l'ottava resta ambigua.
  (double, bool) _checkOctave(List<double> cmndf, double tau, int minTau, int maxTau) {
    final chosen = localMinimumNear(cmndf, tau, minTau, maxTau);
    if (chosen == null) {
      return (tau, false);
    }
    final depth = chosen.$2;
    // Ottava sotto: se il periodo vero è il doppio di quello scelto (seconda
    // armonica più forte della fondamentale, armoniche dispari deboli), il
    // minimo al doppio del ritardo è nettamente più profondo. Si confronta
    // con il ritardo adiacente (il jitter pesa allo stesso modo su entrambi).
    if (tau * 2 <= maxTau) {
      final lower = localMinimumNear(cmndf, tau * 2, minTau, maxTau);
      if (lower != null) {
        final (lowerTau, lowerDepth) = lower;
        final gap = depth - lowerDepth;
        if (gap >= octaveMargin && lowerDepth <= depth * octaveDownRatio) {
          return (lowerTau, false);
        }
        if (gap >= octaveMargin && lowerDepth <= depth * ambiguousRatio) {
          return (tau, true);
        }
      }
    }
    // Periodo multiplo di quello vero (una o più ottave sotto): fra i
    // sottomultipli (da ⅛ a ½) vince il più corto profondo quasi quanto
    // quello scelto (principio di YIN: a parità di periodicità, il periodo
    // più corto).
    for (var k = 8; k >= 2; k--) {
      if (tau / k < minTau) {
        continue;
      }
      final shorter = localMinimumNear(cmndf, tau / k, minTau, maxTau);
      if (shorter != null) {
        final (shorterTau, shorterDepth) = shorter;
        if (shorterDepth <= depth + submultipleMargin && shorterDepth < upperMaxDepth) {
          return (shorterTau, false);
        }
      }
    }
    return (tau, false);
  }

  /// C'è un minimo sotto il periodo minimo, a metà (o un terzo) di [tau],
  /// profondo quanto quello di [tau]? Allora [tau] è un multiplo del periodo
  /// vero, che è fuori dall'intervallo del rilevatore.
  bool _periodicBelowRange(List<double> cmndf, double tau, int minTau) {
    final depth = localMinimumNear(cmndf, tau, minTau, cmndf.length - 1)?.$2 ?? cmndf[tau.round()];
    for (final k in const [2, 3]) {
      final short = tau / k;
      if (short >= minTau) {
        continue;
      }
      final from = math.max(2, (short * 0.97).floor());
      final to = math.min(minTau, (short * 1.03).ceil());
      for (var i = from; i <= to; i++) {
        if (cmndf[i] <= depth + octaveMargin * 2) {
          return true;
        }
      }
    }
    return false;
  }

  /// Minimo locale della funzione [cmndf] entro ±3% di [tau] (un quarto di
  /// semitono), con interpolazione; null se fuori dall'intervallo valido o
  /// se il punto più basso è sul bordo della ricerca (non è un minimo).
  static (double, double)? localMinimumNear(
      List<double> cmndf, double tau, int minTau, int maxTau) {
    if (cmndf.isEmpty) {
      return null;
    }
    final from = math.max(minTau, (tau * 0.97).floor());
    final to = math.min(maxTau, (tau * 1.03).ceil());
    if (from >= to) {
      return null;
    }
    var best = from;
    for (var i = from + 1; i <= to; i++) {
      if (cmndf[i] < cmndf[best]) {
        best = i;
      }
    }
    if ((best == from && from > minTau) || (best == to && to < maxTau)) {
      // Il valore continua a scendere oltre la finestra: non è il minimo
      // di questo periodo.
      final outside = best == from ? cmndf[from - 1] : cmndf[to + 1];
      if (outside < cmndf[best]) {
        return null;
      }
    }
    return (_parabolicInterpolationStatic(cmndf, best), cmndf[best]);
  }

  double _rms(List<double> samples) {
    final energy = samples.fold<double>(0, (sum, sample) => sum + sample * sample);
    return math.sqrt(energy / samples.length);
  }

  double _parabolicInterpolation(List<double> values, int tau) =>
      _parabolicInterpolationStatic(values, tau);

  static double _parabolicInterpolationStatic(List<double> values, int tau) {
    if (tau <= 0 || tau >= values.length - 1) {
      return tau.toDouble();
    }
    final s0 = values[tau - 1];
    final s1 = values[tau];
    final s2 = values[tau + 1];
    final denominator = 2 * (2 * s1 - s2 - s0);
    if (denominator == 0) {
      return tau.toDouble();
    }
    return tau + (s2 - s0) / denominator;
  }
}
