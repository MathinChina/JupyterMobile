import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/kernel/kernel_connection_config.dart';
import '../core/kernel/kernel_source.dart';
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

  String get _termuxScript {
    final port = _portController.text.trim().isEmpty
        ? '8888'
        : _portController.text.trim();
    final token = _tokenController.text.trim().isEmpty
        ? 'changeme'
        : _tokenController.text.trim();
    return 'pkg install python python-numpy && pip install jupyter && '
        'jupyter server --no-browser --port=$port --NotebookApp.token=$token';
  }

  Future<void> _copyTermuxScript() async {
    await Clipboard.setData(ClipboardData(text: _termuxScript));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板，粘贴到 Termux 执行')),
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
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.terminal),
        title: const Text('Termux 一键启动服务'),
        subtitle: const Text('复制到 Termux 执行，先安装 Python 与 jupyter'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _termuxScript,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _copyTermuxScript,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('复制'),
            ),
          ),
        ],
      ),
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
