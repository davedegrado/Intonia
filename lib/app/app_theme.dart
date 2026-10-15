import 'package:flutter/material.dart';

/// Scelta di tema dell'app (persistita nelle impostazioni).
enum AppThemeSetting { system, light, dark, neon }

const _seed = Color(0xFF4F46E5); // Indigo

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
  return _decorate(scheme, const Color(0xFFF6F6FB), IntoniaDecor.light(scheme));
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
  return _decorate(scheme, const Color(0xFF121218), IntoniaDecor.dark(scheme));
}

/// Tema "Neon": navy profondo con accenti ciano/violetto e scenografie.
ThemeData buildNeonTheme() {
  const background = Color(0xFF0B0B1C);
  final base = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
  final scheme = base.copyWith(
    primary: const Color(0xFF8B8CFF),
    onPrimary: const Color(0xFF0D0D1A),
    secondary: const Color(0xFF38BDF8),
    onSecondary: const Color(0xFF0D0D1A),
    tertiary: const Color(0xFFC084FC),
    onTertiary: const Color(0xFF0D0D1A),
    primaryContainer: const Color(0xFF2B2B5E),
    onPrimaryContainer: const Color(0xFFE0E3FF),
    tertiaryContainer: const Color(0xFF321B4F),
    onTertiaryContainer: const Color(0xFFE9D5FF),
    surface: const Color(0xFF15152E),
    onSurface: const Color(0xFFF1F1FF),
    onSurfaceVariant: const Color(0xFFB4B6D9),
    surfaceContainerLow: const Color(0xFF121227),
    surfaceContainerHighest: const Color(0xFF26264D),
    outline: const Color(0xFF6B6D9E),
    outlineVariant: const Color(0xFF2F2F5E),
  );
  return _decorate(scheme, background, const IntoniaDecor.neon());
}

/// Token di design condivisi da tutte le schermate. Il layout è unico: i temi
/// cambiano solo colori e stili. [ambient] attiva le scenografie (fondali,
/// onde, bagliori) che esistono SOLO nel tema Neon.
@immutable
class IntoniaDecor extends ThemeExtension<IntoniaDecor> {
  const IntoniaDecor({
    required this.ambient,
    required this.heroGradient,
    required this.heroBorder,
    required this.onHero,
    required this.featureGradient,
    required this.onFeature,
    required this.featureBorder,
    required this.accents,
    required this.spectrum,
    required this.streak,
    required this.charge,
    required this.success,
    required this.navBackground,
    required this.navIndicator,
    this.glow = Colors.transparent,
  });

  /// Neon: la direzione artistica di riferimento.
  const IntoniaDecor.neon()
      : ambient = true,
        heroGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFC026D3)],
        ),
        heroBorder = const Color(0xFF22D3EE),
        onHero = Colors.white,
        featureGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B2F8F), Color(0xFF4C2A8C), Color(0xFF2A2463)],
        ),
        onFeature = Colors.white,
        featureBorder = const Color(0xFF7C6BFF),
        accents = const [
          Color(0xFF22D3EE),
          Color(0xFF60A5FA),
          Color(0xFFA78BFA),
          Color(0xFFF472B6),
        ],
        spectrum = const LinearGradient(
          colors: [Color(0xFF22D3EE), Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
        ),
        streak = const Color(0xFFFB923C),
        charge = const Color(0xFF22D3EE),
        success = const Color(0xFF34D399),
        navBackground = const Color(0xFF101025),
        navIndicator = const Color(0xFF5B4BDB),
        glow = const Color(0xFF7C5CFA);

  /// Scuro: stessa struttura, superfici semplici, nessun effetto.
  factory IntoniaDecor.dark(ColorScheme scheme) => IntoniaDecor(
        ambient: false,
        heroGradient: _flat(scheme.primary),
        heroBorder: scheme.primary,
        onHero: scheme.onPrimary,
        featureGradient: _flat(scheme.primaryContainer),
        onFeature: scheme.onPrimaryContainer,
        featureBorder: scheme.outlineVariant,
        accents: const [
          Color(0xFF22D3EE),
          Color(0xFF60A5FA),
          Color(0xFFA78BFA),
          Color(0xFFF472B6),
        ],
        spectrum: const LinearGradient(
          colors: [Color(0xFF22D3EE), Color(0xFF6366F1), Color(0xFFA855F7)],
        ),
        streak: const Color(0xFFF97316),
        charge: const Color(0xFF22D3EE),
        success: const Color(0xFF34D399),
        navBackground: scheme.surface,
        navIndicator: scheme.secondaryContainer,
      );

  /// Chiaro: stessa struttura, superfici chiare e contrasti adeguati.
  factory IntoniaDecor.light(ColorScheme scheme) => IntoniaDecor(
        ambient: false,
        heroGradient: _flat(scheme.primary),
        heroBorder: scheme.primary,
        onHero: scheme.onPrimary,
        featureGradient: _flat(scheme.primaryContainer),
        onFeature: scheme.onPrimaryContainer,
        featureBorder: scheme.outlineVariant,
        accents: const [
          Color(0xFF0891B2),
          Color(0xFF2563EB),
          Color(0xFF7C3AED),
          Color(0xFFDB2777),
        ],
        spectrum: const LinearGradient(
          colors: [Color(0xFF0891B2), Color(0xFF4F46E5), Color(0xFF9333EA)],
        ),
        streak: const Color(0xFFEA580C),
        charge: const Color(0xFF0891B2),
        success: const Color(0xFF15803D),
        navBackground: scheme.surface,
        navIndicator: scheme.secondaryContainer,
      );

  static LinearGradient _flat(Color color) => LinearGradient(colors: [color, color]);

  /// Fondali, onde, bagliori e ombre colorate: solo Neon.
  final bool ambient;

  /// Azione principale (microfono, avvio del test).
  final Gradient heroGradient;
  final Color heroBorder;
  final Color onHero;

  /// Card in evidenza ("Crea la tua sequenza", serie).
  final Gradient featureGradient;
  final Color onFeature;
  final Color featureBorder;

  /// Accenti delle categorie e delle statistiche (ciano, blu, viola, magenta).
  final List<Color> accents;

  /// Sfumatura delle barre (estensione, accuratezza).
  final Gradient spectrum;

  final Color streak;
  final Color charge;

  /// Nota intonata, risultati buoni.
  final Color success;

  final Color navBackground;
  final Color navIndicator;

  /// Colore di bagliori e ombre colorate (usato solo con [ambient]).
  final Color glow;

  Color accent(int index) => accents[index % accents.length];

  @override
  IntoniaDecor copyWith({bool? ambient}) => IntoniaDecor(
        ambient: ambient ?? this.ambient,
        heroGradient: heroGradient,
        heroBorder: heroBorder,
        onHero: onHero,
        featureGradient: featureGradient,
        onFeature: onFeature,
        featureBorder: featureBorder,
        accents: accents,
        spectrum: spectrum,
        streak: streak,
        charge: charge,
        success: success,
        navBackground: navBackground,
        navIndicator: navIndicator,
        glow: glow,
      );

  @override
  IntoniaDecor lerp(IntoniaDecor? other, double t) => t < 0.5 || other == null ? this : other;
}

extension IntoniaDecorContext on BuildContext {
  /// Token di design del tema corrente.
  IntoniaDecor get decor =>
      Theme.of(this).extension<IntoniaDecor>() ?? IntoniaDecor.dark(Theme.of(this).colorScheme);
}

ThemeData _decorate(ColorScheme scheme, Color scaffoldBackground, IntoniaDecor decor) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBackground,
    extensions: [decor],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scaffoldBackground,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      // In Neon le card sono leggermente traslucide sul fondale.
      color: decor.ambient ? scheme.surface.withValues(alpha: 0.9) : scheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: decor.navBackground,
      surfaceTintColor: Colors.transparent,
      indicatorColor: decor.navIndicator,
      indicatorShape: const StadiumBorder(),
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? (decor.ambient ? Colors.white : scheme.primary)
              : scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 26,
          color: states.contains(WidgetState.selected)
              ? (decor.ambient ? Colors.white : scheme.onSecondaryContainer)
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
    ),
  );
}
