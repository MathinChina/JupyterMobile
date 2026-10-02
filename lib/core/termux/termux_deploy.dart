/// Termux Jupyter 服务的部署脚本生成器。
///
/// 「配置可选项」的落点：把「配置」与「启动 / 停止命令」分离——
/// 配置一次性写入 `jupyter_server_config.py`，日常只跑启动 / 停止脚本。
///
/// 关键点：
/// - token 用 `c.IdentityProvider.token`（Jupyter Server 2.x 的规范项），
///   不再使用已废弃的 `ServerApp.token` / `NotebookApp.token`。
/// - 「共享目录」模式把配置与 notebook 放到 `/sdcard`，使文件管理器、
///   Shizuku（仅有 shell 权限）可直接读写；Shizuku 进不了 Termux 私有目录
///   `/data/data/com.termux`。
library;

/// 配置文件与 notebook 的存放位置。
enum TermuxConfigLocation {
  /// Termux 默认私有目录 `~/.jupyter`（仅 Termux 自身可访问）。
  private('Termux 私有目录 (~/.jupyter)'),

  /// 外部共享目录 `/sdcard/JupyterMobile`（文件管理器 / Shizuku 可访问）。
  shared('共享目录 (/sdcard，可被 Shizuku 访问)');

  const TermuxConfigLocation(this.label);

  /// 界面展示用中文标签。
  final String label;
}

/// 依据可选项生成 Termux 部署脚本。
class TermuxDeploy {
  const TermuxDeploy({
    required this.location,
    required this.ip,
    required this.port,
    required this.token,
  });

  final TermuxConfigLocation location;

  /// Jupyter 监听地址（本机 Termux 固定 127.0.0.1）。
  final String ip;

  final int port;

  /// 固定 token（App 连接框与配置保持一致）。
  final String token;

  /// 配置目录（脚本内可直接使用；`$HOME` 在双引号中能正确展开）。
  String get configDir => location == TermuxConfigLocation.shared
      ? '/sdcard/JupyterMobile/config'
      : r'$HOME/.jupyter';

  /// notebook 工作目录。
  String get notebookDir => location == TermuxConfigLocation.shared
      ? '/sdcard/JupyterMobile/notebooks'
      : r'$HOME';

  /// 启动日志文件。
  String get logFile => location == TermuxConfigLocation.shared
      ? '/sdcard/JupyterMobile/nb.log'
      : r'$HOME/.jupyter/nb.log';

  /// 首次安装（已装可跳过）。
  String installScript() =>
      'pkg install python python-numpy && pip install jupyter';

  /// 写入配置（配置与命令分离：只做一次）。
  String writeConfigScript() {
    return [
      'mkdir -p "$configDir"',
      'cat > "$configDir/jupyter_server_config.py" <<\'EOF\'',
      "c.ServerApp.ip = '$ip'",
      'c.ServerApp.port = $port',
      'c.ServerApp.open_browser = False',
      '# Jupyter Server 2.x 用 IdentityProvider.token'
          '（旧的 ServerApp.token / NotebookApp.token 已废弃）',
      "c.IdentityProvider.token = '$token'",
      'EOF',
    ].join('\n');
  }

  /// 后台启动，日志落文件。
  String startScript() {
    return [
      'mkdir -p "$notebookDir"',
      'JUPYTER_CONFIG_DIR="$configDir" nohup jupyter notebook'
          ' "$notebookDir" > "$logFile" 2>&1 &',
      'echo "已启动（后台），日志：$logFile"',
    ].join('\n');
  }

  /// 优雅停止，失败则兜底强杀。
  String stopScript() {
    return [
      'jupyter server stop $port 2>/dev/null || pkill -f jupyter-notebook',
      'echo "已停止"',
    ].join('\n');
  }
}
