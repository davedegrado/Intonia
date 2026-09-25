import 'note.dart';

/// Categoria di esercizi mostrata come sezione (accordion) nella Home.
/// L'ordine dell'enum è l'ordine di visualizzazione: Custom per primo.
enum ExerciseCategory {
  custom('Le tue sequenze', 'Crea e allena le tue sequenze personalizzate'),
  triads('Triadi', 'Maggiore, minore, aumentata e diminuita'),
  arpeggios('Arpeggi', 'Triadi estese all\'ottava'),
  pentatonics('Pentatoniche', 'Maggiore e minore'),
  scales('Scale', 'Maggiori, minori e blues'),
  harmonizations('Armonizzazioni a 3 voci', 'Triadi diatoniche su ogni grado della scala'),
  patterns('Pattern', 'Sequenze melodiche di riscaldamento');

  const ExerciseCategory(this.label, this.description);

  final String label;
  final String description;
}

/// Un esercizio è una sequenza completa di offset in semitoni dalla prima
/// nota (la "tonica" scelta nel trainer). Gli offset possono essere negativi
/// e ripetuti: questo permette scale, triadi arpeggiate, armonizzazioni e
/// qualsiasi sequenza custom (anche note tutte uguali).
class ExerciseDefinition {
  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.steps,
    this.isCustom = false,
    this.rootMidi,
    this.focus,
    this.group,
  });

  factory ExerciseDefinition.fromJson(Map<String, dynamic> json) {
    return ExerciseDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ExerciseCategory.custom,
      steps: (json['steps'] as List<dynamic>).map((step) => step as int).toList(),
      isCustom: true,
      rootMidi: json['rootMidi'] as int?,
      focus: json['focus'] as String?,
      group: json['group'] as String?,
    );
  }

  final String id;
  final String name;
  final ExerciseCategory category;
  final List<int> steps;
  final bool isCustom;

  /// Nota di partenza scelta nell'editor (MIDI). Usata come tonalità/ottava
  /// iniziale nel trainer e per rieditare la sequenza con le note originali.
  final int? rootMidi;

  /// Obiettivo dell'esercizio mostrato come tag (es. "Precisione").
  final String? focus;

  /// Gruppo scelto dall'utente per le sequenze custom (accordion in Home).
  final String? group;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'steps': steps,
        if (rootMidi != null) 'rootMidi': rootMidi,
        if (focus != null) 'focus': focus,
        if (group != null) 'group': group,
      };

  List<MusicalNote> buildSequence({
    required PitchClass key,
    required int octave,
  }) {
    final root = MusicalNote(pitchClass: key, octave: octave);
    return steps.map(root.transpose).toList(growable: false);
  }
}

/// Costruisce salita + apice ripetuto + discesa a partire dagli intervalli
/// ascendenti di una scala (comportamento storico dell'app).
List<int> upDownWithRepeatedTop(List<int> ascending, [List<int>? descending]) {
  final down = (descending ?? ascending).reversed.skip(1);
  return [...ascending, ascending.last, ...down];
}

/// Salita + discesa senza ripetere l'apice (adatto a triadi e arpeggi corti).
List<int> upDown(List<int> ascending) {
  return [...ascending, ...ascending.reversed.skip(1)];
}

/// Armonizzazione a 3 voci: per ogni grado della scala (compresa l'ottava)
/// si arpeggia la triade diatonica costruita su quel grado (1-3-5).
/// [ascendingScale] sono gli intervalli della scala senza l'ottava,
/// es. maggiore: [0, 2, 4, 5, 7, 9, 11].
List<int> harmonizedScaleTriads(List<int> ascendingScale) {
  final extended = [
    ...ascendingScale,
    for (final step in ascendingScale) step + 12,
    for (final step in ascendingScale) step + 24,
  ];
  final steps = <int>[];
  for (var degree = 0; degree <= ascendingScale.length; degree++) {
    steps
      ..add(extended[degree])
      ..add(extended[degree + 2])
      ..add(extended[degree + 4]);
  }
  return steps;
}

class ExerciseLibrary {
  const ExerciseLibrary();

  static const _majorScale = [0, 2, 4, 5, 7, 9, 11, 12];
  static const _naturalMinorScale = [0, 2, 3, 5, 7, 8, 10, 12];
  static const _harmonicMinorScale = [0, 2, 3, 5, 7, 8, 11, 12];
  static const _melodicMinorScale = [0, 2, 3, 5, 7, 9, 11, 12];

  List<ExerciseDefinition> get builtIn => [
        // ------------------------------------------------- Triadi
        ExerciseDefinition(
          id: 'triad_major',
          name: 'Triade maggiore',
          category: ExerciseCategory.triads,
          steps: upDown(const [0, 4, 7]),
          focus: 'Precisione',
        ),
        ExerciseDefinition(
          id: 'triad_minor',
          name: 'Triade minore',
          category: ExerciseCategory.triads,
          steps: upDown(const [0, 3, 7]),
          focus: 'Precisione',
        ),
        ExerciseDefinition(
          id: 'triad_augmented',
          name: 'Triade aumentata',
          category: ExerciseCategory.triads,
          steps: upDown(const [0, 4, 8]),
          focus: 'Orecchio',
        ),
        ExerciseDefinition(
          id: 'triad_diminished',
          name: 'Triade diminuita',
          category: ExerciseCategory.triads,
          steps: upDown(const [0, 3, 6]),
          focus: 'Orecchio',
        ),
        // ------------------------------------------------- Arpeggi
        ExerciseDefinition(
          id: 'arpeggio_major_octave',
          name: 'Arpeggio maggiore (8ª)',
          category: ExerciseCategory.arpeggios,
          steps: upDown(const [0, 4, 7, 12]),
          focus: 'Estensione',
        ),
        ExerciseDefinition(
          id: 'arpeggio_minor_octave',
          name: 'Arpeggio minore (8ª)',
          category: ExerciseCategory.arpeggios,
          steps: upDown(const [0, 3, 7, 12]),
          focus: 'Estensione',
        ),
        // ------------------------------------------------- Pentatoniche
        ExerciseDefinition(
          id: 'major_pentatonic',
          name: 'Pentatonica maggiore',
          category: ExerciseCategory.pentatonics,
          steps: upDownWithRepeatedTop(const [0, 2, 4, 7, 9, 12]),
          focus: 'Agilità',
        ),
        ExerciseDefinition(
          id: 'minor_pentatonic',
          name: 'Pentatonica minore',
          category: ExerciseCategory.pentatonics,
          steps: upDownWithRepeatedTop(const [0, 3, 5, 7, 10, 12]),
          focus: 'Agilità',
        ),
        // ------------------------------------------------- Scale
        ExerciseDefinition(
          id: 'major',
          name: 'Scala maggiore',
          category: ExerciseCategory.scales,
          steps: upDownWithRepeatedTop(_majorScale),
          focus: 'Precisione',
        ),
        ExerciseDefinition(
          id: 'natural_minor',
          name: 'Minore naturale',
          category: ExerciseCategory.scales,
          steps: upDownWithRepeatedTop(_naturalMinorScale),
          focus: 'Precisione',
        ),
        ExerciseDefinition(
          id: 'harmonic_minor',
          name: 'Minore armonica',
          category: ExerciseCategory.scales,
          steps: upDownWithRepeatedTop(_harmonicMinorScale),
          focus: 'Precisione',
        ),
        ExerciseDefinition(
          id: 'melodic_minor',
          name: 'Minore melodica',
          category: ExerciseCategory.scales,
          steps: upDownWithRepeatedTop(_melodicMinorScale),
          focus: 'Controllo',
        ),
        ExerciseDefinition(
          id: 'blues',
          name: 'Scala blues',
          category: ExerciseCategory.scales,
          steps: upDownWithRepeatedTop(const [0, 3, 5, 6, 7, 10, 12]),
          focus: 'Agilità',
        ),
        // ------------------------------------------------- Armonizzazioni
        ExerciseDefinition(
          id: 'harmonized_major',
          name: 'Scala maggiore armonizzata',
          category: ExerciseCategory.harmonizations,
          steps: harmonizedScaleTriads(const [0, 2, 4, 5, 7, 9, 11]),
          focus: 'Orecchio',
        ),
        ExerciseDefinition(
          id: 'harmonized_natural_minor',
          name: 'Minore naturale armonizzata',
          category: ExerciseCategory.harmonizations,
          steps: harmonizedScaleTriads(const [0, 2, 3, 5, 7, 8, 10]),
          focus: 'Orecchio',
        ),
        ExerciseDefinition(
          id: 'harmonized_harmonic_minor',
          name: 'Minore armonica armonizzata',
          category: ExerciseCategory.harmonizations,
          steps: harmonizedScaleTriads(const [0, 2, 3, 5, 7, 8, 11]),
          focus: 'Orecchio',
        ),
        ExerciseDefinition(
          id: 'harmonized_melodic_minor',
          name: 'Minore melodica armonizzata',
          category: ExerciseCategory.harmonizations,
          steps: harmonizedScaleTriads(const [0, 2, 3, 5, 7, 9, 11]),
          focus: 'Orecchio',
        ),
        // ------------------------------------------------- Pattern
        ExerciseDefinition(
          id: 'five_note_pattern',
          name: 'Pattern 5 note (1-2-3-4-5)',
          category: ExerciseCategory.patterns,
          steps: upDownWithRepeatedTop(const [0, 2, 4, 5, 7]),
          focus: 'Controllo',
        ),
        ExerciseDefinition(
          id: 'third_leaps',
          name: 'Salti di terza (1-3, 2-4...)',
          category: ExerciseCategory.patterns,
          steps: const [0, 4, 2, 5, 4, 7, 5, 9, 7, 11, 9, 12, 11, 14, 12],
          focus: 'Controllo',
        ),
      ];

  ExerciseDefinition? byId(String id) {
    for (final exercise in builtIn) {
      if (exercise.id == id) {
        return exercise;
      }
    }
    return null;
  }
}
