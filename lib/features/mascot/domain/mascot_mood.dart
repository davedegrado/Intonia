/// Stato espressivo della mascotte di Intonia.
///
/// Il personaggio resta sempre lo stesso: cambiano solo espressione,
/// movimento ed effetti luminosi.
enum MascotMood {
  /// A riposo: oscillazione delicata, luminosità discreta, battito di ciglia.
  idle,

  /// In ascolto o in riproduzione: il diapason vibra ed emette onde sonore.
  listening,

  /// Nota corretta o esercizio completato: sorriso, più luce, saltello.
  success,

  /// Nota da riprovare: inclinazione delicata e gesto incoraggiante.
  retry,

  /// Saluto ("Ciao!"): agita un braccio, occhi sorridenti.
  greeting,
}

/// Reazione temporanea a un evento: la mascotte assume [mood] per
/// [duration], poi torna allo stato di base. Una nuova reazione si riconosce
/// da un [id] diverso (es. un contatore di eventi).
class MascotReaction {
  const MascotReaction({
    required this.mood,
    required this.id,
    this.duration = const Duration(milliseconds: 1400),
  });

  final MascotMood mood;
  final int id;
  final Duration duration;

  @override
  bool operator ==(Object other) => other is MascotReaction && other.mood == mood && other.id == id;

  @override
  int get hashCode => Object.hash(mood, id);
}
