import 'package:flutter/material.dart';

/// Scelta di tema dell'app (persistita nelle impostazioni).
enum AppThemeSetting { system, light, dark, neon }

const _seed = Color(0xFF4F46E5); // Indigo

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
  return _decorate(scheme, const Color(0xFFF6F6FB));
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
  return _decorate(scheme, const Color(0xFF121218));
}

/// Tema "Neon": navy profondo con accenti ciano/violetto.
ThemeData buildNeonTheme() {
  const background = Color(0xFF0D0D1A);
  final base = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
  final scheme = base.copyWith(
    primary: const Color(0xFF818CF8),
    onPrimary: const Color(0xFF0D0D1A),
    secondary: const Color(0xFF38BDF8),
    onSecondary: const Color(0xFF0D0D1A),
    tertiary: const Color(0xFFA855F7),
    onTertiary: const Color(0xFF0D0D1A),
    primaryContainer: const Color(0xFF2B2B54),
    onPrimaryContainer: const Color(0xFFC7D2FE),
    tertiaryContainer: const Color(0xFF321B4F),
    onTertiaryContainer: const Color(0xFFE9D5FF),
    surface: const Color(0xFF16162B),
    surfaceContainerLow: const Color(0xFF131324),
    surfaceContainerHighest: const Color(0xFF232345),
    outlineVariant: const Color(0xFF32325A),
  );
  return _decorate(scheme, background);
}

ThemeData _decorate(ColorScheme scheme, Color scaffoldBackground) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBackground,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scaffoldBackground,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
    ),
  );
}
