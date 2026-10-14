import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/note_progress.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/widgets/scale_sequence_view.dart';

void main() {
  const sequence = [
    MusicalNote(pitchClass: PitchClass.c, octave: 4),
    MusicalNote(pitchClass: PitchClass.e, octave: 4),
    MusicalNote(pitchClass: PitchClass.g, octave: 4),
  ];

  Future<List<int>> pump(WidgetTester tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ScaleSequenceView(
            sequence: sequence,
            progress: const [
              NoteProgressStatus.correct,
              NoteProgressStatus.current,
              NoteProgressStatus.pending,
            ],
            currentIndex: 1,
            onTapNote: tapped.add,
          ),
        ),
      ),
    ));
    return tapped;
  }

  testWidgets('every note chip can be tapped to hear it', (tester) async {
    final tapped = await pump(tester);
    for (var i = 0; i < sequence.length; i++) {
      await tester.tap(find.byKey(ValueKey('sequence-note-$i')));
    }
    expect(tapped, [0, 1, 2]);
  });

  testWidgets('on the staff, the tapped note is played', (tester) async {
    final tapped = await pump(tester);
    await tester.tap(find.byIcon(Icons.queue_music));
    await tester.pumpAndSettle();

    final staff = tester.getTopLeft(find.byKey(const ValueKey('sequence-staff')));
    // Lead 56 px, una nota ogni 34 px: centro della terza nota.
    await tester.tapAt(staff + const Offset(56 + 2 * 34 + 17, 60));
    // Sulla chiave di violino: la nota corrente.
    await tester.tapAt(staff + const Offset(20, 60));
    expect(tapped, [2, 1]);
  });
}
