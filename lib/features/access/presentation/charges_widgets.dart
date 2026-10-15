import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../app/l10n.dart';
import '../application/access_providers.dart';
import '../domain/charge_ledger.dart';

/// "2 h 15 min", "45 min", "meno di 1 min" / "less than 1 min".
String formatWait(AppLocalizations l10n, Duration wait) {
  final minutes = (wait.inSeconds / 60).ceil();
  if (minutes <= 0) {
    return l10n.chargesWaitUnderMinute;
  }
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) {
    return l10n.chargesWaitMinutes(rest);
  }
  return rest == 0 ? l10n.chargesWaitHours(hours) : l10n.chargesWaitHoursMinutes(hours, rest);
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

/// Indicatore compatto delle cariche ("5/7") per le barre in alto; apre la
/// spiegazione con il tempo alla prossima carica. Per Pro: "Pro".
class ChargesChip extends ConsumerWidget {
  const ChargesChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);
    if (entitlement.isPro) {
      return StatusPill(
        key: const ValueKey('charges-chip'),
        icon: Icons.workspace_premium,
        iconColor: context.decor.charge,
        label: 'Pro',
        semanticLabel: entitlement.developer
            ? context.l10n.chargesProDeveloperSemantics
            : context.l10n.chargesProSemantics,
        onTap: () => context.push('/pro'),
      );
    }
    return _ChargesTicker(
      builder: (context, ledger, now) => StatusPill(
        key: const ValueKey('charges-chip'),
        icon: Icons.bolt,
        iconColor: context.decor.charge,
        label: '${ledger.charges}/${ChargeLedger.max}',
        semanticLabel: context.l10n.chargesChipSemantics(ledger.charges, ChargeLedger.max),
        onTap: () => showChargesInfo(context),
      ),
    );
  }
}

/// Pillola compatta (icona + valore) delle barre in alto: serie, cariche.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: colors.surface,
        shape: StadiumBorder(side: BorderSide(color: colors.outlineVariant)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: iconColor ?? colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    final l10n = context.l10n;
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
                      Icon(Icons.bolt, color: context.decor.charge, size: 30),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exhausted ? l10n.chargesExhaustedTitle : l10n.chargesTitle,
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
                      l10n.chargesNextIn(formatWait(l10n, wait)),
                      key: const ValueKey('charges-wait'),
                      style: theme.textTheme.titleSmall,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.chargesExplanation(hours, ChargeLedger.max),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.chargesFreeFeatures,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/pro');
                    },
                    icon: const Icon(Icons.workspace_premium),
                    label: Text(l10n.chargesDiscoverPro),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(exhausted ? l10n.chargesWaitForRecharge : l10n.commonClose),
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
            Icon(Icons.bolt, size: 16, color: context.decor.charge),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                context.l10n.chargesHint(ledger.charges, ChargeLedger.max),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
