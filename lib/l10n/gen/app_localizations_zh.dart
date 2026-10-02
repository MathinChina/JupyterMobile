// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'JupyterMobile';

  @override
  String get appSubtitle => '连接外部 Jupyter 内核，开始你的 notebook';

  @override
  String get kernelSource => '内核来源';

  @override
  String get sourceRemote => '远程服务器';

  @override
  String get sourceExternal => '本机 Termux';

  @override
  String get sourceBundled => '内置 Python';

  @override
  String get bundledComingSoon => '内置 Python 即将推出（阶段⑥）';

  @override
  String get serverAddress => '服务器地址';

  @override
  String get serverAddressHint => '例如 192.168.1.100 或 example.com';

  @override
  String get port => '端口';

  @override
  String get portHint => '默认 8888';

  @override
  String get token => 'Token';

  @override
  String get tokenHint => 'jupyter_server 的 IdentityProvider.token';

  @override
  String get termuxDeploy => 'Termux 服务部署';

  @override
  String get termuxDeploySubtitle => '配置与命令分离：写一次配置，日常只跑启动 / 停止';

  @override
  String get configDir => '配置目录';

  @override
  String get privateDir => 'Termux 私有目录 (~/.jupyter)';

  @override
  String get privateDirDesc => '仅 Termux 可访问，其他 App 看不到';

  @override
  String get sharedDir => '共享目录 (/sdcard/JupyterMobile)';

  @override
  String get sharedDirDesc => '文件管理器 / Shizuku 可直接读写（推荐）';

  @override
  String get stepInstall => '① 首次安装（已装可跳过）';

  @override
  String get stepConfig => '② 写入配置（一次性）';

  @override
  String get stepStart => '③ 启动服务';

  @override
  String get stepStop => '④ 停止服务';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制到剪贴板';

  @override
  String get autoConnect => '自动连接';

  @override
  String get autoConnectDesc => '下次启动直接使用上次配置连接';

  @override
  String get connect => '连接';

  @override
  String get untitled => '未命名.ipynb';

  @override
  String get renameNotebook => '重命名 Notebook';

  @override
  String get fileName => '文件名';

  @override
  String get fileNameHint => '例如 analysis.ipynb';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get open => '打开';

  @override
  String get save => '保存';

  @override
  String get newNotebook => '新建';

  @override
  String get restartKernel => '重启内核';

  @override
  String get disconnect => '断开连接';

  @override
  String get saved => '已保存';

  @override
  String openFailed(Object error) {
    return '打开失败：$error';
  }

  @override
  String get kernelRestarted => '内核已重启';

  @override
  String restartFailed(Object error) {
    return '重启失败：$error';
  }

  @override
  String get code => '代码';

  @override
  String get markdown => 'Markdown';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String get delete => '删除';

  @override
  String get interrupt => '中断';

  @override
  String get run => '运行';

  @override
  String get emptyMarkdown => '（空 Markdown，点击编辑）';

  @override
  String get tapToCode => '（点击输入代码）';

  @override
  String get edit => '编辑';

  @override
  String get preview => '预览';

  @override
  String get done => '完成';

  @override
  String get imageUnavailable => '（图片无法显示）';

  @override
  String get imageInvalid => '（图片数据无效）';

  @override
  String get newNotebookContent => '# 新 Notebook\n\n点击单元格编辑，运行代码单元执行 Python。';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get settings => '设置';

  @override
  String get extensions => '扩展管理';

  @override
  String get extensionPipTitle => '安装 Python 包';

  @override
  String get extensionPackageHint => '例如 numpy、pandas、requests';

  @override
  String get extensionInstall => '安装';

  @override
  String get extensionInstalling => '安装中…';

  @override
  String get extensionOutput => '输出';

  @override
  String get extensionOutputEmpty => '安装输出将显示在这里';

  @override
  String get extensionSuccess => '安装完成';

  @override
  String extensionFailed(Object error) {
    return '安装失败：$error';
  }

  @override
  String get extensionServerTitle => '前端扩展（nbextension / labextension）';

  @override
  String get extensionServerDesc => '服务器级扩展，需在 Termux 中运行';

  @override
  String get stepNbextension => '⑤ 安装 nbextension（前端扩展）';

  @override
  String get stepLabextension => '⑥ 安装 labextension（前端扩展）';

  @override
  String get extensionReplaceName => '把 <name> 替换为扩展名';
}
