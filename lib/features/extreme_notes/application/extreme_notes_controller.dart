import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pitch/pitch_detection_result.dart';
import '../../../core/pitch/pitch_stabilizer.dart';
import '../../../services/pitch/microphone_pitch_service.dart';
import '../../access/application/access_providers.dart';
import '../../trainer/presentation/controllers/trainer_controller.dart';
import '../domain/extreme_notes.dart';

enum ExtremeNotesPhase { intro, listening, done }

enum ExtremeNotesMessage { microphoneDenied, audioUnavailable, interrupted }

class ExtremeNotesState {
  const ExtremeNotesState({
    required this.phase,
    this.lowest,
    this.highest,
    this.detected,
    this.elapsed = Duration.zero,
    this.result,
    this.message,
  });

  final ExtremeNotesPhase phase;

  /// Note estreme riconosciute finora (durante l'ascolto).
  final int? lowest;
  final int? highest;

  /// Nota che si sta cantando, solo come riscontro.
  final PitchDetectionResult? detected;
  final Duration elapsed;
  final ExtremeNotesResult? result;
  final ExtremeNotesMessage? message;
}

final extremeNotesControllerProvider =
    NotifierProvider.autoDispose<ExtremeNotesController, ExtremeNotesState>(
  ExtremeNotesController.new,
);

/// "Trova le note estreme": ascolta il canto libero con il microfono
/// dell'app e, alla fine, mostra la nota più bassa e la più alta riconosciute.
/// Non riproduce note, non registra audio e non salva nulla: ogni sessione
/// riparte da zero.
class ExtremeNotesController extends Notifier<ExtremeNotesState> {
  late MicrophonePitchService _microphone;
  StreamSubscription<PitchDetectionResult>? _subscription;
  ExtremeNotesTracker _tracker = ExtremeNotesTracker();

  /// Validazione temporale dei frame (stessa di esercizi e accordatore).
  final _validator = PitchStabilizer();
  DateTime? _startedAt;

  /// Incrementato a ogni avvio, arresto e dispose (avvii superati).
  int _generation = 0;

  DateTime get _now => ref.read(clockProvider)();

  @override
  ExtremeNotesState build() {
    _microphone = ref.read(microphonePitchServiceProvider);
    ref.onDispose(() {
      _generation++;
      unawaited(_subscription?.cancel());
      _subscription = null;
      unawaited(_microphone.stop());
    });
    return const ExtremeNotesState(phase: ExtremeNotesPhase.intro);
  }

  /// Inizia una sessione nuova (nessun dato della precedente).
  Future<void> start() async {
    if (state.phase == ExtremeNotesPhase.listening) {
      return;
    }
    final generation = ++_generation;
    _tracker = ExtremeNotesTracker();
    _validator.reset();
    _startedAt = _now;
    state = const ExtremeNotesState(phase: ExtremeNotesPhase.listening);
    try {
      final started = await _microphone.start();
      if (generation != _generation) {
        // Sessione chiusa mentre il microfono si avviava: nessuna risorsa
        // resta attiva (se nel frattempo ne è partita un'altra, è sua).
        if (started && state.phase != ExtremeNotesPhase.listening) {
          await _microphone.stop();
        }
        return;
      }
      if (!started) {
        state = const ExtremeNotesState(
            phase: ExtremeNotesPhase.intro, message: ExtremeNotesMessage.microphoneDenied);
        return;
      }
      _subscription = _microphone.pitchStream.listen(_handlePitch, onError: (Object _) {
        unawaited(stop(message: ExtremeNotesMessage.interrupted));
      });
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = const ExtremeNotesState(
          phase: ExtremeNotesPhase.intro, message: ExtremeNotesMessage.audioUnavailable);
    }
  }

  void _handlePitch(PitchDetectionResult detection) {
    if (state.phase != ExtremeNotesPhase.listening) {
      return;
    }
    final now = _now;
    // Le note estreme si raccolgono dai frame validati (verifica dell'ottava
    // nel rilevatore e conferma dei salti d'ottava nello stabilizzatore),
    // non da quelli grezzi.
    final shown = _validator.process(detection, now);
    _tracker.add(shown);
    state = ExtremeNotesState(
      phase: ExtremeNotesPhase.listening,
      lowest: _tracker.lowest,
      highest: _tracker.highest,
      detected: shown.isStable ? shown : null,
      elapsed: now.difference(_startedAt ?? now),
    );
  }

  /// "Termina e mostra i risultati": ferma il microfono e analizza.
  Future<void> stop({ExtremeNotesMessage? message}) async {
    if (state.phase != ExtremeNotesPhase.listening) {
      return;
    }
    _generation++;
    final elapsed = state.elapsed;
    final result = _tracker.result();
    state = ExtremeNotesState(
      phase: ExtremeNotesPhase.done,
      result: result,
      elapsed: elapsed,
      message: message,
    );
    // Prima il microfono: la risorsa si rilascia subito, anche se la
    // chiusura dell'ascolto tarda.
    final subscription = _subscription;
    _subscription = null;
    await _microphone.stop();
    await subscription?.cancel();
  }
}
