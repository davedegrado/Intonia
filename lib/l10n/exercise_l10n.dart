import '../core/music/exercise.dart';
import 'app_localizations.dart';

/// Nomi, categorie e obiettivi degli esercizi predefiniti nella lingua attiva.
/// Le sequenze personalizzate mantengono il nome scelto dall'utente.
extension ExerciseL10n on AppLocalizations {
  // STUB: implementazione completa in arrivo (gruppo D).
  String exerciseName(ExerciseDefinition exercise) => exercise.name;

  /// Nome di un esercizio predefinito dal suo id (es. per le sessioni salvate);
  /// [fallback] per gli esercizi personalizzati o sconosciuti.
  String exerciseNameById(String id, String fallback) => fallback;

  String categoryLabel(ExerciseCategory category) => category.label;

  String categoryDescription(ExerciseCategory category) => category.description;

  /// Obiettivo salvato (es. "Precisione") nella lingua attiva.
  String focusLabel(String focus) => focus;
}
