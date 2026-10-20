// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Perlite Flow';

  @override
  String get navHome => 'ホーム';

  @override
  String get navSearch => '検索';

  @override
  String get navNotes => 'ノート';

  @override
  String get actionRefresh => '更新';

  @override
  String get actionSettings => '設定';

  @override
  String get actionRetry => '再試行';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionOk => 'OK';

  @override
  String get actionDelete => '削除';

  @override
  String get actionAdd => '追加';

  @override
  String get actionSignOut => 'ログアウト';

  @override
  String get actionClear => 'クリア';

  @override
  String get homeEmptyVaultTitle => 'Vault は空です';

  @override
  String get homeEmptyVaultSubtitle =>
      'Perlite サーバーに Markdown ノートを追加してから、引っ張って更新してください。';

  @override
  String get homeNoIndexTitle => 'ホームノートが設定されていません';

  @override
  String get homeNoIndexSubtitle => 'Perlite の設定でインデックスにするノートを指定してください。';

  @override
  String get searchHint => 'ノートの本文やファイル名を検索';

  @override
  String get searchIdleTitle => 'キーワードを入力して検索';

  @override
  String get searchIdleSubtitle => '#タグ、ファイル名、本文に対応しています。';

  @override
  String get searchNoResultsTitle => '一致する結果はありません';

  @override
  String get searchNoResultsSubtitle => '短いキーワードを試すか、#タグが完全か確認してください。';

  @override
  String get searchFileNameMatch => 'ファイル名';

  @override
  String get loginSavedServers => '保存済みサーバー';

  @override
  String get loginNameLabel => '名前（任意）';

  @override
  String get loginNameHint => 'マイノート';

  @override
  String get loginServerLabel => 'サーバー URL';

  @override
  String get loginServerRequired => 'サーバー URL を入力してください';

  @override
  String get loginUsernameLabel => 'ユーザー名';

  @override
  String get loginUsernameHelper => 'Basic 認証を使わない場合は空欄';

  @override
  String get loginPasswordLabel => 'パスワード';

  @override
  String get loginShowPassword => 'パスワードを表示';

  @override
  String get loginHidePassword => 'パスワードを隠す';

  @override
  String get loginSavePassword => 'パスワードを保存';

  @override
  String get loginSavePasswordSubtitle => 'Android のセキュアストレージに保存します';

  @override
  String get loginAutoLogin => '自動ログイン';

  @override
  String get loginAutoLoginSubtitle => '次回起動時に Vault を直接開きます';

  @override
  String get loginConnecting => '接続中…';

  @override
  String get loginSaveAndReconnect => '保存して再接続';

  @override
  String get loginConnect => '接続';

  @override
  String get loginPrivacyNote => '認証情報はこの端末にのみ保存され、第三者に送信されることはありません。';

  @override
  String get loginTagline => 'Android のための Perlite Vault クライアント';

  @override
  String get readerSettings => '表示設定';

  @override
  String get readerFontSize => '文字サイズ';

  @override
  String get readerReload => '再読み込み';

  @override
  String get readerOpenExternal => 'ブラウザで開く';

  @override
  String get readerBackToTop => 'トップへ戻る';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionAccount => 'アカウント';

  @override
  String get settingsNotConnected => '未接続';

  @override
  String get settingsSignOutSubtitle => 'サーバー設定を残してセッションを終了します';

  @override
  String get settingsSignOutConfirmTitle => 'ログアウトしますか？';

  @override
  String get settingsSignOutConfirmMessage => 'サーバー設定は端末に残るため、すぐに再接続できます。';

  @override
  String get settingsSavedServers => '保存済みサーバー';

  @override
  String get settingsDeleteServerTitle => 'サーバーを削除しますか？';

  @override
  String settingsDeleteServerMessage(String name) {
    return '「$name」と保存済みのパスワードを削除します。';
  }

  @override
  String get settingsSectionAppearance => '外観';

  @override
  String get settingsLanguage => '言語';

  @override
  String get languageSystem => 'システムに従う';

  @override
  String get settingsDynamicColor => 'Material You カラー';

  @override
  String get settingsDynamicColorSubtitle => '壁紙の色に合わせます（Android 12+）';

  @override
  String get settingsDarkMode => 'ダークモード';

  @override
  String get themeSystem => 'システムに従う';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get settingsThemeColor => 'アクセントカラー';

  @override
  String get settingsThemeColorOverridden =>
      'アクセントカラー（Material You が有効なためプリセットは無効です）';

  @override
  String get settingsFont => 'フォント';

  @override
  String get settingsChooseFont => 'フォントを選択';

  @override
  String get fontSystem => 'システムデフォルト';

  @override
  String get fontLxgw => '霞鶩文楷';

  @override
  String get fontJetBrainsMono => 'JetBrains Mono + 霞鶩文楷';

  @override
  String get settingsSectionNavigation => 'ナビゲーション';

  @override
  String get settingsTopTitle => '上部バーのタイトル';

  @override
  String get settingsTitleModeRepo => 'Vault';

  @override
  String get settingsTitleModeCustom => 'カスタム';

  @override
  String get settingsTitleFollowRepo => '現在の Vault 名を使用';

  @override
  String settingsTitleFollowRepoNamed(String name) {
    return '現在の Vault 名を使用（$name）';
  }

  @override
  String get settingsTitleCustomEmpty => 'カスタムテキスト';

  @override
  String settingsTitleCustomValue(String text) {
    return 'カスタム：$text';
  }

  @override
  String get settingsCustomTitleHint => '例：マイナレッジベース';

  @override
  String get settingsNavHelp => '矢印で並べ替え、チェックで表示を切り替え、星で起動時のタブを選びます。';

  @override
  String get navDefaultBadge => 'デフォルト';

  @override
  String navPosition(int index, int total) {
    return '$total 件中 $index 番目';
  }

  @override
  String get navHidden => '非表示';

  @override
  String get navMoveUp => '上へ移動';

  @override
  String get navMoveDown => '下へ移動';

  @override
  String get navSetDefault => '起動時のタブに設定';

  @override
  String get settingsSectionStorage => 'ストレージ';

  @override
  String get settingsNoteCache => 'ノートキャッシュ';

  @override
  String settingsCacheUsage(String used, String limit) {
    return '$used / 上限 $limit';
  }

  @override
  String get settingsClearCache => 'キャッシュを削除';

  @override
  String get settingsCacheCleared => 'キャッシュを削除しました';

  @override
  String get settingsCacheLimit => 'キャッシュ上限';

  @override
  String get settingsCacheLimitDialogTitle => 'キャッシュ上限（MB）';

  @override
  String get settingsSectionAbout => 'このアプリについて';

  @override
  String settingsAboutSubtitle(String version) {
    return 'Perlite の Android クライアント · $version';
  }

  @override
  String get settingsSourceCode => 'ソースコード';

  @override
  String get errorUnauthorized => 'ユーザー名またはパスワードが正しくありません（401）';

  @override
  String get errorForbidden => 'アクセスが拒否されました（403）';

  @override
  String get errorNotFound => 'サーバーが 404 を返しました。URL を確認してください。';

  @override
  String get errorDnsFailed => 'ホスト名を解決できません。URL を確認してください。';

  @override
  String get errorTlsFailed => 'TLS ハンドシェイクに失敗しました。HTTPS 証明書を確認してください。';

  @override
  String get errorConnectionRefused =>
      '接続が拒否されました。ポートが閉じているか、ファイアウォールでブロックされています。';

  @override
  String get errorNetworkUnreachable =>
      'ネットワークに到達できません。ネットワークまたはプロキシを確認してください。';

  @override
  String errorConnectionFailed(String detail) {
    return 'サーバーに接続できません：$detail';
  }

  @override
  String errorHttpStatus(String code) {
    return 'サーバーが HTTP $code を返しました';
  }

  @override
  String errorRequestFailed(String detail) {
    return 'リクエストに失敗しました：$detail';
  }

  @override
  String get errorInvalidUrl => 'URL の形式が正しくありません';
}
