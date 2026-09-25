import 'dart:math' as math;

import '../music/note.dart';
import 'pitch_detection_result.dart';

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

  PitchDetectionResult detect(List<double> samples) {
    if (samples.length < 512 || _rms(samples) < rmsSilenceThreshold) {
      return PitchDetectionResult.silence;
    }

    final minTau = (sampleRate / maxFrequency).floor().clamp(2, samples.length ~/ 2);
    final maxTau = (sampleRate / minFrequency).ceil().clamp(minTau + 1, samples.length ~/ 2);
    final difference = List<double>.filled(maxTau + 1, 0);

    for (var tau = 1; tau <= maxTau; tau++) {
      var sum = 0.0;
      for (var i = 0; i < samples.length - tau; i++) {
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
    for (var tau = minTau; tau <= maxTau; tau++) {
      if (cumulative[tau] < threshold) {
        while (tau + 1 <= maxTau && cumulative[tau + 1] < cumulative[tau]) {
          tau++;
        }
        tauEstimate = tau;
        break;
      }
    }

    if (tauEstimate == -1) {
      return PitchDetectionResult.silence;
    }

    final refinedTau = _parabolicInterpolation(cumulative, tauEstimate);
    if (refinedTau <= 0) {
      return PitchDetectionResult.silence;
    }

    final frequency = sampleRate / refinedTau;
    if (frequency < minFrequency || frequency > maxFrequency) {
      return PitchDetectionResult.silence;
    }

    final note = MusicalNote.fromFrequency(frequency);
    final cents = note.centsFromFrequency(frequency);
    final confidence = (1 - cumulative[tauEstimate]).clamp(0.0, 1.0);

    return PitchDetectionResult(
      frequency: frequency,
      note: note,
      cents: cents,
      confidence: confidence,
      isStable: confidence >= stableConfidence && cents.abs() <= 50,
    );
  }

  double _rms(List<double> samples) {
    final energy = samples.fold<double>(0, (sum, sample) => sum + sample * sample);
    return math.sqrt(energy / samples.length);
  }

  double _parabolicInterpolation(List<double> values, int tau) {
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
