// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Perlite Flow';

  @override
  String get navHome => '首页';

  @override
  String get navSearch => '搜索';

  @override
  String get navNotes => '笔记';

  @override
  String get actionRefresh => '刷新';

  @override
  String get actionSettings => '设置';

  @override
  String get actionRetry => '重试';

  @override
  String get actionCancel => '取消';

  @override
  String get actionOk => '确定';

  @override
  String get actionDelete => '删除';

  @override
  String get actionAdd => '新增';

  @override
  String get actionSignOut => '退出登录';

  @override
  String get actionClear => '清除';

  @override
  String get homeEmptyVaultTitle => '知识库是空的';

  @override
  String get homeEmptyVaultSubtitle => '在 Perlite 服务端放入 Markdown 笔记后下拉刷新';

  @override
  String get homeNoIndexTitle => '服务端没有配置首页笔记';

  @override
  String get homeNoIndexSubtitle => '在 Perlite 设置里指定一篇笔记作为首页';

  @override
  String get searchHint => '搜索笔记内容或文件名';

  @override
  String get searchIdleTitle => '输入关键词开始搜索';

  @override
  String get searchIdleSubtitle => '支持 #标签、文件名和正文内容';

  @override
  String get searchNoResultsTitle => '没有找到匹配';

  @override
  String get searchNoResultsSubtitle => '尝试更短的关键词，或检查 #标签 是否完整';

  @override
  String get searchFileNameMatch => '文件名';

  @override
  String get loginSavedServers => '已保存的服务器';

  @override
  String get loginNameLabel => '名称（可选）';

  @override
  String get loginNameHint => '我的笔记';

  @override
  String get loginServerLabel => '服务器地址';

  @override
  String get loginServerRequired => '请输入服务器地址';

  @override
  String get loginUsernameLabel => '用户名';

  @override
  String get loginUsernameHelper => '未使用 Basic Auth 时可留空';

  @override
  String get loginPasswordLabel => '密码';

  @override
  String get loginShowPassword => '显示密码';

  @override
  String get loginHidePassword => '隐藏密码';

  @override
  String get loginSavePassword => '保存密码';

  @override
  String get loginSavePasswordSubtitle => '保存在系统安全存储中';

  @override
  String get loginAutoLogin => '自动登录';

  @override
  String get loginAutoLoginSubtitle => '下次启动直接进入知识库';

  @override
  String get loginConnecting => '连接中…';

  @override
  String get loginSaveAndReconnect => '保存并重连';

  @override
  String get loginConnect => '连接';

  @override
  String get loginPrivacyNote => '凭证只保存在本设备，不会上传到任何第三方服务';

  @override
  String get loginTagline => '为 Android 打造的 Perlite 知识库客户端';

  @override
  String get readerSettings => '阅读设置';

  @override
  String get readerFontSize => '字体大小';

  @override
  String get readerReload => '重新加载';

  @override
  String get readerOpenExternal => '在浏览器中打开';

  @override
  String get readerBackToTop => '回到顶部';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionAccount => '账户';

  @override
  String get settingsNotConnected => '未连接';

  @override
  String get settingsSignOutSubtitle => '保留服务器配置，结束当前会话';

  @override
  String get settingsSignOutConfirmTitle => '退出登录？';

  @override
  String get settingsSignOutConfirmMessage => '服务器配置会保留在设备上，下次可快速重新连接。';

  @override
  String get settingsSavedServers => '已保存的服务器';

  @override
  String get settingsDeleteServerTitle => '删除服务器？';

  @override
  String settingsDeleteServerMessage(String name) {
    return '将移除“$name”及其保存的密码。';
  }

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsLanguage => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get settingsDynamicColor => 'Material You 动态取色';

  @override
  String get settingsDynamicColorSubtitle => '跟随系统壁纸主题色（Android 12+）';

  @override
  String get settingsDarkMode => '深色模式';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsThemeColor => '主题色';

  @override
  String get settingsThemeColorOverridden => '主题色（已启用动态取色，预设色暂不生效）';

  @override
  String get settingsFont => '字体';

  @override
  String get settingsChooseFont => '选择字体';

  @override
  String get fontSystem => '系统默认';

  @override
  String get fontLxgw => '霞鹜文楷';

  @override
  String get fontJetBrainsMono => 'JetBrains Mono + 霞鹜文楷';

  @override
  String get settingsSectionNavigation => '导航';

  @override
  String get settingsTopTitle => '顶部标题';

  @override
  String get settingsTitleModeRepo => '跟随仓库';

  @override
  String get settingsTitleModeCustom => '自定义';

  @override
  String get settingsTitleFollowRepo => '跟随当前仓库';

  @override
  String settingsTitleFollowRepoNamed(String name) {
    return '跟随当前仓库（$name）';
  }

  @override
  String get settingsTitleCustomEmpty => '自定义文字';

  @override
  String settingsTitleCustomValue(String text) {
    return '自定义：$text';
  }

  @override
  String get settingsCustomTitleHint => '例如：我的知识库';

  @override
  String get settingsNavHelp => '使用箭头调整顺序，勾选控制显示，星标设为启动时进入的标签。';

  @override
  String get navDefaultBadge => '默认';

  @override
  String navPosition(int index, int total) {
    return '位置 $index / $total';
  }

  @override
  String get navHidden => '已隐藏';

  @override
  String get navMoveUp => '上移';

  @override
  String get navMoveDown => '下移';

  @override
  String get navSetDefault => '设为启动标签';

  @override
  String get settingsSectionStorage => '存储';

  @override
  String get settingsNoteCache => '笔记缓存';

  @override
  String settingsCacheUsage(String used, String limit) {
    return '已使用 $used / 上限 $limit';
  }

  @override
  String get settingsClearCache => '清理缓存';

  @override
  String get settingsCacheCleared => '缓存已清理';

  @override
  String get settingsCacheLimit => '缓存上限';

  @override
  String get settingsCacheLimitDialogTitle => '缓存上限（MB）';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String settingsAboutSubtitle(String version) {
    return 'Perlite Android 客户端 · $version';
  }

  @override
  String get settingsSourceCode => '源代码';

  @override
  String get errorUnauthorized => '用户名或密码错误（401）';

  @override
  String get errorForbidden => '访问被拒绝（403）';

  @override
  String get errorNotFound => '服务器返回 404，请检查 URL';

  @override
  String get errorDnsFailed => '域名解析失败，请检查地址';

  @override
  String get errorTlsFailed => 'TLS 握手失败，请检查 HTTPS 证书';

  @override
  String get errorConnectionRefused => '连接被拒绝（端口未开放或被防火墙拦截）';

  @override
  String get errorNetworkUnreachable => '网络不可达，请检查网络或代理';

  @override
  String errorConnectionFailed(String detail) {
    return '无法连接服务器：$detail';
  }

  @override
  String errorHttpStatus(String code) {
    return '服务器返回 HTTP $code';
  }

  @override
  String errorRequestFailed(String detail) {
    return '请求失败：$detail';
  }

  @override
  String get errorInvalidUrl => 'URL 格式不正确';
}
