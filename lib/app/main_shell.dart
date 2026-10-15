import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/tuner/application/tuner_controller.dart';

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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('main-navigation'),
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
