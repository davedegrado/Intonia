import '../core/music/exercise.dart';
import 'app_localizations.dart';

/// Obiettivi (focus) degli esercizi. Il valore salvato resta quello italiano
/// storico (es. "Precisione"); qui si traduce nella lingua attiva.
enum ExerciseFocus {
  accuracy('Precisione', 'Accuracy'),
  ear('Orecchio', 'Ear training'),
  agility('Agilità', 'Agility'),
  control('Controllo', 'Control'),
  range('Estensione', 'Range');

  const ExerciseFocus(this.storedValue, this.englishValue);

  /// Valore persistito nelle sequenze e nelle definizioni predefinite.
  final String storedValue;

  /// Equivalente inglese, riconosciuto se mai salvato.
  final String englishValue;

  static ExerciseFocus? parse(String value) {
    final normalized = value.trim().toLowerCase();
    for (final focus in values) {
      if (focus.storedValue.toLowerCase() == normalized ||
          focus.englishValue.toLowerCase() == normalized) {
        return focus;
      }
    }
    return null;
  }
}

/// Nomi, categorie e obiettivi degli esercizi predefiniti nella lingua attiva.
/// Le sequenze personalizzate mantengono il nome scelto dall'utente.
extension ExerciseL10n on AppLocalizations {
  String exerciseName(ExerciseDefinition exercise) =>
      exercise.isCustom ? exercise.name : exerciseNameById(exercise.id, exercise.name);

  /// Nome di un esercizio predefinito dal suo id (es. per le sessioni salvate);
  /// [fallback] per gli esercizi personalizzati o sconosciuti.
  String exerciseNameById(String id, String fallback) => switch (id) {
        'triad_major' => exerciseNameTriadMajor,
        'triad_minor' => exerciseNameTriadMinor,
        'triad_augmented' => exerciseNameTriadAugmented,
        'triad_diminished' => exerciseNameTriadDiminished,
        'arpeggio_major_octave' => exerciseNameArpeggioMajorOctave,
        'arpeggio_minor_octave' => exerciseNameArpeggioMinorOctave,
        'major_pentatonic' => exerciseNameMajorPentatonic,
        'minor_pentatonic' => exerciseNameMinorPentatonic,
        'major' => exerciseNameMajor,
        'natural_minor' => exerciseNameNaturalMinor,
        'harmonic_minor' => exerciseNameHarmonicMinor,
        'melodic_minor' => exerciseNameMelodicMinor,
        'blues' => exerciseNameBlues,
        'harmonized_major' => exerciseNameHarmonizedMajor,
        'harmonized_natural_minor' => exerciseNameHarmonizedNaturalMinor,
        'harmonized_harmonic_minor' => exerciseNameHarmonizedHarmonicMinor,
        'harmonized_melodic_minor' => exerciseNameHarmonizedMelodicMinor,
        'five_note_pattern' => exerciseNameFiveNotePattern,
        'third_leaps' => exerciseNameThirdLeaps,
        _ => fallback,
      };

  String categoryLabel(ExerciseCategory category) => switch (category) {
        ExerciseCategory.custom => categoryLabelCustom,
        ExerciseCategory.triads => categoryLabelTriads,
        ExerciseCategory.arpeggios => categoryLabelArpeggios,
        ExerciseCategory.pentatonics => categoryLabelPentatonics,
        ExerciseCategory.scales => categoryLabelScales,
        ExerciseCategory.harmonizations => categoryLabelHarmonizations,
        ExerciseCategory.patterns => categoryLabelPatterns,
      };

  String categoryDescription(ExerciseCategory category) => switch (category) {
        ExerciseCategory.custom => categoryDescriptionCustom,
        ExerciseCategory.triads => categoryDescriptionTriads,
        ExerciseCategory.arpeggios => categoryDescriptionArpeggios,
        ExerciseCategory.pentatonics => categoryDescriptionPentatonics,
        ExerciseCategory.scales => categoryDescriptionScales,
        ExerciseCategory.harmonizations => categoryDescriptionHarmonizations,
        ExerciseCategory.patterns => categoryDescriptionPatterns,
      };

  /// Obiettivo salvato (es. "Precisione") nella lingua attiva; un valore
  /// sconosciuto viene mostrato così com'è.
  String focusLabel(String focus) => switch (ExerciseFocus.parse(focus)) {
        ExerciseFocus.accuracy => focusAccuracy,
        ExerciseFocus.ear => focusEar,
        ExerciseFocus.agility => focusAgility,
        ExerciseFocus.control => focusControl,
        ExerciseFocus.range => focusRange,
        null => focus,
      };
}
