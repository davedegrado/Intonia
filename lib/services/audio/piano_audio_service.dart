import 'dart:async';

import 'package:flutter_midi_pro/flutter_midi_pro.dart';

import '../../core/music/note.dart';

class PianoAudioService {
  PianoAudioService({MidiPro? midiPro}) : _midiPro = midiPro ?? MidiPro();

  static const _assetPath = 'assets/soundfonts/piano.sf2';
  static const _channel = 0;
  static const _velocity = 104;

  final MidiPro _midiPro;
  int? _soundFontId;
  bool _cancelSequence = false;
  final Set<int> _activeNotes = {};

  Future<void> initialize() async {
    if (_soundFontId != null) {
      return;
    }

    final sfId = await _midiPro.loadSoundfontAsset(assetPath: _assetPath, bank: 0, program: 0);
    await _midiPro.selectInstrument(sfId: sfId, channel: _channel, bank: 0, program: 0);
    _soundFontId = sfId;
  }

  Future<void> playNote(MusicalNote note, {Duration duration = const Duration(milliseconds: 650)}) async {
    await initialize();
    final sfId = _soundFontId;
    if (sfId == null) {
      return;
    }

    await _midiPro.playNote(sfId: sfId, channel: _channel, key: note.midiNumber, velocity: _velocity);
    _activeNotes.add(note.midiNumber);
    unawaited(Future<void>.delayed(duration, () => stopNote(note)));
  }

  Future<void> stopNote(MusicalNote note) async {
    final sfId = _soundFontId;
    if (sfId == null || !_activeNotes.contains(note.midiNumber)) {
      return;
    }

    await _midiPro.stopNote(sfId: sfId, channel: _channel, key: note.midiNumber);
    _activeNotes.remove(note.midiNumber);
  }

  Future<void> playSequence({
    required List<MusicalNote> notes,
    required int bpm,
    required bool loop,
    required void Function(int index) onNote,
  }) async {
    await initialize();
    _cancelSequence = false;
    final beat = Duration(milliseconds: (60000 / bpm).round());

    do {
      for (var i = 0; i < notes.length; i++) {
        if (_cancelSequence) {
          await stopAll();
          return;
        }
        onNote(i);
        await playNote(notes[i], duration: beat);
        await Future<void>.delayed(beat);
      }
    } while (loop && !_cancelSequence);

    await stopAll();
  }

  Future<void> stopAll() async {
    _cancelSequence = true;
    final sfId = _soundFontId;
    if (sfId == null) {
      return;
    }

    for (final midi in List<int>.from(_activeNotes)) {
      await _midiPro.stopNote(sfId: sfId, channel: _channel, key: midi);
      _activeNotes.remove(midi);
    }
  }

}
