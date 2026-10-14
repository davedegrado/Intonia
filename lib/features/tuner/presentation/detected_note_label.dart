import 'package:flutter/material.dart';

import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';

/// Nota riconosciuta: il nome (DO, RE…) è l'informazione principale, l'ottava
/// resta visibile ma piccola e attenuata accanto al nome.
class DetectedNoteLabel extends StatelessWidget {
  const DetectedNoteLabel({required this.note, required this.notation, super.key});

  final SpelledNote note;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.primary,
      height: 1,
    );
    final octaveStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Semantics(
      label: '${note.label(notation)}, ottava ${note.letterOctave}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(note.label(notation), key: const ValueKey('note-name'), style: nameStyle),
          const SizedBox(width: 2),
          Text('${note.letterOctave}', key: const ValueKey('note-octave'), style: octaveStyle),
        ],
      ),
    );
  }
}
