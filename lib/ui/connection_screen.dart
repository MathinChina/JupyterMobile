import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/kernel/kernel_connection_config.dart';
import '../core/kernel/kernel_source.dart';
import '../core/termux/termux_deploy.dart';
import '../state/connection_providers.dart';
import 'main_screen.dart';

/// 连接界面：选择内核来源、填写地址/端口/token、提示 Termux 用法。
///
/// 「保持上一次状态」落在这里：进入时恢复上次配置；开启「自动连接」后
/// 下次启动直接连。
class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8888');
  final _tokenController = TextEditingController();

  bool _obscureToken = true;
  bool _autoConnect = false;
  KernelSource _source = KernelSource.external;
  TermuxConfigLocation _configLocation = TermuxConfigLocation.shared;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  /// 恢复上次配置；若开启自动连接则直接连。
  Future<void> _restore() async {
    final persistence = ref.read(connectionPersistenceProvider);
    final config = await persistence.loadConfig();
    final autoConnect = await persistence.getAutoConnect();
    if (!mounted) return;
    setState(() {
      if (config != null) {
        _source = config.source;
        _hostController.text = config.host;
        _portController.text = config.port.toString();
        _tokenController.text = config.token;
      }
      _autoConnect = autoConnect;
    });
    if (autoConnect && config != null) {
      await _connect(config);
    }
  }

  KernelConnectionConfig _currentConfig() {
    final host = _source == KernelSource.external
        ? '127.0.0.1'
        : _hostController.text.trim();
    return KernelConnectionConfig(
      source: _source,
      host: host.isEmpty ? '127.0.0.1' : host,
      port: int.tryParse(_portController.text.trim()) ?? 8888,
      token: _tokenController.text.trim(),
    );
  }

  Future<void> _connect([KernelConnectionConfig? override]) async {
    final config = override ?? _currentConfig();
    final controller = ref.read(connectionControllerProvider.notifier);
    final ok = await controller.connect(config);
    if (!mounted) return;

    final persistence = ref.read(connectionPersistenceProvider);
    await persistence.saveConfig(config);
    await persistence.setAutoConnect(_autoConnect);

    if (ok) {
      final state = ref.read(connectionControllerProvider);
      if (state is ConnectionConnected && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MainScreen(connection: state.connection),
          ),
        );
      }
    }
  }

  /// 依据界面当前填写值 + 部署可选项生成脚本集。
  TermuxDeploy get _deploy {
    final port = int.tryParse(_portController.text.trim()) ?? 8888;
    final token = _tokenController.text.trim().isEmpty
        ? 'changeme'
        : _tokenController.text.trim();
    return TermuxDeploy(
      location: _configLocation,
      ip: '127.0.0.1',
      port: port,
      token: token,
    );
  }

  Future<void> _copy(String text, {String? message}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? '已复制到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionControllerProvider);
    final isConnecting = state is ConnectionConnecting;
    final errorText = state is ConnectionError ? state.message : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            const Text(
              'JupyterMobile',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('连接外部 Jupyter 内核，开始你的 notebook'),
            const SizedBox(height: 24),
            _buildSourceSection(),
            const SizedBox(height: 16),
            _buildFormSection(),
            const SizedBox(height: 16),
            _buildTermuxCard(),
            const SizedBox(height: 16),
            _buildAutoConnectSwitch(),
            if (errorText != null) ...[
              const SizedBox(height: 12),
              _buildError(errorText),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isConnecting ? null : () => _connect(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('连接', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('内核来源', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: KernelSource.values.map((source) {
            final enabled = source != KernelSource.bundled;
            return ChoiceChip(
              label: Text(source.label),
              selected: _source == source,
              onSelected: enabled
                  ? (_) => setState(() => _source = source)
                  : null,
              disabledColor: Colors.grey.shade200,
            );
          }).toList(),
        ),
        if (_source == KernelSource.bundled)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '内置 Python 即将推出（阶段⑥）',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_source == KernelSource.remote) ...[
          _buildLabel('服务器地址'),
          const SizedBox(height: 8),
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(
              hintText: '例如 192.168.1.100 或 example.com',
              prefixIcon: Icon(Icons.dns),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
        ],
        _buildLabel('端口'),
        const SizedBox(height: 8),
        TextField(
          controller: _portController,
          decoration: const InputDecoration(
            hintText: '默认 8888',
            prefixIcon: Icon(Icons.numbers),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildLabel('Token'),
        const SizedBox(height: 8),
        TextField(
          controller: _tokenController,
          obscureText: _obscureToken,
          decoration: InputDecoration(
            hintText: 'jupyter_server 的 --NotebookApp.token',
            prefixIcon: const Icon(Icons.key),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureToken ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _obscureToken = !_obscureToken),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermuxCard() {
    final deploy = _deploy;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.terminal),
        title: const Text('Termux 服务部署'),
        subtitle: const Text('配置与命令分离：写一次配置，日常只跑启动 / 停止'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Text('配置目录', style: TextStyle(fontWeight: FontWeight.w600)),
          RadioGroup<TermuxConfigLocation>(
            groupValue: _configLocation,
            onChanged: (TermuxConfigLocation? v) {
              if (v != null) setState(() => _configLocation = v);
            },
            child: Column(
              children: [
                RadioListTile<TermuxConfigLocation>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Termux 私有目录 (~/.jupyter)'),
                  subtitle: const Text('仅 Termux 可访问，其他 App 看不到'),
                  value: TermuxConfigLocation.private,
                ),
                RadioListTile<TermuxConfigLocation>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('共享目录 (/sdcard/JupyterMobile)'),
                  subtitle: const Text('文件管理器 / Shizuku 可直接读写（推荐）'),
                  value: TermuxConfigLocation.shared,
                ),
              ],
            ),
          ),
          const Divider(),
          _buildScriptBlock('① 首次安装（已装可跳过）', deploy.installScript()),
          _buildScriptBlock('② 写入配置（一次性）', deploy.writeConfigScript()),
          _buildScriptBlock('③ 启动服务', deploy.startScript()),
          _buildScriptBlock('④ 停止服务', deploy.stopScript()),
        ],
      ),
    );
  }

  Widget _buildScriptBlock(String title, String script) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            script,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _copy(script),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('复制'),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoConnectSwitch() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('自动连接'),
      subtitle: const Text('下次启动直接使用上次配置连接'),
      value: _autoConnect,
      onChanged: (v) => setState(() => _autoConnect = v),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
  }
}
