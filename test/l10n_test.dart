import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlite_flow/l10n/l10n.dart';
import 'package:perlite_flow/models/nav_tab.dart';
import 'package:perlite_flow/services/perlite_client.dart';
import 'package:perlite_flow/state/theme_state.dart';

void main() {
  test('ships English, Chinese, and Japanese', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(['en', 'zh', 'ja']),
    );
  });

  test('localizes navigation, fonts, and service errors', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final zh = await AppLocalizations.delegate.load(const Locale('zh'));
    final ja = await AppLocalizations.delegate.load(const Locale('ja'));

    expect(NavTab.search.label(en), 'Search');
    expect(NavTab.search.label(zh), '搜索');
    expect(NavTab.search.label(ja), '検索');
    expect(ThemeState.fontChoices[1].label(ja), '霞鶩文楷');

    const error = PerliteException(PerliteErrorKind.httpStatus, '502');
    expect(en.errorMessage(error), 'The server returned HTTP 502');
    expect(zh.errorMessage(error), '服务器返回 HTTP 502');
    expect(ja.errorMessage(error), 'サーバーが HTTP 502 を返しました');
  });
}
