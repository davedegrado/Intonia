import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/pitch/yin_pitch_detector.dart';

List<double> sine(double frequency, int sampleRate, int length, {double amplitude = 0.3}) {
  return [
    for (var i = 0; i < length; i++)
      amplitude * math.sin(2 * math.pi * frequency * i / sampleRate),
  ];
}

void main() {
  test('low-band detector locks onto 41.2 Hz / MI1 (fry territory)', () {
    // Stessa configurazione del rilevatore banda-bassa del servizio:
    // 44100/4 = 11025 Hz, finestra 1024 campioni.
    final detector = YinPitchDetector(
      sampleRate: 11025,
      minFrequency: 30,
      maxFrequency: 250,
      threshold: 0.18,
      stableConfidence: 0.60,
      rmsSilenceThreshold: 0.009,
    );

    final result = detector.detect(sine(41.2, 11025, 1024));

    expect(result.frequency, closeTo(41.2, 1.5));
    expect(result.note.fullLabel, 'MI1');
    expect(result.isStable, isTrue);
  });

  test('low-band detector detects C2 (65 Hz)', () {
    final detector = YinPitchDetector(
      sampleRate: 11025,
      minFrequency: 30,
      maxFrequency: 250,
      threshold: 0.18,
      stableConfidence: 0.60,
      rmsSilenceThreshold: 0.009,
    );

    final result = detector.detect(sine(65.4, 11025, 1024));

    expect(result.frequency, closeTo(65.4, 1.5));
    expect(result.note.fullLabel, 'DO2');
  });

  test('standard detector still detects A4', () {
    final detector = YinPitchDetector(sampleRate: 44100);
    final result = detector.detect(sine(440, 44100, 2048));

    expect(result.frequency, closeTo(440, 2));
    expect(result.note.fullLabel, 'LA4');
    expect(result.isStable, isTrue);
  });
}
