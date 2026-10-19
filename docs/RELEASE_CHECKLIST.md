# Checklist di rilascio

Checklist operativa per la prima pubblicazione di Intonia su App Store e
Google Play. Ultimo audit: **18 ottobre 2026**, commit `65b92a7` (`main`).
Procedure dettagliate: [`BUILD_AND_RELEASE.md`](BUILD_AND_RELEASE.md); prove
audio: [`AUDIO_MANUAL_TEST_CHECKLIST.md`](AUDIO_MANUAL_TEST_CHECKLIST.md).

Legenda: `[x]` completato e verificato con evidenze · `[ ]` da fare ·
`[!]` bloccato o richiede una verifica esterna · `[?]` non determinabile con
le evidenze disponibili. **Chi**: *sviluppo* (modifica nel repository),
*titolare* (account Apple/Google, decisioni, prove su dispositivo).

## Priorità

### P0 — Blocchi alla pubblicazione

1. **Privacy policy pubblica assente** (§4.6): obbligatoria per App Store
   (URL nei metadati e link nell'app) e per Google Play (app con permesso
   microfono). Nel repository e nell'app non c'è alcun link.
2. **Paywall con prezzi e pulsanti non funzionanti** (§4.8): `ProScreen`
   mostra €4,99 / €39,99 con "Abbonati" e "Ripristina acquisti" disattivati.
   Prima dell'invio decidere: integrare gli acquisti in-app oppure togliere
   prezzi/pulsanti dalla build pubblica.
3. **Nessuna build Android firmabile per Play** (§5): upload key non creata
   (o non nota), AAB release mai compilato; esiste solo l'APK di test firmato
   con chiave debug.
4. **Checklist audio su dispositivi reali non eseguita** (§3): l'unica
   evidenza è avvio e microfono apparentemente funzionante su un iPhone e un
   Samsung; accuratezza, permessi negati, interruzioni e guida non verificati.
5. **Metadati e dichiarazioni store assenti** (§7): screenshot (anche iPad,
   l'app dichiara il supporto iPad), descrizioni, URL di supporto, App
   Privacy, Data safety, classificazione per età.

### P1 — Da completare prima della pubblicazione

1. Manifest privacy iOS (`PrivacyInfo.xcprivacy`) assente per app e widget,
   che usa `UserDefaults` (API "required reason") (§4.4).
2. Avvisi di licenza delle librerie native Android di `flutter_midi_pro`
   (FluidSynth, GLib, libinstpatch, libsndfile: LGPL; altre BSD/Apache) non
   mostrati nell'app (§4.7).
3. Testo della richiesta microfono iOS solo in italiano, mentre l'app è anche
   in inglese (§4.3).
4. Identificare quale build TestFlight è installata e se è stata compilata con
   Pro sviluppatore (§6).
5. Confermare tipo di account Google Play: per gli account personali recenti
   serve un test chiuso (12 tester per 14 giorni) prima della produzione (§5).
6. Prove su iPad (rotazione, multitasking) e su un Android di fascia bassa (§3).

### P2 — Miglioramenti successivi

- Nota guida senza pausa d'ascolto, acquisti Pro reali se rimandati,
  statistiche avanzate, percorsi guidati, Karaoke Mode: vedi
  [`ROADMAP.md`](ROADMAP.md).
- Test automatici dell'interfaccia su dispositivo (integration test) e build
  iOS/Android in CI anche sulle PR.
- Rimuovere dal repository gli artefatti non usati (`assets/soundfonts/intonia_piano_bright.sf2`,
  `outputs/roadmap-vocal-scale-trainer/`) se non servono più.

---

## 1. Qualità del codice e test automatici

- [x] **Versione Flutter** — 3.44.3 stable, Dart 3.12.2 (`flutter --version`
  in locale, `FLUTTER_VERSION` nei workflow, `.metadata`).
- [x] **Dipendenze bloccate** — `flutter pub get --enforce-lockfile` riuscito
  in locale il 18/10/2026; `pubspec.lock` versionato.
- [x] **Formattazione** — `dart format --output=none --set-exit-if-changed lib test`:
  103 file, 0 modificati (locale, 18/10/2026).
- [x] **Analisi statica** — `flutter analyze`: nessun problema (locale).
- [x] **Test** — `flutter test`: 201 test superati (locale, commit `65b92a7`).
- [x] **CI su `main`** — run CI #66 su `65b92a7` (16/10/2026) riuscito:
  format, analyze, test e APK di test.
- [ ] **Ripetere i controlli sul commit da pubblicare** — Evidenza: run CI
  verde sullo stesso commit della build inviata in revisione. Chi: titolare.

I test automatici coprono logica e interfaccia con servizi audio finti: non
dimostrano il comportamento di microfono e altoparlante reali.

## 2. Test funzionali manuali

Da eseguire sulla build candidata (non su una build sviluppatore), annotando
dispositivo, OS, build ed esito.

- [ ] **Primo avvio** — splash, Guida di Intonia mostrata una volta, Home.
- [ ] **Navigazione** — Home, Esercizi, Estensione, Profilo; Impostazioni.
- [ ] **Lingua e notazione** — italiano/inglese, C D E / DO RE MI; widget nella
  stessa lingua.
- [ ] **Esercizi** — modalità Ascendente, Discendente, Completo; ripetizione
  del vertice; cambio di tonalità e ottava.
- [ ] **Editor sequenze** — crea, modifica, copia da esercizio, elimina;
  persistenza dopo il riavvio.
- [ ] **Free/Pro** — consumo e ricarica delle cariche in una build senza Pro
  sviluppatore; limite dello storico Free (8 sessioni).
- [ ] **Profilo e storico** — sessioni, estensione, "Non ero io".
- [ ] **Widget Home** — Android e iOS: aggiunta, aggiornamento dopo una
  sessione, cambio giorno.
- [ ] **Impostazioni → Info → Licenze** — presente la licenza FluidR3.

## 3. Test audio su dispositivi reali

Procedura completa in `AUDIO_MANUAL_TEST_CHECKLIST.md`.

- [x] **Avvio e microfono, iPhone (TestFlight) e Samsung Android** — confermato
  dal titolare: l'app si avvia e il microfono sembra funzionare. Build,
  versione OS e modello non registrati.
- [?] **Accuratezza del riconoscimento** (note, ottave, gravi/acute) — nessuna
  evidenza specifica. Checklist §Riconoscimento.
- [ ] **Permessi** — prima richiesta, permesso negato, riattivazione dalle
  impostazioni di sistema e ritorno all'app (checklist 1–3).
- [ ] **Note sostenute e passaggi ascendenti/discendenti** (12a–12e, 12g).
- [ ] **Rumore ambientale e calibrazione** (11).
- [ ] **Guida al piano non convalidata come voce**, in vivavoce (13).
- [ ] **Interruzioni** — background, telefonata/allarme, cuffie (15–18).
- [ ] **Prestazioni** — 10 minuti continui (20).
- [ ] **Matrice minima** — almeno un iPhone e un Android (fatto solo l'avvio);
  idealmente un Android di fascia bassa e un iPad.

## 4. Privacy, permessi e licenze

### 4.1 Elaborazione locale — verificato nel codice

- [x] **Audio solo in memoria** — `MicrophonePitchService` usa
  `record.startStream` (PCM 16 bit), analizza i campioni con YIN e non scrive
  file audio.
- [x] **Nessuna dipendenza di rete o analytics** — `pubspec.lock`: nessun
  pacchetto HTTP, analytics, crash reporting o pubblicità; nessuna chiamata
  di rete nel codice Dart.
- [x] **Android release senza permesso Internet nei sorgenti** — il manifest
  principale e quelli di `record_android`, `home_widget` e `flutter_midi_pro`
  dichiarano solo `RECORD_AUDIO` (`INTERNET` è solo nei manifest debug/profile
  generati da Flutter); `usesCleartextTraffic=false`. Da riconfermare sul
  manifest unito dell'AAB (`aapt dump permissions` o Play Console).
- [x] **Privacy manifest dei plugin** — `record_ios` e `flutter_midi_pro`
  includono `PrivacyInfo.xcprivacy` senza tracciamento né dati raccolti.

### 4.2 Dati salvati sul dispositivo

- [x] File JSON nella cartella documenti dell'app: `app_settings.json`,
  `custom_exercises.json`, `session_history.json` (ultime 500 sessioni),
  `range_history.json`, `charges.json`. Widget: giorno dell'ultimo
  allenamento, serie e lingua nei dati condivisi (App Group su iOS).
  Nessun account, nessun dato trasmesso. Si cancellano disinstallando l'app.

### 4.3 Permesso microfono

- [x] **iOS** — `NSMicrophoneUsageDescription` presente ("…analizzato solo sul
  dispositivo e non viene registrato né inviato").
- [x] **Android** — `RECORD_AUDIO` richiesto a runtime da `record`.
- [ ] **Testo iOS in inglese** — il progetto non ha `InfoPlist.strings` per
  `en`: gli utenti in inglese vedono la richiesta in italiano. Chi: sviluppo.

### 4.4 Manifest privacy iOS

- [!] **`PrivacyInfo.xcprivacy` dell'app** — assente per `Runner` e
  `IntoniaWidgetExtension`; il widget legge `UserDefaults(suiteName:)`,
  API che Apple chiede di dichiarare. Gli upload TestFlight sono stati
  accettati. **Da confermare dall'utente:** App Store Connect ha inviato email
  "ITMS-91053: Missing API declaration" dopo gli upload? Chi: titolare, poi
  sviluppo.

### 4.5 Dichiarazioni store (in base al codice attuale)

- [ ] **App Store → App Privacy**: "Dati non raccolti" coerente con §4.1–4.2.
- [ ] **Google Play → Sicurezza dei dati**: nessun dato raccolto o condiviso;
  audio elaborato solo sul dispositivo. Chi: titolare.

### 4.6 Privacy policy

- [ ] **Pagina pubblica** (es. GitHub Pages) che descriva microfono, dati
  locali, assenza di raccolta, contatto. Chi: titolare (testo e hosting).
- [ ] **URL nei metadati** di App Store Connect e Play Console. Chi: titolare.
- [ ] **Link nell'app** (es. Impostazioni → Info), richiesto da Apple.
  Chi: sviluppo. Oggi assente.

### 4.7 Licenze

- [x] **SoundFont FluidR3 (MIT)** — testo in
  `assets/soundfonts/licenses/FLUIDR3-COPYING.txt`, mostrato in Impostazioni
  → Info → Licenze; `test/soundfont_asset_test.dart`.
- [x] **Pacchetti Dart** — licenze raccolte automaticamente da Flutter nella
  stessa pagina.
- [!] **Librerie native Android di `flutter_midi_pro` 3.1.6** — l'APK include
  `.so` precompilati: FluidSynth, GLib, libinstpatch, libsndfile (LGPL-2.1),
  FLAC, Ogg, Vorbis, Opus, PCRE (BSD), Oboe (Apache-2.0), libomp e libc++
  (Apache-2.0 con eccezione LLVM). Il plugin non fornisce i testi delle licenze
  e l'app non li mostra. Da aggiungere ai crediti e verificare gli obblighi
  LGPL (librerie dinamiche, avviso, accesso ai sorgenti). Su iOS il plugin usa
  AVFoundation, senza FluidSynth. Chi: sviluppo + verifica del titolare.

### 4.8 Acquisti e paywall

- [!] **Paywall** — `ProScreen.purchasesAvailable = false`,
  `NoPurchasesEntitlementSource`: nessun acquisto possibile, ma prezzi e
  pulsanti visibili. Decisione del titolare: integrare gli acquisti
  (`ROADMAP.md` → *Intonia Pro: acquisti reali*) o nasconderli nella build
  pubblica. Con acquisti: termini d'uso (EULA) e prodotti negli store.

## 5. Build e firma Android

- [x] **applicationId** `io.github.davedegrado.intonia` (namespace uguale).
- [x] **Firma release sicura** — `key.properties` e `*.jks`/`*.keystore` in
  `.gitignore`; senza credenziali la release fallisce (`checkReleaseSigning`).
- [x] **SDK** — targetSdk/compileSdk 36, minSdk 24 (default di Flutter 3.44.3).
- [x] **Pagine da 16 KB** — librerie native `arm64-v8a` e `x86_64` di
  `flutter_midi_pro` allineate a 16 KB (`readelf`, segmenti LOAD 0x4000).
- [x] **APK di test in CI** — release-mode, firma debug, Pro sviluppatore:
  **non pubblicabile**.
- [ ] **Upload key** — creare e conservare fuori dal repository (o confermare
  che esiste). Chi: titolare.
- [ ] **AAB release** — `flutter build appbundle --release` mai eseguito;
  nessun workflow lo produce. Chi: titolare (in locale) o sviluppo (workflow
  con segreti, se richiesto).
- [ ] **Verifica AAB** — avvio, audio e widget di un'installazione da test
  interno Play (la build di test della CI ha Pro attivo e firma diversa).
- [ ] **Versione** — `version: 0.1.0+1`: incrementare `+N` a ogni upload.
- [?] **App in Play Console e tipo di account** — **Da confermare dall'utente:**
  l'app è già creata in Play Console? L'account è personale e creato dopo
  novembre 2023 (test chiuso obbligatorio con 12 tester per 14 giorni)?
- [ ] **Play App Signing** attivo al primo upload. Chi: titolare.

## 6. Build e distribuzione iOS

- [x] **Bundle ID** `io.github.davedegrado.intonia`; widget
  `io.github.davedegrado.intonia.IntoniaWidget`; App Group
  `group.io.github.davedegrado.intonia`; iOS 15.0; iPhone e iPad.
- [x] **Export compliance** — `ITSAppUsesNonExemptEncryption = false`.
- [x] **Workflow TestFlight** — 26 run manuali: #1 e #2 falliti (13/10/2026,
  firma), primo upload riuscito #3 (13/10/2026), ultimo #26 riuscito su
  `65b92a7` (16/10/2026). I segreti Apple risultano quindi configurati.
- [x] **Installazione TestFlight** — confermata dal titolare su un iPhone.
- [?] **Quale build è installata** — **Da confermare dall'utente:** numero di
  build in TestFlight (corrisponde al numero del run) e se il run aveva
  "Pro sviluppatore" attivo.
- [ ] **Build candidata** — run su `main` **senza** Pro sviluppatore, dopo
  la risoluzione dei P0; verificare in App Store Connect che sia elaborata
  senza avvisi.
- [ ] **Verifiche iOS su dispositivo** — `BUILD_AND_RELEASE.md` §4.2.

## 7. Metadati, screenshot e dichiarazioni degli store

Nulla di quanto segue è nel repository; tutto da fare negli account.
Chi: titolare.

- [ ] Nome "Intonia" disponibile su entrambi gli store.
- [ ] Sottotitolo/descrizione breve e descrizione, in italiano e inglese.
- [ ] Screenshot iPhone (6,9" o 6,5") e **iPad 13"** (supporto iPad
  dichiarato); screenshot telefono Android e grafica in evidenza 1024×500.
- [ ] Icona store (App Store 1024×1024 già nell'asset catalog; Play 512×512).
- [ ] Categoria (es. Musica / Istruzione), parole chiave.
- [ ] URL di supporto (obbligatorio su App Store) e email di contatto.
- [ ] URL privacy policy (§4.6).
- [ ] Classificazione per età (App Store) e questionario IARC (Play).
- [ ] Play: pubblico di destinazione, annunci (nessuno), app governativa/
  finanziaria/salute (no), accesso all'app (nessun login).
- [ ] Note per la revisione Apple: uso del microfono, nessun account.
- [ ] Prezzo (gratuita) e paesi di distribuzione.

## 8. Verifiche finali prima dell'invio in revisione

- [ ] Tutti i P0 chiusi e i P1 chiusi o accettati consapevolmente.
- [ ] CI verde sul commit della build candidata.
- [ ] Build iOS e AAB dallo **stesso commit**, senza Pro sviluppatore.
- [ ] Checklist audio eseguita su quella build (almeno iPhone + Android).
- [ ] Versione e numero di build coerenti tra store e `pubspec.yaml`.
- [ ] Privacy policy raggiungibile da browser e dall'app.
- [ ] Dichiarazioni privacy degli store coerenti con il codice (§4).
- [ ] Tag Git della versione inviata (es. `v0.1.0`).

## 9. Verifiche successive alla pubblicazione

- [ ] Installazione dallo store su un iPhone e un Android puliti: avvio,
  permesso microfono, un esercizio completo, widget.
- [ ] Scheda store: testi, screenshot, link privacy e supporto funzionanti.
- [ ] Arresti anomali e ANR in App Store Connect / Play Console (vitals),
  dato che l'app non ha crash reporting proprio.
- [ ] Recensioni degli utenti nella prima settimana.
- [ ] Aggiornare questa checklist e `BUILD_AND_RELEASE.md` §6 con data,
  versione e build pubblicate.
