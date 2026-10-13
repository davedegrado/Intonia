# Build, test e preparazione al rilascio

Guida operativa per sviluppare, verificare e preparare le build di Intonia.
Lo stato delle verifiche ancora aperte è riassunto in fondo.

## 1. Ambiente di sviluppo

- **Flutter 3.44.3** (stable, Dart 3.12.2): è la versione con cui è stato creato
  il progetto (`.metadata`), generato `pubspec.lock` e configurata la CI.
- **Android**: Android SDK con la piattaforma indicata da Flutter, JDK 17+ e
  CMake 3.22.1 (richiesto da `flutter_midi_pro`, che compila FluidSynth).
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
insieme a una build Android debug. La CI non usa segreti e non pubblica nulla.

## 3. Build Android

### Debug / profile

```sh
flutter run                 # debug su dispositivo/emulatore
flutter build apk --debug
```

Non richiedono credenziali.

### Release (firma di produzione)

L'identificativo Android è **`io.github.davedegrado.intonia`**, identico al
Bundle ID iOS. L'app non è ancora registrata sugli store: dopo il primo upload
su Google Play l'applicationId non potrà più essere cambiato.

La build release viene firmata solo con la upload key fornita localmente;
**senza credenziali fallisce** (task `checkReleaseSigning`) invece di usare la
chiave debug.

1. Creare la upload key (l'app non è ancora su Play), ad esempio:
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

## 4. iOS (da eseguire su macOS)

Bundle Identifier: **`io.github.davedegrado.intonia`** (lo stesso di Android;
da registrare in App Store Connect / Certificates, Identifiers & Profiles e non
più modificabile dopo la prima submission). Firma: *Automatic*, senza team
impostato nel progetto: va scelto in Xcode (*Runner → Signing &
Capabilities*), non versionare profili o certificati.

Verifiche da eseguire, nessuna delle quali è stata possibile senza macOS:

1. `flutter build ios --release --no-codesign` (genera `Podfile`, esegue
   `pod install`): deve completare senza errori; committare `ios/Podfile` e
   `ios/Podfile.lock` generati.
2. Avvio su simulatore e dispositivo fisico: la Home deve comparire (il
   progetto usa il ciclo di vita UIScene, `Info.plist` + `SceneDelegate`).
3. Prima richiesta microfono: compare il testo di `NSMicrophoneUsageDescription`;
   con permesso negato il trainer mostra il messaggio di errore.
4. Rotazione e multitasking su iPad (orientamenti iPad tutti dichiarati).
5. *Product → Archive* in Xcode con il team corretto, poi *Validate App*.
6. Checklist audio manuale (`docs/AUDIO_MANUAL_TEST_CHECKLIST.md`).

## 5. Licenze degli asset

Ogni asset distribuito con l'app deve avere origine e licenza documentate.

- Pianoforte: `soundfonts/intonia_piano_classic.sf2`, estratto da
  **Fluid (R3) GM SoundFont** (© 2000–2002, 2008 Frank Wen), **licenza MIT**.
  Dettagli e verifiche: `soundfonts/soundfont-info.txt`.
- La licenza MIT richiede di includere copyright e testo della licenza: il file
  `soundfonts/licenses/FLUIDR3-COPYING.txt` è incluso nell'app e mostrato in
  *Impostazioni → Info → Licenze* (`lib/app/third_party_licenses.dart`).
- `soundfonts/intonia_piano_bright.sf2` resta nel repository ma non è incluso
  nell'app (non è dichiarato in `pubspec.yaml`).

Per aggiungere o sostituire un asset audio: dichiararlo in `pubspec.yaml`,
conservare la licenza originale in `soundfonts/licenses/`, registrarla in
`registerThirdPartyLicenses()` e aggiornare i crediti in *Impostazioni → Info*.

## 6. Stato delle verifiche (ottobre 2026)

| Verifica | Stato |
|---|---|
| `dart format`, `flutter analyze`, `flutter test` (Flutter 3.44.3) | Superati localmente e in CI |
| Build Android debug | Superata in CI |
| Build Android release | Non eseguita: richiede la upload key |
| Build iOS | Non eseguita: richiede macOS/Xcode |
| Audio su dispositivi reali | Non eseguito: vedi checklist manuale |
| Licenza SoundFont | Risolta: FluidR3 (MIT), notice incluso nell'app |
