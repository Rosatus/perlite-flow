import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Perlite Flow'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get actionSettings;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @homeEmptyVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your vault is empty'**
  String get homeEmptyVaultTitle;

  /// No description provided for @homeEmptyVaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add Markdown notes on the Perlite server, then pull to refresh.'**
  String get homeEmptyVaultSubtitle;

  /// No description provided for @homeNoIndexTitle.
  ///
  /// In en, this message translates to:
  /// **'No home note configured'**
  String get homeNoIndexTitle;

  /// No description provided for @homeNoIndexSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a note as the index page in your Perlite settings.'**
  String get homeNoIndexSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search note content or file names'**
  String get searchHint;

  /// No description provided for @searchIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Type to start searching'**
  String get searchIdleTitle;

  /// No description provided for @searchIdleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Supports #tags, file names, and note content.'**
  String get searchIdleSubtitle;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter keyword or check that the #tag is complete.'**
  String get searchNoResultsSubtitle;

  /// No description provided for @searchFileNameMatch.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get searchFileNameMatch;

  /// No description provided for @loginSavedServers.
  ///
  /// In en, this message translates to:
  /// **'Saved servers'**
  String get loginSavedServers;

  /// No description provided for @loginNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get loginNameLabel;

  /// No description provided for @loginNameHint.
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get loginNameHint;

  /// No description provided for @loginServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get loginServerLabel;

  /// No description provided for @loginServerRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the server URL'**
  String get loginServerRequired;

  /// No description provided for @loginUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsernameLabel;

  /// No description provided for @loginUsernameHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if Basic Auth is not used'**
  String get loginUsernameHelper;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePassword;

  /// No description provided for @loginSavePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get loginSavePassword;

  /// No description provided for @loginSavePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stored in Android secure storage'**
  String get loginSavePasswordSubtitle;

  /// No description provided for @loginAutoLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in automatically'**
  String get loginAutoLogin;

  /// No description provided for @loginAutoLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the vault directly next time'**
  String get loginAutoLoginSubtitle;

  /// No description provided for @loginConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get loginConnecting;

  /// No description provided for @loginSaveAndReconnect.
  ///
  /// In en, this message translates to:
  /// **'Save and reconnect'**
  String get loginSaveAndReconnect;

  /// No description provided for @loginConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get loginConnect;

  /// No description provided for @loginPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Credentials stay on this device and are never sent to third parties.'**
  String get loginPrivacyNote;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Perlite vault, made for Android'**
  String get loginTagline;

  /// No description provided for @readerSettings.
  ///
  /// In en, this message translates to:
  /// **'Reading settings'**
  String get readerSettings;

  /// No description provided for @readerFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get readerFontSize;

  /// No description provided for @readerReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get readerReload;

  /// No description provided for @readerOpenExternal.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get readerOpenExternal;

  /// No description provided for @readerBackToTop.
  ///
  /// In en, this message translates to:
  /// **'Back to top'**
  String get readerBackToTop;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsNotConnected;

  /// No description provided for @settingsSignOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep server profiles and end this session'**
  String get settingsSignOutSubtitle;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Server profiles stay on this device so you can reconnect quickly.'**
  String get settingsSignOutConfirmMessage;

  /// No description provided for @settingsSavedServers.
  ///
  /// In en, this message translates to:
  /// **'Saved servers'**
  String get settingsSavedServers;

  /// No description provided for @settingsDeleteServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete server?'**
  String get settingsDeleteServerTitle;

  /// No description provided for @settingsDeleteServerMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes \"{name}\" and its saved password.'**
  String settingsDeleteServerMessage(String name);

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @settingsDynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Material You colors'**
  String get settingsDynamicColor;

  /// No description provided for @settingsDynamicColorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match your wallpaper colors (Android 12+)'**
  String get settingsDynamicColorSubtitle;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsThemeColor;

  /// No description provided for @settingsThemeColorOverridden.
  ///
  /// In en, this message translates to:
  /// **'Accent color (Material You is active; presets are paused)'**
  String get settingsThemeColorOverridden;

  /// No description provided for @settingsFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settingsFont;

  /// No description provided for @settingsChooseFont.
  ///
  /// In en, this message translates to:
  /// **'Choose font'**
  String get settingsChooseFont;

  /// No description provided for @fontSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get fontSystem;

  /// No description provided for @fontLxgw.
  ///
  /// In en, this message translates to:
  /// **'LXGW WenKai'**
  String get fontLxgw;

  /// No description provided for @fontJetBrainsMono.
  ///
  /// In en, this message translates to:
  /// **'JetBrains Mono + LXGW WenKai'**
  String get fontJetBrainsMono;

  /// No description provided for @settingsSectionNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get settingsSectionNavigation;

  /// No description provided for @settingsTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Top bar title'**
  String get settingsTopTitle;

  /// No description provided for @settingsTitleModeRepo.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get settingsTitleModeRepo;

  /// No description provided for @settingsTitleModeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settingsTitleModeCustom;

  /// No description provided for @settingsTitleFollowRepo.
  ///
  /// In en, this message translates to:
  /// **'Use current vault'**
  String get settingsTitleFollowRepo;

  /// No description provided for @settingsTitleFollowRepoNamed.
  ///
  /// In en, this message translates to:
  /// **'Use current vault ({name})'**
  String settingsTitleFollowRepoNamed(String name);

  /// No description provided for @settingsTitleCustomEmpty.
  ///
  /// In en, this message translates to:
  /// **'Custom text'**
  String get settingsTitleCustomEmpty;

  /// No description provided for @settingsTitleCustomValue.
  ///
  /// In en, this message translates to:
  /// **'Custom: {text}'**
  String settingsTitleCustomValue(String text);

  /// No description provided for @settingsCustomTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My knowledge base'**
  String get settingsCustomTitleHint;

  /// No description provided for @settingsNavHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the arrows to reorder tabs, the checkboxes to show or hide them, and the star to choose the launch tab.'**
  String get settingsNavHelp;

  /// No description provided for @navDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get navDefaultBadge;

  /// No description provided for @navPosition.
  ///
  /// In en, this message translates to:
  /// **'Position {index} of {total}'**
  String navPosition(int index, int total);

  /// No description provided for @navHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get navHidden;

  /// No description provided for @navMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get navMoveUp;

  /// No description provided for @navMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get navMoveDown;

  /// No description provided for @navSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as launch tab'**
  String get navSetDefault;

  /// No description provided for @settingsSectionStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsSectionStorage;

  /// No description provided for @settingsNoteCache.
  ///
  /// In en, this message translates to:
  /// **'Note cache'**
  String get settingsNoteCache;

  /// No description provided for @settingsCacheUsage.
  ///
  /// In en, this message translates to:
  /// **'{used} used of {limit}'**
  String settingsCacheUsage(String used, String limit);

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsCacheCleared;

  /// No description provided for @settingsCacheLimit.
  ///
  /// In en, this message translates to:
  /// **'Cache limit'**
  String get settingsCacheLimit;

  /// No description provided for @settingsCacheLimitDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cache limit (MB)'**
  String get settingsCacheLimitDialogTitle;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Android client for Perlite · {version}'**
  String settingsAboutSubtitle(String version);

  /// No description provided for @settingsSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get settingsSourceCode;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Incorrect username or password (401)'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access denied (403)'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The server returned 404. Check the URL.'**
  String get errorNotFound;

  /// No description provided for @errorDnsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve the host name. Check the URL.'**
  String get errorDnsFailed;

  /// No description provided for @errorTlsFailed.
  ///
  /// In en, this message translates to:
  /// **'TLS handshake failed. Check the HTTPS certificate.'**
  String get errorTlsFailed;

  /// No description provided for @errorConnectionRefused.
  ///
  /// In en, this message translates to:
  /// **'Connection refused. The port may be closed or blocked by a firewall.'**
  String get errorConnectionRefused;

  /// No description provided for @errorNetworkUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Network unreachable. Check your network or proxy.'**
  String get errorNetworkUnreachable;

  /// No description provided for @errorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server: {detail}'**
  String errorConnectionFailed(String detail);

  /// No description provided for @errorHttpStatus.
  ///
  /// In en, this message translates to:
  /// **'The server returned HTTP {code}'**
  String errorHttpStatus(String code);

  /// No description provided for @errorRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed: {detail}'**
  String errorRequestFailed(String detail);

  /// No description provided for @errorInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get errorInvalidUrl;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
