import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends ChangeNotifier {
  static const _modeKey = 'theme_mode';
  static const _seedKey = 'theme_seed';
  static const _dynKey = 'theme_dynamic';
  static const _fontKey = 'theme_font_family';

  ThemeMode mode = ThemeMode.system;
  Color seed = const Color(0xFF00796B); // teal — calm reading accent
  bool useDynamicColor = true;
  /// Stable font choice id, or 'system' for the platform default.
  /// Every non-system choice is bundled in the APK.
  String fontFamily = 'system';

  /// Set by the app once it knows the device actually exposed a core
  /// palette. Drives the visibility of the dynamic-colour toggle.
  bool dynamicColorAvailable = false;

  static const List<Color> presets = [
    Color(0xFF00796B), // teal
    Color(0xFF5E35B1), // deep purple
    Color(0xFF1565C0), // blue
    Color(0xFF2E7D32), // green
    Color(0xFFEF6C00), // orange
    Color(0xFFAD1457), // pink
    Color(0xFF546E7A), // blue grey
    Color(0xFF8D6E63), // brown
  ];

  /// Bundled font families. Keep this list in sync with pubspec.yaml and
  /// the reader's @font-face declarations; no font is downloaded at runtime.
  static const List<FontChoice> fontChoices = [
    FontChoice(id: 'system', label: '系统默认', family: null),
    FontChoice(
      id: 'lxgw',
      label: '霞鹜文楷 LXGW WenKai',
      family: 'LXGW WenKai',
    ),
    FontChoice(
      id: 'jetbrainsMono',
      label: 'JetBrains Mono + 霞鹜文楷',
      family: 'JetBrains Mono',
      fallback: ['LXGW WenKai'],
    ),
  ];

  /// Resolves the currently selected choice. Null when the user picked
  /// 'system' or when the saved id isn't in `fontChoices`.
  FontChoice? get effectiveChoice {
    for (final c in fontChoices) {
      if (c.id == fontFamily) return c;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mode = ThemeMode.values[prefs.getInt(_modeKey) ?? 0];
    seed = Color(prefs.getInt(_seedKey) ?? seed.toARGB32());
    useDynamicColor = prefs.getBool(_dynKey) ?? true;
    fontFamily = prefs.getString(_fontKey) ?? 'system';
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    mode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, m.index);
  }

  Future<void> setSeed(Color c) async {
    seed = c;
    useDynamicColor = false; // explicit pick wins over Material You
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedKey, c.toARGB32());
    await prefs.setBool(_dynKey, false);
  }

  Future<void> setDynamicColor(bool v) async {
    useDynamicColor = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynKey, v);
  }

  Future<void> setFontFamily(String id) async {
    fontFamily = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, id);
  }

  /// Builds the TextTheme for the resolved bundled family.
  TextTheme textThemeFor(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme;
    final choice = effectiveChoice;
    final family = choice?.family;
    if (family == null) return base;
    return base.apply(
      fontFamily: family,
      fontFamilyFallback: choice!.fallback,
    );
  }

  /// Resolves the family name of the currently selected choice. Null when
  /// 'system' is picked or the saved id isn't in `fontChoices`.
  String? get effectiveFontFamily => effectiveChoice?.family;
}

/// One selectable font option.
class FontChoice {
  /// Stable id stored in SharedPreferences.
  final String id;
  /// Human-readable label shown in the settings list.
  final String label;
  /// Family name declared in pubspec. Null means "system default".
  final String? family;
  /// Bundled families used for glyphs missing from [family].
  final List<String> fallback;
  const FontChoice({
    required this.id,
    required this.label,
    required this.family,
    this.fallback = const [],
  });

  TextStyle get previewStyle =>
      TextStyle(fontFamily: family, fontFamilyFallback: fallback);
}
