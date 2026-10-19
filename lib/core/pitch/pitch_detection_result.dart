import '../music/note.dart';

class PitchDetectionResult {
  const PitchDetectionResult({
    required this.frequency,
    required this.note,
    required this.cents,
    required this.confidence,
    required this.isStable,
    this.uncertain = false,
  });

  final double frequency;
  final MusicalNote note;
  final double cents;
  final double confidence;
  final bool isStable;

  /// Periodicità presente ma ottava ambigua: il frame non va usato per
  /// decidere la nota (chi lo riceve mantiene lo stato precedente).
  final bool uncertain;

  /// Voce periodica ma ottava ambigua: nessuna nota, chi lo riceve
  /// mantiene lo stato precedente come in una breve caduta del segnale.
  static const uncertainFrame = PitchDetectionResult(
    frequency: 0,
    note: MusicalNote(pitchClass: PitchClass.c, octave: 4),
    cents: 0,
    confidence: 0,
    isStable: false,
    uncertain: true,
  );

  static const silence = PitchDetectionResult(
    frequency: 0,
    note: MusicalNote(pitchClass: PitchClass.c, octave: 4),
    cents: 0,
    confidence: 0,
    isStable: false,
  );
}
