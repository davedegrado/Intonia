import '../../../l10n/app_localizations.dart';
import '../../mascot/domain/mascot_mood.dart';
import 'trainer_state.dart';
import 'training_settings.dart';
import 'training_state_machine.dart';

/// Stato della mascotte ricavato SOLO dallo stato del trainer già calcolato
/// dalla macchina a stati (nessuna soglia musicale aggiuntiva):
/// - esercizio completato → [MascotMood.success];
/// - in ascolto, appena convalidata una nota (in attesa del cambio nota)
///   → [MascotMood.success];
/// - in ascolto, nota segnata come errore (in attesa di un nuovo tentativo)
///   → [MascotMood.retry];
/// - microfono in ascolto o riproduzione in corso → [MascotMood.listening];
/// - altrimenti → [MascotMood.idle].
MascotMood mascotMoodForTrainer(TrainerState state) {
  if (state.sequence.isEmpty) {
    return MascotMood.idle;
  }
  if (state.isFinished) {
    return MascotMood.success;
  }
  if (state.isListening) {
    return switch (state.validationState) {
      TrainingValidationState.waitChange => MascotMood.success,
      TrainingValidationState.waitRetry => MascotMood.retry,
      TrainingValidationState.waitNote => MascotMood.listening,
    };
  }
  if (state.isPlaying) {
    return MascotMood.listening;
  }
  return MascotMood.idle;
}

/// Messaggio del fumetto della mascotte nel trainer, nella lingua di [l10n].
String mascotMessageForTrainer(TrainerState state, AppLocalizations l10n) {
  final listenMode = state.settings.mode == TrainerMode.listen;
  if (state.isFinished) {
    return l10n.mascotCompleted;
  }
  return switch (mascotMoodForTrainer(state)) {
    MascotMood.success => l10n.mascotSuccess,
    MascotMood.retry => l10n.mascotRetry,
    MascotMood.listening => listenMode ? l10n.mascotListenSequence : l10n.mascotSingNote,
    MascotMood.idle ||
    MascotMood.greeting =>
      listenMode ? l10n.mascotIdleListen : l10n.mascotIdleTrain,
  };
}
