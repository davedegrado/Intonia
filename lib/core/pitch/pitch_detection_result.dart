import '../music/note.dart';

class PitchDetectionResult {
  const PitchDetectionResult({
    required this.frequency,
    required this.note,
    required this.cents,
    required this.confidence,
    required this.isStable,
  });

  final double frequency;
  final MusicalNote note;
  final double cents;
  final double confidence;
  final bool isStable;

  static const silence = PitchDetectionResult(
    frequency: 0,
    note: MusicalNote(pitchClass: PitchClass.c, octave: 4),
    cents: 0,
    confidence: 0,
    isStable: false,
  );
}
