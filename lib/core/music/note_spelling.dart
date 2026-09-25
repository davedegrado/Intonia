import 'note.dart';

/// Nota "scritta" correttamente: lettera diatonica + alterazione.
/// Es. il decimo semitono sopra FA è SIb (non LA#), la terza minore di DO
/// è MIb (non RE#), la quinta aumentata di DO è SOL#.
class SpelledNote {
  const SpelledNote({
    required this.letterIndex,
    required this.alteration,
    required this.letterOctave,
    required this.midi,
  });

  /// 0=DO/C, 1=RE/D ... 6=SI/B.
  final int letterIndex;

  /// -2 (doppio bemolle) ... +2 (doppio diesis).
  final int alteration;

  /// Ottava riferita alla lettera (es. DOb5 suona come SI4 ma si scrive in 5ª).
  final int letterOctave;

  final int midi;

  static const italianLetters = ['DO', 'RE', 'MI', 'FA', 'SOL', 'LA', 'SI'];
  static const englishLetters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

  /// Posizione diatonica assoluta (per il pentagramma).
  int get diatonicIndex => letterOctave * 7 + letterIndex;

  String get accidental => switch (alteration) {
        -2 => 'bb',
        -1 => 'b',
        1 => '#',
        2 => '##',
        _ => '',
      };

  String label(NoteNotation notation) {
    final letters = notation == NoteNotation.english ? englishLetters : italianLetters;
    return '${letters[letterIndex]}$accidental';
  }

  String fullLabel(NoteNotation notation) => '${label(notation)}$letterOctave';
}

/// Motore di spelling: decide diesis/bemolle in base alla distanza in gradi
/// dalla tonica dell'esercizio.
class NoteSpeller {
  const NoteSpeller._();

  /// Semitono naturale di ogni lettera (DO=0 ... SI=11).
  static const _naturalSemitones = [0, 2, 4, 5, 7, 9, 11];

  /// Nome preferito per ogni tonica (semitono → lettera, alterazione):
  /// REb, MIb, FA#, LAb, SIb per i tasti neri.
  static const _preferredRoots = <int, (int, int)>{
    0: (0, 0), // DO
    1: (1, -1), // REb
    2: (1, 0), // RE
    3: (2, -1), // MIb
    4: (2, 0), // MI
    5: (3, 0), // FA
    6: (3, 1), // FA#
    7: (4, 0), // SOL
    8: (5, -1), // LAb
    9: (5, 0), // LA
    10: (6, -1), // SIb
    11: (6, 0), // SI
  };

  /// Offset (mod 12) dalla tonica → (gradi diatonici da salire, alterazione).
  static const _degreeTable = <int, (int, int)>{
    0: (0, 0), // unisono
    1: (1, -1), // 2ª minore
    2: (1, 0), // 2ª maggiore
    3: (2, -1), // 3ª minore
    4: (2, 0), // 3ª maggiore
    5: (3, 0), // 4ª giusta
    6: (4, -1), // 5ª diminuita
    7: (4, 0), // 5ª giusta
    8: (5, -1), // 6ª minore
    9: (5, 0), // 6ª maggiore
    10: (6, -1), // 7ª minore
    11: (6, 0), // 7ª maggiore
  };

  /// Etichetta preferita di una tonalità (per dropdown e picker):
  /// es. semitono 10 → 'SIb' / 'Bb', semitono 6 → 'FA#' / 'F#'.
  static String keyLabel(PitchClass key, NoteNotation notation) {
    final (letter, alt) = _preferredRoots[key.semitone]!;
    final letters = notation == NoteNotation.english
        ? SpelledNote.englishLetters
        : SpelledNote.italianLetters;
    final accidental = alt == -1 ? 'b' : alt == 1 ? '#' : '';
    return '${letters[letter]}$accidental';
  }

  /// Spelling della tonica (lettera preferita, ottava della lettera).
  static SpelledNote spellRoot(MusicalNote root) {
    final (letter, alt) = _preferredRoots[root.pitchClass.semitone]!;
    // Ottava tale che (naturale + alterazione) == midi della tonica.
    final naturalInOctave = _naturalSemitones[letter] + alt;
    final letterOctave = (root.midiNumber - naturalInOctave) ~/ 12 - 1;
    return SpelledNote(
      letterIndex: letter,
      alteration: alt,
      letterOctave: letterOctave,
      midi: root.midiNumber,
    );
  }

  /// Spelling di una nota rispetto alla tonica.
  /// [preferAugmentedFifth]: se true, l'offset 8 viene scritto come 5ª
  /// aumentata (#5, es. SOL# su DO) invece che 6ª minore (LAb su DO).
  static SpelledNote spellNote(
    MusicalNote note, {
    required MusicalNote root,
    bool preferAugmentedFifth = false,
  }) {
    final rootSpelling = spellRoot(root);
    final offset = note.midiNumber - root.midiNumber;
    final normalized = ((offset % 12) + 12) % 12;
    final octaveShift = (offset - normalized) ~/ 12;

    var (degrees, _) = _degreeTable[normalized]!;
    if (normalized == 8 && preferAugmentedFifth) {
      degrees = 4; // 5ª aumentata
    }

    final targetDiatonic = rootSpelling.diatonicIndex + degrees + octaveShift * 7;
    final letterIndex = ((targetDiatonic % 7) + 7) % 7;
    final letterOctave = (targetDiatonic - letterIndex) ~/ 7;
    final naturalMidi = (letterOctave + 1) * 12 + _naturalSemitones[letterIndex];
    final alteration = note.midiNumber - naturalMidi;

    if (alteration.abs() > 2) {
      // Caso limite: ripiega sullo spelling assoluto preferito della nota.
      return spellRoot(note);
    }

    return SpelledNote(
      letterIndex: letterIndex,
      alteration: alteration,
      letterOctave: letterOctave,
      midi: note.midiNumber,
    );
  }

  /// Spelling di un'intera sequenza rispetto alla prima nota (tonica).
  /// Rileva automaticamente il contesto "aumentato" (c'è la 3ª maggiore ma
  /// non la 5ª giusta) per scrivere #5 invece di b6.
  static List<SpelledNote> spellSequence(List<MusicalNote> sequence) {
    if (sequence.isEmpty) {
      return const [];
    }
    final root = sequence.first;
    final offsets = {
      for (final note in sequence) ((note.midiNumber - root.midiNumber) % 12 + 12) % 12,
    };
    final augmented = offsets.contains(4) && offsets.contains(8) && !offsets.contains(7);

    return [
      for (final note in sequence)
        spellNote(note, root: root, preferAugmentedFifth: augmented),
    ];
  }
}
