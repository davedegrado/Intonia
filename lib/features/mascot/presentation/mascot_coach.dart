import 'package:flutter/material.dart';

import '../domain/mascot_mood.dart';
import 'intonia_mascot.dart';

/// Mascotte con fumetto: accompagna l'utente con un messaggio breve.
class MascotCoach extends StatelessWidget {
  const MascotCoach({
    required this.mood,
    required this.message,
    this.reaction,
    this.mascotSize = 72,
    super.key,
  });

  final MascotMood mood;
  final String message;
  final MascotReaction? reaction;
  final double mascotSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IntoniaMascot(mood: mood, reaction: reaction, size: mascotSize),
        const SizedBox(width: 6),
        Expanded(child: MascotSpeechBubble(text: message)),
      ],
    );
  }
}

/// Fumetto con bordo sfumato nei colori della mascotte; il testo cambia
/// con una dissolvenza.
class MascotSpeechBubble extends StatelessWidget {
  const MascotSpeechBubble({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16);
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: [MascotPainter.cyan, MascotPainter.violet, MascotPainter.magenta],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14.5),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            text,
            key: ValueKey(text),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
