import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/note_text.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/l10n/app_localizations.dart';

/// Span di testo di primo livello (nome e ottava) di un Text.rich.
List<TextSpan> _parts(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder);
  final spans = <TextSpan>[];
  text.textSpan!.visitChildren((span) {
    if (span is TextSpan && span.text != null) {
      spans.add(span);
    }
    return true;
  });
  return spans;
}

void main() {
  testWidgets('the note name dominates, the octave is small and secondary', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
      home: Scaffold(
        body: NoteText(
          spelledMidi(60),
          notation: NoteNotation.italian,
          style: const TextStyle(fontSize: 30, color: Colors.white),
        ),
      ),
    ));

    final parts = _parts(tester, find.byType(Text));
    expect(parts.map((p) => p.text), ['DO', '4']);
    expect(parts[1].style!.fontSize, 15, reason: "l'ottava è la metà del nome");
    expect(parts[1].style!.color, isNot(parts[0].style!.color));

    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('DO, ottava 4'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the octave is announced in the active language', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: NoteText(spelledMidi(70), notation: NoteNotation.english),
      ),
    ));
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Bb, octave 4'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a range keeps both octaves small, with surrounding text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
      home: Scaffold(
        body: NoteRangeText(
          low: spelledMidi(48),
          high: spelledMidi(79),
          notation: NoteNotation.english,
          style: const TextStyle(fontSize: 20),
          prefix: 'Range: ',
        ),
      ),
    ));
    final parts = _parts(tester, find.byType(Text));
    expect(parts.map((p) => p.text).join(), 'Range: C3 – G5');
    final octaves = parts.where((p) => p.text == '3' || p.text == '5');
    expect(octaves.every((p) => p.style!.fontSize == 10), isTrue);
  });
}
