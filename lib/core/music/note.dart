import 'dart:math' as math;

/// Notazione con cui mostrare i nomi delle note.
enum NoteNotation { italian, english }

enum PitchClass {
  c('DO', 'C', 0),
  cSharp('DO#', 'C#', 1),
  d('RE', 'D', 2),
  dSharp('RE#', 'D#', 3),
  e('MI', 'E', 4),
  f('FA', 'F', 5),
  fSharp('FA#', 'F#', 6),
  g('SOL', 'G', 7),
  gSharp('SOL#', 'G#', 8),
  a('LA', 'A', 9),
  aSharp('LA#', 'A#', 10),
  b('SI', 'B', 11);

  const PitchClass(this.italianLabel, this.englishLabel, this.semitone);

  final String italianLabel;
  final String englishLabel;
  final int semitone;

  /// Label italiana, mantenuta per retrocompatibilità.
  String get label => italianLabel;

  String labelFor(NoteNotation notation) {
    return notation == NoteNotation.english ? englishLabel : italianLabel;
  }

  static PitchClass fromSemitone(int semitone) {
    final normalized = semitone % 12;
    return PitchClass.values.firstWhere((pitch) => pitch.semitone == normalized);
  }
}

class MusicalNote {
  const MusicalNote({
    required this.pitchClass,
    required this.octave,
  });

  factory MusicalNote.fromMidi(int midiNumber) {
    return MusicalNote(
      pitchClass: PitchClass.fromSemitone(midiNumber),
      octave: (midiNumber ~/ 12) - 1,
    );
  }

  factory MusicalNote.fromFrequency(double frequency) {
    final midi = (69 + 12 * math.log(frequency / 440) / math.ln2).round();
    return MusicalNote.fromMidi(midi);
  }

  final PitchClass pitchClass;
  final int octave;

  int get midiNumber => (octave + 1) * 12 + pitchClass.semitone;

  double get frequency => (440 * math.pow(2, (midiNumber - 69) / 12)).toDouble();

  String get label => pitchClass.label;

  String get fullLabel => '$label$octave';

  String labelFor(NoteNotation notation) => pitchClass.labelFor(notation);

  String fullLabelFor(NoteNotation notation) => '${labelFor(notation)}$octave';

  MusicalNote transpose(int semitones) => MusicalNote.fromMidi(midiNumber + semitones);

  double centsFromFrequency(double frequency) {
    return 1200 * math.log(frequency / this.frequency) / math.ln2;
  }

  @override
  bool operator ==(Object other) {
    return other is MusicalNote && other.midiNumber == midiNumber;
  }

  @override
  int get hashCode => midiNumber.hashCode;
}
