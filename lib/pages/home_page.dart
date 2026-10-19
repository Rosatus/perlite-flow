import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/file_node.dart';
import '../models/nav_tab.dart';
import '../models/search_result.dart';
import '../services/perlite_client.dart';
import '../state/app_state.dart';
import '../state/theme_state.dart';
import '../state/ui_state.dart';
import '../widgets/file_tree.dart';
import '../widgets/note_webview.dart';
import '../widgets/search_excerpt_text.dart';
import 'reader_page.dart';
import 'settings_page.dart';

/// Home: bottom-nav shell with three tabs — Vault (file tree),
/// Home (the ``?home`` landing note rendered in a WebView) and
/// Search (IME-aware debounced query). The app bar keeps a single
/// action (settings) so each tab owns its own controls.
class HomePage extends StatefulWidget {
  final AppState app;
  final ThemeState theme;
  final UiState ui;
  const HomePage({
    super.key,
    required this.app,
    required this.theme,
    required this.ui,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  List<FileNode> _tree = [];
  bool _treeLoading = true;
  String? _treeError;

  List<SearchResultGroup> _results = [];
  bool _searching = false;
  String? _searchError;
  Timer? _debounce;
  int _searchSeq = 0;

  String? _homeHtml;
  bool _homeLoading = false;
  String? _homeError;
  bool _homeRequested = false;

  int _tab = 0;

  PerliteClient get _client => widget.app.client!;

  @override
  void initState() {
    super.initState();
    _tab = widget.ui.defaultIndex;
    _loadTree();
    _searchCtrl.addListener(_onQueryChanged);
    // If home is the default landing tab, start fetching it now so it
    // doesn't flash a spinner on first paint.
    if (_currentTab == NavTab.home) {
      _homeRequested = true;
      _loadHome();
    }
  }

  NavTab get _currentTab =>
      widget.ui.tabs.isEmpty
          ? NavTab.home
          : widget.ui.tabs[_tab.clamp(0, widget.ui.tabs.length - 1)];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadTree() async {
    setState(() {
      _treeLoading = true;
      _treeError = null;
    });
    try {
      final tree = await _client.fetchFileTree();
      if (!mounted) return;
      setState(() {
        _tree = tree;
        _treeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _treeError = e.toString();
        _treeLoading = false;
      });
    }
  }

  Future<void> _loadHome() async {
    setState(() {
      _homeLoading = true;
      _homeError = null;
    });
    try {
      final html = await _client.fetchHomeHtml();
      if (!mounted) return;
      setState(() {
        _homeHtml = html;
        _homeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _homeError = e.toString();
        _homeLoading = false;
      });
    }
  }

  void _onTab(int i) {
    setState(() => _tab = i);
    if (_currentTab == NavTab.home && !_homeRequested) {
      _homeRequested = true;
      _loadHome();
    }
    if (_currentTab == NavTab.search) {
      // Focus search field only after the frame so the keyboard does not
      // fight the tab transition.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  void _onQueryChanged() {
    final composing = _searchCtrl.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searchError = null;
        _searching = false;
      });
      return;
    }
    final seq = ++_searchSeq;
    setState(() => _searching = true);
    try {
      final results = await _client.search(q);
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _results = results;
        _searchError = null;
        _searching = false;
      });
    } catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searchError = e.toString();
        _searching = false;
      });
    }
  }

  void _openNote(String notePath, {String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          app: widget.app,
          notePath: notePath,
          title: title,
        ),
      ),
    );
  }

  void _openAttachment(FileNode node) {
    final url = node.downloadUrl;
    if (url == null) return;
    launchUrl(Uri.parse(_client.resolveUrl(url)),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(Symbols.flowsheet, size: 22, color: cs.primary),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _appBarTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Symbols.refresh),
            onPressed: _onRefreshForTab,
          ),
          IconButton(
            tooltip: '设置',
            icon: const Icon(Symbols.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SettingsPage(
                        app: widget.app,
                        theme: widget.theme,
                        ui: widget.ui),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab.clamp(0, widget.ui.tabs.length - 1),
        children: [
          for (final t in widget.ui.tabs)
            switch (t) {
              NavTab.notes => _buildTreeTab(),
              NavTab.home => _buildHomeTab(),
              NavTab.search => _buildSearchTab(),
            },
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.clamp(0, widget.ui.tabs.length - 1),
        onDestinationSelected: _onTab,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: [
          for (final t in widget.ui.tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon, fill: 1),
              label: t.label,
            ),
        ],
      ),
    );
  }

  String get _appBarTitle {
    switch (widget.ui.appBarTitleMode) {
      case AppBarTitleMode.app:
        return 'Perlite Flow';
      case AppBarTitleMode.profile:
        final p = widget.app.active;
        if (p == null) return 'Perlite Flow';
        return p.name.isEmpty ? p.baseUrl : p.name;
      case AppBarTitleMode.custom:
        final t = widget.ui.customTitle.trim();
        return t.isEmpty ? 'Perlite Flow' : t;
    }
  }

  VoidCallback get _onRefreshForTab {
    return switch (_currentTab) {
      NavTab.notes => _loadTree,
      NavTab.home => _loadHome,
      NavTab.search => () {
          _searchCtrl.clear();
          _runSearch();
        },
    };
  }

  // ---------- vault tree tab ----------

  Widget _buildTreeTab() {
    if (_treeLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_treeError != null) {
      return _ErrorPane(message: _treeError!, onRetry: _loadTree);
    }
    if (_tree.isEmpty) {
      return _EmptyPane(
        icon: Symbols.folder_open,
        title: '知识库是空的',
        subtitle: '在 Perlite 服务端放入 Markdown 笔记后下拉刷新',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTree,
      child: FileTreeView(
        nodes: _tree,
        onOpenNote: (n) => _openNote(n.notePath!, title: n.name),
        onOpenAttachment: _openAttachment,
      ),
    );
  }

  // ---------- home note tab ----------

  Widget _buildHomeTab() {
    if (!_homeRequested || _homeLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_homeError != null) {
      return _ErrorPane(message: _homeError!, onRetry: _loadHome);
    }
    final html = _homeHtml;
    if (html == null || html.trim().isEmpty) {
      return _EmptyPane(
        icon: Symbols.home,
        title: '服务端没有配置首页笔记',
        subtitle: '在 Perlite 设置里指定一篇笔记作为 index',
      );
    }
    return FutureBuilder<String?>(
      future: widget.app.activePassword(),
      builder: (context, snap) {
        return NoteWebView(
          html: html,
          baseUrl: widget.app.active?.baseUrl ?? '',
          basicAuthUser: widget.app.active?.username,
          basicAuthPassword: snap.data,
          onOpenNote: _openNote,
          onOpenExternal: _openExternal,
        );
      },
    );
  }

  Future<void> _openExternal(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // ---------- search tab ----------

  Widget _buildSearchTab() {
    final cs = Theme.of(context).colorScheme;
    final inSearch = _searchCtrl.text.isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '搜索笔记内容或文件名',
              prefixIcon: const Icon(Symbols.search),
              suffixIcon: inSearch
                  ? IconButton(
                      icon: const Icon(Symbols.close),
                      onPressed: () {
                        _searchCtrl.clear();
                        _runSearch();
                      },
                    )
                  : null,
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onSubmitted: (_) => _runSearch(),
          ),
        ),
        Expanded(child: _buildSearchResults()),
      ],
    );
  }

  Widget _buildSearchResults() {
    final cs = Theme.of(context).colorScheme;
    if (_searchCtrl.text.isEmpty) {
      return _EmptyPane(
        icon: Symbols.manage_search,
        title: '输入关键词开始搜索',
        subtitle: '支持 #tag、文件名、正文内容',
      );
    }
    if (_searching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError != null) {
      return _ErrorPane(message: _searchError!, onRetry: _runSearch);
    }
    if (_results.isEmpty) {
      return _EmptyPane(
        icon: Symbols.search_off,
        title: '没有找到匹配',
        subtitle: '尝试更短的关键词或检查 #tag 是否完整',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, i) => Divider(
        height: 1,
        indent: 16,
        color: cs.outlineVariant.withValues(alpha: 0.4),
      ),
      itemBuilder: (context, i) {
        final g = _results[i];
        final fileName = g.displayPath.split('/').last;
        final excerpts = g.excerpts.take(2).toList();
        return InkWell(
          onTap: () => _openNote(g.notePath, title: fileName),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      g.isFileNameMatch
                          ? Symbols.draft
                          : Symbols.find_in_page,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (g.isFileNameMatch)
                      _KindChip('文件名', cs),
                  ],
                ),
                if (g.displayPath.contains('/'))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      g.displayPath,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (final ex in excerpts)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SearchExcerptText(
                      ex,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KindChip extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _KindChip(this.text, this.cs);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: cs.onSecondaryContainer),
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _EmptyPane({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorPane({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.cloud_off, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Symbols.refresh, size: 18),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
