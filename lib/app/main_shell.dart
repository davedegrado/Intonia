import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/tuner/application/tuner_controller.dart';
import 'app_theme.dart';

/// Destinazioni principali, nell'ordine della barra di navigazione.
const mainDestinations = [
  (path: '/', label: 'Home', icon: Icons.home_outlined, selected: Icons.home),
  (
    path: '/exercises',
    label: 'Esercizi',
    icon: Icons.music_note_outlined,
    selected: Icons.music_note
  ),
  (path: '/range', label: 'Estensione', icon: Icons.bar_chart_outlined, selected: Icons.bar_chart),
  (path: '/profile', label: 'Profilo', icon: Icons.person_outline, selected: Icons.person),
];

/// Scaffold delle quattro sezioni principali con la barra di navigazione.
class MainShell extends ConsumerWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decor = context.decor;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      // Stessa barra in tutti i temi; in Neon superficie sfumata con un filo
      // luminoso in alto.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: decor.ambient ? null : decor.navBackground,
          gradient: decor.ambient
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF17163A), Color(0xFF0D0D20)],
                )
              : null,
          border: Border(
            top: BorderSide(
              color: decor.ambient
                  ? decor.glow.withValues(alpha: 0.45)
                  : colors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          boxShadow: decor.ambient
              ? [
                  BoxShadow(
                    color: decor.glow.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ]
              : null,
        ),
        child: NavigationBar(
          key: const ValueKey('main-navigation'),
          backgroundColor: Colors.transparent,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            // Il riconoscimento in tempo reale vive solo nella Home.
            if (index != navigationShell.currentIndex) {
              ref.read(tunerControllerProvider.notifier).stop();
            }
            navigationShell.goBranch(
              index,
              // Toccare la sezione già aperta torna alla sua radice.
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            for (final destination in mainDestinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selected),
                label: destination.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Apre una sezione principale fermando prima il riconoscimento in tempo reale.
void goToSection(BuildContext context, WidgetRef ref, String path) {
  ref.read(tunerControllerProvider.notifier).stop();
  context.go(path);
}

/// Apre una schermata a tutto schermo (sopra la barra) fermando prima il
/// riconoscimento in tempo reale.
void pushFullScreen(BuildContext context, WidgetRef ref, String route, {Object? extra}) {
  ref.read(tunerControllerProvider.notifier).stop();
  context.push(route, extra: extra);
}
