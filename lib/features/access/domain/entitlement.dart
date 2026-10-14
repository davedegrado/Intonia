/// Piano dell'utente. Fonte unica per distinguere Free e Pro: la logica delle
/// cariche resta separata e chiede solo [Entitlement.isPro].
enum Plan { free, pro }

/// Funzioni riservate a Intonia Pro. Solo funzioni già esistenti nell'app;
/// quelle future sono in docs/ROADMAP.md.
enum ProFeature {
  /// Esercizi strutturati senza consumare cariche.
  unlimitedExercises,

  /// Creazione, modifica e salvataggio di sequenze personalizzate.
  customSequences,

  /// Storico completo delle sessioni nel profilo.
  fullHistory,
}

class Entitlement {
  const Entitlement({required this.plan, this.expiresAt, this.developer = false});

  static const free = Entitlement(plan: Plan.free);

  /// Pro della build sviluppatore (vedi [DeveloperProEntitlementSource]).
  static const developerPro = Entitlement(plan: Plan.pro, developer: true);

  final Plan plan;

  /// Scadenza dell'abbonamento, quando nota (dagli store).
  final DateTime? expiresAt;

  /// Pro concesso dalla build sviluppatore, non da un abbonamento.
  final bool developer;

  bool get isPro => plan == Plan.pro;

  bool allows(ProFeature feature) => isPro;
}

/// Origine dell'entitlement. Oggi l'app non integra acquisti: l'unica
/// implementazione restituisce Free. L'integrazione con App Store / Google
/// Play (con verifica degli abbonamenti) sostituirà questa classe senza
/// toccare cariche e interfaccia.
abstract class EntitlementSource {
  Future<Entitlement> load();
}

class NoPurchasesEntitlementSource implements EntitlementSource {
  const NoPurchasesEntitlementSource();

  @override
  Future<Entitlement> load() async => Entitlement.free;
}

/// Pro per le build dello sviluppatore, attivato solo in compilazione con
/// `--dart-define=INTONIA_DEV_PRO=true` (nessun pulsante o codice nell'app).
/// Le build compilate così non vanno inviate in revisione agli store.
class DeveloperProEntitlementSource implements EntitlementSource {
  const DeveloperProEntitlementSource();

  /// Vero solo nelle build compilate con il flag.
  static const enabled = bool.fromEnvironment('INTONIA_DEV_PRO');

  @override
  Future<Entitlement> load() async => Entitlement.developerPro;
}
