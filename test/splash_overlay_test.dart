import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/splash_overlay.dart';

void main() {
  const splash = ValueKey('splash');

  Widget host() => const MaterialApp(home: SplashOverlay(child: Text('home')));

  testWidgets('stays for two seconds, then fades out', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.byKey(splash), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byKey(splash), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a tap skips it', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.byKey(splash));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.byKey(splash), findsNothing);
  });
}
