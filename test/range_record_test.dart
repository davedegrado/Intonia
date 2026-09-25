import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/session/range_record.dart';

void main() {
  test('range record JSON round-trip and span', () {
    final record = RangeRecord(
      timestamp: DateTime(2026, 7, 8, 18, 30),
      minMidi: 45, // LA2
      maxMidi: 76, // MI5
    );

    expect(record.spanSemitones, 31);

    final restored = RangeRecord.fromJson(record.toJson());
    expect(restored.timestamp, record.timestamp);
    expect(restored.minMidi, 45);
    expect(restored.maxMidi, 76);
    expect(restored.spanSemitones, 31);
  });

  test('formatSpan expresses the span in octaves + semitones', () {
    expect(formatSpan(31), '2 ottave + 7 semitoni');
    expect(formatSpan(24), '2 ottave');
    expect(formatSpan(13), '1 ottava + 1 semitono');
    expect(formatSpan(12), '1 ottava');
    expect(formatSpan(7), '7 semitoni');
    expect(formatSpan(1), '1 semitono');
    expect(formatSpan(0), '0 semitoni');
  });
}
