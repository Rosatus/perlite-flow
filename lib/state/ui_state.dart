import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/nav_tab.dart';

/// Persisted UI preferences: bottom-nav tab order and which tab the app
/// opens on. Kept separate from `ThemeState` because it changes rarely
/// but is read every frame by `HomePage`.
class UiState extends ChangeNotifier {
  static const _orderKey = 'nav_tab_order';
  static const _defaultKey = 'nav_default_tab';

  /// Visible tabs in display order. Never empty — at minimum the user
  /// keeps one tab so there's something to look at.
  List<NavTab> tabs = List.of(NavTab.defaultOrder);

  /// Tab shown on app start. Falls back to `tabs.first` if it points
  /// at a hidden tab.
  NavTab defaultTab = NavTab.home;

  int get defaultIndex {
    final i = tabs.indexOf(defaultTab);
    return i >= 0 ? i : 0;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_orderKey);
    if (saved != null) {
      final parsed = saved
          .map(NavTab.tryParse)
          .whereType<NavTab>()
          .toList();
      if (parsed.isNotEmpty) {
        tabs = parsed;
      }
    }
    final def = prefs.getString(_defaultKey);
    if (def != null) {
      final t = NavTab.tryParse(def);
      if (t != null && tabs.contains(t)) {
        defaultTab = t;
      }
    }
    notifyListeners();
  }

  Future<void> setOrder(List<NavTab> next) async {
    if (next.isEmpty) return;
    tabs = List.of(next);
    if (!tabs.contains(defaultTab)) {
      defaultTab = tabs.first;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _orderKey, tabs.map((t) => t.name).toList());
    await prefs.setString(_defaultKey, defaultTab.name);
  }

  Future<void> setDefault(NavTab t) async {
    if (!tabs.contains(t)) return;
    defaultTab = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultKey, t.name);
  }

  /// Convenience for settings UI — swaps the tab into or out of the
  /// visible set while preserving order. Hidden tabs are appended to
  /// the end when re-enabled.
  Future<void> setTabVisible(NavTab t, bool visible) async {
    final next = List<NavTab>.of(tabs);
    if (visible && !next.contains(t)) {
      next.add(t);
    } else if (!visible && next.contains(t)) {
      if (next.length == 1) return; // keep at least one
      next.remove(t);
    }
    await setOrder(next);
  }
}
