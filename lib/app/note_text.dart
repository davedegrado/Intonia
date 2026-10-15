import 'package:flutter/material.dart';

import '../core/music/note.dart';
import '../core/music/note_spelling.dart';
import '../l10n/app_localizations.dart';

/// Rapporto tra la dimensione dell'ottava e quella del nome della nota.
const _octaveScale = 0.5;

/// Nota come testo, con il nome (DO, RE…) come informazione principale e
/// l'ottava piccola e attenuata subito dopo. Da usare ovunque si mostra una
/// nota con l'ottava, anche dentro una frase.
InlineSpan noteSpan(
  SpelledNote note,
  NoteNotation notation, {
  required TextStyle style,
  Color? octaveColor,
}) {
  final size = style.fontSize ?? 14;
  final color = octaveColor ?? (style.color ?? Colors.black).withValues(alpha: 0.6);
  return TextSpan(
    children: [
      TextSpan(text: note.label(notation), style: style),
      TextSpan(
        text: '${note.letterOctave}',
        style: style.copyWith(
          fontSize: size * _octaveScale,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

/// Nota da un numero MIDI, scritta come tonica (es. SIb e non LA#).
SpelledNote spelledMidi(int midi) => NoteSpeller.spellRoot(MusicalNote.fromMidi(midi));

/// Widget di una nota con l'ottava piccola (vedi [noteSpan]).
class NoteText extends StatelessWidget {
  const NoteText(
    this.note, {
    required this.notation,
    this.style,
    this.octaveColor,
    this.textAlign,
    super.key,
  });

  final SpelledNote note;
  final NoteNotation notation;
  final TextStyle? style;
  final Color? octaveColor;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    return Text.rich(
      noteSpan(note, notation, style: base, octaveColor: octaveColor),
      textAlign: textAlign,
      semanticsLabel: _l10n(context).noteSemanticsLabel(note.label(notation), note.letterOctave),
    );
  }
}

/// Testi nella lingua attiva; inglese se manca la localizzazione (es. widget
/// mostrati fuori da MaterialApp nei test).
AppLocalizations _l10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('en'));

/// Intervallo tra due note ("DO3 – SOL5") con le ottave piccole.
class NoteRangeText extends StatelessWidget {
  const NoteRangeText({
    required this.low,
    required this.high,
    required this.notation,
    this.style,
    this.octaveColor,
    this.textAlign,
    this.prefix,
    this.suffix,
    super.key,
  });

  final SpelledNote low;
  final SpelledNote high;
  final NoteNotation notation;
  final TextStyle? style;
  final Color? octaveColor;
  final TextAlign? textAlign;

  /// Testo prima e dopo l'intervallo, con lo stesso stile.
  final String? prefix;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (prefix != null) TextSpan(text: prefix),
          noteSpan(low, notation, style: base, octaveColor: octaveColor),
          const TextSpan(text: ' – '),
          noteSpan(high, notation, style: base, octaveColor: octaveColor),
          if (suffix != null) TextSpan(text: suffix),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
