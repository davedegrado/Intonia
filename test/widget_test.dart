import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/vocal_scale_trainer_app.dart';
import 'package:vocal_scale_trainer/features/settings/application/settings_providers.dart';

void main() {
  testWidgets('renders the home and the exercise catalog', (tester) async {
    // Dispositivo in italiano: l'interfaccia segue la lingua del sistema.
    await tester.pumpWidget(ProviderScope(
      overrides: [deviceLocaleProvider.overrideWithValue(const Locale('it'))],
      child: const VocalScaleTrainerApp(),
    ));
    await tester.pump();

    // Splash per 2 secondi, poi dissolvenza verso la Home.
    expect(find.byKey(const ValueKey('splash')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    // La Home ha animazioni continue (mascotte): niente pumpAndSettle.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('splash')), findsNothing);

    // Home: mascotte e riconoscimento in primo piano, barra con 4 sezioni.
    expect(find.text('Intonia'), findsOneWidget);
    expect(find.text('Avvia ascolto'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    // Il catalogo è nella sezione Esercizi.
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Esercizi'),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Crea la tua sequenza'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Armonizzazioni a 3 voci'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Armonizzazioni a 3 voci'), findsOneWidget);
  });
}
