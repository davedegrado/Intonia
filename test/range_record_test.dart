import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/l10n.dart';
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

  test('span expresses the width in octaves + semitones (Italian)', () {
    final l10n = lookupAppLocalizations(const Locale('it'));
    expect(l10n.span(31), '2 ottave + 7 semitoni');
    expect(l10n.span(24), '2 ottave');
    expect(l10n.span(13), '1 ottava + 1 semitono');
    expect(l10n.span(12), '1 ottava');
    expect(l10n.span(7), '7 semitoni');
    expect(l10n.span(1), '1 semitono');
    expect(l10n.span(0), '0 semitoni');
    expect(l10n.rangeSpanDetail(l10n.span(29), 29), '2 ottave + 5 semitoni (29 semitoni)');
  });

  test('span expresses the width in octaves + semitones (English)', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(l10n.span(31), '2 octaves + 7 semitones');
    expect(l10n.span(24), '2 octaves');
    expect(l10n.span(13), '1 octave + 1 semitone');
    expect(l10n.span(12), '1 octave');
    expect(l10n.span(7), '7 semitones');
    expect(l10n.span(1), '1 semitone');
    expect(l10n.span(0), '0 semitones');
    expect(l10n.rangeSpanDetail(l10n.span(29), 29), '2 octaves + 5 semitones (29 semitones)');
    expect(l10n.rangeSpanDetail(l10n.span(1), 1), '1 semitone (1 semitone)');
  });
}
