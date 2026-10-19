import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends ChangeNotifier {
  static const _modeKey = 'theme_mode';
  static const _seedKey = 'theme_seed';
  static const _dynKey = 'theme_dynamic';
  static const _fontKey = 'theme_font_family';

  ThemeMode mode = ThemeMode.system;
  Color seed = const Color(0xFF00796B); // teal — calm reading accent
  bool useDynamicColor = true;
  /// Google Fonts family name, or 'system' for the platform default.
  /// Applied via ThemeData.textTheme.apply so it covers every style
  /// without per-widget wiring.
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

  /// Curated font families that pair well with the app. 'system'
  /// is a sentinel meaning "use the platform default" — it is NOT
  /// passed to GoogleFonts.
  static const List<FontChoice> fontChoices = [
    FontChoice(id: 'system', label: '系统默认', family: null),
    FontChoice(id: 'notoSans', label: '思源黑体 Noto Sans SC', family: 'Noto Sans SC'),
    FontChoice(id: 'notoSerif', label: '思源宋体 Noto Serif SC', family: 'Noto Serif SC'),
    // Simplified LXGW WenKai ships over HTTP from the server vault
    // (/Notes/System/fonts/) — the WebView declares it via @font-face and
    // the app UI falls back to system fonts. family name matches the
    // @font-face declared family so the reader applies it natively.
    FontChoice(id: 'lxgw', label: '霞鹜文楷 LXGW WenKai', family: 'LXGW WenKai'),
    FontChoice(id: 'notoSansTC', label: '思源黑体 Noto Sans TC', family: 'Noto Sans TC'),
    FontChoice(id: 'notoSerifTC', label: '思源宋体 Noto Serif TC', family: 'Noto Serif TC'),
    FontChoice(id: 'ibmPlexSans', label: 'IBM Plex Sans', family: 'IBM Plex Sans'),
    FontChoice(id: 'inter', label: 'Inter', family: 'Inter'),
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

  /// Builds the TextTheme for the resolved family. The returned
  /// theme already has the right fontFamily baked in; pass it
  /// into `ThemeData(textTheme: ...)`.
  TextTheme textThemeFor(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme;
    final family = effectiveFontFamily;
    if (family == null) return base;
    // WenKai is fetched by the WebView via @font-face and isn't in the
    // google_fonts map, so asking for a TextTheme would throw — apply it
    // directly. Google Fonts names go through the package to lazy-load.
    if (family == 'LXGW WenKai') {
      return base.apply(fontFamily: family);
    }
    try {
      return GoogleFonts.getTextTheme(family, base);
    } catch (_) {
      return base;
    }
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
  /// Family name — bundled name when `bundled`, otherwise Google Fonts.
  /// Null means "system default".
  final String? family;
  const FontChoice({
    required this.id,
    required this.label,
    required this.family,
  });
}
