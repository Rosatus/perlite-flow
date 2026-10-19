import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends ChangeNotifier {
  static const _modeKey = 'theme_mode';
  static const _seedKey = 'theme_seed';
  static const _dynKey = 'theme_dynamic';

  ThemeMode mode = ThemeMode.system;
  Color seed = const Color(0xFF00796B); // teal — calm reading accent
  bool useDynamicColor = true;

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

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mode = ThemeMode.values[prefs.getInt(_modeKey) ?? 0];
    seed = Color(prefs.getInt(_seedKey) ?? seed.toARGB32());
    useDynamicColor = prefs.getBool(_dynKey) ?? true;
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
}
