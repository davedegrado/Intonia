import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_providers.dart';
import 'app_router.dart';
import 'app_theme.dart';

class VocalScaleTrainerApp extends ConsumerWidget {
  const VocalScaleTrainerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(themeSettingProvider);
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
      routerConfig: appRouter,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('it'), Locale('en')],
    );
  }
}
