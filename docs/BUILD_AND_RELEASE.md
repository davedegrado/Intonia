# Build, test e preparazione al rilascio

Guida operativa per sviluppare, verificare e preparare le build di Intonia.
Lo stato delle verifiche è riassunto al §6; le attività rimanenti prima della
pubblicazione sono in [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md).

## 1. Ambiente di sviluppo

- **Flutter 3.44.3** (stable, Dart 3.12.2): è la versione con cui è stato creato
  il progetto (`.metadata`), generato `pubspec.lock` e configurata la CI.
- **Android**: Android SDK con la piattaforma indicata da Flutter, JDK 17+ e
  CMake 3.22.1 (richiesto da `flutter_midi_pro`, che compila il proprio
  wrapper JNI e include FluidSynth come librerie precompilate).
- **iOS**: macOS con Xcode e CocoaPods (`flutter_midi_pro` non supporta Swift
  Package Manager, quindi Flutter genera il `Podfile` al primo build iOS).

```sh
flutter --version          # deve riportare 3.44.3
flutter pub get --enforce-lockfile
```

`pubspec.lock` è versionato: aggiornare le dipendenze solo intenzionalmente
(`flutter pub upgrade`) e committare il lockfile risultante.

## 2. Analisi e test

```sh
dart format --output=none --set-exit-if-changed lib test   # page_width: 100 da analysis_options.yaml
flutter analyze
flutter test
```

Gli stessi controlli girano in CI (`.github/workflows/ci.yml`) su push a
`main`, sulle pull request e manualmente (*Actions → CI → Run workflow*),
insieme alla build di un APK di test. La CI non usa segreti e non pubblica nulla.

**APK di test**: ogni run produce `intonia-test-<commit>.apk`, scaricabile da
*Actions → CI → (run) → Artifacts → intonia-test-apk* (conservato 14 giorni;
lo scaricato è uno zip che contiene l'APK). È compilato in modalità release
(prestazioni realistiche per il riconoscimento del pitch) ma firmato con la
chiave debug: si installa sul telefono abilitando l'installazione da origini
sconosciute, **non è pubblicabile** su Google Play. La chiave debug è
conservata nella cache di GitHub Actions e riusata tra i run, così ogni APK
si installa come aggiornamento del precedente (storico e impostazioni
restano). Se la cache viene svuotata (es. 7 giorni senza run) nasce una chiave
nuova e Android rifiuta l'aggiornamento ("App non installata"): in quel caso,
una volta, disinstallare la versione presente e installare la nuova.

## 3. Build Android

### Debug / profile

```sh
flutter run                 # debug su dispositivo/emulatore
flutter build apk --debug
```

Non richiedono credenziali.

### Release (firma di produzione)

L'identificativo Android è **`io.github.davedegrado.intonia`**, identico al
Bundle ID iOS. Su Google Play non risulta ancora alcun upload (da confermare
in Play Console): dopo il primo upload l'applicationId non potrà più essere
cambiato. targetSdk/compileSdk 36 e minSdk 24 sono i default di Flutter 3.44.3.

La build release viene firmata solo con la upload key fornita localmente;
**senza credenziali fallisce** (task `checkReleaseSigning`) invece di usare la
chiave debug.

1. Creare la upload key (se non esiste già), ad esempio:
   `keytool -genkeypair -v -keystore intonia-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
   Con Play App Signing Google conserva la chiave di distribuzione; la upload
   key, se persa, può essere reimpostata dalla Play Console. Conservarla
   **fuori dal repository** insieme alle password (es. password manager).
2. Copiare `android/key.properties.example` in `android/key.properties`
   (ignorato da Git) e compilarlo:

   ```properties
   storeFile=/percorso/sicuro/intonia-upload-keystore.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

   In alternativa (es. CI privata) impostare le variabili d'ambiente
   `INTONIA_UPLOAD_STORE_FILE`, `INTONIA_UPLOAD_STORE_PASSWORD`,
   `INTONIA_UPLOAD_KEY_ALIAS`, `INTONIA_UPLOAD_KEY_PASSWORD`.
   `key.properties` ha la precedenza sulle variabili.
3. Compilare:

   ```sh
   flutter build appbundle --release   # AAB per Google Play
   flutter build apk --release         # APK per test interni
   ```

4. Verificare la firma:
   `keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk`.

Solo per prove locali su dispositivo, senza upload key:
`INTONIA_ALLOW_DEBUG_SIGNED_RELEASE=true flutter build apk --release`.
L'artefatto è firmato con la chiave debug e **non è pubblicabile**.

Versione: `version: X.Y.Z+N` in `pubspec.yaml` (`N` = versionCode Android /
CFBundleVersion iOS, da incrementare a ogni upload).

## 4. iOS

Deployment target: **iOS 15.0** (richiesto da `home_widget`, iOS 14+, e da
App Store Connect da aprile 2027). Widget della schermata Home:
estensione WidgetKit `ios/IntoniaWidget/` (target `IntoniaWidgetExtension`,
Bundle ID `io.github.davedegrado.intonia.IntoniaWidget`), dati condivisi con
l'app tramite l'App Group `group.io.github.davedegrado.intonia`.

Bundle Identifier: **`io.github.davedegrado.intonia`** (lo stesso di Android,
non più modificabile dopo il primo upload). Firma: *Automatic*, senza team
impostato nel progetto: non versionare profili, certificati o chiavi.
`Info.plist` dichiara `ITSAppUsesNonExemptEncryption = false` (l'app non usa
crittografia), così App Store Connect non chiede l'export compliance a ogni build.

### 4.1 TestFlight dalla CI (senza Mac)

Il workflow `.github/workflows/ios-testflight.yml` compila su un runner macOS
di GitHub e carica la build su TestFlight. Si avvia **solo a mano** e richiede
l'iscrizione all'Apple Developer Program.

Configurazione, una sola volta (già completata: i run dal #3 caricano le
build, quindi Bundle ID, app in App Store Connect e secret esistono):

1. **Bundle ID** — [developer.apple.com](https://developer.apple.com/account) →
   *Certificates, Identifiers & Profiles → Identifiers → +* → *App IDs → App*:
   Bundle ID *Explicit* `io.github.davedegrado.intonia`, nessuna capability.
2. **App in App Store Connect** — [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   → *App → + → Nuova app*: piattaforma iOS, nome (es. "Intonia"; deve essere
   libero sullo store), lingua principale Italiano, il Bundle ID del punto 1,
   SKU a scelta (es. `intonia`). Creare l'app **non** la pubblica.
3. **Chiave API** — App Store Connect → *Utenti e accessi → Integrazioni →
   App Store Connect API → Chiavi del team → +*, ruolo **Admin** (necessario
   perché Xcode crei da solo certificato e profilo di distribuzione).
   Scaricare il file `AuthKey_XXXXXXXXXX.p8` (si può scaricare **una sola
   volta**) e annotare *Key ID* e *Issuer ID*.
4. **Team ID** — developer.apple.com → *Membership details → Team ID*.
5. **App Group e widget** (serve al widget della schermata Home per leggere
   la serie di giorni scritta dall'app):
   - *Identifiers → +* → **App Groups**: `group.io.github.davedegrado.intonia`.
   - *Identifiers* → `io.github.davedegrado.intonia` → abilita **App Groups**
     → *Configure* → seleziona il gruppo → *Save*.
   - *Identifiers → + → App IDs → App*: Bundle ID *Explicit*
     `io.github.davedegrado.intonia.IntoniaWidget`, con **App Groups**
     abilitato sullo stesso gruppo.
6. **Secret GitHub** — repository → *Settings → Secrets and variables →
   Actions → New repository secret*:

   | Secret | Valore |
   |---|---|
   | `APP_STORE_CONNECT_API_KEY_ID` | Key ID |
   | `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
   | `APP_STORE_CONNECT_API_KEY_P8` | contenuto completo del file `.p8`, righe `BEGIN`/`END` comprese |
   | `APPLE_TEAM_ID` | Team ID |

   Conservare il file `.p8` in un posto sicuro fuori dal repository; se
   compromessa, revocare la chiave da App Store Connect.

Per ogni build di test:

1. GitHub → *Actions → iOS TestFlight → Run workflow* (branch `main`).
2. A fine run (circa 15–30 minuti) Apple elabora la build: compare in App
   Store Connect → *TestFlight* dopo qualche minuto, con un'email di conferma.
3. La prima volta: *TestFlight → Test interni → +*, creare un gruppo e
   aggiungere il proprio Apple ID. I test interni non richiedono la revisione
   Apple.
4. Sull'iPhone: installare l'app **TestFlight** dall'App Store, accettare
   l'invito e installare Intonia.

Il numero di build è il numero progressivo del run del workflow; la versione
(`0.1.0`) viene da `pubspec.yaml`. In caso di errori leggere i log del job.

Storico: i run #1 e #2 (13/10/2026) sono falliti per la firma
(corretta nei commit successivi del branch `fix/ios-config-no-codesign`); dal run #3
(13/10/2026) gli upload riescono. Al 18/10/2026 l'ultimo run riuscito è il #26
su `65b92a7` (16/10/2026). Il workflow riuscito conferma l'upload, non
l'elaborazione di Apple né quale build sia installata sui telefoni: questo si
verifica in App Store Connect → *TestFlight*.

### 4.1.1 Pro sviluppatore

Le build compilate con `--dart-define=INTONIA_DEV_PRO=true` sono Pro senza
abbonamento (in alto compare "Pro" al posto delle cariche; la schermata Intonia Pro indica "Build sviluppatore"). Nell'app non c'è
alcun pulsante o codice per attivarlo: decide solo la compilazione.

- **APK di test della CI**: sempre con Pro sviluppatore (non pubblicabile).
- **TestFlight**: *Run workflow* → spunta **Pro sviluppatore**. Spenta di
  default. Una build TestFlight è la stessa che si invia in revisione: le build
  con Pro sviluppatore **non vanno mai inviate** (il run lo segnala con un
  avviso e nel riepilogo). Per la pubblicazione, rilanciare il workflow senza
  la spunta.
- **In locale**: `flutter run --dart-define=INTONIA_DEV_PRO=true`.

Con l'app pubblicata e gli acquisti integrati: codici promozionali / offer code
(App Store Connect) e tester delle licenze (Play Console) danno Pro gratis
sull'app dello store.

### 4.2 Verifiche su dispositivo

Stato: su un iPhone (TestFlight) l'app si avvia e il microfono sembra
funzionare (confermato dal titolare); i punti seguenti non risultano
eseguiti in modo documentato.

1. Avvio: la Home deve comparire (ciclo di vita UIScene, `Info.plist` +
   `SceneDelegate`).
2. Prima richiesta microfono: compare il testo di `NSMicrophoneUsageDescription`;
   con permesso negato il trainer mostra il messaggio di errore.
3. Rotazione e multitasking su iPad (orientamenti iPad tutti dichiarati).
4. Checklist audio manuale (`docs/AUDIO_MANUAL_TEST_CHECKLIST.md`).

## 5. Licenze degli asset

Ogni asset distribuito con l'app deve avere origine e licenza documentate.

- Pianoforte: `assets/soundfonts/intonia_piano_classic.sf2`, estratto da
  **Fluid (R3) GM SoundFont** (© 2000–2002, 2008 Frank Wen), **licenza MIT**.
  Dettagli e verifiche: `assets/soundfonts/soundfont-info.txt`.
- La licenza MIT richiede di includere copyright e testo della licenza: il file
  `assets/soundfonts/licenses/FLUIDR3-COPYING.txt` è incluso nell'app e mostrato in
  *Impostazioni → Info → Licenze* (`lib/app/third_party_licenses.dart`).
- `assets/soundfonts/intonia_piano_bright.sf2` resta nel repository ma non è incluso
  nell'app (non è dichiarato in `pubspec.yaml`).

- **Librerie native Android** di `flutter_midi_pro`: l'APK include FluidSynth,
  GLib, libinstpatch e libsndfile (LGPL-2.1) e altre librerie BSD/Apache
  precompilate, i cui avvisi di licenza **non** sono ancora mostrati
  nell'app (vedi `RELEASE_CHECKLIST.md` §4.7). Su iOS il plugin usa
  AVFoundation.

Per aggiungere o sostituire un asset audio: dichiararlo in `pubspec.yaml`,
conservare la licenza originale in `assets/soundfonts/licenses/`, registrarla in
`registerThirdPartyLicenses()` e aggiornare i crediti in *Impostazioni → Info*.

## 6. Stato delle verifiche (audit del 18/10/2026, commit `65b92a7`)

| Verifica | Stato |
|---|---|
| `dart format`, `flutter analyze`, `flutter test` (Flutter 3.44.3) | Superati in locale il 18/10/2026 (201 test) e in CI (run #66 su `main`) |
| Build Android di test (APK release-mode, firma debug, Pro sviluppatore) | Prodotta dalla CI, scaricabile come artifact; **non pubblicabile** |
| Build Android release (AAB firmato con upload key) | Mai eseguita: richiede la upload key |
| Build iOS e upload TestFlight | Workflow riuscito dal run #3; ultimo run #26 su `65b92a7` |
| App installata da TestFlight | Confermato dal titolare su un iPhone (build non registrata) |
| App provata su Android | Confermato dal titolare su un Samsung (tipo di build non registrato) |
| Audio su dispositivi reali | Solo avvio e microfono apparentemente funzionante; checklist manuale non eseguita |
| Licenza SoundFont | Risolta: FluidR3 (MIT), notice incluso nell'app |
| Licenze librerie native Android | Da completare (avvisi LGPL/BSD non mostrati) |
| Privacy policy e metadati store | Assenti |

## 7. Widget della schermata Home

Mostra la mascotte, i giorni consecutivi di allenamento (numero grande e
pallini degli ultimi 7 giorni) e un invito ad
allenarsi; toccandolo si apre l'app.

- **Dati**: l'app pubblica giorno dell'ultimo allenamento e serie a quella
  data (`lib/features/home_widget/`, `lib/services/widget/home_widget_service.dart`)
  all'avvio e a ogni sessione salvata; il widget ricalcola lo stato del giorno
  da solo (anche ad app chiusa), con la stessa logica in Dart, Kotlin e Swift.
- **Android**: `IntoniaWidgetProvider.kt`, `res/layout/widget_intonia.xml`,
  `res/xml/intonia_widget_info.xml` (3×2 celle, ridimensionabile).
- **iOS**: `ios/IntoniaWidget/` (SwiftUI/WidgetKit, formati piccolo e medio),
  aggiornato anche a mezzanotte.
- **Immagini della mascotte** nei widget: generate dal disegno dell'app con
  `flutter test tool/render_widget_mascot_test.dart`.
