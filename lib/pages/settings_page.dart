import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../models/server_profile.dart';
import '../models/nav_tab.dart';
import '../services/note_cache.dart';
import '../state/app_state.dart';
import '../state/theme_state.dart';
import '../state/ui_state.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  final AppState app;
  final ThemeState theme;
  final UiState ui;

  const SettingsPage({
    super.key,
    required this.app,
    required this.theme,
    required this.ui,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _cacheBytes = 0;
  int _cacheLimit = NoteCache.defaultLimitBytes;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = 'v${info.version} (${info.buildNumber})');
  }

  Future<void> _loadCacheStats() async {
    final size = await widget.app.cache.totalBytes();
    final limit = await widget.app.cache.limitBytes;
    if (!mounted) return;
    setState(() {
      _cacheBytes = size;
      _cacheLimit = limit;
    });
  }

  String _fmt(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _clearCache() async {
    await widget.app.cache.clear();
    await _loadCacheStats();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.settingsCacheCleared)));
  }

  Future<void> _editCacheLimit() async {
    final ctrl = TextEditingController(
      text: (_cacheLimit / (1024 * 1024)).toStringAsFixed(0),
    );
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.settingsCacheLimitDialogTitle),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'MB'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim())),
            child: Text(ctx.l10n.actionOk),
          ),
        ],
      ),
    );
    if (v != null && v > 0) {
      await widget.app.cache.setLimitBytes(v * 1024 * 1024);
      await _loadCacheStats();
    }
  }

  String get _appBarSubtitle {
    switch (widget.ui.appBarTitleMode) {
      case AppBarTitleMode.app:
        return context.l10n.appTitle;
      case AppBarTitleMode.profile:
        final p = widget.app.active;
        return p == null
            ? context.l10n.settingsTitleFollowRepo
            : context.l10n.settingsTitleFollowRepoNamed(
                p.name.isEmpty ? p.baseUrl : p.name,
              );
      case AppBarTitleMode.custom:
        final t = widget.ui.customTitle.trim();
        return t.isEmpty
            ? context.l10n.settingsTitleCustomEmpty
            : context.l10n.settingsTitleCustomValue(t);
    }
  }

  String get _fontLabel {
    final id = widget.theme.fontFamily;
    for (final c in ThemeState.fontChoices) {
      if (c.id == id) return c.label(context.l10n);
    }
    return context.l10n.fontSystem;
  }

  Future<void> _editFont() async {
    final current = widget.theme.fontFamily;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l10n.settingsChooseFont),
        children: [
          for (final c in ThemeState.fontChoices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, c.id),
              child: Row(
                children: [
                  Icon(
                    c.id == current
                        ? Symbols.radio_button_checked
                        : Symbols.radio_button_unchecked,
                    size: 20,
                    color: c.id == current
                        ? Theme.of(ctx).colorScheme.primary
                        : Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.label(ctx.l10n),
                      style: c.family != null ? c.previewStyle : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (choice == null) return;
    await widget.theme.setFontFamily(choice);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _editAppBarTitle() async {
    final ui = widget.ui;
    var mode = ui.appBarTitleMode;
    final ctrl = TextEditingController(text: ui.customTitle);
    final choice = await showDialog<AppBarTitleMode>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ctx.l10n.settingsTopTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<AppBarTitleMode>(
                segments: [
                  ButtonSegment(
                    value: AppBarTitleMode.app,
                    label: Text(ctx.l10n.appTitle),
                  ),
                  ButtonSegment(
                    value: AppBarTitleMode.profile,
                    label: Text(ctx.l10n.settingsTitleModeRepo),
                  ),
                  ButtonSegment(
                    value: AppBarTitleMode.custom,
                    label: Text(ctx.l10n.settingsTitleModeCustom),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) => setLocal(() => mode = s.first),
              ),
              if (mode == AppBarTitleMode.custom)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: ctx.l10n.settingsCustomTitleHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, mode),
              child: Text(ctx.l10n.actionOk),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    await ui.setAppBarTitle(choice, text: ctrl.text.trim());
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteProfile(ServerProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.settingsDeleteServerTitle),
        content: Text(
          ctx.l10n.settingsDeleteServerMessage(
            p.name.isEmpty ? p.baseUrl : p.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.app.deleteProfile(p.id);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.app.active;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(l10n.settingsSectionAccount),
          ListTile(
            leading: const Icon(Symbols.dns),
            title: Text(
              active?.name.isNotEmpty == true
                  ? active!.name
                  : active?.baseUrl ?? l10n.settingsNotConnected,
            ),
            subtitle: Text(active?.baseUrl ?? ''),
            trailing: const Icon(Symbols.edit),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LoginPage(app: widget.app, editing: active),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.logout),
            title: Text(l10n.actionSignOut),
            subtitle: Text(l10n.settingsSignOutSubtitle),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(ctx.l10n.settingsSignOutConfirmTitle),
                  content: Text(ctx.l10n.settingsSignOutConfirmMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(ctx.l10n.actionCancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(ctx.l10n.actionSignOut),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              if (!context.mounted) return;
              await widget.app.logout();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          if (widget.app.profiles.isNotEmpty) ...[
            const Divider(indent: 16, endIndent: 16, height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Text(
                    l10n.settingsSavedServers,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Symbols.add, size: 18),
                    label: Text(l10n.actionAdd),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoginPage(app: widget.app),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final p in widget.app.profiles)
              ListTile(
                dense: true,
                leading: const Icon(Symbols.dns, size: 20),
                title: Text(p.name.isEmpty ? p.baseUrl : p.name),
                subtitle: p.name.isNotEmpty
                    ? Text(p.baseUrl, style: const TextStyle(fontSize: 11))
                    : null,
                trailing: p.id == active?.id
                    ? const Icon(Symbols.check_circle, size: 18)
                    : IconButton(
                        icon: const Icon(Symbols.delete, size: 18),
                        tooltip: l10n.actionDelete,
                        onPressed: () => _deleteProfile(p),
                      ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(app: widget.app, editing: p),
                  ),
                ),
              ),
          ],
          const Divider(),
          _SectionHeader(l10n.settingsSectionAppearance),
          ListTile(
            leading: const Icon(Symbols.language),
            title: Text(l10n.settingsLanguage),
            trailing: DropdownButton<String>(
              value: widget.ui.locale?.languageCode ?? '',
              underline: const SizedBox(),
              onChanged: (code) => widget.ui.setLocale(
                code == null || code.isEmpty ? null : Locale(code),
              ),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.languageSystem)),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'zh', child: Text('简体中文')),
                const DropdownMenuItem(value: 'ja', child: Text('日本語')),
              ],
            ),
          ),
          if (widget.theme.dynamicColorAvailable)
            SwitchListTile(
              secondary: const Icon(Symbols.palette),
              title: Text(l10n.settingsDynamicColor),
              subtitle: Text(l10n.settingsDynamicColorSubtitle),
              value: widget.theme.useDynamicColor,
              onChanged: widget.theme.setDynamicColor,
            ),
          ListTile(
            leading: const Icon(Symbols.dark_mode),
            title: Text(l10n.settingsDarkMode),
            trailing: DropdownButton<ThemeMode>(
              value: widget.theme.mode,
              underline: const SizedBox(),
              onChanged: (m) => m != null ? widget.theme.setMode(m) : null,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.themeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.themeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.themeDark),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.theme.useDynamicColor &&
                          widget.theme.dynamicColorAvailable
                      ? l10n.settingsThemeColorOverridden
                      : l10n.settingsThemeColor,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in ThemeState.presets)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => widget.theme.setSeed(c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 3,
                              color:
                                  widget.theme.seed.toARGB32() == c.toARGB32()
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                            ),
                          ),
                          child: widget.theme.seed.toARGB32() == c.toARGB32()
                              ? const Icon(
                                  Symbols.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.font_download),
            title: Text(l10n.settingsFont),
            subtitle: Text(_fontLabel),
            onTap: _editFont,
          ),
          const Divider(),
          _SectionHeader(l10n.settingsSectionNavigation),
          ListTile(
            leading: const Icon(Symbols.title),
            title: Text(l10n.settingsTopTitle),
            subtitle: Text(_appBarSubtitle),
            trailing: const Icon(Symbols.edit),
            onTap: _editAppBarTitle,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              l10n.settingsNavHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _NavTabEditor(ui: widget.ui),
          const Divider(),
          _SectionHeader(l10n.settingsSectionStorage),
          ListTile(
            leading: const Icon(Symbols.database),
            title: Text(l10n.settingsNoteCache),
            subtitle: Text(
              l10n.settingsCacheUsage(_fmt(_cacheBytes), _fmt(_cacheLimit)),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.delete),
            title: Text(l10n.settingsClearCache),
            onTap: _clearCache,
          ),
          ListTile(
            leading: const Icon(Symbols.tune),
            title: Text(l10n.settingsCacheLimit),
            subtitle: Text(_fmt(_cacheLimit)),
            onTap: _editCacheLimit,
          ),
          const Divider(),
          _SectionHeader(l10n.settingsSectionAbout),
          ListTile(
            leading: const Icon(Symbols.info),
            title: Text(l10n.appTitle),
            subtitle: Text(l10n.settingsAboutSubtitle(_version)),
          ),
          ListTile(
            leading: const Icon(Symbols.code),
            title: Text(l10n.settingsSourceCode),
            subtitle: const Text('github.com/Rosatus/perlite-flow'),
            trailing: const Icon(Symbols.open_in_new),
            onTap: () => launchUrl(
              Uri.parse('https://github.com/Rosatus/perlite-flow'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Reorderable tab list — users pick which tabs show up in the bottom
/// nav, drag to reorder, and pick the launch tab.
class _NavTabEditor extends StatelessWidget {
  final UiState ui;
  const _NavTabEditor({required this.ui});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // All three tabs, in the user's chosen order, then any hidden ones
    // appended so the toggle remains reachable.
    final visible = ui.tabs;
    final hidden = NavTab.values.where((t) => !visible.contains(t)).toList();
    final all = [...visible, ...hidden];
    return Column(
      children: [
        for (final t in all)
          Builder(
            builder: (context) {
              final isVisible = visible.contains(t);
              final isDefault = ui.defaultTab == t;
              final idx = isVisible ? visible.indexOf(t) : -1;
              return ListTile(
                dense: true,
                leading: Checkbox(
                  value: isVisible,
                  onChanged: all.length - hidden.length > 1 || !isVisible
                      ? (v) => ui.setTabVisible(t, v ?? false)
                      : null,
                ),
                title: Row(
                  children: [
                    Icon(t.icon, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(t.label(context.l10n)),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.l10n.navDefaultBadge,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: isVisible
                    ? Text(
                        context.l10n.navPosition(idx + 1, visible.length),
                        style: const TextStyle(fontSize: 11),
                      )
                    : Text(
                        context.l10n.navHidden,
                        style: const TextStyle(fontSize: 11),
                      ),
                trailing: isVisible
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Symbols.arrow_upward, size: 18),
                            tooltip: context.l10n.navMoveUp,
                            onPressed: idx > 0
                                ? () {
                                    final next = List<NavTab>.of(visible);
                                    next.removeAt(idx);
                                    next.insert(idx - 1, t);
                                    ui.setOrder(next);
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Symbols.arrow_downward, size: 18),
                            tooltip: context.l10n.navMoveDown,
                            onPressed: idx < visible.length - 1
                                ? () {
                                    final next = List<NavTab>.of(visible);
                                    next.removeAt(idx);
                                    next.insert(idx + 1, t);
                                    ui.setOrder(next);
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: Icon(
                              isDefault ? Symbols.star : Symbols.star,
                              size: 18,
                              fill: isDefault ? 1 : 0,
                              color: isDefault ? cs.primary : null,
                            ),
                            tooltip: context.l10n.navSetDefault,
                            onPressed: isDefault
                                ? null
                                : () => ui.setDefault(t),
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),
      ],
    );
  }
}
