import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/dynamic_color_service.dart';
import 'state/app_state.dart';
import 'state/theme_state.dart';
import 'state/ui_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PerliteFlowApp());
}

class PerliteFlowApp extends StatefulWidget {
  const PerliteFlowApp({super.key});

  @override
  State<PerliteFlowApp> createState() => _PerliteFlowAppState();
}

class _PerliteFlowAppState extends State<PerliteFlowApp> {
  final AppState app = AppState();
  final ThemeState theme = ThemeState();
  final UiState ui = UiState();

  /// Fetched once from Android 12+ Material You. Null when the device does
  /// not expose a core palette (pre-API 31 or no wallpaper colours set).
  Color? _dynamicSeed;

  @override
  void initState() {
    super.initState();
    theme.load();
    ui.load();
    app.init();
    app.addListener(_onAppChange);
    theme.addListener(_onAppChange);
    ui.addListener(_onAppChange);
    _loadCorePalette();
  }

  Future<void> _loadCorePalette() async {
    final seed = await DynamicColorService.seedFromCorePalette();
    if (!mounted || seed == null) return;
    setState(() {
      _dynamicSeed = seed;
      theme.dynamicColorAvailable = true;
    });
  }

  void _onAppChange() => setState(() {});

  @override
  void dispose() {
    app.removeListener(_onAppChange);
    theme.removeListener(_onAppChange);
    ui.removeListener(_onAppChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = _resolveScheme(Brightness.light);
    final dark = _resolveScheme(Brightness.dark);

    return MaterialApp(
      title: 'Perlite Flow',
      debugShowCheckedModeBanner: false,
      themeMode: theme.mode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: light,
        textTheme: theme.textThemeFor(Brightness.light),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: dark,
        textTheme: theme.textThemeFor(Brightness.dark),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _buildHome(),
    );
  }

  ColorScheme _resolveScheme(Brightness brightness) {
    // Material You wins when both the user opted in and the device has
    // a palette. Otherwise honour the seed preset.
    if (theme.useDynamicColor && _dynamicSeed != null) {
      return ColorScheme.fromSeed(
        seedColor: _dynamicSeed!,
        brightness: brightness,
      );
    }
    return ColorScheme.fromSeed(
      seedColor: theme.seed,
      brightness: brightness,
    );
  }

  Widget _buildHome() {
    switch (app.phase) {
      case AppPhase.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AppPhase.onboarding:
        return LoginPage(app: app);
      case AppPhase.ready:
        return HomePage(app: app, theme: theme, ui: ui);
    }
  }
}
