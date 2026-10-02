import 'package:shared_preferences/shared_preferences.dart';

import '../core/kernel/kernel_connection_config.dart';

/// 连接配置的本地持久化（`shared_preferences`）。
///
/// 「保持上一次状态」的第一层：记住连接配置 + 自动连接开关。
/// 恢复上次 notebook（第二层）字段已预留，阶段①+ 再启用。
class ConnectionPersistence {
  static const _configKey = 'kernel_connection_config';
  static const _autoConnectKey = 'auto_connect';
  static const _lastNotebookKey = 'last_notebook_path';

  Future<void> saveConfig(KernelConnectionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, config.encode());
  }

  Future<KernelConnectionConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw == null) return null;
    try {
      return KernelConnectionConfig.decode(raw);
    } catch (_) {
      // 数据损坏时回退到默认，而不是让 App 崩溃。
      return null;
    }
  }

  Future<bool> getAutoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoConnectKey) ?? false;
  }

  Future<void> setAutoConnect(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoConnectKey, value);
  }

  // 预留：恢复上次打开的 notebook（阶段①+ 实现）。
  Future<String?> getLastNotebookPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastNotebookKey);
  }

  Future<void> setLastNotebookPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNotebookKey, path);
  }
}
