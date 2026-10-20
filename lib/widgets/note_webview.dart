import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Renders a Perlite HTML fragment inside a WebView styled like the Perlite
/// web app. Internal links and external links are intercepted and reported
/// through callbacks so the app can navigate natively.
///
/// The generated document is served through [WebViewAssetLoader] on the
/// reserved origin `https://appassets.androidplatform.net`. That keeps
/// `file://` out of the picture — where `localStorage`/`sessionStorage` and
/// CORS are unreliable — and lets `@font-face` pull the bundled TTFs through
/// `AssetsPathHandler` without a network round trip.
class NoteWebView extends StatefulWidget {
  final String html;
  final String baseUrl;
  final String? basicAuthUser;
  final String? basicAuthPassword;

  /// Reader font scale (1.0 = 16px body). Persisted by the caller.
  final double fontScale;

  /// Called with a vault-relative note path (e.g. `/docs/Note`) when the user
  /// taps an `internal-link`.
  final void Function(String notePath)? onOpenNote;

  /// Called with an absolute http(s) URL for external links and attachments.
  final void Function(String url)? onOpenExternal;

  /// Called when the WebView finishes loading. Lets the reader wire up
  /// scroll progress + jump-to-top via the controller.
  final void Function(InAppWebViewController controller)? onControllerReady;

  /// Reader body font — app font choice, applied via @font-face in the
  /// generated HTML when it isn't the system sentinel. Empty = system.
  final String readerFont;

  const NoteWebView({
    super.key,
    required this.html,
    required this.baseUrl,
    this.basicAuthUser,
    this.basicAuthPassword,
    this.fontScale = 1.0,
    this.onOpenNote,
    this.onOpenExternal,
    this.onControllerReady,
    this.readerFont = 'system',
  });

  /// URL the note document is served from. Lives on the asset loader's
  /// default domain so requests are intercepted locally.
  static final WebUri _documentUri = WebUri(
    'https://appassets.androidplatform.net/pf_note/index.html',
  );

  static const _shellTemplate = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<base href="__BASE__/">
<style>
  :root { color-scheme: light dark; }
  html { -webkit-text-size-adjust: 100%; }
  /* Bundled fonts, served locally by WebViewAssetLoader. */
  @font-face {
    font-family: 'JetBrains Mono';
    src: url('/flutter_assets/assets/fonts/JetBrainsMono-Regular.ttf') format('truetype');
    font-weight: 400;    font-display: swap;
    /* Latin + common symbols — JBM is Latin-only here so it never wins CJK. */
    unicode-range:
      U+0000-00FF, U+0100-024F, U+0259,
      U+2000-206F, U+2070-209F, U+20A0-20CF, U+2100-214F,
      U+2190-21FF, U+2200-22FF, U+2300-23FF, U+2500-257F,
      U+2580-259F, U+25A0-25FF, U+2600-26FF, U+2700-27BF,
      U+FF00-FF5E, U+FF61-FF9F, U+FFE0-FFE6;
  }
  @font-face {
    font-family: 'LXGW WenKai';
    src: url('/flutter_assets/assets/fonts/LXGWWenKai-Regular.ttf') format('truetype');
    font-weight: 400;
    font-display: swap;
    /* CJK blocks — WenKai only claims these, leaving Latin to JBM. */
    unicode-range:
      U+3000-303F, U+3040-309F, U+30A0-30FF,
      U+3400-4DBF, U+4E00-9FFF, U+F900-FAFF,
      U+FE30-FE4F, U+FF00-FFEF, U+20000-2A6DF,
      U+2A700-2B73F, U+2B740-2B81F, U+2B820-2CEAF;
  }
  body {
    font-family: __BODY_FONT__, "PingFang SC", "Noto Sans SC", sans-serif;
    line-height: 1.7;
    padding: 16px 20px 48px;
    margin: 0;
    word-wrap: break-word;
    font-size: __FONTSIZE__px;
  }
  img, video, embed { max-width: 100%; height: auto; }
  pre {
    overflow-x: auto;
    padding: 12px;
    border-radius: 8px;
    font-size: 0.86em;
  }
  code { font-family: "JetBrains Mono", "LXGW WenKai", "Consolas", monospace; }
  a { word-break: break-all; }
  blockquote {
    margin: 0.8em 0;
    padding: 0 0 0 1em;
    border-left: 3px solid #8888;
    color: #888;
  }
  table { border-collapse: collapse; display: block; overflow-x: auto; }
  th, td { border: 1px solid #8884; padding: 6px 12px; }
  @media (prefers-color-scheme: dark) {
    body { background: #1a1b1e; color: #dcddde; }
    a { color: #7fbfff; }
    pre { background: #141518; }
    code { color: #e0b6f0; }
  }
  @media (prefers-color-scheme: light) {
    body { background: #fbfbfc; color: #1f2328; }
    a { color: #0066cc; }
    pre { background: #f2f3f5; }
  }
</style>
</head>
<body>
__CONTENT__
<script>
document.addEventListener('click', function(e) {
  var a = e.target.closest('a');
  if (!a) return;
  var href = a.getAttribute('href') || '';
  if (href.startsWith('#')) return; // in-page anchors
  e.preventDefault();
  e.stopPropagation();
  var cls = a.className || '';
  var isInternal = cls.indexOf('internal-link') !== -1;
  window.flutter_inappwebview.callHandler('pfLink', {
    href: href,
    internal: isInternal
  });
}, true);
</script>
</body>
</html>
''';

  String _wrapHtml() {
    final px = (16 * fontScale).clamp(10.0, 28.0).toStringAsFixed(1);
    // Reader defaults to the bundled fonts: JBM for Latin + WenKai for CJK.
    // An explicit non-default font selection slots in ahead of WenKai.
    String bodyFont;
    switch (readerFont) {
      case 'system':
      case 'LXGW WenKai':
        bodyFont = '"JetBrains Mono", "LXGW WenKai"';
        break;
      default:
        bodyFont = '"JetBrains Mono", "$readerFont", "LXGW WenKai"';
    }
    return _shellTemplate
        .replaceFirst('__FONTSIZE__', px)
        .replaceFirst('__BODY_FONT__', bodyFont)
        .replaceFirst('__BASE__', baseUrl)
        .replaceFirst('__CONTENT__', html);
  }

  @override
  State<NoteWebView> createState() => _NoteWebViewState();
}

/// Serves the current note HTML for a fixed path on the asset loader domain.
/// The state keeps [html] up to date so the native request thread always
/// gets the latest document without any cross-thread coordination.
/// Serves bundled Flutter assets (fonts) to the WebView. `AssetsPathHandler`
/// opens files relative to the APK's raw assets dir, but Flutter nests its
/// bundle under `flutter_assets/` — so we load through `rootBundle` which
/// knows the prefix.
class _BundleAssetPathHandler extends CustomPathHandler {
  _BundleAssetPathHandler({required super.path});

  @override
  Future<WebResourceResponse?> handle(String path) async {
    final rel = path.startsWith('/') ? path.substring(1) : path;
    try {
      final data = await rootBundle.load(rel);
      return WebResourceResponse(
        contentType: _mimeFor(rel),
        // ByteData.buffer can be a shared slab with an offset — copy the
        // exact byte range so Chromium doesn't reject malformed font data.
        data: Uint8List.fromList(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)),
      );
    } catch (_) {
      return WebResourceResponse(
        contentType: 'text/plain',
        statusCode: 404,
        reasonPhrase: 'Not Found',
        headers: const {},
      );
    }
  }

  static String _mimeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'ttf' => 'font/ttf',
      'otf' => 'font/otf',
      'woff' => 'font/woff',
      'woff2' => 'font/woff2',
      'html' => 'text/html',
      'css' => 'text/css',
      'js' => 'application/javascript',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'svg' => 'image/svg+xml',
      _ => 'application/octet-stream',
    };
  }
}
class _NoteHtmlPathHandler extends CustomPathHandler {
  _NoteHtmlPathHandler({required super.path});

  String html = '<!DOCTYPE html><html><body></body></html>';

  @override
  Future<WebResourceResponse?> handle(String path) async {
    if (!path.endsWith('index.html')) {
      return WebResourceResponse(
        contentType: 'text/plain',
        statusCode: 404,
        reasonPhrase: 'Not Found',
        headers: const {},
      );
    }
    return WebResourceResponse(
      contentType: 'text/html',
      contentEncoding: 'utf-8',
      data: utf8.encode(html),
    );
  }
}

class _NoteWebViewState extends State<NoteWebView> {
  InAppWebViewController? _controller;
  late final _NoteHtmlPathHandler _htmlHandler;

  @override
  void initState() {
    super.initState();
    _htmlHandler = _NoteHtmlPathHandler(path: '/pf_note/')
      ..html = widget._wrapHtml();
  }

  @override
  void didUpdateWidget(NoteWebView old) {
    super.didUpdateWidget(old);
    if (old.html != widget.html || old.readerFont != widget.readerFont) {
      _htmlHandler.html = widget._wrapHtml();
      _controller?.loadUrl(
        urlRequest: URLRequest(url: NoteWebView._documentUri),
      );
      return;
    }
    // Apply font scale changes without a full reload — cheaper and keeps
    // the scroll position.
    if (old.fontScale != widget.fontScale) {
      final px = (16 * widget.fontScale).clamp(10.0, 28.0).toStringAsFixed(1);
      _controller?.evaluateJavascript(
        source: 'document.body.style.fontSize = "${px}px";',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
        javaScriptEnabled: true,
        supportZoom: true,
        builtInZoomControls: false,
        displayZoomControls: false,
        mediaPlaybackRequiresUserGesture: false,
        transparentBackground: true,
        // Serve the note document + bundled fonts from local handlers on
        // appassets.androidplatform.net — everything stays same-origin.
        webViewAssetLoader: WebViewAssetLoader(
          pathHandlers: [
            _htmlHandler,
            _BundleAssetPathHandler(path: '/flutter_assets/'),
          ],
        ),
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        widget.onControllerReady?.call(controller);
        controller.addJavaScriptHandler(
          handlerName: 'pfLink',
          callback: (args) {
            if (args.isEmpty) return;
            final map = args.first as Map;
            final href = (map['href'] ?? '') as String;
            final internal = map['internal'] == true;
            if (internal) {
              final notePath = _extractNotePath(href, widget.baseUrl);
              if (notePath != null) {
                widget.onOpenNote?.call(notePath);
                return;
              }
            }
            if (href.isNotEmpty) {
              widget.onOpenExternal?.call(_absolutize(href, widget.baseUrl));
            }
          },
        );
        // Kick off the initial document load.
        controller.loadUrl(
          urlRequest: URLRequest(url: NoteWebView._documentUri),
        );
      },
      shouldOverrideUrlLoading: (controller, action) async {
        final url = action.request.url;
        if (url == null) return NavigationActionPolicy.ALLOW;
        // The note document and any same-origin subresources are local.
        if (url.host == 'appassets.androidplatform.net') {
          return NavigationActionPolicy.ALLOW;
        }
        final scheme = url.scheme;
        if (scheme == 'about' || scheme == 'data') {
          return NavigationActionPolicy.ALLOW;
        }
        // All real navigation is handled through the JS bridge; cancel here
        // so the WebView never leaves the note document.
        return NavigationActionPolicy.CANCEL;
      },
      onReceivedHttpAuthRequest: (controller, challenge) async {
        if (widget.basicAuthUser != null &&
            widget.basicAuthUser!.isNotEmpty) {
          return HttpAuthResponse(
            username: widget.basicAuthUser!,
            password: widget.basicAuthPassword ?? '',
            action: HttpAuthResponseAction.PROCEED,
            permanentPersistence: true,
          );
        }
        return HttpAuthResponse(action: HttpAuthResponseAction.CANCEL);
      },
    );
  }

  /// Internal links render as `href="<uriPath>/<note path>"`; strip the
  /// configured base path to recover the `mdfile` argument.
  String? _extractNotePath(String href, String base) {
    var path = href;
    if (path.startsWith(base)) {
      path = path.substring(base.length);
    }
    // Perlite serves markdown without extension in internal links.
    if (path.startsWith('/')) path = path.substring(1);
    if (path.isEmpty) return null;
    // Strip fragment (#heading) — we don't scroll to headings across notes.
    final hashIdx = path.indexOf('#');
    if (hashIdx >= 0) path = path.substring(0, hashIdx);
    if (path.isEmpty) return null;
    // Decode %20 etc; the mdfile param takes a leading `/`.
    return '/${Uri.decodeComponent(path)}';
  }

  String _absolutize(String href, String base) {
    if (href.startsWith('http://') || href.startsWith('https://')) return href;
    if (href.startsWith('/')) return '$base$href';
    return '$base/$href';
  }
}
