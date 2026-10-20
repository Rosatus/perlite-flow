import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../l10n/l10n.dart';

/// A bottom-nav destination the user can reorder or hide.
///
/// `notes` and `search` and `home` are the three built-in tabs; the
/// settings page exposes reorder/remove affordances backed by this enum.
enum NavTab {
  home(icon: Symbols.home, selectedIcon: Symbols.home),
  search(icon: Symbols.search, selectedIcon: Symbols.search),
  notes(icon: Symbols.folder_open, selectedIcon: Symbols.folder_open);

  final IconData icon;
  final IconData selectedIcon;

  const NavTab({required this.icon, required this.selectedIcon});

  String label(AppLocalizations l10n) => switch (this) {
    NavTab.home => l10n.navHome,
    NavTab.search => l10n.navSearch,
    NavTab.notes => l10n.navNotes,
  };

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
