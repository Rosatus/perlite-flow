// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Perlite Flow';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navNotes => 'Notes';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionSettings => 'Settings';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionOk => 'OK';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionClear => 'Clear';

  @override
  String get homeEmptyVaultTitle => 'Your vault is empty';

  @override
  String get homeEmptyVaultSubtitle =>
      'Add Markdown notes on the Perlite server, then pull to refresh.';

  @override
  String get homeNoIndexTitle => 'No home note configured';

  @override
  String get homeNoIndexSubtitle =>
      'Choose a note as the index page in your Perlite settings.';

  @override
  String get searchHint => 'Search note content or file names';

  @override
  String get searchIdleTitle => 'Type to start searching';

  @override
  String get searchIdleSubtitle =>
      'Supports #tags, file names, and note content.';

  @override
  String get searchNoResultsTitle => 'No matches found';

  @override
  String get searchNoResultsSubtitle =>
      'Try a shorter keyword or check that the #tag is complete.';

  @override
  String get searchFileNameMatch => 'File name';

  @override
  String get loginSavedServers => 'Saved servers';

  @override
  String get loginNameLabel => 'Name (optional)';

  @override
  String get loginNameHint => 'My notes';

  @override
  String get loginServerLabel => 'Server URL';

  @override
  String get loginServerRequired => 'Enter the server URL';

  @override
  String get loginUsernameLabel => 'Username';

  @override
  String get loginUsernameHelper => 'Leave empty if Basic Auth is not used';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginSavePassword => 'Save password';

  @override
  String get loginSavePasswordSubtitle => 'Stored in Android secure storage';

  @override
  String get loginAutoLogin => 'Sign in automatically';

  @override
  String get loginAutoLoginSubtitle => 'Open the vault directly next time';

  @override
  String get loginConnecting => 'Connecting…';

  @override
  String get loginSaveAndReconnect => 'Save and reconnect';

  @override
  String get loginConnect => 'Connect';

  @override
  String get loginPrivacyNote =>
      'Credentials stay on this device and are never sent to third parties.';

  @override
  String get loginTagline => 'Your Perlite vault, made for Android';

  @override
  String get readerSettings => 'Reading settings';

  @override
  String get readerFontSize => 'Font size';

  @override
  String get readerReload => 'Reload';

  @override
  String get readerOpenExternal => 'Open in browser';

  @override
  String get readerBackToTop => 'Back to top';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsNotConnected => 'Not connected';

  @override
  String get settingsSignOutSubtitle =>
      'Keep server profiles and end this session';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out?';

  @override
  String get settingsSignOutConfirmMessage =>
      'Server profiles stay on this device so you can reconnect quickly.';

  @override
  String get settingsSavedServers => 'Saved servers';

  @override
  String get settingsDeleteServerTitle => 'Delete server?';

  @override
  String settingsDeleteServerMessage(String name) {
    return 'This removes \"$name\" and its saved password.';
  }

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get settingsDynamicColor => 'Material You colors';

  @override
  String get settingsDynamicColorSubtitle =>
      'Match your wallpaper colors (Android 12+)';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsThemeColor => 'Accent color';

  @override
  String get settingsThemeColorOverridden =>
      'Accent color (Material You is active; presets are paused)';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsChooseFont => 'Choose font';

  @override
  String get fontSystem => 'System default';

  @override
  String get fontLxgw => 'LXGW WenKai';

  @override
  String get fontJetBrainsMono => 'JetBrains Mono + LXGW WenKai';

  @override
  String get settingsSectionNavigation => 'Navigation';

  @override
  String get settingsTopTitle => 'Top bar title';

  @override
  String get settingsTitleModeRepo => 'Vault';

  @override
  String get settingsTitleModeCustom => 'Custom';

  @override
  String get settingsTitleFollowRepo => 'Use current vault';

  @override
  String settingsTitleFollowRepoNamed(String name) {
    return 'Use current vault ($name)';
  }

  @override
  String get settingsTitleCustomEmpty => 'Custom text';

  @override
  String settingsTitleCustomValue(String text) {
    return 'Custom: $text';
  }

  @override
  String get settingsCustomTitleHint => 'e.g. My knowledge base';

  @override
  String get settingsNavHelp =>
      'Use the arrows to reorder tabs, the checkboxes to show or hide them, and the star to choose the launch tab.';

  @override
  String get navDefaultBadge => 'Default';

  @override
  String navPosition(int index, int total) {
    return 'Position $index of $total';
  }

  @override
  String get navHidden => 'Hidden';

  @override
  String get navMoveUp => 'Move up';

  @override
  String get navMoveDown => 'Move down';

  @override
  String get navSetDefault => 'Set as launch tab';

  @override
  String get settingsSectionStorage => 'Storage';

  @override
  String get settingsNoteCache => 'Note cache';

  @override
  String settingsCacheUsage(String used, String limit) {
    return '$used used of $limit';
  }

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String get settingsCacheLimit => 'Cache limit';

  @override
  String get settingsCacheLimitDialogTitle => 'Cache limit (MB)';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String settingsAboutSubtitle(String version) {
    return 'Android client for Perlite · $version';
  }

  @override
  String get settingsSourceCode => 'Source code';

  @override
  String get errorUnauthorized => 'Incorrect username or password (401)';

  @override
  String get errorForbidden => 'Access denied (403)';

  @override
  String get errorNotFound => 'The server returned 404. Check the URL.';

  @override
  String get errorDnsFailed =>
      'Could not resolve the host name. Check the URL.';

  @override
  String get errorTlsFailed =>
      'TLS handshake failed. Check the HTTPS certificate.';

  @override
  String get errorConnectionRefused =>
      'Connection refused. The port may be closed or blocked by a firewall.';

  @override
  String get errorNetworkUnreachable =>
      'Network unreachable. Check your network or proxy.';

  @override
  String errorConnectionFailed(String detail) {
    return 'Could not connect to the server: $detail';
  }

  @override
  String errorHttpStatus(String code) {
    return 'The server returned HTTP $code';
  }

  @override
  String errorRequestFailed(String detail) {
    return 'Request failed: $detail';
  }

  @override
  String get errorInvalidUrl => 'Invalid URL';
}
