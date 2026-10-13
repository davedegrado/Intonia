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
}
