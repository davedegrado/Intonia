import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/vocal_scale_trainer_app.dart';

void main() {
  testWidgets('renders exercise library home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VocalScaleTrainerApp()));
    await tester.pump();

    // Parte alta: titolo, tuner e invito custom.
    expect(find.text('Intonia'), findsOneWidget);
    expect(find.text('Riconoscimento in tempo reale'), findsOneWidget);
    expect(find.text('Crea la tua sequenza'), findsOneWidget);

    // La ListView è lazy: le sezioni successive esistono solo dopo lo scroll.
    await tester.dragUntilVisible(
      find.text('Triade maggiore'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Triade maggiore'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Armonizzazioni a 3 voci'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Armonizzazioni a 3 voci'), findsOneWidget);
  });
}
