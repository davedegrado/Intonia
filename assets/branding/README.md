# Branding – splash screen

File sorgente (non inclusi nell'app Flutter, non dichiarati in `pubspec.yaml`):

- `splash_full.png` — splash completa (941×1672) fornita per Intonia.
- `app_icon_source.png` — icona (1254×1254) fornita per Intonia: riquadro
  arrotondato su fondo scuro; viene ritagliata appena dentro il bordo
  luminoso perché iOS e Android applicano la propria maschera.
- `splash_logo.png` — logo ritagliato da `splash_full.png` (senza scritte),
  bordi sfumati nel colore di sfondo.

`splash.jpg` (JPEG ~160 KB ricavato da `splash_full.png`) è invece incluso
nell'app: dopo la splash di sistema l'app mostra l'immagine completa per 2
secondi e poi sfuma verso la Home (`lib/app/splash_overlay.dart`; un tocco la
salta).

Colore di sfondo della splash: **`#03011A`** (bordi di `splash_full.png`).

## Dove vengono usati

| Piattaforma | Cosa si vede | File |
|---|---|---|
| iOS | immagine completa a tutto schermo (aspect fill) | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` (1x/2x/3x), `ios/Runner/Base.lproj/LaunchScreen.storyboard` |
| Android 12+ | splash di sistema: sfondo + logo centrale (il sistema non consente immagini a tutto schermo) | `android/app/src/main/res/values*-v31/styles.xml`, `drawable-*/splash_icon.png` |
| Android ≤ 11 | sfondo + logo centrale | `drawable*/launch_background.xml`, `drawable-*/splash_icon.png` |

`splash_icon.png` è un quadrato da 288 dp (1152 px in xxxhdpi) con il logo
entro il cerchio centrale da 192 dp che Android 12+ lascia visibile.

## Sostituire splash o icona

Sostituire `splash_full.png` e/o `app_icon_source.png` e rigenerare tutto con

```sh
python3 tool/generate_branding.py   # richiede Pillow
```

Lo script produce `splash.jpg`, `splash_logo.png`, le LaunchImage iOS
(1x/2x/3x), le `splash_icon.png` Android, le icone iOS (`AppIcon.appiconset`)
e quelle Android (icona adattiva `drawable/ic_launcher_foreground.png` e
icone legacy `mipmap-*/ic_launcher.png`). Se cambiano le proporzioni della
splash, aggiornare la dimensione di `LaunchImage` in
`ios/Runner/Base.lproj/LaunchScreen.storyboard` (dimensione 1x).
Su iOS la launch screen viene messa in cache: per vedere la nuova versione
può servire riavviare il telefono o reinstallare l'app.
