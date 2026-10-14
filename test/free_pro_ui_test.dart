import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/features/access/domain/charge_ledger.dart';
import 'package:vocal_scale_trainer/features/access/domain/entitlement.dart';
import 'package:vocal_scale_trainer/features/access/presentation/charges_widgets.dart';
import 'package:vocal_scale_trainer/features/access/presentation/pro_screen.dart';
import 'package:vocal_scale_trainer/features/library/presentation/custom_exercise_editor_screen.dart';

import 'support/access_fakes.dart';

Widget _app(Widget child, {required List overrides}) => ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  final clock = FakeClock(DateTime(2026, 10, 14, 12));

  List overrides(ChargeLedger stored, {Entitlement entitlement = Entitlement.free}) => [
        clockProvider.overrideWithValue(clock.call),
        chargesRepositoryProvider.overrideWithValue(InMemoryChargesRepository(stored)),
        entitlementSourceProvider.overrideWithValue(FixedEntitlementSource(entitlement)),
      ];

  test('wait formatting', () {
    expect(formatWait(const Duration(hours: 2, minutes: 15)), '2 h 15 min');
    expect(formatWait(const Duration(minutes: 45)), '45 min');
    expect(formatWait(const Duration(hours: 3)), '3 h');
    expect(formatWait(Duration.zero), 'meno di 1 min');
  });

  testWidgets('home card: available charges and time to the next one', (tester) async {
    final stored = ChargeLedger(charges: 5, regenStartedAt: DateTime(2026, 10, 14, 11, 15));
    await tester.pumpWidget(_app(const ChargesCard(), overrides: overrides(stored)));
    await tester.pump();
    expect(find.textContaining('5/7'), findsOneWidget);
    expect(find.text('Prossima carica tra 2 h 15 min'), findsOneWidget);
  });

  testWidgets('home card shows Pro instead of charges for Pro users', (tester) async {
    await tester.pumpWidget(_app(const ChargesCard(),
        overrides: overrides(ChargeLedger.full, entitlement: const Entitlement(plan: Plan.pro))));
    await tester.pump();
    expect(find.text('Intonia Pro'), findsOneWidget);
    expect(find.textContaining('/7'), findsNothing);
    expect(find.textContaining('build sviluppatore'), findsNothing);
  });

  testWidgets('developer Pro build: unlimited and labelled as such', (tester) async {
    expect(DeveloperProEntitlementSource.enabled, isFalse,
        reason: 'i test e le build normali non sono Pro sviluppatore');
    final entitlement = await const DeveloperProEntitlementSource().load();
    expect(entitlement.allows(ProFeature.unlimitedExercises), isTrue);
    await tester.pumpWidget(_app(const ChargesCard(),
        overrides: overrides(ChargeLedger.full, entitlement: entitlement)));
    await tester.pump();
    expect(find.text('Esercizi illimitati · build sviluppatore'), findsOneWidget);
  });

  testWidgets('exhausted sheet: wait time, free features and Pro', (tester) async {
    final stored = ChargeLedger(charges: 0, regenStartedAt: DateTime(2026, 10, 14, 10));
    await tester.pumpWidget(_app(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showChargesExhausted(context),
          child: const Text('apri'),
        ),
      ),
      overrides: overrides(stored),
    ));
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    expect(find.text('Cariche esaurite'), findsOneWidget);
    expect(find.text('Prossima carica tra 1 h.'), findsOneWidget);
    expect(find.textContaining('test di estensione vocale sono sempre gratuiti'), findsOneWidget);
    expect(find.text('Scopri Intonia Pro'), findsOneWidget);
  });

  testWidgets('Free users see an explanation instead of the sequence editor', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [...overrides(ChargeLedger.full)],
      child: const MaterialApp(home: CustomExerciseEditorScreen()),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('custom-sequences-pro')), findsOneWidget);
    expect(find.text('Salva'), findsNothing);
  });

  testWidgets('Pro users get the sequence editor', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [...overrides(ChargeLedger.full, entitlement: const Entitlement(plan: Plan.pro))],
      child: const MaterialApp(home: CustomExerciseEditorScreen()),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('custom-sequences-pro')), findsNothing);
    expect(find.text('Salva'), findsOneWidget);
  });

  testWidgets('paywall shows the prices and does not simulate purchases', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [...overrides(ChargeLedger.full)],
      child: const MaterialApp(home: ProScreen()),
    ));
    await tester.pump();
    expect(find.text('€4,99'), findsOneWidget);
    expect(find.text('€39,99'), findsOneWidget);
    final subscribe = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Abbonati'));
    expect(subscribe.onPressed, isNull);
  });
}
