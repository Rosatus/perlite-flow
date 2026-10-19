import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
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
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('缓存已清理')));
  }

  Future<void> _editCacheLimit() async {
    final ctrl = TextEditingController(
      text: (_cacheLimit / (1024 * 1024)).toStringAsFixed(0),
    );
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('缓存上限 (MB)'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'MB'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(ctrl.text.trim())),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (v != null && v > 0) {
      await widget.app.cache.setLimitBytes(v * 1024 * 1024);
      await _loadCacheStats();
    }
  }

  Future<void> _deleteProfile(ServerProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除服务器？'),
        content: Text(
          '将移除 "${p.name.isEmpty ? p.baseUrl : p.name}" 及其保存的密码。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader('账户'),
          ListTile(
            leading: const Icon(Symbols.dns),
            title: Text(active?.name.isNotEmpty == true
                ? active!.name
                : active?.baseUrl ?? '未连接'),
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
            title: const Text('退出登录'),
            subtitle: const Text('保留服务器配置，清除会话'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('退出登录？'),
                  content: const Text('服务器配置保留在设备上，下次可快速重新连接。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('退出'),
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
                  Text('已保存的服务器',
                      style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Symbols.add, size: 18),
                    label: const Text('新增'),
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
                        tooltip: '删除',
                        onPressed: () => _deleteProfile(p),
                      ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        LoginPage(app: widget.app, editing: p),
                  ),
                ),
              ),
          ],
          const Divider(),
          const _SectionHeader('外观'),
          if (widget.theme.dynamicColorAvailable)
            SwitchListTile(
              secondary: const Icon(Symbols.palette),
              title: const Text('Material You 动态取色'),
              subtitle: const Text('跟随系统壁纸主题色（Android 12+）'),
              value: widget.theme.useDynamicColor,
              onChanged: widget.theme.setDynamicColor,
            ),
          ListTile(
            leading: const Icon(Symbols.dark_mode),
            title: const Text('深色模式'),
            trailing: DropdownButton<ThemeMode>(
              value: widget.theme.mode,
              underline: const SizedBox(),
              onChanged: (m) =>
                  m != null ? widget.theme.setMode(m) : null,
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('跟随系统')),
                DropdownMenuItem(
                    value: ThemeMode.light, child: Text('浅色')),
                DropdownMenuItem(
                    value: ThemeMode.dark, child: Text('深色')),
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
                      ? '主题色（已启用动态取色，预选色暂未生效）'
                      : '主题色',
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
                              color: widget.theme.seed.toARGB32() ==
                                      c.toARGB32()
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                            ),
                          ),
                          child: widget.theme.seed.toARGB32() == c.toARGB32()
                              ? const Icon(Symbols.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('导航'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '长按拖动调整顺序；勾选控制显示。打开应用时默认进入所选标签。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          _NavTabEditor(ui: widget.ui),
          const Divider(),
          const _SectionHeader('存储'),
          ListTile(
            leading: const Icon(Symbols.database),
            title: const Text('笔记缓存'),
            subtitle:
                Text('已使用 ${_fmt(_cacheBytes)} / 上限 ${_fmt(_cacheLimit)}'),
          ),
          ListTile(
            leading: const Icon(Symbols.delete),
            title: const Text('清理缓存'),
            onTap: _clearCache,
          ),
          ListTile(
            leading: const Icon(Symbols.tune),
            title: const Text('缓存上限'),
            subtitle: Text(_fmt(_cacheLimit)),
            onTap: _editCacheLimit,
          ),
          const Divider(),
          const _SectionHeader('关于'),
          const ListTile(
            leading: Icon(Symbols.info),
            title: Text('Perlite Flow'),
            subtitle: Text('非官方 Perlite Android 客户端 · v1.0.0'),
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
          Builder(builder: (context) {
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
                  Text(t.label),
                  if (isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '默认',
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
                  ? Text('位置 ${idx + 1} / ${visible.length}',
                      style: const TextStyle(fontSize: 11))
                  : const Text('已隐藏', style: TextStyle(fontSize: 11)),
              trailing: isVisible
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Symbols.arrow_upward, size: 18),
                          tooltip: '上移',
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
                          tooltip: '下移',
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
                          tooltip: '设为默认',
                          onPressed:
                              isDefault ? null : () => ui.setDefault(t),
                        ),
                      ],
                    )
                  : null,
            );
          }),
      ],
    );
  }
}
