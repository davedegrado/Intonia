/// Parametri del riconoscimento delle note cantate, in un unico punto.
///
/// Il riconoscimento è diviso in tre livelli:
/// 1. **Rilevamento della frequenza** (YinPitchDetector): non cambia qui, resta
///    preciso al centesimo.
/// 2. **Riconoscimento della nota** ([PitchStabilizer]): decide quale nota
///    mostrare. È volutamente tollerante, perché la voce non è uno strumento
///    stabile: filtra i frame anomali, ignora il vibrato e le brevi cadute di
///    segnale.
/// 3. **Valutazione dell'esercizio** (TrainingStateMachine): confronta la nota
///    riconosciuta con quella richiesta usando la tolleranza dell'esercizio
///    ([defaultExerciseToleranceCents], regolabile dall'utente).
class PitchRecognitionConfig {
  const PitchRecognitionConfig({
    this.smoothingFrames = 3,
    this.noteSwitchMs = 80,
    this.immediateSwitchCents = 150,
    this.dropoutGraceMs = 100,
  });

  static const standard = PitchRecognitionConfig();

  /// Frame consecutivi su cui si calcola la mediana dell'altezza (un frame
  /// ≈ 23 ms). Con 3 un singolo frame anomalo (es. errore d'ottava) viene
  /// scartato aggiungendo circa un frame di ritardo.
  final int smoothingFrames;

  /// La nota riconosciuta passa al semitono vicino solo se la voce resta
  /// oltre il confine (a ±50 cent dal centro) per questo tempo senza
  /// interruzioni. Il vibrato attraversa il confine per tempi più brevi
  /// (circa 50–75 ms per ciclo anche con ±100 cent a 4,5–6 Hz), quindi non
  /// fa cambiare nota; una nota diversa cantata davvero sì.
  final int noteSwitchMs;

  /// Oltre questa distanza dalla nota riconosciuta (un salto più ampio di un
  /// semitono) la nuova nota è evidente e viene riconosciuta subito.
  final int immediateSwitchCents;

  /// Cadute brevi del segnale (consonanti, respiro, confidenza bassa per un
  /// frame) che non interrompono la nota in corso. Deve restare sotto la
  /// pausa che distingue un nuovo attacco (TrainingStateMachine.breakMs).
  final int dropoutGraceMs;

  /// Tolleranza predefinita degli esercizi: distanza massima dal centro della
  /// nota richiesta perché sia considerata corretta. Adatta alla voce reale;
  /// per esercizi di precisione l'utente può ridurla nelle impostazioni.
  static const defaultExerciseToleranceCents = 35;

  /// Valori selezionabili per la tolleranza degli esercizi.
  static const minExerciseToleranceCents = 10;
  static const maxExerciseToleranceCents = 50;

  /// Tolleranza predefinita del test di estensione: lì conta raggiungere la
  /// nota, non l'intonazione fine.
  static const rangeTestToleranceCents = 40;

  /// Solo indicazione visiva nel riconoscimento libero: entro questo scarto
  /// lo scostamento è mostrato come "intonato". Non influisce sul
  /// riconoscimento della nota.
  static const inTuneCents = 20;
}
