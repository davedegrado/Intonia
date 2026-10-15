import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session/session_record.dart';
import '../features/access/presentation/charges_widgets.dart';
import '../features/profile/application/history_providers.dart';
import 'app_theme.dart';
import 'l10n.dart';
import 'main_shell.dart';

/// Serie giornaliera e cariche, per la barra in alto delle sezioni principali.
class StatusChips extends StatelessWidget {
  const StatusChips({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreakChip(),
          SizedBox(width: 8),
          ChargesChip(),
        ],
      ),
    );
  }
}

/// Giorni di fila con almeno una sessione; apre il Profilo.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionHistoryProvider).value ?? const <SessionRecord>[];
    final streak = computeStreak(sessions.map((r) => r.timestamp), DateTime.now());
    return StatusPill(
      key: const ValueKey('streak-chip'),
      icon: Icons.local_fire_department,
      iconColor: streak > 0 ? context.decor.streak : Theme.of(context).colorScheme.outline,
      label: '$streak',
      semanticLabel: context.l10n.statusStreakSemantics(streak),
      onTap: () => goToSection(context, ref, '/profile'),
    );
  }
}
