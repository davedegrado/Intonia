import fs from 'node:fs/promises';
import path from 'node:path';
import { SpreadsheetFile, Workbook } from '@oai/artifact-tool';

const outputDir = path.resolve('..');
await fs.mkdir(outputDir, { recursive: true });

const workbook = Workbook.create();
const checklist = workbook.worksheets.add('Checklist');
const notes = workbook.worksheets.add('Note tecniche');

checklist.showGridLines = false;
notes.showGridLines = false;

const rows = [
  ['ID', 'Area', 'Punto roadmap', 'Stato', 'Evidenza', 'Nota'],
  [1, 'Repository', 'Mappatura workspace e contesto precedente', 'Completato', 'Directory iniziale vuota, nessun Git repo, memoria Python desktop verificata', 'Base Flutter creata da zero nel workspace corrente'],
  [2, 'Architettura', 'Flutter feature-first con Riverpod, go_router e Material 3', 'Completato', 'pubspec.yaml, lib/app, lib/features, lib/core, lib/services', 'SDK Flutter non presente localmente per analisi automatica'],
  [3, 'Dominio musicale', 'Note, frequenze, scale estendibili e sequenza ascendente/discendente', 'Completato', 'lib/core/music/note.dart, lib/core/music/scale.dart, test/music_scale_test.dart', 'La nota piu alta viene ripetuta'],
  [4, 'Audio', 'Riproduzione note con SoundFont/MIDI e controlli play/stop/replay/loop', 'Completato con blocco asset', 'lib/services/audio/piano_audio_service.dart', 'Richiede assets/soundfonts/piano.sf2 con licenza commerciale verificata'],
  [5, 'Pitch Detection', 'Microfono PCM16 e algoritmo YIN con filtri voce/silenzio/stabilita', 'Completato', 'lib/services/pitch/microphone_pitch_service.dart, lib/core/pitch/yin_pitch_detector.dart', 'Da calibrare su dispositivi fisici iOS/Android'],
  [6, 'Training FSM', 'WAIT_NOTE, WAIT_CHANGE, WAIT_RETRY senza falsi errori su nota precedente', 'Completato', 'lib/features/trainer/domain/training_state_machine.dart, test/training_state_machine_test.dart', 'Coperto da test di comportamento principali'],
  [7, 'UI Home', 'Home con tonalita, scala, ottava, BPM, tolleranza, stabilita, Play e Stop', 'Completato', 'lib/features/trainer/presentation/screens/trainer_home_screen.dart', 'Tema chiaro Material 3 responsive'],
  [8, 'Modalita Ascolto', 'Scala riprodotta con nota corrente, Play, Stop, Replay, Loop', 'Completato', 'TrainerController.playSequence e UI controls', 'Loop abilitato solo in modalita Ascolto'],
  [9, 'Modalita Allenamento', 'Riproduzione nota, ascolto microfono, avanzamento solo su nota corretta', 'Completato', 'TrainerController, TrainingStateMachine', 'Richiede permessi microfono runtime'],
  [10, 'Feedback', 'Nota rilevata, cents, barra intonazione e indicatore basso/intonato/alto', 'Completato', 'PitchFeedbackPanel', 'Aggiornamento fluido via stream pitch'],
  [11, 'Ascolta nota', 'Pulsante per riprodurre la nota richiesta', 'Completato', 'OutlinedButton con Icons.volume_up e PianoAudioService.playNote', 'Dipende dal SoundFont'],
  [12, 'Statistiche', 'Tempo, errori, accuratezza, percentuale, note corrette e grafico base', 'Completato', 'SessionStatsPanel, SessionStats', 'Grafico implementato come barra accuratezza; grafici avanzati predisposti per modulo futuro'],
  [13, 'Moduli futuri', 'Intervalli, triadi, arpeggi, accordi, progressioni, vocalizzi, ear training, stats, profilo, cloud, IAP', 'Completato', 'lib/features/future_modules/domain/future_module.dart', 'Cloud Sync e IAP marcati pianificati perche non offline-core'],
  [14, 'Android', 'Manifest microfono, MainActivity, Gradle e icona', 'Parziale', 'android/app/src/main/...', 'Manca verifica con Flutter SDK e toolchain Android installata'],
  [15, 'iOS', 'Info.plist microfono, AppDelegate, LaunchScreen', 'Parziale', 'ios/Runner/...', 'Xcode project completo normalmente generato da flutter create; verifica non possibile qui'],
  [16, 'Qualita', 'Assenza marker TODO/FIXME/Unimplemented', 'Completato', 'rg TODO/FIXME/Unimplemented senza risultati', 'Analisi statica Flutter bloccata da SDK mancante'],
  [17, 'Verifica', 'flutter pub get, flutter analyze e flutter test', 'Bloccato', 'flutter non riconosciuto nel PATH', 'Installare Flutter SDK o aggiungerlo al PATH e rieseguire'],
];

checklist.getRange('A1:F18').values = rows;
checklist.getRange('A1:F1').format = {
  fill: '#1F4E79',
  font: { bold: true, color: '#FFFFFF' },
};
checklist.getRange('A1:F18').format.borders = { preset: 'inside', style: 'thin', color: '#D8E2EF' };
checklist.getRange('A1:F18').format.wrapText = true;
checklist.getRange('A:A').format.columnWidth = 6;
checklist.getRange('B:B').format.columnWidth = 18;
checklist.getRange('C:C').format.columnWidth = 42;
checklist.getRange('D:D').format.columnWidth = 24;
checklist.getRange('E:E').format.columnWidth = 46;
checklist.getRange('F:F').format.columnWidth = 52;
checklist.getRange('A2:A18').format.numberFormat = '0';
checklist.freezePanes.freezeRows(1);
checklist.tables.add('A1:F18', true, 'RoadmapChecklist');

checklist.getRange('H1:I6').values = [
  ['Riepilogo', 'Valore'],
  ['Totale punti', null],
  ['Completati pieni', null],
  ['Parziali', null],
  ['Bloccati', null],
  ['Completamento operativo', null],
];
checklist.getRange('I2:I6').formulas = [
  ['=COUNTA(D2:D18)'],
  ['=COUNTIF(D2:D18,"Completato")'],
  ['=COUNTIF(D2:D18,"Parziale")+COUNTIF(D2:D18,"Completato con blocco asset")'],
  ['=COUNTIF(D2:D18,"Bloccato")'],
  ['=I3/I2'],
];
checklist.getRange('H1:I1').format = {
  fill: '#2364AA',
  font: { bold: true, color: '#FFFFFF' },
};
checklist.getRange('H1:I6').format.borders = { preset: 'all', style: 'thin', color: '#C9D6E4' };
checklist.getRange('I6').format.numberFormat = '0.0%';
checklist.getRange('H:H').format.columnWidth = 24;
checklist.getRange('I:I').format.columnWidth = 18;

const statusRange = checklist.getRange('D2:D18');
statusRange.conditionalFormats.add('containsText', {
  text: 'Completato',
  format: { fill: '#DFF3E6', font: { color: '#145A32' } },
});
statusRange.conditionalFormats.add('containsText', {
  text: 'Parziale',
  format: { fill: '#FFF3CD', font: { color: '#7A4E00' } },
});
statusRange.conditionalFormats.add('containsText', {
  text: 'Bloccato',
  format: { fill: '#F8D7DA', font: { color: '#842029' } },
});

notes.getRange('A1:D1').values = [['Tema', 'Decisione', 'Motivo', 'Azione richiesta']];
notes.getRange('A2:D8').values = [
  ['Audio', 'Usare flutter_midi_pro con piano.sf2', 'Supporta SoundFont e MIDI note su Android/iOS; evita onde sinusoidali', 'Inserire SoundFont piano con licenza commerciale in assets/soundfonts/piano.sf2'],
  ['Pitch', 'YIN implementato in Dart sopra stream PCM16 record', 'Riduce dipendenza da plugin pitch detection poco mantenuti', 'Testare soglie confidence/RMS su device fisici'],
  ['Offline', 'Nessuna dipendenza cloud nel core', 'La versione richiesta deve funzionare completamente offline', 'Cloud Sync resta modulo pianificato separato'],
  ['FSM', 'WAIT_CHANGE obbligatorio dopo nota corretta', 'Evita falsi errori quando il cantante mantiene la nota precedente', 'Validare con sessioni vocali reali'],
  ['Android', 'Manifest RECORD_AUDIO e Gradle configurati', 'Necessario per stream microfono e FluidSynth del plugin MIDI', 'Installare CMake 3.22.1 per build flutter_midi_pro'],
  ['iOS', 'NSMicrophoneUsageDescription configurato', 'Necessario per App Store e runtime permission', 'Rigenerare/validare Xcode project con Flutter SDK installato'],
  ['Verifica locale', 'Bloccata', 'flutter e dart non sono nel PATH di questa macchina', 'Eseguire flutter pub get, flutter analyze, flutter test, flutter run'],
];
notes.getRange('A1:D1').format = {
  fill: '#1F4E79',
  font: { bold: true, color: '#FFFFFF' },
};
notes.getRange('A1:D8').format.borders = { preset: 'inside', style: 'thin', color: '#D8E2EF' };
notes.getRange('A1:D8').format.wrapText = true;
notes.getRange('A:A').format.columnWidth = 18;
notes.getRange('B:B').format.columnWidth = 34;
notes.getRange('C:C').format.columnWidth = 48;
notes.getRange('D:D').format.columnWidth = 48;
notes.freezePanes.freezeRows(1);
notes.tables.add('A1:D8', true, 'TechnicalNotes');

const checklistPreview = await workbook.render({ sheetName: 'Checklist', range: 'A1:I18', scale: 1, format: 'png' });
await fs.writeFile(path.join(outputDir, 'checklist-preview.png'), new Uint8Array(await checklistPreview.arrayBuffer()));
const notesPreview = await workbook.render({ sheetName: 'Note tecniche', range: 'A1:D8', scale: 1, format: 'png' });
await fs.writeFile(path.join(outputDir, 'notes-preview.png'), new Uint8Array(await notesPreview.arrayBuffer()));

const inspect = await workbook.inspect({
  kind: 'table',
  range: 'Checklist!A1:I18',
  include: 'values,formulas',
  tableMaxRows: 20,
  tableMaxCols: 10,
});
console.log(inspect.ndjson);

const errors = await workbook.inspect({
  kind: 'match',
  searchTerm: '#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A',
  options: { useRegex: true, maxResults: 300 },
  summary: 'final formula error scan',
});
console.log(errors.ndjson);

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(path.join(outputDir, 'roadmap-vocal-scale-trainer.xlsx'));
