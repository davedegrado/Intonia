import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/music/note.dart';
import '../../../../core/music/note_spelling.dart';
import '../../../settings/application/settings_providers.dart';
import '../../domain/note_progress.dart';

/// Vista compatta della sequenza: una sola riga orizzontale scrollabile
/// (chips o pentagramma) con auto-scroll sulla nota corrente.
class ScaleSequenceView extends ConsumerStatefulWidget {
  const ScaleSequenceView({
    required this.sequence,
    required this.progress,
    required this.currentIndex,
    this.onTapCurrent,
    super.key,
  });

  final List<MusicalNote> sequence;
  final List<NoteProgressStatus> progress;
  final int currentIndex;

  /// Chiamato quando l'utente tocca la nota corrente (per riascoltarla).
  final VoidCallback? onTapCurrent;

  @override
  ConsumerState<ScaleSequenceView> createState() => _ScaleSequenceViewState();
}

class _ScaleSequenceViewState extends ConsumerState<ScaleSequenceView> {
  static const _chipExtent = 60.0; // 52 + spacing
  static const _staffNoteExtent = 34.0;
  static const _staffLeadWidth = 56.0;

  final _scrollController = ScrollController();
  bool _staffMode = false;

  @override
  void didUpdateWidget(ScaleSequenceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.sequence.length != widget.sequence.length) {
      _scrollToCurrent();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) {
      return;
    }
    final extent = _staffMode ? _staffNoteExtent : _chipExtent;
    final lead = _staffMode ? _staffLeadWidth : 0.0;
    final viewport = _scrollController.position.viewportDimension;
    final target = (lead + widget.currentIndex * extent - viewport / 2 + extent / 2)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notation = ref.watch(notationProvider);
    final spelled = NoteSpeller.spellSequence(widget.sequence);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.view_week, size: 18), tooltip: 'Note'),
                ButtonSegment(value: true, icon: Icon(Icons.queue_music, size: 18), tooltip: 'Pentagramma'),
              ],
              selected: {_staffMode},
              onSelectionChanged: (selection) {
                setState(() => _staffMode = selection.first);
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_staffMode)
          GestureDetector(
            // Toccando il pentagramma si riascolta la nota corrente.
            onTap: widget.onTapCurrent,
            child: _StaffView(
              spelled: spelled,
              progress: widget.progress,
              controller: _scrollController,
              noteExtent: _staffNoteExtent,
              leadWidth: _staffLeadWidth,
            ),
          )
        else
          _ChipsRow(
            spelled: spelled,
            progress: widget.progress,
            controller: _scrollController,
            notation: notation,
            extent: _chipExtent,
            onTapCurrent: widget.onTapCurrent,
          ),
      ],
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.spelled,
    required this.progress,
    required this.controller,
    required this.notation,
    required this.extent,
    this.onTapCurrent,
  });

  final List<SpelledNote> spelled;
  final List<NoteProgressStatus> progress;
  final ScrollController controller;
  final NoteNotation notation;
  final double extent;
  final VoidCallback? onTapCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemCount: spelled.length,
        itemExtent: extent,
        itemBuilder: (context, i) {
          final status = progress[i];
          final isCurrent = status == NoteProgressStatus.current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: isCurrent ? onTapCurrent : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: sequenceStatusColor(status, colors, background: true),
                  border: Border.all(color: sequenceStatusColor(status, colors)),
                ),
                child: Text(
                  spelled[i].label(notation),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: status == NoteProgressStatus.pending
                            ? colors.onSurfaceVariant
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StaffView extends StatelessWidget {
  const _StaffView({
    required this.spelled,
    required this.progress,
    required this.controller,
    required this.noteExtent,
    required this.leadWidth,
  });

  final List<SpelledNote> spelled;
  final List<NoteProgressStatus> progress;
  final ScrollController controller;
  final double noteExtent;
  final double leadWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = leadWidth + spelled.length * noteExtent + 16;

    return SizedBox(
      height: 130,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: CustomPaint(
          size: Size(width, 130),
          painter: _StaffPainter(
            spelled: spelled,
            progress: progress,
            colors: colors,
            noteExtent: noteExtent,
            leadWidth: leadWidth,
          ),
        ),
      ),
    );
  }
}

class _StaffPainter extends CustomPainter {
  _StaffPainter({
    required this.spelled,
    required this.progress,
    required this.colors,
    required this.noteExtent,
    required this.leadWidth,
  });

  final List<SpelledNote> spelled;
  final List<NoteProgressStatus> progress;
  final ColorScheme colors;
  final double noteExtent;
  final double leadWidth;

  static const _gap = 9.0; // distanza tra le linee del pentagramma
  static const _e4Diatonic = 30; // MI4 = linea inferiore

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = colors.onSurfaceVariant.withValues(alpha: 0.7)
      ..strokeWidth = 1;

    // Pentagramma centrato: linea inferiore (MI4) in basso.
    final bottomLineY = size.height * 0.68;
    for (var line = 0; line < 5; line++) {
      final y = bottomLineY - line * _gap;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Chiave di violino.
    final clef = TextPainter(
      text: TextSpan(
        text: '\u{1D11E}',
        style: TextStyle(fontSize: 62, color: colors.onSurfaceVariant),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    clef.paint(canvas, Offset(4, bottomLineY - 4 * _gap - 14));

    double yFor(int diatonic) => bottomLineY - (diatonic - _e4Diatonic) * _gap / 2;

    for (var i = 0; i < spelled.length; i++) {
      final note = spelled[i];
      final status = i < progress.length ? progress[i] : NoteProgressStatus.pending;
      final x = leadWidth + i * noteExtent + noteExtent / 2;
      final y = yFor(note.diatonicIndex);
      final color = sequenceStatusColor(status, colors, forStaff: true);

      // Tagli addizionali sotto e sopra il pentagramma.
      final ledgerPaint = Paint()
        ..color = colors.onSurfaceVariant.withValues(alpha: 0.7)
        ..strokeWidth = 1;
      for (var d = _e4Diatonic - 2; d >= note.diatonicIndex; d -= 2) {
        final ly = yFor(d);
        canvas.drawLine(Offset(x - 10, ly), Offset(x + 10, ly), ledgerPaint);
      }
      for (var d = _e4Diatonic + 10; d <= note.diatonicIndex; d += 2) {
        final ly = yFor(d);
        canvas.drawLine(Offset(x - 10, ly), Offset(x + 10, ly), ledgerPaint);
      }

      // Alone sulla nota corrente.
      if (status == NoteProgressStatus.current) {
        canvas.drawCircle(
          Offset(x, y),
          10,
          Paint()..color = color.withValues(alpha: 0.25),
        );
      }

      // Testa della nota.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 12.5, height: 9.5),
        Paint()..color = color,
      );

      // Alterazione.
      if (note.accidental.isNotEmpty) {
        final accidental = TextPainter(
          text: TextSpan(
            text: note.accidental.replaceAll('b', '♭').replaceAll('#', '♯'),
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        accidental.paint(canvas, Offset(x - 10 - accidental.width, y - accidental.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_StaffPainter oldDelegate) {
    return oldDelegate.spelled != spelled ||
        oldDelegate.progress != progress ||
        oldDelegate.colors != colors;
  }
}

/// Colori condivisi per lo stato di avanzamento.
Color sequenceStatusColor(
  NoteProgressStatus status,
  ColorScheme colors, {
  bool background = false,
  bool forStaff = false,
}) {
  const green = Color(0xFF1F8A5B);
  if (forStaff) {
    return switch (status) {
      NoteProgressStatus.pending => colors.onSurfaceVariant,
      NoteProgressStatus.current => colors.primary,
      NoteProgressStatus.correct => green,
      NoteProgressStatus.error => colors.error,
    };
  }
  if (background) {
    return switch (status) {
      NoteProgressStatus.pending => colors.surfaceContainerHighest,
      NoteProgressStatus.current => colors.primary,
      NoteProgressStatus.correct => green,
      NoteProgressStatus.error => colors.error,
    };
  }
  return switch (status) {
    NoteProgressStatus.pending => colors.outlineVariant,
    NoteProgressStatus.current => colors.primary,
    NoteProgressStatus.correct => green,
    NoteProgressStatus.error => colors.error,
  };
}
