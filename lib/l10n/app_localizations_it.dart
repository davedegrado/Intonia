// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Intonia';

  @override
  String get navHome => 'Home';

  @override
  String get navExercises => 'Esercizi';

  @override
  String get navRange => 'Estensione';

  @override
  String get navProfile => 'Profilo';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonBack => 'Indietro';

  @override
  String get commonRetry => 'Riprova';

  @override
  String spanSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semitoni',
      one: '1 semitono',
    );
    return '$_temp0';
  }

  @override
  String spanOctaves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ottave',
      one: '1 ottava',
    );
    return '$_temp0';
  }

  @override
  String spanOctavesAndSemitones(String octaves, String semitones) {
    return '$octaves + $semitones';
  }

  @override
  String get languageSectionTitle => 'Lingua';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHint =>
      'I nomi delle note (C D E oppure DO RE MI) si scelgono a parte, in Notazione delle note.';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeNeon => 'Neon';

  @override
  String get notationInternational => 'C D E';

  @override
  String get notationItalian => 'DO RE MI';

  @override
  String get trainerAdvancedSettings => 'Impostazioni avanzate';

  @override
  String get trainerCurrentNote => 'Nota corrente';

  @override
  String get trainerPlayCurrentNote => 'Ascolta la nota corrente';

  @override
  String get trainerSessionStats => 'Statistiche sessione';

  @override
  String get trainerStartingNote => 'Nota di partenza:';

  @override
  String get trainerKey => 'Tonalità';

  @override
  String get trainerOctave => 'Ottava';

  @override
  String get trainerModeListen => 'Ascolto';

  @override
  String get trainerModeTrain => 'Allenamento';

  @override
  String get trainerPlay => 'Play';

  @override
  String get trainerStop => 'Stop';

  @override
  String get trainerBpm => 'BPM';

  @override
  String trainerSettingValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get trainerTolerance => 'Tolleranza';

  @override
  String trainerToleranceValue(int cents) {
    return '± $cents cent';
  }

  @override
  String get trainerStabilityTime => 'Durata stabilità';

  @override
  String trainerMilliseconds(int ms) {
    return '$ms ms';
  }

  @override
  String get trainerGuideEveryNote => 'Suona la guida su ogni nota';

  @override
  String get trainerGuideEveryNoteHint =>
      'Se disattivo, senti solo la prima nota: tocca una nota per riascoltarla';

  @override
  String get trainerLoop => 'Loop (solo modalità Ascolto)';

  @override
  String get trainerCalibrate => 'Calibra rumore di fondo';

  @override
  String get trainerCalibrating => 'Resta in silenzio… (3 s)';

  @override
  String get trainerCalibrationFailed =>
      'Calibrazione non riuscita: controlla il permesso microfono.';

  @override
  String get trainerCalibrationDone => 'Calibrazione completata: rumore di fondo filtrato.';

  @override
  String get trainerStatusMicOn => 'Microfono attivo';

  @override
  String get trainerStatusPlaying => 'Riproduzione';

  @override
  String get trainerStatusReady => 'Pronta';

  @override
  String get trainerMicrophoneDenied =>
      'Permesso microfono negato: abilitalo nelle impostazioni di sistema per allenarti.';

  @override
  String get trainerAudioUnavailable =>
      'Audio non inizializzato: verifica microfono e SoundFont piano.sf2.';

  @override
  String get trainerDetection => 'Riconoscimento';

  @override
  String get trainerDetectedNote => 'Nota rilevata';

  @override
  String get trainerDeviation => 'Scostamento';

  @override
  String trainerCentsValue(String value) {
    return '$value cent';
  }

  @override
  String get trainerListening => 'In ascolto';

  @override
  String get trainerInTune => 'intonata';

  @override
  String get trainerTooLow => 'troppo bassa';

  @override
  String get trainerTooHigh => 'troppo alta';

  @override
  String get trainerStatTime => 'Tempo';

  @override
  String get trainerStatErrors => 'Errori';

  @override
  String get trainerStatAccuracy => 'Accuratezza';

  @override
  String get trainerStatCorrect => 'Corrette';

  @override
  String get trainerViewNotes => 'Note';

  @override
  String get trainerViewStaff => 'Pentagramma';

  @override
  String trainerNoteCorrect(String note) {
    return '$note, corretta';
  }

  @override
  String trainerNoteWrong(String note) {
    return '$note, da riprovare';
  }

  @override
  String trainerNoteCurrent(String note) {
    return '$note, nota corrente';
  }

  @override
  String trainerNotePending(String note) {
    return '$note, da cantare';
  }

  @override
  String get trainerTapToHear => 'tocca per ascoltarla';

  @override
  String trainerStaffSemantics(String notes) {
    return 'Pentagramma: $notes';
  }

  @override
  String get mascotSemanticLabel => 'Mascotte di Intonia';

  @override
  String get mascotCompleted => 'Esercizio completato! Grande lavoro.';

  @override
  String get mascotSuccess => 'Perfetto! Continua così.';

  @override
  String get mascotRetry => 'Quasi! Prova ancora.';

  @override
  String get mascotListenSequence => 'Ascolta bene la sequenza…';

  @override
  String get mascotSingNote => 'Canta la nota: ti ascolto.';

  @override
  String get mascotIdleListen => 'Premi Play e ascolta la sequenza.';

  @override
  String get mascotIdleTrain => 'Pronto ad allenare il tuo orecchio?';

  @override
  String get sessionPerfectTitle => 'Perfetto!';

  @override
  String get sessionPerfectMessage => 'Nessun errore: sei intonatissimo!';

  @override
  String get sessionGreatTitle => 'Ottimo lavoro!';

  @override
  String get sessionGreatMessage => 'Quasi perfetto: l\'orecchio sta migliorando.';

  @override
  String get sessionGoodTitle => 'Bene!';

  @override
  String get sessionGoodMessage => 'Ci sei quasi: ripeti per fissare le note.';

  @override
  String get sessionRetryTitle => 'Non mollare!';

  @override
  String get sessionRetryMessage => 'Riascolta le note e riprova: migliori a ogni giro.';

  @override
  String get sessionCorrect => 'Corrette';

  @override
  String get sessionErrors => 'Errori';

  @override
  String get sessionDuration => 'Durata';

  @override
  String sessionSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get sessionAccuracy => 'precisione';

  @override
  String sessionAccuracySemantics(int percent) {
    return 'Precisione $percent per cento';
  }

  @override
  String get sessionContinue => 'Continua';

  @override
  String get sessionRepeat => 'Ripeti esercizio';

  @override
  String get rangeSectionTitle => 'Estensione vocale';

  @override
  String get rangeHeadline => 'Scopri la tua estensione vocale';

  @override
  String get rangeIntro =>
      'Parti da una nota comoda: scendiamo fino alla più grave e saliamo fino alla più acuta che riesci a cantare. Il risultato resta nel profilo per seguire i progressi.';

  @override
  String get rangeStartTest => 'Avvia test';

  @override
  String get rangeRetakeTest => 'Rifai il test';

  @override
  String get rangeNoTestsYet => 'Nessun test ancora: il tuo risultato comparirà qui.';

  @override
  String get rangePreviousTests => 'Test precedenti';

  @override
  String get rangeHistoryInProfile => 'Storico dei test nel profilo';

  @override
  String get rangeLatestResult => 'Ultimo risultato';

  @override
  String rangeSpanDetail(String span, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semitoni',
      one: '1 semitono',
    );
    return '$span ($_temp0)';
  }

  @override
  String get rangeLowest => 'Più grave';

  @override
  String get rangeHighest => 'Più acuta';

  @override
  String rangeDeltaShort(String delta) {
    return '$delta st';
  }

  @override
  String get rangeTestTitle => 'Test estensione vocale';

  @override
  String get rangeHowItWorks => 'Come funziona';

  @override
  String get rangeHowItWorksBody =>
      'Premi \"Inizia il test\" e canta una nota comoda, tenendola per un momento: la riconosco e da lì scendiamo un semitono alla volta. Si avanza solo quando becchi la nota; quando proprio non ci arrivi, premi \"Limite grave raggiunto\" (o salta la singola nota). Poi si sale verso l\'acuto allo stesso modo. Alla fine l\'estensione viene salvata nel profilo.';

  @override
  String get rangeSensitivity => 'Sensibilità';

  @override
  String get rangeTolerance => 'Tolleranza';

  @override
  String get rangeStabilityTime => 'Durata stabilità';

  @override
  String rangeCents(int cents) {
    return '± $cents cent';
  }

  @override
  String get rangeLastTestPrefix => 'Ultimo test: ';

  @override
  String get rangeStartButton => 'Inizia il test';

  @override
  String get rangeTowardLow => 'Verso il grave';

  @override
  String get rangeTowardHigh => 'Verso l\'acuto';

  @override
  String get rangeSingThisNote => 'Canta questa nota (tocca per risentirla)';

  @override
  String get rangeValidatedSoFar => 'Range convalidato finora: ';

  @override
  String get rangeSkipNote => 'Salta questa nota';

  @override
  String get rangeLowLimitReached => 'Limite grave raggiunto';

  @override
  String get rangeHighLimitReached => 'Limite acuto raggiunto';

  @override
  String get rangeCancelTest => 'Annulla il test';

  @override
  String get rangeSingComfortable => 'Canta una nota comoda e tienila';

  @override
  String get rangeListening => 'In ascolto…';

  @override
  String get rangeStartHoldHint => 'Quando la barra è piena, quella è la tua nota di partenza.';

  @override
  String get rangeYourRange => 'La tua estensione';

  @override
  String rangeProgressBetter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count semitoni',
      one: '+1 semitono',
    );
    return '$_temp0 rispetto all\'ultimo test';
  }

  @override
  String get rangeProgressSame => 'Stessa ampiezza dell\'ultimo test';

  @override
  String rangeProgressWorse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '-$count semitoni',
      one: '-1 semitono',
    );
    return '$_temp0 rispetto all\'ultimo test';
  }

  @override
  String rangeProgressWorseEncouraging(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '-$count semitoni',
      one: '-1 semitono',
    );
    return '$_temp0 rispetto all\'ultimo test: capita, la voce cambia di giorno in giorno';
  }

  @override
  String get rangeSavedToProfile =>
      'Risultato salvato nel profilo: lo storico dei test ti mostra i progressi nel tempo.';

  @override
  String get rangeRetryTest => 'Riprova il test';

  @override
  String get rangeContinue => 'Continua';

  @override
  String get rangeCoachValidated => 'Bravo! Prossima nota.';

  @override
  String get rangeCoachSkipped => 'Nessun problema, proviamo la prossima.';

  @override
  String get rangeCoachSetup => 'Parti da una nota comoda: scendiamo insieme verso il grave.';

  @override
  String get rangeCoachFindingStart => 'Canta una nota comoda e tienila: la riconosco io.';

  @override
  String get rangeCoachDescending => 'Canta la nota: andiamo verso il grave.';

  @override
  String get rangeCoachAscending => 'Ora saliamo verso l\'acuto!';

  @override
  String get rangeCoachDone => 'Ecco la tua estensione! Ottimo lavoro.';

  @override
  String get rangeCoachRetry => 'Riproviamo partendo da una nota più comoda.';

  @override
  String get rangeMicDenied =>
      'Permesso microfono negato: abilitalo nelle impostazioni di sistema.';

  @override
  String get rangeAudioInitFailed => 'Audio non inizializzato: verifica microfono e SoundFont.';

  @override
  String get rangeNothingValidated => 'Nessuna nota convalidata: il test non è stato salvato.';

  @override
  String get rangeResultFirst => 'Ecco la tua estensione!';

  @override
  String get rangeResultBetter => 'Nuovo record!';

  @override
  String get rangeResultSame => 'Estensione confermata!';

  @override
  String get rangeResultWorse => 'Ecco la tua estensione di oggi';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get profileSettingsTooltip => 'Impostazioni';

  @override
  String get profileEmptyTitle => 'Nessuna sessione ancora';

  @override
  String get profileEmptyBody =>
      'Completa un allenamento: qui troverai streak, accuratezza, estensione vocale e storico.';

  @override
  String get profileStatSessions => 'Sessioni';

  @override
  String get profileStatMinutes => 'Minuti totali';

  @override
  String get profileStatAccuracy => 'Accuratezza media';

  @override
  String get profileStatRange => 'Estensione';

  @override
  String get profileBestWorstNotes => 'Note migliori e peggiori';

  @override
  String get profileRangeTests => 'Test estensione vocale';

  @override
  String profileRangeDeltaUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count semitoni',
      one: '+1 semitono',
    );
    return '$_temp0 rispetto al precedente';
  }

  @override
  String profileRangeDeltaDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '-$count semitoni',
      one: '-1 semitono',
    );
    return '$_temp0 rispetto al precedente';
  }

  @override
  String get profileRangeUnchanged => 'invariato';

  @override
  String get profileDeleteRangeTooltip => 'Elimina test';

  @override
  String get profileDeleteSessionTooltip => 'Elimina sessione';

  @override
  String get profileAllSessions => 'Tutte le sessioni';

  @override
  String get profileRecentSessions => 'Ultime sessioni';

  @override
  String profileFullHistoryPro(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessioni',
      one: '1 sessione',
    );
    return 'Storico completo ($_temp0) con Intonia Pro';
  }

  @override
  String get profileDeleteRangeTitle => 'Eliminare il test?';

  @override
  String profileDeleteRangeBody(String date) {
    return 'Il test del $date verrà rimosso.';
  }

  @override
  String get profileDeleteSessionTitle => 'Eliminare la sessione?';

  @override
  String profileDeleteSessionBody(String name, String date) {
    return '\"$name\" del $date verrà rimossa da statistiche, streak ed estensione vocale.';
  }

  @override
  String profileStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni di fila',
      one: '1 giorno di fila',
    );
    return '$_temp0';
  }

  @override
  String get profileStreakStart => 'Allenati oggi per far partire la streak!';

  @override
  String get profileStreakKeep => 'Continua così, non spezzarla!';

  @override
  String get exerciseNameTriadMajor => 'Triade maggiore';

  @override
  String get exerciseNameTriadMinor => 'Triade minore';

  @override
  String get exerciseNameTriadAugmented => 'Triade aumentata';

  @override
  String get exerciseNameTriadDiminished => 'Triade diminuita';

  @override
  String get exerciseNameArpeggioMajorOctave => 'Arpeggio maggiore (8ª)';

  @override
  String get exerciseNameArpeggioMinorOctave => 'Arpeggio minore (8ª)';

  @override
  String get exerciseNameMajorPentatonic => 'Pentatonica maggiore';

  @override
  String get exerciseNameMinorPentatonic => 'Pentatonica minore';

  @override
  String get exerciseNameMajor => 'Scala maggiore';

  @override
  String get exerciseNameNaturalMinor => 'Minore naturale';

  @override
  String get exerciseNameHarmonicMinor => 'Minore armonica';

  @override
  String get exerciseNameMelodicMinor => 'Minore melodica';

  @override
  String get exerciseNameBlues => 'Scala blues';

  @override
  String get exerciseNameHarmonizedMajor => 'Scala maggiore armonizzata';

  @override
  String get exerciseNameHarmonizedNaturalMinor => 'Minore naturale armonizzata';

  @override
  String get exerciseNameHarmonizedHarmonicMinor => 'Minore armonica armonizzata';

  @override
  String get exerciseNameHarmonizedMelodicMinor => 'Minore melodica armonizzata';

  @override
  String get exerciseNameFiveNotePattern => 'Pattern 5 note (1-2-3-4-5)';

  @override
  String get exerciseNameThirdLeaps => 'Salti di terza (1-3, 2-4...)';

  @override
  String get categoryLabelCustom => 'Le tue sequenze';

  @override
  String get categoryDescriptionCustom => 'Crea e allena le tue sequenze personalizzate';

  @override
  String get categoryLabelTriads => 'Triadi';

  @override
  String get categoryDescriptionTriads => 'Maggiore, minore, aumentata e diminuita';

  @override
  String get categoryLabelArpeggios => 'Arpeggi';

  @override
  String get categoryDescriptionArpeggios => 'Triadi estese all\'ottava';

  @override
  String get categoryLabelPentatonics => 'Pentatoniche';

  @override
  String get categoryDescriptionPentatonics => 'Maggiore e minore';

  @override
  String get categoryLabelScales => 'Scale';

  @override
  String get categoryDescriptionScales => 'Maggiori, minori e blues';

  @override
  String get categoryLabelHarmonizations => 'Armonizzazioni a 3 voci';

  @override
  String get categoryDescriptionHarmonizations => 'Triadi diatoniche su ogni grado della scala';

  @override
  String get categoryLabelPatterns => 'Pattern';

  @override
  String get categoryDescriptionPatterns => 'Sequenze melodiche di riscaldamento';

  @override
  String get focusAccuracy => 'Precisione';

  @override
  String get focusEar => 'Orecchio';

  @override
  String get focusAgility => 'Agilità';

  @override
  String get focusControl => 'Controllo';

  @override
  String get focusRange => 'Estensione';

  @override
  String get editorTitleNew => 'Nuova sequenza';

  @override
  String get editorTitleEdit => 'Modifica sequenza';

  @override
  String get editorNameLabel => 'Nome';

  @override
  String get editorNameHint => 'Es. Sirene d\'ottava / Vocalizzo 1-3-5-8';

  @override
  String get editorGroupLabel => 'Gruppo (opzionale)';

  @override
  String get editorGroupHint => 'Es. Riscaldamento, Lezione 3…';

  @override
  String get editorTagLabel => 'Tag (opzionale)';

  @override
  String get editorAddNotesTitle => 'Aggiungi note';

  @override
  String get editorAddNotesHint =>
      'Puoi partire da qualsiasi nota, ripetere la stessa nota e scendere sotto la prima. Nel trainer potrai comunque trasporre tutta la sequenza.';

  @override
  String editorOctaveShort(int octave) {
    return 'Ott. $octave';
  }

  @override
  String editorSequenceTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequenza ($count note)',
      one: 'Sequenza (1 nota)',
    );
    return '$_temp0';
  }

  @override
  String get editorPreview => 'Anteprima';

  @override
  String get editorRemoveLast => 'Rimuovi ultima nota';

  @override
  String get editorEmptySequence => 'Tocca le note qui sopra per costruire la sequenza.';

  @override
  String get editorErrorNoName => 'Dai un nome alla sequenza.';

  @override
  String get editorErrorTooFewNotes => 'Aggiungi almeno 2 note.';

  @override
  String get editorAudioUnavailable => 'Audio non disponibile: verifica il SoundFont piano.sf2.';

  @override
  String get editorProTitle => 'Crea la tua sequenza';

  @override
  String get editorProHeadline => 'Le tue sequenze, su misura';

  @override
  String get editorProBody =>
      'Componi qualsiasi giro di note partendo dalla nota che vuoi: vocalizzi, pattern, salti, prove di estensione. Le sequenze si salvano nella Home, raggruppate come preferisci, e si allenano come gli esercizi predefiniti.';

  @override
  String get editorProNote =>
      'Creare, modificare e salvare sequenze è una funzione di Intonia Pro. Le sequenze che hai già salvato restano disponibili.';

  @override
  String get editorProCta => 'Scopri Intonia Pro';

  @override
  String noteSemanticsLabel(String note, int octave) {
    return '$note, ottava $octave';
  }

  @override
  String statusStreakSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serie: $count giorni di fila',
      one: 'Serie: 1 giorno di fila',
    );
    return '$_temp0';
  }

  @override
  String get homeBubbleIdle => 'Canta o suona una nota: ti dico qual è!';

  @override
  String get homeBubbleListening => 'Ti ascolto… canta o suona una nota.';

  @override
  String get homeBubbleInTune => 'Perfettamente intonata!';

  @override
  String get homeBubbleAlmost => 'Ci sei quasi: aggiusta un pochino.';

  @override
  String get homeBubblePermissionDenied =>
      'Permesso microfono negato: attivalo nelle impostazioni.';

  @override
  String get homeStartListening => 'Avvia ascolto';

  @override
  String get homeStopListening => 'Ferma ascolto';

  @override
  String get homeMicStartSemantics => 'Avvia il riconoscimento delle note';

  @override
  String get homeMicStopSemantics => 'Ferma il riconoscimento';

  @override
  String get homeNotePlaceholder => 'Qui vedrai la nota riconosciuta e quanto sei intonato.';

  @override
  String get homeNoteDetected => 'Nota rilevata';

  @override
  String get homeLastNote => 'Ultima nota';

  @override
  String get homeDeviation => 'Scostamento';

  @override
  String homeCents(String value) {
    return '$value cent';
  }

  @override
  String get homeQuickNotation => 'Notazione';

  @override
  String get homeQuickTheme => 'Tema';

  @override
  String get homeQuickSettings => 'Impostazioni';

  @override
  String get exercisesCategories => 'Categorie';

  @override
  String exercisesSequenceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sequenze',
      one: '1 sequenza',
    );
    return '$_temp0';
  }

  @override
  String exercisesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esercizi',
      one: '1 esercizio',
    );
    return '$_temp0';
  }

  @override
  String exercisesNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count note',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String get exercisesProBadge => 'PRO';

  @override
  String get exercisesEdit => 'Modifica';

  @override
  String get exercisesDeleteTitle => 'Eliminare la sequenza?';

  @override
  String exercisesDeleteMessage(String name) {
    return '“$name” verrà rimossa definitivamente.';
  }

  @override
  String get exercisesCreateTitle => 'Crea la tua sequenza';

  @override
  String get exercisesCreateSubtitle =>
      'Componi qualsiasi giro di note: pattern, vocalizzi, prove di estensione…';

  @override
  String get chargesProSemantics => 'Intonia Pro: esercizi illimitati';

  @override
  String get chargesProDeveloperSemantics => 'Intonia Pro, build sviluppatore: esercizi illimitati';

  @override
  String chargesChipSemantics(int count, int max) {
    return 'Cariche esercizi: $count su $max';
  }

  @override
  String get chargesWaitUnderMinute => 'meno di 1 min';

  @override
  String chargesWaitMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String chargesWaitHours(int hours) {
    return '$hours h';
  }

  @override
  String chargesWaitHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get chargesTitle => 'Cariche esercizi';

  @override
  String get chargesExhaustedTitle => 'Cariche esaurite';

  @override
  String chargesNextIn(String wait) {
    return 'Prossima carica tra $wait.';
  }

  @override
  String chargesExplanation(int hours, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Se ne ricarica una ogni $hours ore',
      one: 'Se ne ricarica una ogni ora',
    );
    return 'Ogni sessione di esercizio usa una carica. $_temp0, anche ad app chiusa, fino a $max.';
  }

  @override
  String get chargesFreeFeatures =>
      'Il riconoscimento in tempo reale e il test di estensione vocale sono sempre gratuiti e illimitati.';

  @override
  String get chargesDiscoverPro => 'Scopri Intonia Pro';

  @override
  String get chargesWaitForRecharge => 'Aspetto la ricarica';

  @override
  String chargesHint(int count, int max) {
    return 'Ogni sessione usa 1 carica · $count/$max disponibili';
  }

  @override
  String get proTitle => 'Intonia Pro';

  @override
  String get proHeadlinePro => 'Hai Intonia Pro';

  @override
  String get proHeadlineFree => 'Allenati senza limiti';

  @override
  String get proDeveloperNote => 'Build sviluppatore: Pro attivo senza abbonamento.';

  @override
  String get proBenefitUnlimitedTitle => 'Esercizi illimitati';

  @override
  String get proBenefitUnlimitedText => 'Nessuna carica: tutte le sessioni che vuoi.';

  @override
  String get proBenefitCustomTitle => 'Sequenze personalizzate';

  @override
  String get proBenefitCustomText => 'Crea, modifica e salva i tuoi esercizi.';

  @override
  String get proBenefitHistoryTitle => 'Storico completo';

  @override
  String get proBenefitHistoryText => 'Tutte le tue sessioni nel profilo.';

  @override
  String get proBenefitComingTitle => 'In arrivo';

  @override
  String get proBenefitComingText =>
      'Statistiche avanzate, grafici dei progressi e percorsi personalizzati.';

  @override
  String proFreeForever(int max) {
    return 'Gratis per sempre: riconoscimento delle note in tempo reale, test di estensione vocale, tutti gli esercizi con $max cariche che si ricaricano, profilo, statistiche essenziali e serie giornaliera.';
  }

  @override
  String get proPlanMonthly => 'Mensile';

  @override
  String get proPlanYearly => 'Annuale';

  @override
  String get proPriceMonthly => '€4,99';

  @override
  String get proPriceYearly => '€39,99';

  @override
  String get proPeriodMonth => 'al mese';

  @override
  String get proPeriodYear => 'all\'anno';

  @override
  String get proYearlySaving => 'Risparmi il 33%';

  @override
  String get proSubscribe => 'Abbonati';

  @override
  String get proComingSoon =>
      'Gli abbonamenti saranno disponibili a breve tramite App Store e Google Play.';

  @override
  String get proRestore => 'Ripristina acquisti';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsNotation => 'Notazione delle note';

  @override
  String get settingsInfo => 'Info';

  @override
  String settingsAbout(String version) {
    return 'Intonia $version — allenamento di intonazione offline.';
  }

  @override
  String get settingsSoundCredit =>
      'Suono di pianoforte: Fluid (R3) SoundFont, © 2000–2002, 2008 Frank Wen, licenza MIT.';

  @override
  String get settingsLicenses => 'Licenze';

  @override
  String get trainerDirectionForward => 'Ascendente';

  @override
  String get trainerDirectionReverse => 'Discendente';

  @override
  String get trainerDirectionComplete => 'Completo';

  @override
  String get trainerRepeatTop => 'Ripeti la nota di vertice';

  @override
  String get trainerRepeatTopHint => 'Ripete la nota più alta prima di scendere';

  @override
  String get exercisesCreateFromScratch => 'Crea da zero';

  @override
  String get exercisesCreateFromExercise => 'Parti da un esercizio';

  @override
  String get exercisesCreateFromExerciseHint => 'Copia un esercizio e modificalo liberamente';

  @override
  String profileSessionKeyOctave(String key, int octave) {
    return '$key · Ottava $octave';
  }

  @override
  String get profileSessionTopRepeated => 'vertice ripetuto';

  @override
  String get guideTitle => 'Guida di Intonia';

  @override
  String get guideOpenHint => 'Rivedi le spiegazioni delle funzioni dell\'app';

  @override
  String get guideNext => 'Avanti';

  @override
  String get guideDone => 'Fine';

  @override
  String get guideSkip => 'Salta';

  @override
  String guideProgress(int current, int total) {
    return '$current di $total';
  }

  @override
  String get guideKey => 'La nota da cui parte l\'esercizio.';

  @override
  String get guideOctave =>
      'Quanto in alto o in basso si svolge l\'esercizio: scegline una comoda per la tua voce.';

  @override
  String get guideDirectionTitle => 'Modalità';

  @override
  String get guideDirection =>
      'Ascendente esegue la sequenza dal basso verso l\'alto, Discendente dall\'alto verso il basso, Completo sale e poi riscende.';

  @override
  String get guideRepeatTop =>
      'Solo in Completo: canti due volte la nota più alta prima di scendere.';

  @override
  String get rangeNotMine => 'Non ero io';

  @override
  String get rangeNotMineResult => 'Non ero io: togli questo test';

  @override
  String get rangeNotMineTitle => 'Non era il tuo test?';

  @override
  String rangeNotMineBody(String date) {
    return 'Il test del $date verrà tolto dai risultati e dallo storico.';
  }

  @override
  String get rangeNotMineConfirm => 'Togli';

  @override
  String get tessituraTitle => 'Test di tessitura';

  @override
  String get tessituraSectionTitle => 'Zona comoda (tessitura)';

  @override
  String get tessituraSectionIntro =>
      'Non la nota più alta o più bassa: la parte della voce in cui cantare ti viene facile.';

  @override
  String get tessituraStart => 'Trova la tua zona comoda';

  @override
  String get tessituraRetake => 'Rifai il test di tessitura';

  @override
  String get tessituraHowItWorks =>
      'Canti una nota alla volta, dopo averla ascoltata al piano: prima una nota comoda per verificare che ti senta bene, poi salendo e scendendo per semitoni, alcune note tenute più a lungo e alcune ripetute. Ogni tanto ti chiedo quanto sforzo ti è costato. Circa 5–8 minuti; puoi fermarti quando vuoi.';

  @override
  String get tessituraUsesRange =>
      'Parto dal tuo ultimo test di estensione e mi muovo su e giù da lì.';

  @override
  String get tessituraNoRange =>
      'Non hai ancora un test di estensione: si parte tenendo una nota comoda. Con un test di estensione la mappa è più affidabile.';

  @override
  String get tessituraNotAClassification =>
      'È una stima per allenarti, non una classificazione della voce (soprano, contralto, tenore, basso) né una valutazione medica.';

  @override
  String get tessituraCoachIntro => 'Cerchiamo dove la tua voce si sente a casa!';

  @override
  String get tessituraCoachFindStart => 'Tieni una nota che ti viene facile.';

  @override
  String get tessituraCoachRate => 'Dimmi com\'è andata.';

  @override
  String get tessituraCoachDone => 'Ecco la tua stima!';

  @override
  String get tessituraCoachProvisional =>
      'Una prima stima: ripeti il test per renderla più precisa.';

  @override
  String get tessituraFinishNow => 'Termina ora';

  @override
  String get tessituraCancel => 'Annulla';

  @override
  String get tessituraComfortZone => 'Zona comoda';

  @override
  String get tessituraNoZone => 'Dati insufficienti';

  @override
  String get tessituraToVerify => 'Da verificare';

  @override
  String tessituraReliability(String level) {
    return 'Attendibilità: $level';
  }

  @override
  String get tessituraReliabilityLow => 'bassa';

  @override
  String get tessituraReliabilityMedium => 'media';

  @override
  String get tessituraReliabilityHigh => 'alta';

  @override
  String get tessituraProvisional => 'Stima provvisoria';

  @override
  String get tessituraLastResult => 'Ultimo risultato';

  @override
  String tessituraCompareSame(String date) {
    return 'Stessa ampiezza del $date.';
  }

  @override
  String tessituraCompareDelta(String date, String delta) {
    return '$delta semitoni rispetto al $date.';
  }

  @override
  String get tessituraLegend =>
      'Tre fasce separate: estensione osservata (tutte le note raggiunte), estensione utilizzabile (note riuscite in modo affidabile) e zona comoda (note stabili, ripetibili e facili per te). Punti: note da ricontrollare. È una stima basata sulle prove e sul tuo giudizio, non una misura fisiologica: può cambiare con la giornata, il riscaldamento e la stanchezza.';

  @override
  String get workoutTitle => 'Allenamento del giorno';

  @override
  String get workoutGoal =>
      'Una sessione pronta con gli esercizi che già conosci: riscaldamento, alcuni esercizi principali e un ripasso finale. Quando ci sono abbastanza dati riprende anche gli esercizi che trovi più difficili.';

  @override
  String get workoutCoachReady => 'Pronto per la sessione di oggi?';

  @override
  String get workoutCoachDone => 'Allenamento finito, bravo!';

  @override
  String get workoutCoachPartial => 'Buon lavoro: la prossima volta prova anche quelli saltati.';

  @override
  String get workoutDurationLabel => 'Durata';

  @override
  String workoutMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String workoutSummaryLine(int minutes, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esercizi',
      one: '1 esercizio',
    );
    return 'Circa $minutes min · $_temp0';
  }

  @override
  String get workoutBalanced =>
      'Routine bilanciata: non ci sono ancora abbastanza dati sulle tue sessioni.';

  @override
  String get workoutPersonalized => 'In base alle tue sessioni precedenti.';

  @override
  String workoutPersonalizedHard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esercizi',
      one: '1 esercizio',
    );
    return 'In base alle tue sessioni precedenti, con $_temp0 da ripassare.';
  }

  @override
  String get workoutDurationNote =>
      'I tempi sono indicativi: vengono dalle tue sessioni precedenti o, se non ce ne sono, dal numero di note.';

  @override
  String workoutChargesNote(int count, int available) {
    return 'Ogni esercizio usa 1 carica, come gli altri esercizi ($count esercizi, ne hai $available).';
  }

  @override
  String get workoutStart => 'Inizia l\'allenamento';

  @override
  String get workoutRoleWarmUp => 'Riscaldamento';

  @override
  String get workoutRoleMain => 'Principale';

  @override
  String get workoutRoleReview => 'Ripasso';

  @override
  String get workoutDifficultTag => 'da ripassare';

  @override
  String get workoutDifficultReason =>
      'Scelto perché nelle ultime sessioni ti è risultato più difficile.';

  @override
  String workoutApproxMinutes(int minutes) {
    return '~$minutes min';
  }

  @override
  String workoutApproxSeconds(int seconds) {
    return '~$seconds s';
  }

  @override
  String workoutProgress(int done, int total) {
    return '$done di $total fatti';
  }

  @override
  String workoutRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mancano $count esercizi',
      one: 'Manca 1 esercizio',
      zero: 'Finito l\'ultimo',
    );
    return '$_temp0';
  }

  @override
  String workoutStepOf(int index, int total) {
    return '$index di $total';
  }

  @override
  String get workoutOpenStep => 'Inizia l\'esercizio';

  @override
  String get workoutSkip => 'Salta';

  @override
  String get workoutSkipped => 'Saltato';

  @override
  String get workoutInterrupt => 'Interrompi l\'allenamento';

  @override
  String get workoutInterruptTitle => 'Interrompere l\'allenamento?';

  @override
  String get workoutInterruptBody =>
      'Verrà salvato come interrotto, non come completato. Gli esercizi finiti restano nella cronologia.';

  @override
  String get workoutKeepGoing => 'Continua';

  @override
  String get workoutCompleted => 'Allenamento completato';

  @override
  String get workoutPartial => 'Allenamento finito con qualche esercizio saltato';

  @override
  String workoutDoneLine(int done, int total) {
    return '$done esercizi completati su $total';
  }

  @override
  String workoutAccuracyLine(int percent) {
    return 'Precisione complessiva: $percent%';
  }

  @override
  String workoutInProgress(int done, int total) {
    return 'In corso: $done di $total';
  }

  @override
  String get workoutDoneToday => 'Completato oggi';

  @override
  String workoutPartialToday(int done, int total) {
    return 'Fatto oggi: $done di $total';
  }

  @override
  String get achievementsTitle => 'Obiettivi e badge';

  @override
  String get achievementsCoach => 'Ogni piccolo passo conta!';

  @override
  String get achievementsStreakCurrent => 'Serie attuale';

  @override
  String get achievementsStreakBest => 'Serie migliore';

  @override
  String get achievementsBadges => 'Badge';

  @override
  String achievementsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String achievementsBadgeCount(int unlocked, int total) {
    return '$unlocked di $total';
  }

  @override
  String get achievementsDaily => 'Missioni di oggi';

  @override
  String get achievementsDailyHint => 'Nuove missioni ogni giorno a mezzanotte.';

  @override
  String get achievementsWeekly => 'Missioni della settimana';

  @override
  String achievementsWeeklyHint(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Fino a domenica $dateString.';
  }

  @override
  String get achievementsMissionDone => 'Fatto';

  @override
  String achievementsProgress(int value, int target) {
    return '$value di $target';
  }

  @override
  String achievementsUnlockedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Sbloccato il $dateString';
  }

  @override
  String get achievementsLocked => 'Da sbloccare';

  @override
  String get achievementsUnlocked => 'Sbloccato';

  @override
  String get achievementsToastTitle => 'Badge sbloccato!';

  @override
  String achievementsProfileSummary(int unlocked, int total, int done, int missions) {
    return '$unlocked/$total badge · missioni di oggi $done/$missions';
  }

  @override
  String get achievementsCategoryConsistency => 'Costanza';

  @override
  String get achievementsCategoryTraining => 'Allenamento';

  @override
  String get achievementsCategoryAccuracy => 'Precisione';

  @override
  String get achievementsCategoryExploration => 'Esplorazione';

  @override
  String get achievementsCountingRules =>
      'Contano solo gli esercizi completati (non quelli interrotti), ognuno una volta sola. Gli obiettivi di precisione richiedono almeno 5 note cantate. La serie conta i giorni con almeno una sessione: aprire l\'app non basta.';

  @override
  String get achievementNoteRunHint =>
      'Contato dalle sessioni registrate da questa versione di Intonia in poi.';

  @override
  String get achievementFirstExerciseName => 'Primo passo';

  @override
  String get achievementFirstExerciseDesc => 'Completa il tuo primo esercizio.';

  @override
  String get achievementDays3Name => 'Tre giorni';

  @override
  String get achievementDays3Desc => 'Completa esercizi in 3 giorni diversi.';

  @override
  String get achievementDays7Name => 'Sette giorni';

  @override
  String get achievementDays7Desc => 'Completa esercizi in 7 giorni diversi.';

  @override
  String get achievementStreak7Name => 'Serie di 7';

  @override
  String get achievementStreak7Desc => 'Allenati 7 giorni di fila.';

  @override
  String get achievementStreak30Name => 'Serie di 30';

  @override
  String get achievementStreak30Desc => 'Allenati 30 giorni di fila.';

  @override
  String get achievementExercises5Name => 'Si comincia';

  @override
  String get achievementExercises5Desc => 'Completa 5 esercizi.';

  @override
  String get achievementExercises25Name => 'In forma';

  @override
  String get achievementExercises25Desc => 'Completa 25 esercizi.';

  @override
  String get achievementFirstWorkoutName => 'Primo allenamento';

  @override
  String get achievementFirstWorkoutDesc => 'Completa un Allenamento del giorno.';

  @override
  String get achievementWorkouts5Name => 'Cinque allenamenti';

  @override
  String get achievementWorkouts5Desc => 'Completa 5 Allenamenti del giorno.';

  @override
  String get achievementWorkouts10Name => 'Dieci allenamenti';

  @override
  String get achievementWorkouts10Desc => 'Completa 10 Allenamenti del giorno.';

  @override
  String get achievementPerfectName => 'Perfetto!';

  @override
  String get achievementPerfectDesc => 'Completa un esercizio con il 100% di precisione.';

  @override
  String get achievementAccurate5Name => 'Orecchio fino';

  @override
  String get achievementAccurate5Desc => 'Completa 5 esercizi con almeno il 90% di precisione.';

  @override
  String get achievementNoteRun10Name => 'Dieci di fila';

  @override
  String get achievementNoteRun10Desc => 'Canta 10 note corrette di fila in un esercizio.';

  @override
  String get achievementCategories3Name => 'Esploratore';

  @override
  String get achievementCategories3Desc => 'Completa esercizi in 3 categorie diverse.';

  @override
  String get achievementFirstTessituraName => 'Zona comoda';

  @override
  String get achievementFirstTessituraDesc => 'Completa il test di tessitura.';

  @override
  String get achievementSecondTessituraName => 'Di nuovo in zona';

  @override
  String get achievementSecondTessituraDesc => 'Rifai il test di tessitura in un altro giorno.';

  @override
  String get missionDailyExercises2 => 'Completa 2 esercizi oggi';

  @override
  String get missionDailyExercises3 => 'Completa 3 esercizi oggi';

  @override
  String get missionDailyWorkout => 'Completa l\'Allenamento del giorno';

  @override
  String get missionDailyAccuracy90 => 'Ottieni almeno il 90% in un esercizio';

  @override
  String get missionWeeklyCategories2 => 'Completa esercizi in 2 categorie';

  @override
  String get missionWeeklyDays3 => 'Completa esercizi in 3 giorni diversi';

  @override
  String get missionWeeklyWorkouts2 => 'Completa 2 Allenamenti del giorno';

  @override
  String get guideMicTitle => 'Il microfono';

  @override
  String get guideMicText =>
      'Ciao, sono Intonia! Tocca qui e canta o suona una nota: ti dico qual è e di quanti cent sei fuori.';

  @override
  String get guideWorkoutText =>
      'Una sessione pronta con gli esercizi che conosci: apri questa scheda, scegli 5, 10 o 15 minuti e inizia.';

  @override
  String get guideStatusTitle => 'Serie e cariche';

  @override
  String get guideStatusText =>
      'Qui vedi quanti giorni di fila ti sei allenato e le cariche degli esercizi: ogni sessione ne usa una e si ricaricano col tempo.';

  @override
  String get guideCategoriesText =>
      'Gli esercizi sono divisi per categoria: triadi, arpeggi, scale e altro. Ognuna allena un aspetto diverso della voce.';

  @override
  String get guideCustomText =>
      'Qui componi le tue sequenze, da zero o partendo da un esercizio (Intonia Pro).';

  @override
  String get guideRangeText =>
      'Scopri la nota più grave e la più acuta che riesci a cantare. I risultati restano qui e nel profilo.';

  @override
  String get guideTessituraText =>
      'Il test di tessitura cerca la parte della voce in cui cantare ti viene facile.';

  @override
  String get guideStatsTitle => 'Le tue statistiche';

  @override
  String get guideStatsText =>
      'Serie di giorni, sessioni, minuti e precisione media: tutto si aggiorna mentre ti alleni.';

  @override
  String get guideAchievementsText =>
      'Le missioni di oggi e della settimana e i badge da sbloccare strada facendo.';

  @override
  String get guideHistoryTitle => 'Cronologia';

  @override
  String get guideHistoryText => 'Le ultime sessioni con esercizio, tonalità, ottava e risultato.';

  @override
  String get guideLanguageText => 'Italiano o inglese: di base uso la lingua del telefono.';

  @override
  String get guideThemeText => 'Sistema, Chiaro, Scuro o Neon: scegli l\'aspetto che preferisci.';

  @override
  String get guideNotationText => 'C D E o DO RE MI: cambia i nomi delle note in tutta l\'app.';

  @override
  String get guideReopenText => 'Da qui puoi riaprire questa guida quando vuoi. Buon canto!';

  @override
  String get guideTargetUnavailable => 'Lo troverai qui quando avrai usato questa parte dell\'app.';

  @override
  String guideNavTitle(String section) {
    return 'Vai a $section';
  }

  @override
  String guideNavText(String section) {
    return 'Tocca «$section» nella barra in basso per continuare.';
  }

  @override
  String get guideTapHint => 'Tocca per continuare';

  @override
  String get guideOpenCategoryTitle => 'Apri una categoria';

  @override
  String get guideOpenCategoryText => 'Tocca la categoria per vedere i suoi esercizi.';

  @override
  String get guideOpenExerciseTitle => 'Apri un esercizio';

  @override
  String get guideOpenExerciseText => 'Ora tocca un esercizio: ti mostro le sue impostazioni.';

  @override
  String get guideModeTitle => 'Ascolto o allenamento';

  @override
  String get guideModeText =>
      'Con le cuffie ascolti la sequenza; con il microfono canti e io controllo l\'intonazione. Poi premi Play.';

  @override
  String get guideAdvancedText =>
      'Velocità, tolleranza, quanto tenere ogni nota, guida su ogni nota e calibrazione del rumore di fondo.';

  @override
  String get guideHelpTitle => 'Aiuto in ogni esercizio';

  @override
  String get guideHelpText => 'Tocca ? in qualsiasi esercizio per rivedere queste spiegazioni.';

  @override
  String get guideBackTitle => 'Torna agli esercizi';

  @override
  String get guideBackText => 'Tocca la freccia in alto per tornare all\'elenco degli esercizi.';

  @override
  String get guideOpenSettingsTitle => 'Apri le impostazioni';

  @override
  String get guideOpenSettingsText => 'Tocca l\'ingranaggio in alto per aprire le impostazioni.';

  @override
  String get tessituraStageCalibration => 'Riscaldamento';

  @override
  String get tessituraStageExplore => 'Esplorazione';

  @override
  String get tessituraStageHold => 'Tenuta';

  @override
  String get tessituraStageRepeat => 'Ripetibilità';

  @override
  String get tessituraStageMelodic => 'Frase melodica';

  @override
  String get tessituraInstructionNote => 'Canta questa nota su «a» per circa 3 secondi';

  @override
  String get tessituraInstructionHold => 'Tienila su «a» per circa 6 secondi, se ti è comodo';

  @override
  String tessituraInstructionRepeat(int number, int total) {
    return 'Ripeti la nota ($number di $total)';
  }

  @override
  String tessituraInstructionMelodic(int number, int total) {
    return 'Nota $number di $total della frase';
  }

  @override
  String get tessituraCueCalibrate => 'Partiamo da una nota comoda.';

  @override
  String get tessituraCueRecenter => 'Partiamo dalla nota che ti viene naturale.';

  @override
  String get tessituraCueNotHeard =>
      'Non ti ho sentito bene: riprova, un po\' più vicino al microfono.';

  @override
  String get tessituraCueRetry => 'Riproviamo questa nota, con calma.';

  @override
  String get tessituraCueStepUp => 'Saliamo di un semitono.';

  @override
  String get tessituraCueStepDown => 'Scendiamo di un semitono.';

  @override
  String get tessituraCueBackToComfort => 'Torniamo a note comode e scendiamo verso il grave.';

  @override
  String get tessituraCueHold => 'Ora qualche nota tenuta più a lungo.';

  @override
  String get tessituraCueRepeat => 'Ripetiamo qualche nota per vedere quanto è sicura.';

  @override
  String get tessituraCueMelodic => 'Canta le note una dopo l\'altra.';

  @override
  String get tessituraGetReady => 'Preparati…';

  @override
  String get tessituraListen => 'Ascolta la nota…';

  @override
  String get tessituraYourTurn => 'Quando vuoi, canta';

  @override
  String get tessituraSinging => 'Ti ascolto';

  @override
  String get tessituraReplay => 'Riascolta';

  @override
  String get tessituraEndNote => 'Basta così';

  @override
  String get tessituraStrain => 'Troppo faticoso';

  @override
  String get tessituraRegisterShift => 'Ho cambiato registro';

  @override
  String get tessituraEffortQuestion => 'Quanto sforzo ti è costata questa nota?';

  @override
  String get tessituraEffort1 => '1 · Molto facile';

  @override
  String get tessituraEffort2 => '2 · Facile';

  @override
  String get tessituraEffort3 => '3 · Moderato';

  @override
  String get tessituraEffort4 => '4 · Difficile';

  @override
  String get tessituraEffort5 => '5 · Molto difficile';

  @override
  String get tessituraEffortSkip => 'Preferisco non rispondere';

  @override
  String get tessituraStrainTitle => 'Fermiamoci un attimo';

  @override
  String get tessituraStrainBody =>
      'Non forzare la voce. Se senti fastidio o dolore, fermati: puoi tornare a note comode o terminare qui.';

  @override
  String get tessituraStrainContinue => 'Torna a note comode';

  @override
  String get tessituraStrainFinish => 'Termina il test';

  @override
  String get tessituraMelodicTitle => 'Verifica melodica (facoltativa)';

  @override
  String get tessituraMelodicBody =>
      'Una frase di 9 note dentro la zona trovata, per vedere se le note funzionano anche una dopo l\'altra. Circa 30 secondi.';

  @override
  String get tessituraMelodicYes => 'Fai la verifica';

  @override
  String get tessituraMelodicNo => 'Salta e mostra il risultato';

  @override
  String get tessituraCannotCalibrate =>
      'Non riesco a sentire bene la voce: prova in un posto più silenzioso, un po\' più vicino al microfono.';

  @override
  String get tessituraInterrupted =>
      'Il microfono si è interrotto: ecco il risultato con le prove fatte.';

  @override
  String get tessituraObserved => 'Estensione osservata';

  @override
  String get tessituraUsable => 'Estensione utilizzabile';

  @override
  String get tessituraLowestObserved => 'Più grave rilevata';

  @override
  String get tessituraHighestObserved => 'Più acuta rilevata';

  @override
  String get tessituraInsufficientHint =>
      'I dati raccolti non bastano per stimare una zona comoda affidabile. Ripeti il test con calma, in un posto silenzioso.';

  @override
  String get tessituraReliabilityInsufficient => 'insufficiente';

  @override
  String get tessituraRegisterNotes => 'Possibile cambio di registro';

  @override
  String get tessituraSignalIssues =>
      'Diverse prove non erano valutabili (rumore o segnale debole).';

  @override
  String get tessituraEstimateDisclaimer =>
      'Stima basata sulle prove e sul tuo giudizio, non una misura fisiologica.';

  @override
  String get tessituraNoValidData => 'Nessuna prova valutabile: il risultato non è stato salvato.';

  @override
  String get extremeTitle => 'Trova le note estreme';

  @override
  String get extremeSectionIntro =>
      'Canta liberamente una canzone: Intonia trova la nota più alta e la più bassa che canti.';

  @override
  String get extremeIntro =>
      'Canta una canzone che ti piace, come vuoi. Intonia ascolta e, quando hai finito, ti mostra la nota più bassa e la più alta che ha riconosciuto. Non servono note di riferimento e non viene registrato nulla.';

  @override
  String get extremeStart => 'Inizia a cantare';

  @override
  String get extremeListening => 'Ti ascolto: canta liberamente';

  @override
  String get extremeLowestSoFar => 'Più bassa finora';

  @override
  String get extremeHighestSoFar => 'Più alta finora';

  @override
  String get extremeStop => 'Termina e mostra i risultati';

  @override
  String get extremeLowest => 'Nota più bassa rilevata';

  @override
  String get extremeHighest => 'Nota più alta rilevata';

  @override
  String get extremeNone =>
      'Non ho riconosciuto nessuna nota. Riprova cantando un po\' più forte, vicino al microfono.';

  @override
  String get extremeSingle =>
      'Ho riconosciuto una sola nota: canta un brano più vario per trovare anche l\'altra estremità.';

  @override
  String get extremeUncertain => 'incerta';

  @override
  String get extremeUncertainHint =>
      'Le note incerte sono state sentite solo per un attimo: potrebbero essere imprecise.';

  @override
  String extremeQuality(String level) {
    return 'Qualità del rilevamento: $level';
  }

  @override
  String get extremeQualityGood => 'buona';

  @override
  String get extremeQualityFair => 'discreta';

  @override
  String get extremeQualityPoor => 'scarsa';

  @override
  String get extremeQualityHint => 'Con poco canto o molto rumore il risultato è meno affidabile.';

  @override
  String get extremeDisclaimer =>
      'Sono le note più alte e più basse rilevate in questa sessione, non l\'estensione massima della tua voce, e non cambiano la tua zona comoda. Le note sopra il DO6 circa non vengono rilevate.';

  @override
  String get extremeAgain => 'Ripeti da capo';

  @override
  String get extremeBack => 'Torna a Estensione';

  @override
  String get extremeInterrupted =>
      'Il microfono si è interrotto: ecco cosa ho sentito fino a quel momento.';

  @override
  String get streakCardStart => 'Inizia oggi la tua serie!';

  @override
  String get streakCardKeepGoing => 'Allenati oggi per non perdere la serie!';

  @override
  String get streakCardStarted => 'Primo giorno: ottimo inizio!';

  @override
  String get streakCardActive => 'Continua così, sei sulla strada giusta!';

  @override
  String streakCardDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'giorni\ndi fila',
      one: 'giorno\ndi fila',
    );
    return '$_temp0';
  }

  @override
  String get precisionCardTitle => 'Precisione media';

  @override
  String get precisionCardPeriod => 'Questa settimana';

  @override
  String get precisionCardEmpty => 'Fai un esercizio per misurarla';

  @override
  String get precisionCardImproved => 'Voce sempre più intonata!';

  @override
  String get precisionCardHigh => 'Intonazione eccellente!';

  @override
  String get precisionCardMid => 'Buona intonazione, continua così!';

  @override
  String get precisionCardLow => 'Ogni esercizio affina la tua voce';

  @override
  String precisionCardSemantics(int percent) {
    return 'Precisione media della settimana: $percent per cento';
  }

  @override
  String get weekdaysShort => 'Lun,Mar,Mer,Gio,Ven,Sab,Dom';

  @override
  String precisionDayMeasured(String day, int percent) {
    return '$day: precisione $percent per cento';
  }

  @override
  String precisionDayActivity(String day) {
    return '$day: allenamento senza note valutate';
  }

  @override
  String precisionDayEmpty(String day) {
    return '$day: nessun allenamento';
  }

  @override
  String precisionDayFuture(String day) {
    return '$day: non ancora arrivato';
  }
}
