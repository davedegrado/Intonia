import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/features/access/domain/charge_ledger.dart';

void main() {
  final t0 = DateTime(2026, 10, 14, 9);
  const step = ChargeLedger.interval;

  test('first install starts with 7 charges and no regeneration', () {
    expect(ChargeLedger.full.charges, 7);
    expect(ChargeLedger.full.refreshed(t0), ChargeLedger.full);
    expect(ChargeLedger.full.timeToNext(t0), isNull);
  });

  test('each consumption takes one charge; from full the regeneration starts', () {
    final one = ChargeLedger.full.consumed(t0)!;
    expect(one.charges, 6);
    expect(one.regenStartedAt, t0);
    final two = one.consumed(t0.add(const Duration(minutes: 30)))!;
    expect(two.charges, 5);
    expect(two.regenStartedAt, t0, reason: 'il tempo maturato non si azzera');
    expect(
        two.timeToNext(t0.add(const Duration(minutes: 30))), const Duration(hours: 2, minutes: 30));
  });

  test('one charge every 3 hours', () {
    final ledger = ChargeLedger(charges: 3, regenStartedAt: t0);
    expect(ledger.refreshed(t0.add(step - const Duration(seconds: 1))).charges, 3);
    final after = ledger.refreshed(t0.add(step));
    expect(after.charges, 4);
    expect(after.regenStartedAt, t0.add(step));
  });

  test('several charges after a long absence, keeping the partial progress', () {
    final ledger = ChargeLedger(charges: 1, regenStartedAt: t0);
    final now = t0.add(step * 4 + const Duration(hours: 1));
    final after = ledger.refreshed(now);
    expect(after.charges, 5);
    expect(after.timeToNext(now), const Duration(hours: 2));
  });

  test('never above the limit; regeneration stops when full', () {
    final ledger = ChargeLedger(charges: 2, regenStartedAt: t0);
    final after = ledger.refreshed(t0.add(const Duration(days: 30)));
    expect(after.charges, ChargeLedger.max);
    expect(after.regenStartedAt, isNull);
    // Consumando di nuovo il conteggio riparte da quel momento.
    final later = t0.add(const Duration(days: 31));
    final used = after.consumed(later)!;
    expect(used.charges, 6);
    expect(used.timeToNext(later), step);
  });

  test('no consumption when charges are exhausted', () {
    final empty = ChargeLedger(charges: 0, regenStartedAt: t0);
    expect(empty.consumed(t0.add(const Duration(hours: 1))), isNull);
    expect(empty.consumed(t0.add(step)), isNotNull, reason: 'dopo 3 ore una carica è maturata');
  });

  test('clock moved back: no free charges, regeneration restarts from now', () {
    final ledger = ChargeLedger(charges: 2, regenStartedAt: t0);
    final earlier = t0.subtract(const Duration(days: 2));
    final after = ledger.refreshed(earlier);
    expect(after.charges, 2);
    expect(after.regenStartedAt, earlier);
    expect(after.timeToNext(earlier), step);
  });

  test('invalid or tampered stored data is handled safely', () {
    expect(ChargeLedger.fromJson({'charges': 99}).charges, ChargeLedger.max);
    expect(ChargeLedger.fromJson({'charges': -4}).charges, 0);
    expect(ChargeLedger.fromJson({'charges': 'x'}).charges, ChargeLedger.max);
    final badDate = ChargeLedger.fromJson({'charges': 3, 'regenStartedAt': 'not a date'});
    expect(badDate.regenStartedAt, isNull);
    // Senza un riferimento valido la rigenerazione riparte da adesso.
    expect(badDate.refreshed(t0), ChargeLedger(charges: 3, regenStartedAt: t0));
  });

  test('round trip through JSON', () {
    final ledger = ChargeLedger(charges: 4, regenStartedAt: t0);
    final restored = ChargeLedger.fromJson(ledger.toJson());
    expect(restored.charges, 4);
    expect(restored.regenStartedAt!.isAtSameMomentAs(t0), isTrue);
  });
}
