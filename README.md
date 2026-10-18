# Intonia

Flutter mobile app for offline pitch/intonation training on iOS and Android.
Voice-first, but the exercise model is instrument-agnostic.
(Project/package name remains `vocal_scale_trainer` for historical reasons.)

## Run

Requires Flutter 3.44.3 (see `docs/BUILD_AND_RELEASE.md`).

```sh
flutter pub get --enforce-lockfile
flutter run
```

Checks (also run in CI, `.github/workflows/ci.yml`):

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Release builds, Android signing (`android/key.properties`, never committed),
iOS TestFlight workflow (`.github/workflows/ios-testflight.yml`, manual):
`docs/BUILD_AND_RELEASE.md`.
Manual audio checks on real devices: `docs/AUDIO_MANUAL_TEST_CHECKLIST.md`.
Release status and remaining store work: `docs/RELEASE_CHECKLIST.md`;
roadmap: `docs/ROADMAP.md`.

## Status (audit 2026-10-18)

- CI green on `main`; TestFlight builds uploaded by the workflow and installed
  on an iPhone; app also tried on a Samsung Android phone (launch and
  microphone only: recognition accuracy not yet verified on devices).
- Not yet published on any store. Open blockers (privacy policy, paywall
  without working purchases, signed Android AAB, device audio checklist, store
  listings) are tracked in `docs/RELEASE_CHECKLIST.md`.
- Offline: no network, analytics or crash-reporting dependencies; audio is
  analysed in memory and never stored.

## Audio asset

The app loads `assets/soundfonts/intonia_piano_classic.sf2` (piano extracted from the
Fluid (R3) GM SoundFont by Frank Wen, MIT license) through `flutter_midi_pro`.
The license text is bundled and shown in Settings → Info → Licenses.
See `assets/soundfonts/soundfont-info.txt`.

Android builds for `flutter_midi_pro` require CMake 3.22.1 because the plugin builds a JNI
wrapper around prebuilt FluidSynth libraries (LGPL-2.1; their notices are not yet shown in the
app, see `docs/RELEASE_CHECKLIST.md` §4.7). On iOS the plugin uses AVFoundation.

## Architecture

The project uses a feature-first layout:

- `lib/core`: music theory (`exercise.dart` defines the generic exercise model and built-in library), pitch detection, and session models.
- `lib/app`: app shell, router (bottom navigation: Home, Exercises, Range, Profile), themes, licenses, splash.
- `lib/services`: platform-facing audio and microphone services, home-screen widget bridge, and JSON persistence (`services/storage`: settings, custom exercises, session and range history, charges).
- `lib/features/library`: Home (mascot, live note recognition via the microphone button), the Exercises catalogue grouped by type (Custom first, then Triads, Arpeggios, Pentatonics, Scales, 3-voice Harmonizations, Patterns) and the custom sequence editor (absolute notes, any octave, repeated/descending notes allowed, copy from a built-in exercise).
- `lib/features/tuner`: live recognition controller used by Home.
- `lib/features/range`: vocal range test and its history.
- `lib/features/settings`: settings and global preferences (theme, language, note notation C-D-E vs DO-RE-MI, persisted).
- `lib/features/profile`: profile screen with practice streak, per-note accuracy, detected vocal range, and session history (persisted to `session_history.json`, last 500 sessions).
- `lib/features/trainer`: training feature with domain state machine, controller, and the trainer screen (Ascending/Descending/Full modes, guide on every note or first note only).
- `lib/features/access`: Free/Pro model (exercise charges, entitlement, Pro screen; real purchases not integrated, see `docs/ROADMAP.md`).
- `lib/features/guide`, `lib/features/mascot`, `lib/features/home_widget`: in-app guide, animated mascot, home-screen widget data.
- `lib/features/future_modules`: registry of planned modules only (no implementation).

## Exercises

An exercise is a full sequence of semitone offsets from the first note (`ExerciseDefinition.steps`);
offsets may be negative or repeated, so scales, arpeggiated triads, harmonized scales, and arbitrary
custom patterns share the same model. Custom exercises remember their editor root note (`rootMidi`)
and are persisted to `custom_exercises.json` in the app documents directory.

During training, the validator accepts a repeated note when it is re-attacked after a short break
(default 150 ms of unstable signal), and the piano guide can play every note or only the first one.

Note names are spelled enharmonically relative to the exercise root (`lib/core/music/note_spelling.dart`):
F major shows SIb/Bb, C minor shows MIb-LAb-SIb, the augmented triad shows #5. The sequence view is a
single horizontally scrolling row (auto-scrolls to the current note) with a toggle between note chips
and a treble-clef staff rendering.
