import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A bottom-nav destination the user can reorder or hide.
///
/// `notes` and `search` and `home` are the three built-in tabs; the
/// settings page exposes reorder/remove affordances backed by this enum.
enum NavTab {
  home(label: '首页', icon: Symbols.home, selectedIcon: Symbols.home),
  search(label: '搜索', icon: Symbols.search, selectedIcon: Symbols.search),
  notes(label: '笔记', icon: Symbols.folder_open, selectedIcon: Symbols.folder_open);

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  static const List<NavTab> defaultOrder = [
    NavTab.home,
    NavTab.search,
    NavTab.notes,
  ];

  static NavTab? tryParse(String s) {
    for (final t in values) {
      if (t.name == s) return t;
    }
    return null;
  }
}
