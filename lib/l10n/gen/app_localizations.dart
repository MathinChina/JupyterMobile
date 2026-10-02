import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
/// import 'gen/app_localizations.dart';
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
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'JupyterMobile'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'连接外部 Jupyter 内核，开始你的 notebook'**
  String get appSubtitle;

  /// No description provided for @kernelSource.
  ///
  /// In zh, this message translates to:
  /// **'内核来源'**
  String get kernelSource;

  /// No description provided for @sourceRemote.
  ///
  /// In zh, this message translates to:
  /// **'远程服务器'**
  String get sourceRemote;

  /// No description provided for @sourceExternal.
  ///
  /// In zh, this message translates to:
  /// **'本机 Termux'**
  String get sourceExternal;

  /// No description provided for @sourceBundled.
  ///
  /// In zh, this message translates to:
  /// **'内置 Python'**
  String get sourceBundled;

  /// No description provided for @bundledComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'内置 Python 即将推出（阶段⑥）'**
  String get bundledComingSoon;

  /// No description provided for @serverAddress.
  ///
  /// In zh, this message translates to:
  /// **'服务器地址'**
  String get serverAddress;

  /// No description provided for @serverAddressHint.
  ///
  /// In zh, this message translates to:
  /// **'例如 192.168.1.100 或 example.com'**
  String get serverAddressHint;

  /// No description provided for @port.
  ///
  /// In zh, this message translates to:
  /// **'端口'**
  String get port;

  /// No description provided for @portHint.
  ///
  /// In zh, this message translates to:
  /// **'默认 8888'**
  String get portHint;

  /// No description provided for @token.
  ///
  /// In zh, this message translates to:
  /// **'Token'**
  String get token;

  /// No description provided for @tokenHint.
  ///
  /// In zh, this message translates to:
  /// **'jupyter_server 的 IdentityProvider.token'**
  String get tokenHint;

  /// No description provided for @generateToken.
  ///
  /// In zh, this message translates to:
  /// **'随机生成'**
  String get generateToken;

  /// No description provided for @deployMethod.
  ///
  /// In zh, this message translates to:
  /// **'部署方式'**
  String get deployMethod;

  /// No description provided for @deployManual.
  ///
  /// In zh, this message translates to:
  /// **'手动命令'**
  String get deployManual;

  /// No description provided for @deployOneClick.
  ///
  /// In zh, this message translates to:
  /// **'一键脚本'**
  String get deployOneClick;

  /// No description provided for @stepOneClick.
  ///
  /// In zh, this message translates to:
  /// **'一键部署'**
  String get stepOneClick;

  /// No description provided for @oneClickHint.
  ///
  /// In zh, this message translates to:
  /// **'安装后可用 jm status / jm stop / jm log 管理服务'**
  String get oneClickHint;

  /// No description provided for @termuxDeploy.
  ///
  /// In zh, this message translates to:
  /// **'Termux 服务部署'**
  String get termuxDeploy;

  /// No description provided for @termuxDeploySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'配置与命令分离：写一次配置，日常只跑启动 / 停止'**
  String get termuxDeploySubtitle;

  /// No description provided for @configDir.
  ///
  /// In zh, this message translates to:
  /// **'配置目录'**
  String get configDir;

  /// No description provided for @privateDir.
  ///
  /// In zh, this message translates to:
  /// **'Termux 私有目录 (~/.jupyter)'**
  String get privateDir;

  /// No description provided for @privateDirDesc.
  ///
  /// In zh, this message translates to:
  /// **'仅 Termux 可访问，其他 App 看不到'**
  String get privateDirDesc;

  /// No description provided for @sharedDir.
  ///
  /// In zh, this message translates to:
  /// **'共享目录 (/sdcard/JupyterMobile)'**
  String get sharedDir;

  /// No description provided for @sharedDirDesc.
  ///
  /// In zh, this message translates to:
  /// **'文件管理器 / Shizuku 可直接读写（推荐）'**
  String get sharedDirDesc;

  /// No description provided for @stepInstall.
  ///
  /// In zh, this message translates to:
  /// **'① 首次安装（已装可跳过）'**
  String get stepInstall;

  /// No description provided for @stepConfig.
  ///
  /// In zh, this message translates to:
  /// **'② 写入配置（一次性）'**
  String get stepConfig;

  /// No description provided for @stepStart.
  ///
  /// In zh, this message translates to:
  /// **'③ 启动服务'**
  String get stepStart;

  /// No description provided for @stepStop.
  ///
  /// In zh, this message translates to:
  /// **'④ 停止服务'**
  String get stepStop;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get copied;

  /// No description provided for @autoConnect.
  ///
  /// In zh, this message translates to:
  /// **'自动连接'**
  String get autoConnect;

  /// No description provided for @autoConnectDesc.
  ///
  /// In zh, this message translates to:
  /// **'下次启动直接使用上次配置连接'**
  String get autoConnectDesc;

  /// No description provided for @connect.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get connect;

  /// No description provided for @untitled.
  ///
  /// In zh, this message translates to:
  /// **'未命名.ipynb'**
  String get untitled;

  /// No description provided for @renameNotebook.
  ///
  /// In zh, this message translates to:
  /// **'重命名 Notebook'**
  String get renameNotebook;

  /// No description provided for @fileName.
  ///
  /// In zh, this message translates to:
  /// **'文件名'**
  String get fileName;

  /// No description provided for @fileNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如 analysis.ipynb'**
  String get fileNameHint;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get ok;

  /// No description provided for @open.
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get open;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @newNotebook.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get newNotebook;

  /// No description provided for @restartKernel.
  ///
  /// In zh, this message translates to:
  /// **'重启内核'**
  String get restartKernel;

  /// No description provided for @disconnect.
  ///
  /// In zh, this message translates to:
  /// **'断开连接'**
  String get disconnect;

  /// No description provided for @saved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get saved;

  /// No description provided for @openFailed.
  ///
  /// In zh, this message translates to:
  /// **'打开失败：{error}'**
  String openFailed(Object error);

  /// No description provided for @kernelRestarted.
  ///
  /// In zh, this message translates to:
  /// **'内核已重启'**
  String get kernelRestarted;

  /// No description provided for @restartFailed.
  ///
  /// In zh, this message translates to:
  /// **'重启失败：{error}'**
  String restartFailed(Object error);

  /// No description provided for @code.
  ///
  /// In zh, this message translates to:
  /// **'代码'**
  String get code;

  /// No description provided for @markdown.
  ///
  /// In zh, this message translates to:
  /// **'Markdown'**
  String get markdown;

  /// No description provided for @moveUp.
  ///
  /// In zh, this message translates to:
  /// **'上移'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In zh, this message translates to:
  /// **'下移'**
  String get moveDown;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @collapse.
  ///
  /// In zh, this message translates to:
  /// **'折叠'**
  String get collapse;

  /// No description provided for @expand.
  ///
  /// In zh, this message translates to:
  /// **'展开'**
  String get expand;

  /// No description provided for @interrupt.
  ///
  /// In zh, this message translates to:
  /// **'中断'**
  String get interrupt;

  /// No description provided for @run.
  ///
  /// In zh, this message translates to:
  /// **'运行'**
  String get run;

  /// No description provided for @emptyMarkdown.
  ///
  /// In zh, this message translates to:
  /// **'（空 Markdown，点击编辑）'**
  String get emptyMarkdown;

  /// No description provided for @tapToCode.
  ///
  /// In zh, this message translates to:
  /// **'（点击输入代码）'**
  String get tapToCode;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @preview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get preview;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @imageUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'（图片无法显示）'**
  String get imageUnavailable;

  /// No description provided for @imageInvalid.
  ///
  /// In zh, this message translates to:
  /// **'（图片数据无效）'**
  String get imageInvalid;

  /// No description provided for @newNotebookContent.
  ///
  /// In zh, this message translates to:
  /// **'# 新 Notebook\n\n点击单元格编辑，运行代码单元执行 Python。'**
  String get newNotebookContent;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @extensions.
  ///
  /// In zh, this message translates to:
  /// **'扩展管理'**
  String get extensions;

  /// No description provided for @extensionPipTitle.
  ///
  /// In zh, this message translates to:
  /// **'安装 Python 包'**
  String get extensionPipTitle;

  /// No description provided for @extensionPackageHint.
  ///
  /// In zh, this message translates to:
  /// **'例如 numpy、pandas、requests'**
  String get extensionPackageHint;

  /// No description provided for @extensionInstall.
  ///
  /// In zh, this message translates to:
  /// **'安装'**
  String get extensionInstall;

  /// No description provided for @extensionInstalling.
  ///
  /// In zh, this message translates to:
  /// **'安装中…'**
  String get extensionInstalling;

  /// No description provided for @extensionOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出'**
  String get extensionOutput;

  /// No description provided for @extensionOutputEmpty.
  ///
  /// In zh, this message translates to:
  /// **'安装输出将显示在这里'**
  String get extensionOutputEmpty;

  /// No description provided for @extensionSuccess.
  ///
  /// In zh, this message translates to:
  /// **'安装完成'**
  String get extensionSuccess;

  /// No description provided for @extensionFailed.
  ///
  /// In zh, this message translates to:
  /// **'安装失败：{error}'**
  String extensionFailed(Object error);

  /// No description provided for @extensionServerTitle.
  ///
  /// In zh, this message translates to:
  /// **'前端扩展（nbextension / labextension）'**
  String get extensionServerTitle;

  /// No description provided for @extensionServerDesc.
  ///
  /// In zh, this message translates to:
  /// **'服务器级扩展，需在 Termux 中运行'**
  String get extensionServerDesc;

  /// No description provided for @stepNbextension.
  ///
  /// In zh, this message translates to:
  /// **'⑤ 安装 nbextension（前端扩展）'**
  String get stepNbextension;

  /// No description provided for @stepLabextension.
  ///
  /// In zh, this message translates to:
  /// **'⑥ 安装 labextension（前端扩展）'**
  String get stepLabextension;

  /// No description provided for @extensionReplaceName.
  ///
  /// In zh, this message translates to:
  /// **'把 <name> 替换为扩展名'**
  String get extensionReplaceName;

  /// No description provided for @donate.
  ///
  /// In zh, this message translates to:
  /// **'赞助'**
  String get donate;

  /// No description provided for @donateTitle.
  ///
  /// In zh, this message translates to:
  /// **'赞助支持'**
  String get donateTitle;

  /// No description provided for @donateIntro.
  ///
  /// In zh, this message translates to:
  /// **'如果这个工具对你有帮助，欢迎请作者喝杯咖啡 ☕'**
  String get donateIntro;

  /// No description provided for @donateBuyMeACoffee.
  ///
  /// In zh, this message translates to:
  /// **'Buy Me a Coffee'**
  String get donateBuyMeACoffee;

  /// No description provided for @donateBilibili.
  ///
  /// In zh, this message translates to:
  /// **'B站充电'**
  String get donateBilibili;

  /// No description provided for @donateTapToOpen.
  ///
  /// In zh, this message translates to:
  /// **'点击前往赞助页'**
  String get donateTapToOpen;

  /// No description provided for @donateTapToCharge.
  ///
  /// In zh, this message translates to:
  /// **'点击前往充电页'**
  String get donateTapToCharge;

  /// No description provided for @donateNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'尚未配置链接（见 lib/core/donate_config.dart）'**
  String get donateNotConfigured;

  /// No description provided for @donateLinkFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开链接：{url}'**
  String donateLinkFailed(Object url);
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
