// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JupyterMobile';

  @override
  String get appSubtitle =>
      'Connect to an external Jupyter kernel and start your notebook';

  @override
  String get kernelSource => 'Kernel source';

  @override
  String get sourceRemote => 'Remote server';

  @override
  String get sourceExternal => 'Local Termux';

  @override
  String get sourceBundled => 'Bundled Python';

  @override
  String get bundledComingSoon => 'Bundled Python coming soon (phase 6)';

  @override
  String get serverAddress => 'Server address';

  @override
  String get serverAddressHint => 'e.g. 192.168.1.100 or example.com';

  @override
  String get port => 'Port';

  @override
  String get portHint => 'Default 8888';

  @override
  String get token => 'Token';

  @override
  String get tokenHint => 'IdentityProvider.token of jupyter_server';

  @override
  String get generateToken => 'Generate';

  @override
  String get termuxDeploy => 'Termux service setup';

  @override
  String get termuxDeploySubtitle =>
      'Separate config from commands: write config once, then start/stop';

  @override
  String get configDir => 'Config directory';

  @override
  String get privateDir => 'Termux private dir (~/.jupyter)';

  @override
  String get privateDirDesc => 'Only Termux can access it';

  @override
  String get sharedDir => 'Shared dir (/sdcard/JupyterMobile)';

  @override
  String get sharedDirDesc =>
      'Accessible by file manager / Shizuku (recommended)';

  @override
  String get stepInstall => '① Install (skip if already installed)';

  @override
  String get stepConfig => '② Write config (once)';

  @override
  String get stepStart => '③ Start service';

  @override
  String get stepStop => '④ Stop service';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get autoConnect => 'Auto connect';

  @override
  String get autoConnectDesc => 'Connect using last config on next launch';

  @override
  String get connect => 'Connect';

  @override
  String get untitled => 'Untitled.ipynb';

  @override
  String get renameNotebook => 'Rename notebook';

  @override
  String get fileName => 'File name';

  @override
  String get fileNameHint => 'e.g. analysis.ipynb';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get open => 'Open';

  @override
  String get save => 'Save';

  @override
  String get newNotebook => 'New';

  @override
  String get restartKernel => 'Restart kernel';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get saved => 'Saved';

  @override
  String openFailed(Object error) {
    return 'Open failed: $error';
  }

  @override
  String get kernelRestarted => 'Kernel restarted';

  @override
  String restartFailed(Object error) {
    return 'Restart failed: $error';
  }

  @override
  String get code => 'Code';

  @override
  String get markdown => 'Markdown';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get delete => 'Delete';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get interrupt => 'Interrupt';

  @override
  String get run => 'Run';

  @override
  String get emptyMarkdown => '(Empty Markdown, tap to edit)';

  @override
  String get tapToCode => '(Tap to enter code)';

  @override
  String get edit => 'Edit';

  @override
  String get preview => 'Preview';

  @override
  String get done => 'Done';

  @override
  String get imageUnavailable => '(Image cannot be displayed)';

  @override
  String get imageInvalid => '(Invalid image data)';

  @override
  String get newNotebookContent =>
      '# New Notebook\n\nTap a cell to edit, run a code cell to execute Python.';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get settings => 'Settings';

  @override
  String get extensions => 'Extensions';

  @override
  String get extensionPipTitle => 'Install Python package';

  @override
  String get extensionPackageHint => 'e.g. numpy, pandas, requests';

  @override
  String get extensionInstall => 'Install';

  @override
  String get extensionInstalling => 'Installing…';

  @override
  String get extensionOutput => 'Output';

  @override
  String get extensionOutputEmpty => 'Install output will appear here';

  @override
  String get extensionSuccess => 'Installation finished';

  @override
  String extensionFailed(Object error) {
    return 'Install failed: $error';
  }

  @override
  String get extensionServerTitle =>
      'Front-end extensions (nbextension / labextension)';

  @override
  String get extensionServerDesc => 'Server-level extensions, run in Termux';

  @override
  String get stepNbextension => '⑤ Install nbextension (front-end extension)';

  @override
  String get stepLabextension => '⑥ Install labextension (front-end extension)';

  @override
  String get extensionReplaceName => 'Replace <name> with the extension name';

  @override
  String get donate => 'Donate';

  @override
  String get donateTitle => 'Support';

  @override
  String get donateIntro =>
      'If this tool helps you, consider buying the author a coffee ☕';

  @override
  String get donateBuyMeACoffee => 'Buy Me a Coffee';

  @override
  String get donateBilibili => 'Bilibili charge';

  @override
  String get donateTapToOpen => 'Open sponsor page';

  @override
  String get donateTapToCharge => 'Open charging page';

  @override
  String get donateNotConfigured =>
      'Link not configured yet (see lib/core/donate_config.dart)';

  @override
  String get donateScan => 'Scan to donate';

  @override
  String get donateWechat => 'WeChat reward';

  @override
  String get donateAlipay => 'Alipay';

  @override
  String get donatePlaceholder => 'QR code\ncoming soon';

  @override
  String donateLinkFailed(Object url) {
    return 'Cannot open link: $url';
  }
}
