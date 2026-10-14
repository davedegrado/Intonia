import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage/charges_repository.dart';
import '../domain/charge_ledger.dart';
import '../domain/entitlement.dart';

/// Orologio dell'app: sostituibile nei test (nessuna attesa reale).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final chargesRepositoryProvider = Provider<ChargesRepository>((ref) => ChargesRepository());

final entitlementSourceProvider =
    Provider<EntitlementSource>((ref) => const NoPurchasesEntitlementSource());

/// Piano corrente (Free finché non sono integrati gli acquisti).
final entitlementProvider = NotifierProvider<EntitlementNotifier, Entitlement>(
  EntitlementNotifier.new,
);

class EntitlementNotifier extends Notifier<Entitlement> {
  late Future<void> _loaded = _read();

  @override
  Entitlement build() {
    unawaited(_loaded);
    return Entitlement.free;
  }

  /// Entitlement dopo il caricamento iniziale: da usare prima di decidere se
  /// addebitare una carica (un utente Pro non deve mai perderne).
  Future<Entitlement> resolve() async {
    await _loaded;
    return state;
  }

  /// Rilegge l'entitlement dalla sua origine (es. dopo un acquisto).
  Future<void> refresh() {
    return _loaded = _read();
  }

  Future<void> _read() async {
    final loaded = await ref.read(entitlementSourceProvider).load();
    if (ref.mounted) {
      state = loaded;
    }
  }
}

/// Cariche Free, persistite. Lo stato esposto è aggiornato all'ultimo
/// [ChargesNotifier.refresh]; le decisioni ([tryConsume]) ricalcolano sempre
/// con l'orologio corrente.
final chargesProvider = NotifierProvider<ChargesNotifier, ChargeLedger>(ChargesNotifier.new);

class ChargesNotifier extends Notifier<ChargeLedger> {
  late final Future<void> _loaded = _load();

  /// Sessioni già addebitate: un avvio ripetuto della stessa sessione
  /// (doppio tap, richiesta duplicata) non consuma una seconda carica.
  final _chargedSessions = <String>{};

  @override
  ChargeLedger build() {
    unawaited(_loaded);
    return ChargeLedger.full;
  }

  Future<void> _load() async {
    final stored = await ref.read(chargesRepositoryProvider).load();
    if (!ref.mounted) {
      return;
    }
    // Cariche maturate mentre l'app era chiusa.
    state = stored.refreshed(_now);
    if (state != stored) {
      await ref.read(chargesRepositoryProvider).save(state);
    }
  }

  DateTime get _now => ref.read(clockProvider)();

  /// Attende il caricamento iniziale e aggiorna le cariche maturate.
  Future<ChargeLedger> refresh() async {
    await _loaded;
    if (!ref.mounted) {
      return state;
    }
    final updated = state.refreshed(_now);
    if (updated != state) {
      state = updated;
      await ref.read(chargesRepositoryProvider).save(updated);
    }
    return state;
  }

  /// Consuma una carica per la sessione [sessionId]. Ritorna false se le
  /// cariche sono esaurite; true (senza consumare) se la sessione era già
  /// stata addebitata.
  Future<bool> tryConsume(String sessionId) async {
    await _loaded;
    if (_chargedSessions.contains(sessionId)) {
      return true;
    }
    final next = state.consumed(_now);
    if (next == null) {
      state = state.refreshed(_now);
      return false;
    }
    _chargedSessions.add(sessionId);
    state = next;
    await ref.read(chargesRepositoryProvider).save(next);
    return true;
  }
}

/// Accesso agli esercizi strutturati: Pro illimitato, Free con le cariche.
/// Il riconoscimento in tempo reale e il test di estensione non passano di qui.
final exerciseAccessProvider = Provider<ExerciseAccess>((ref) {
  return ExerciseAccess(
    entitlement: ref.watch(entitlementProvider),
    charges: ref.watch(chargesProvider),
  );
});

class ExerciseAccess {
  const ExerciseAccess({required this.entitlement, required this.charges});

  final Entitlement entitlement;
  final ChargeLedger charges;

  bool get unlimited => entitlement.allows(ProFeature.unlimitedExercises);

  bool get canStartSession => unlimited || charges.charges > 0;
}
