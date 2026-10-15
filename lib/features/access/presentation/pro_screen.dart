import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/intonia_mascot.dart';
import '../application/access_providers.dart';
import '../domain/charge_ledger.dart';

/// Piano di abbonamento mostrato nel paywall (prezzi indicativi).
enum ProPlan {
  monthly,
  yearly;

  String title(AppLocalizations l10n) => switch (this) {
        monthly => l10n.proPlanMonthly,
        yearly => l10n.proPlanYearly,
      };

  String price(AppLocalizations l10n) => switch (this) {
        monthly => l10n.proPriceMonthly,
        yearly => l10n.proPriceYearly,
      };

  String period(AppLocalizations l10n) => switch (this) {
        monthly => l10n.proPeriodMonth,
        yearly => l10n.proPeriodYear,
      };

  String? note(AppLocalizations l10n) => switch (this) {
        monthly => null,
        yearly => l10n.proYearlySaving,
      };
}

/// Intonia Pro: vantaggi e piani. Gli acquisti non sono ancora integrati:
/// i pulsanti restano disattivati, nessun acquisto viene simulato.
class ProScreen extends ConsumerWidget {
  const ProScreen({super.key});

  static const purchasesAvailable = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final entitlement = ref.watch(entitlementProvider);
    final isPro = entitlement.isPro;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.proTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Center(child: IntoniaMascot(mood: MascotMood.greeting, size: 120)),
            const SizedBox(height: 8),
            Text(
              isPro ? l10n.proHeadlinePro : l10n.proHeadlineFree,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (entitlement.developer) ...[
              const SizedBox(height: 4),
              Text(
                l10n.proDeveloperNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            _Benefit(
              icon: Icons.all_inclusive,
              title: l10n.proBenefitUnlimitedTitle,
              text: l10n.proBenefitUnlimitedText,
            ),
            _Benefit(
              icon: Icons.edit_note,
              title: l10n.proBenefitCustomTitle,
              text: l10n.proBenefitCustomText,
            ),
            _Benefit(
              icon: Icons.history,
              title: l10n.proBenefitHistoryTitle,
              text: l10n.proBenefitHistoryText,
            ),
            _Benefit(
              icon: Icons.insights,
              title: l10n.proBenefitComingTitle,
              text: l10n.proBenefitComingText,
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  l10n.proFreeForever(ChargeLedger.max),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            if (!isPro) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  for (final plan in ProPlan.values) Expanded(child: _PlanCard(plan: plan)),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                // Acquisti in-app non ancora integrati (vedi docs/ROADMAP.md).
                onPressed: purchasesAvailable ? _noop : null,
                child: Text(l10n.proSubscribe),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.proComingSoon,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              TextButton(
                onPressed: purchasesAvailable ? _noop : null,
                child: Text(l10n.proRestore),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(text),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final ProPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final note = plan.note(l10n);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(plan.title(l10n), style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(plan.price(l10n),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text(plan.period(l10n), style: theme.textTheme.bodySmall),
            if (note != null) ...[
              const SizedBox(height: 6),
              Text(note,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
