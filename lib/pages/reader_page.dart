import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:async';

import '../l10n/l10n.dart';
import '../services/perlite_client.dart';
import '../state/app_state.dart';
import '../state/theme_state.dart';
import '../widgets/note_webview.dart';

/// Reader: cache-first, network-refresh-in-background, with reader
/// controls (font scale, open external, scroll-to-top) and a thin
/// scroll progress bar under the app bar.
class ReaderPage extends StatefulWidget {
  final AppState app;
  final String notePath;
  final String? title;

  /// App-wide font choice; pushed through to the WebView so CJK/Latin
  /// glyphs resolve to the same family the chrome uses.
  final ThemeState theme;

  const ReaderPage({
    super.key,
    required this.app,
    required this.notePath,
    required this.theme,
    this.title,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  static const _fontScaleKey = 'reader_font_scale';

  String? _html;
  Object? _error;
  bool _loading = true;
  String _title = '';
  double _fontScale = 1.0;
  InAppWebViewController? _web;
  double _scrollProgress = 0;

  PerliteClient get _client => widget.app.client!;

  @override
  void initState() {
    super.initState();
    _title = widget.title ?? widget.notePath.split('/').last;
    _loadFontScale();
    _load();
  }

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getDouble(_fontScaleKey);
    if (v != null && mounted) setState(() => _fontScale = v);
  }

  Future<void> _setFontScale(double v) async {
    setState(() => _fontScale = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, v);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final server = widget.app.active?.baseUrl ?? '';
    // Show cached content instantly; refresh from network in parallel.
    final cached = await widget.app.cache.read(server, widget.notePath);
    if (cached != null && mounted) {
      setState(() {
        _html = cached;
        _loading = false;
      });
      _extractTitle(cached);
      _refreshInBackground();
      return;
    }

    try {
      final html = await _client.fetchNoteHtml(widget.notePath);
      if (!mounted) return;
      setState(() {
        _html = html;
        _loading = false;
      });
      unawaited(widget.app.cache.write(server, widget.notePath, html));
      _extractTitle(html);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final html = await _client.fetchNoteHtml(widget.notePath);
      if (!mounted) return;
      if (html != _html) {
        setState(() => _html = html);
        _extractTitle(html);
      }
      unawaited(
        widget.app.cache.write(
          widget.app.active?.baseUrl ?? '',
          widget.notePath,
          html,
        ),
      );
    } catch (_) {
      // Keep stale cache silently on refresh failure.
    }
  }

  void _extractTitle(String html) {
    final m = RegExp(r'<div class="mdTitleHide">([^<]*)</div>')
        .firstMatch(html);
    if (m != null && m.group(1)!.isNotEmpty) {
      setState(() => _title = m.group(1)!);
    }
  }

  void _openNote(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReaderPage(app: widget.app, notePath: path, theme: widget.theme),
      ),
    );
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openReaderSettings() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctx.l10n.readerSettings,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Symbols.format_size,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(ctx.l10n.readerFontSize),
                    Expanded(
                      child: Slider(
                        value: _fontScale,
                        min: 0.75,
                        max: 1.5,
                        divisions: 5,
                        label: '${(_fontScale * 100).round()}%',
                        onChanged: _setFontScale,
                      ),
                    ),
                    Text(
                      '${(_fontScale * 100).round()}%',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToTop() {
    _web?.evaluateJavascript(
      source: 'window.scrollTo({top: 0, behavior: "smooth"});',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Symbols.text_fields),
            tooltip: context.l10n.readerSettings,
            onPressed: _openReaderSettings,
          ),
          IconButton(
            icon: const Icon(Symbols.refresh),
            tooltip: context.l10n.readerReload,
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Symbols.open_in_new),
            tooltip: context.l10n.readerOpenExternal,
            onPressed: () {
              final url =
                  '${widget.app.active?.baseUrl ?? ''}/index.php?link=${Uri.encodeComponent(widget.notePath)}';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _scrollProgress > 0
              ? LinearProgressIndicator(
                  value: _scrollProgress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                )
              : const SizedBox(height: 2),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _scrollProgress > 0.1
          ? FloatingActionButton.small(
              heroTag: 'top',
              onPressed: _scrollToTop,
              tooltip: context.l10n.readerBackToTop,
              child: const Icon(Symbols.arrow_upward),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Symbols.error, size: 48),
              const SizedBox(height: 12),
              Text(
                context.l10n.errorMessage(_error!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _load,
                child: Text(context.l10n.actionRetry),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<String?>(
      future: widget.app.activePassword(),
      builder: (context, snap) {
        final pwd = snap.data;
        return NoteWebView(
          html: _html!,
          baseUrl: widget.app.active?.baseUrl ?? '',
          basicAuthUser: widget.app.active?.username,
          basicAuthPassword: pwd,
          fontScale: _fontScale,
          readerFontId: widget.theme.effectiveChoice?.id ?? 'system',
          onOpenNote: _openNote,
          onOpenExternal: _openExternal,
          onControllerReady: (ctrl) {
            _web = ctrl;
            // Wire scroll events through JS -> Flutter so the app bar
            // progress + FAB stay in sync.
            ctrl.addJavaScriptHandler(
              handlerName: 'pfScroll',
              callback: (args) {
                if (args.isEmpty) return;
                final v = args.first;
                if (v is num && mounted) {
                  setState(
                    () => _scrollProgress = v.toDouble().clamp(0.0, 1.0),
                  );
                }
              },
            );
          },
          onLoadStop: (ctrl) {
            // Every reload replaces the document, so reinstall the listener.
            ctrl.evaluateJavascript(
              source: '''
(() => {
  let last = 0;
  window.addEventListener('scroll', () => {
    const max = document.documentElement.scrollHeight - window.innerHeight;
    const p = max > 0 ? (window.scrollY / max) : 0;
    if (Math.abs(p - last) > 0.005) {
      last = p;
      window.flutter_inappwebview.callHandler('pfScroll', p);
    }
  }, { passive: true });
})();
''',
            );
          },
        );
      },
    );
  }
}
