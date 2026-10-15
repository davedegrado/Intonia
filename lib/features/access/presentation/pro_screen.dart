import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/intonia_mascot.dart';
import '../application/access_providers.dart';
import '../domain/charge_ledger.dart';

/// Piano di abbonamento mostrato nel paywall (prezzi indicativi).
class ProPlan {
  const ProPlan({required this.title, required this.price, required this.period, this.note});

  final String title;
  final String price;
  final String period;
  final String? note;

  static const monthly = ProPlan(title: 'Mensile', price: '€4,99', period: 'al mese');
  static const yearly = ProPlan(
    title: 'Annuale',
    price: '€39,99',
    period: "all'anno",
    note: 'Risparmi il 33%',
  );
}

/// Intonia Pro: vantaggi e piani. Gli acquisti non sono ancora integrati:
/// i pulsanti restano disattivati, nessun acquisto viene simulato.
class ProScreen extends ConsumerWidget {
  const ProScreen({super.key});

  static const purchasesAvailable = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entitlement = ref.watch(entitlementProvider);
    final isPro = entitlement.isPro;

    return Scaffold(
      appBar: AppBar(title: const Text('Intonia Pro')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Center(child: IntoniaMascot(mood: MascotMood.greeting, size: 120)),
            const SizedBox(height: 8),
            Text(
              isPro ? 'Hai Intonia Pro' : 'Allenati senza limiti',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (entitlement.developer) ...[
              const SizedBox(height: 4),
              Text(
                'Build sviluppatore: Pro attivo senza abbonamento.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            const _Benefit(
              icon: Icons.all_inclusive,
              title: 'Esercizi illimitati',
              text: 'Nessuna carica: tutte le sessioni che vuoi.',
            ),
            const _Benefit(
              icon: Icons.edit_note,
              title: 'Sequenze personalizzate',
              text: 'Crea, modifica e salva i tuoi esercizi.',
            ),
            const _Benefit(
              icon: Icons.history,
              title: 'Storico completo',
              text: 'Tutte le tue sessioni nel profilo.',
            ),
            const _Benefit(
              icon: Icons.insights,
              title: 'In arrivo',
              text: 'Statistiche avanzate, grafici dei progressi e percorsi personalizzati.',
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Gratis per sempre: riconoscimento delle note in tempo reale, test di '
                  'estensione vocale, tutti gli esercizi con ${ChargeLedger.max} cariche '
                  'che si ricaricano, profilo, statistiche essenziali e serie giornaliera.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            if (!isPro) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  for (final plan in [ProPlan.monthly, ProPlan.yearly])
                    Expanded(child: _PlanCard(plan: plan)),
                ],
              ),
              const SizedBox(height: 16),
              const FilledButton(
                // Acquisti in-app non ancora integrati (vedi docs/ROADMAP.md).
                onPressed: purchasesAvailable ? _noop : null,
                child: Text('Abbonati'),
              ),
              const SizedBox(height: 8),
              Text(
                'Gli abbonamenti saranno disponibili a breve tramite App Store e Google Play.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const TextButton(
                onPressed: purchasesAvailable ? _noop : null,
                child: Text('Ripristina acquisti'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(plan.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(plan.price,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text(plan.period, style: theme.textTheme.bodySmall),
            if (plan.note != null) ...[
              const SizedBox(height: 6),
              Text(plan.note!,
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
