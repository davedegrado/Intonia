import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/access_providers.dart';
import '../domain/charge_ledger.dart';

/// Colore delle cariche: distinto dall'arancione della serie giornaliera.
const chargeColor = Color(0xFF22D3EE);

/// "2 h 15 min", "45 min", "meno di 1 min".
String formatWait(Duration wait) {
  final minutes = (wait.inSeconds / 60).ceil();
  if (minutes <= 0) {
    return 'meno di 1 min';
  }
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) {
    return '$rest min';
  }
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

/// Aggiorna periodicamente le cariche maturate mentre è visibile (solo per
/// il conto alla rovescia: la logica usa i timestamp, non questo timer).
class _ChargesTicker extends ConsumerStatefulWidget {
  const _ChargesTicker({required this.builder});

  final Widget Function(BuildContext context, ChargeLedger ledger, DateTime now) builder;

  @override
  ConsumerState<_ChargesTicker> createState() => _ChargesTickerState();
}

class _ChargesTickerState extends ConsumerState<_ChargesTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(chargesProvider.notifier).refresh());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(ref.read(chargesProvider.notifier).refresh());
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(chargesProvider);
    return widget.builder(context, ledger, ref.read(clockProvider)());
  }
}

/// Riquadro delle cariche nella Home (o "Intonia Pro" per gli utenti Pro).
class ChargesCard extends ConsumerWidget {
  const ChargesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entitlement = ref.watch(entitlementProvider);

    if (entitlement.isPro) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.workspace_premium, color: chargeColor),
          title: const Text('Intonia Pro'),
          subtitle: const Text('Esercizi illimitati'),
          onTap: () => context.push('/pro'),
        ),
      );
    }

    return _ChargesTicker(
      builder: (context, ledger, now) {
        final wait = ledger.timeToNext(now);
        return Card(
          key: const ValueKey('charges-card'),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showChargesInfo(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: chargeColor, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: '${ledger.charges}/${ChargeLedger.max}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const TextSpan(text: '  cariche esercizi'),
                          ]),
                          key: const ValueKey('charges-count'),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          wait == null
                              ? 'Cariche al completo'
                              : ledger.charges == 0
                                  ? 'Esaurite: la prossima tra ${formatWait(wait)}'
                                  : 'Prossima carica tra ${formatWait(wait)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/pro'),
                    child: const Text('Pro'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Spiegazione delle cariche.
Future<void> showChargesInfo(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _ChargesSheet(exhausted: false),
  );
}

/// Cariche esaurite all'avvio di un esercizio.
Future<void> showChargesExhausted(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _ChargesSheet(exhausted: true),
  );
}

class _ChargesSheet extends StatelessWidget {
  const _ChargesSheet({required this.exhausted});

  final bool exhausted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = ChargeLedger.interval.inHours;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: _ChargesTicker(
          builder: (context, ledger, now) {
            final wait = ledger.timeToNext(now);
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: chargeColor, size: 30),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exhausted ? 'Cariche esaurite' : 'Cariche esercizi',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${ledger.charges}/${ChargeLedger.max}',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (wait != null)
                    Text(
                      'Prossima carica tra ${formatWait(wait)}.',
                      key: const ValueKey('charges-wait'),
                      style: theme.textTheme.titleSmall,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Ogni sessione di esercizio usa una carica. Se ne ricarica una ogni '
                    '$hours ore, anche ad app chiusa, fino a ${ChargeLedger.max}.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Il riconoscimento in tempo reale e il test di estensione vocale sono '
                    'sempre gratuiti e illimitati.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/pro');
                    },
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Scopri Intonia Pro'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(exhausted ? 'Aspetto la ricarica' : 'Chiudi'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Riga informativa sotto il pulsante Play per gli utenti Free.
class ChargesHint extends ConsumerWidget {
  const ChargesHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(entitlementProvider).isPro) {
      return const SizedBox.shrink();
    }
    final ledger = ref.watch(chargesProvider);
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => showChargesInfo(context),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, size: 16, color: chargeColor),
            const SizedBox(width: 4),
            Text(
              'Ogni sessione usa 1 carica · ${ledger.charges}/${ChargeLedger.max} disponibili',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
