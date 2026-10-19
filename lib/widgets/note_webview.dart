import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Renders a Perlite HTML fragment inside a WebView styled like the Perlite
/// web app. Internal links and external links are intercepted and reported
/// through callbacks so the app can navigate natively.
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

  static const _shellTemplate = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  :root { color-scheme: light dark; }
  html { -webkit-text-size-adjust: 100%; }
  /* Fonts bundled with the app: latin goes to JBM, CJK falls to WenKai. */
  @font-face {
    font-family: 'JetBrains Mono';
    src: url('https://appassets.androidplatform.net/assets/fonts/JetBrainsMono-Regular.ttf');
    font-weight: 400;
  }
  @font-face {
    font-family: 'LXGW WenKai';
    src: url('https://appassets.androidplatform.net/assets/fonts/LXGWWenKai-Regular.ttf');
    font-weight: 400;
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
    // Only an explicit non-default font selection overrides this stack.
    String bodyFont;
    switch (readerFont) {
      case 'system':
      case 'LXGW WenKai':
        bodyFont = '"JetBrains Mono", "LXGW WenKai"';
        break;
      case 'Noto Serif SC':
      case 'Noto Serif TC':
        bodyFont = '"JetBrains Mono", "$readerFont", "LXGW WenKai"';
        break;
      default:
        bodyFont = '"JetBrains Mono", "$readerFont", "LXGW WenKai"';
    }
    return _shellTemplate
        .replaceFirst('__FONTSIZE__', px)
        .replaceFirst('__BODY_FONT__', bodyFont)
        .replaceFirst('__CONTENT__', html);
  }

  @override
  State<NoteWebView> createState() => _NoteWebViewState();
}

class _NoteWebViewState extends State<NoteWebView> {
  InAppWebViewController? _controller;

  @override
  void didUpdateWidget(NoteWebView old) {
    super.didUpdateWidget(old);
    // Apply font scale changes without a full reload — cheaper and keeps
    // the scroll position.
    if (old.fontScale != widget.fontScale) {
      final px = (16 * widget.fontScale).clamp(10.0, 28.0).toStringAsFixed(1);
      _controller?.evaluateJavascript(
        source:
            'document.body.style.fontSize = "${px}px";',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: widget._wrapHtml(),
        baseUrl: WebUri(widget.baseUrl),
      ),
      initialSettings: InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
        javaScriptEnabled: true,
        supportZoom: true,
        builtInZoomControls: false,
        displayZoomControls: false,
        mediaPlaybackRequiresUserGesture: false,
        transparentBackground: true,
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
      },
      shouldOverrideUrlLoading: (controller, action) async {
        final url = action.request.url;
        if (url == null) return NavigationActionPolicy.ALLOW;
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
