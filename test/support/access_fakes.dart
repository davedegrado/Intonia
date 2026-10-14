import 'package:vocal_scale_trainer/features/access/domain/charge_ledger.dart';
import 'package:vocal_scale_trainer/features/access/domain/entitlement.dart';
import 'package:vocal_scale_trainer/services/storage/charges_repository.dart';

/// Orologio controllabile: si sposta in avanti senza attese reali.
class FakeClock {
  FakeClock([DateTime? start]) : now = start ?? DateTime(2026, 10, 14, 9);

  DateTime now;

  DateTime call() => now;

  void advance(Duration duration) => now = now.add(duration);
}

/// Cariche persistite in memoria (sopravvivono ai "riavvii" dei container).
class InMemoryChargesRepository extends ChargesRepository {
  InMemoryChargesRepository([this.stored]);

  ChargeLedger? stored;
  int saves = 0;

  @override
  Future<ChargeLedger> load() async => stored ?? ChargeLedger.full;

  @override
  Future<void> save(ChargeLedger ledger) async {
    stored = ledger;
    saves++;
  }
}

class FixedEntitlementSource implements EntitlementSource {
  const FixedEntitlementSource(this.entitlement);

  final Entitlement entitlement;

  @override
  Future<Entitlement> load() async => entitlement;
}
