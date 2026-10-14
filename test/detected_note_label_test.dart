import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/music/note_spelling.dart';
import 'package:vocal_scale_trainer/features/tuner/presentation/detected_note_label.dart';

void main() {
  testWidgets('the note name dominates, the octave is small and secondary', (tester) async {
    final note = NoteSpeller.spellRoot(const MusicalNote(pitchClass: PitchClass.c, octave: 4));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: DetectedNoteLabel(note: note, notation: NoteNotation.italian)),
    ));

    final name = tester.widget<Text>(find.byKey(const ValueKey('note-name')));
    final octave = tester.widget<Text>(find.byKey(const ValueKey('note-octave')));
    expect(name.data, 'DO');
    expect(octave.data, '4', reason: "l'ottava resta visibile");
    expect(name.style!.fontSize!, greaterThan(octave.style!.fontSize! * 2));
    expect(octave.style!.color, isNot(name.style!.color));

    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('DO, ottava 4'), findsOneWidget);
    handle.dispose();
  });
}
