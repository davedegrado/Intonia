import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home_widget/application/home_widget_sync.dart';
import '../features/settings/application/settings_providers.dart';
import 'app_router.dart';
import 'app_theme.dart';
import 'splash_overlay.dart';

class VocalScaleTrainerApp extends ConsumerWidget {
  const VocalScaleTrainerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(themeSettingProvider);
    // Mantiene aggiornato il widget della schermata Home del telefono.
    ref.watch(homeWidgetSyncProvider);
    final neon = setting == AppThemeSetting.neon;

    return MaterialApp.router(
      title: 'Intonia',
      debugShowCheckedModeBanner: false,
      theme: neon ? buildNeonTheme() : buildLightTheme(),
      darkTheme: neon ? buildNeonTheme() : buildDarkTheme(),
      themeMode: switch (setting) {
        AppThemeSetting.light => ThemeMode.light,
        AppThemeSetting.dark || AppThemeSetting.neon => ThemeMode.dark,
        AppThemeSetting.system => ThemeMode.system,
      },
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => SplashOverlay(child: child ?? const SizedBox.shrink()),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('it'), Locale('en')],
    );
  }
}
