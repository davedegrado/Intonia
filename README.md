# Intonia

Flutter mobile app for offline pitch/intonation training on iOS and Android.
Voice-first, but the exercise model is instrument-agnostic.
(Project/package name remains `vocal_scale_trainer` for historical reasons.)

## Run

```powershell
flutter pub get
flutter run
```

## Audio asset

The app is wired to load `assets/soundfonts/piano.sf2` through `flutter_midi_pro`.
Use a piano SoundFont with a license that explicitly allows commercial mobile distribution.

Android builds for `flutter_midi_pro` require CMake 3.22.1 because the plugin builds FluidSynth.

## Architecture

The project uses a feature-first layout:

- `lib/core`: music theory (`exercise.dart` defines the generic exercise model and built-in library), pitch detection, and session models.
- `lib/services`: platform-facing audio and microphone services, plus JSON persistence for custom exercises (`services/storage`).
- `lib/features/library`: home screen with the exercise library grouped by type (Custom first, then Triads, Arpeggios, Pentatonics, Scales, 3-voice Harmonizations, Patterns as expandable accordions) and the custom sequence editor (absolute notes, any octave, repeated/descending notes allowed).
- `lib/features/settings`: settings screen and global preferences (theme mode, note notation DO-RE-MI vs C-D-E, persisted).
- `lib/features/profile`: profile screen with practice streak, per-note accuracy, detected vocal range, and session history (persisted to `session_history.json`, last 500 sessions).
- `lib/features/trainer`: training feature with domain state machine, controller, and the mobile-first trainer screen (notes on top, controls pinned at the bottom, advanced settings in a bottom sheet).
- `lib/features/future_modules`: module registry for intervals, chords, progressions, vocalises, ear training, profile, cloud sync, and in-app purchases.

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
