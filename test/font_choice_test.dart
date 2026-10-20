import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlite_flow/state/theme_state.dart';
import 'package:perlite_flow/widgets/note_webview.dart';

void main() {
  test('reader font stack honors the selected bundled font', () {
    expect(NoteWebView.cssFontStack('system'), startsWith('"PingFang SC"'));
    expect(NoteWebView.cssFontStack('lxgw'), startsWith('"LXGW WenKai"'));
    expect(
      NoteWebView.cssFontStack('jetbrainsMono'),
      startsWith('"JetBrains Mono", "LXGW WenKai"'),
    );
  });

  test('font URLs stay local even with a remote base href', () {
    const view = NoteWebView(
      html: '<p>test</p>',
      baseUrl: 'http://10.0.2.2:8080',
    );
    final document = view.buildDocumentForTest();
    expect(document, contains('<base href="http://10.0.2.2:8080/">'));
    expect(
      document,
      contains(
        'https://appassets.androidplatform.net/assets/flutter_assets/assets/fonts/LXGWWenKai-Regular.ttf',
      ),
    );
  });

  test('app theme uses only bundled font families', () {
    final theme = ThemeState()..fontFamily = 'jetbrainsMono';
    final text = theme.textThemeFor(Brightness.light).bodyMedium!;
    expect(text.fontFamily, 'JetBrains Mono');
    expect(text.fontFamilyFallback, ['LXGW WenKai']);
  });
}
