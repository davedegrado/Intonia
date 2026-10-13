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
  Future<void>? _initializing;

  /// Incrementato da ogni [playSequence] e da [stopAll]: una sequenza
  /// prosegue solo finché la generazione con cui è partita è quella corrente,
  /// così uno Stop→Play rapido non lascia due sequenze sovrapposte.
  int _sequenceGeneration = 0;

  /// Token dell'ultima pressione di ogni tasto: lo stop ritardato di una nota
  /// non deve interrompere una ripetizione successiva della stessa nota.
  final Map<int, int> _noteTokens = {};
  final Set<int> _activeNotes = {};

  Future<void> initialize() {
    if (_soundFontId != null) {
      return Future.value();
    }
    // Chiamate concorrenti condividono lo stesso caricamento del SoundFont.
    return _initializing ??= _load().whenComplete(() => _initializing = null);
  }

  Future<void> _load() async {
    final sfId = await _midiPro.loadSoundfontAsset(assetPath: _assetPath, bank: 0, program: 0);
    await _midiPro.selectInstrument(sfId: sfId, channel: _channel, bank: 0, program: 0);
    _soundFontId = sfId;
  }

  Future<void> playNote(
    MusicalNote note, {
    Duration duration = const Duration(milliseconds: 650),
  }) async {
    await initialize();
    final sfId = _soundFontId;
    if (sfId == null) {
      return;
    }

    final key = note.midiNumber;
    final token = (_noteTokens[key] ?? 0) + 1;
    _noteTokens[key] = token;
    await _midiPro.playNote(sfId: sfId, channel: _channel, key: key, velocity: _velocity);
    _activeNotes.add(key);
    unawaited(
      Future<void>.delayed(duration, () {
        if (_noteTokens[key] == token) {
          return stopNote(note);
        }
      }),
    );
  }

  Future<void> stopNote(MusicalNote note) async {
    final sfId = _soundFontId;
    if (sfId == null || !_activeNotes.contains(note.midiNumber)) {
      return;
    }

    _activeNotes.remove(note.midiNumber);
    await _midiPro.stopNote(sfId: sfId, channel: _channel, key: note.midiNumber);
  }

  /// Suona [notes] in sequenza. Ritorna true se la sequenza è terminata
  /// naturalmente, false se è stata interrotta da [stopAll] o sostituita da
  /// un'altra [playSequence].
  Future<bool> playSequence({
    required List<MusicalNote> notes,
    required int bpm,
    required bool loop,
    required void Function(int index) onNote,
  }) async {
    final generation = ++_sequenceGeneration;
    await initialize();
    final beat = Duration(milliseconds: (60000 / bpm).round());
    bool cancelled() => generation != _sequenceGeneration;

    do {
      for (var i = 0; i < notes.length; i++) {
        if (cancelled()) {
          return false;
        }
        onNote(i);
        await playNote(notes[i], duration: beat);
        await Future<void>.delayed(beat);
      }
    } while (loop && !cancelled());

    if (cancelled()) {
      return false;
    }
    await stopAll();
    return true;
  }

  Future<void> stopAll() async {
    _sequenceGeneration++;
    final sfId = _soundFontId;
    if (sfId == null) {
      return;
    }

    for (final midi in List<int>.from(_activeNotes)) {
      _activeNotes.remove(midi);
      await _midiPro.stopNote(sfId: sfId, channel: _channel, key: midi);
    }
  }

  /// Ferma le note e rilascia il SoundFont caricato nel sintetizzatore nativo.
  Future<void> dispose() async {
    await stopAll();
    final sfId = _soundFontId;
    _soundFontId = null;
    if (sfId != null) {
      await _midiPro.unloadSoundfont(sfId);
    }
  }
}
