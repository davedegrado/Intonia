import '../../mascot/domain/mascot_mood.dart';
import 'note_progress.dart';
import 'trainer_state.dart';

/// Stato della mascotte ricavato SOLO dallo stato del trainer già calcolato
/// dalla macchina a stati (nessuna soglia musicale aggiuntiva):
/// - esercizio completato o nota corrente convalidata → [MascotMood.success];
/// - nota corrente segnata come errore → [MascotMood.retry];
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
    return switch (state.progress[state.currentIndex]) {
      NoteProgressStatus.correct => MascotMood.success,
      NoteProgressStatus.error => MascotMood.retry,
      NoteProgressStatus.pending || NoteProgressStatus.current => MascotMood.listening,
    };
  }
  if (state.isPlaying) {
    return MascotMood.listening;
  }
  return MascotMood.idle;
}
