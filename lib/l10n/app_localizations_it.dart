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
  String get trainerDirectionForward => 'Dritto';

  @override
  String get trainerDirectionReverse => 'Al contrario';

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
  String get guideHome =>
      'Tocca il microfono e canta o suona una nota: ti dico qual è e di quanti cent sei fuori. In alto trovi la serie di giorni e le cariche degli esercizi; in basso, l\'accesso rapido a notazione, tema e impostazioni.';

  @override
  String get guideExercises =>
      'Scegli una categoria (triadi, arpeggi, scale e altre), apri un esercizio e premi Play per allenarti con la voce. Ogni sessione usa una carica. Con Crea la tua sequenza puoi comporre le tue (Intonia Pro).';

  @override
  String get guideExerciseSettingsTitle => 'Impostazioni dell\'esercizio';

  @override
  String get guideExerciseSettings =>
      'Nell\'esercizio scegli tonalità e ottava, la modalità (Dritto, Al contrario o Completo) e, in Completo, se ripetere la nota di vertice. Il pulsante ? dell\'esercizio spiega queste opzioni.';

  @override
  String get guideRange =>
      'Il test parte da una nota comoda, scende fino alla tua nota più grave e poi sale fino alla più acuta. Il risultato mostra le due note estreme e l\'ampiezza in ottave e semitoni; i test precedenti sono qui e nel profilo.';

  @override
  String get guideProfile =>
      'La serie di giorni, le sessioni, i minuti totali, la precisione media, l\'estensione vocale, le note migliori e peggiori, i test di estensione e le ultime sessioni con tonalità e ottava.';

  @override
  String get guideSettingsTitle => 'Impostazioni';

  @override
  String get guideSettings =>
      'Scegli la lingua, il tema (Sistema, Chiaro, Scuro o Neon) e la notazione delle note (C D E o DO RE MI). Da qui puoi riaprire questa guida quando vuoi.';

  @override
  String get guideKey => 'La nota da cui parte l\'esercizio.';

  @override
  String get guideOctave =>
      'Quanto in alto o in basso si svolge l\'esercizio: scegline una comoda per la tua voce.';

  @override
  String get guideDirectionTitle => 'Modalità';

  @override
  String get guideDirection =>
      'Dritto esegue la sequenza in avanti, Al contrario all\'indietro, Completo in avanti e poi a ritroso.';

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
}
