import '../../../core/music/note.dart';

enum TrainerMode { listen, train }

class TrainingSettings {
  const TrainingSettings({
    required this.key,
    required this.octave,
    required this.bpm,
    required this.toleranceCents,
    required this.stabilityMs,
    required this.mode,
    required this.loop,
    required this.guideEveryNote,
  });

  factory TrainingSettings.defaults() {
    return const TrainingSettings(
      key: PitchClass.c,
      octave: 4,
      bpm: 72,
      toleranceCents: 20,
      stabilityMs: 200,
      mode: TrainerMode.train,
      loop: false,
      guideEveryNote: true,
    );
  }

  final PitchClass key;
  final int octave;
  final int bpm;
  final int toleranceCents;
  final int stabilityMs;
  final TrainerMode mode;
  final bool loop;

  /// In allenamento: se true il piano suona ogni nota quando si avanza;
  /// se false suona solo la prima nota dell'esercizio.
  final bool guideEveryNote;

  TrainingSettings copyWith({
    PitchClass? key,
    int? octave,
    int? bpm,
    int? toleranceCents,
    int? stabilityMs,
    TrainerMode? mode,
    bool? loop,
    bool? guideEveryNote,
  }) {
    return TrainingSettings(
      key: key ?? this.key,
      octave: octave ?? this.octave,
      bpm: bpm ?? this.bpm,
      toleranceCents: toleranceCents ?? this.toleranceCents,
      stabilityMs: stabilityMs ?? this.stabilityMs,
      mode: mode ?? this.mode,
      loop: loop ?? this.loop,
      guideEveryNote: guideEveryNote ?? this.guideEveryNote,
    );
  }
}
