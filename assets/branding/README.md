# Branding – splash screen

File sorgente (non inclusi nell'app Flutter, non dichiarati in `pubspec.yaml`):

- `splash_full.png` — splash completa (852×1846) fornita per Intonia.
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

## Sostituire la splash

Per una resa più nitida sugli iPhone più grandi conviene una sorgente di
almeno 1290×2796 px. Dopo aver sostituito `splash_full.png`/`splash_logo.png`
vanno rigenerate le immagini iOS (1x = 1/3, 2x = 2/3, 3x = originale) e le
`splash_icon.png` Android (288/432/576/864/1152 px per mdpi…xxxhdpi).
Su iOS la launch screen viene messa in cache: per vedere la nuova versione
può servire riavviare il telefono o reinstallare l'app.
