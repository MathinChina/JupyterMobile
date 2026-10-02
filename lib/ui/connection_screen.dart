import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/kernel/kernel_connection_config.dart';
import '../core/kernel/kernel_source.dart';
import '../core/termux/termux_deploy.dart';
import '../l10n/gen/app_localizations.dart';
import '../state/connection_providers.dart';
import '../state/locale_provider.dart';
import 'donate_page.dart';
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
      SnackBar(
        content: Text(message ?? AppLocalizations.of(context).copied),
      ),
    );
  }

  void _openDonate() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const DonatePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(connectionControllerProvider);
    final isConnecting = state is ConnectionConnecting;
    final errorText = state is ConnectionError ? state.message : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'JupyterMobile',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: l10n.donate,
                  onPressed: _openDonate,
                  icon: const Icon(Icons.favorite, color: Colors.pink),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.appSubtitle),
            const SizedBox(height: 24),
            _buildSourceSection(l10n),
            const SizedBox(height: 16),
            _buildFormSection(l10n),
            const SizedBox(height: 16),
            _buildTermuxCard(l10n),
            const SizedBox(height: 16),
            _buildAutoConnectSwitch(l10n),
            const SizedBox(height: 16),
            _buildLanguageSection(l10n),
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
                  : Text(l10n.connect, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.kernelSource,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: KernelSource.values.map((source) {
            final enabled = source != KernelSource.bundled;
            return ChoiceChip(
              label: Text(_sourceLabel(l10n, source)),
              selected: _source == source,
              onSelected: enabled
                  ? (_) => setState(() => _source = source)
                  : null,
              disabledColor: Colors.grey.shade200,
            );
          }).toList(),
        ),
        if (_source == KernelSource.bundled)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.bundledComingSoon,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildFormSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_source == KernelSource.remote) ...[
          _buildLabel(l10n.serverAddress),
          const SizedBox(height: 8),
          TextField(
            controller: _hostController,
            decoration: InputDecoration(
              hintText: l10n.serverAddressHint,
              prefixIcon: const Icon(Icons.dns),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
        ],
        _buildLabel(l10n.port),
        const SizedBox(height: 8),
        TextField(
          controller: _portController,
          decoration: InputDecoration(
            hintText: l10n.portHint,
            prefixIcon: const Icon(Icons.numbers),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildLabel(l10n.token),
        const SizedBox(height: 8),
        TextField(
          controller: _tokenController,
          obscureText: _obscureToken,
          decoration: InputDecoration(
            hintText: l10n.tokenHint,
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

  Widget _buildTermuxCard(AppLocalizations l10n) {
    final deploy = _deploy;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.terminal),
        title: Text(l10n.termuxDeploy),
        subtitle: Text(l10n.termuxDeploySubtitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(l10n.configDir,
              style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  title: Text(l10n.privateDir),
                  subtitle: Text(l10n.privateDirDesc),
                  value: TermuxConfigLocation.private,
                ),
                RadioListTile<TermuxConfigLocation>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.sharedDir),
                  subtitle: Text(l10n.sharedDirDesc),
                  value: TermuxConfigLocation.shared,
                ),
              ],
            ),
          ),
          const Divider(),
          _buildScriptBlock(l10n, l10n.stepInstall, deploy.installScript()),
          _buildScriptBlock(l10n, l10n.stepConfig, deploy.writeConfigScript()),
          _buildScriptBlock(l10n, l10n.stepStart, deploy.startScript()),
          _buildScriptBlock(l10n, l10n.stepStop, deploy.stopScript()),
          const Divider(),
          Text(l10n.extensionServerTitle,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(l10n.extensionServerDesc,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(l10n.extensionReplaceName,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          _buildScriptBlock(
              l10n, l10n.stepNbextension, deploy.nbextensionScript('<name>')),
          _buildScriptBlock(l10n,
              l10n.stepLabextension, deploy.labextensionScript('<name>')),
        ],
      ),
    );
  }

  Widget _buildScriptBlock(
      AppLocalizations l10n, String title, String script) {
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
            label: Text(l10n.copy),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoConnectSwitch(AppLocalizations l10n) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.autoConnect),
      subtitle: Text(l10n.autoConnectDesc),
      value: _autoConnect,
      onChanged: (v) => setState(() => _autoConnect = v),
    );
  }

  Widget _buildLanguageSection(AppLocalizations l10n) {
    final current = _localePreference();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.language)),
            DropdownButton<LocalePreference>(
              value: current,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(
                  value: LocalePreference.system,
                  child: Text(l10n.languageSystem),
                ),
                DropdownMenuItem(
                  value: LocalePreference.zh,
                  child: Text(l10n.languageChinese),
                ),
                DropdownMenuItem(
                  value: LocalePreference.en,
                  child: Text(l10n.languageEnglish),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(localeControllerProvider.notifier).setPreference(v);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  LocalePreference _localePreference() {
    final locale = ref.watch(localeControllerProvider);
    if (locale == null) return LocalePreference.system;
    return LocalePreference.fromStorage(locale.languageCode);
  }

  String _sourceLabel(AppLocalizations l10n, KernelSource source) {
    return switch (source) {
      KernelSource.remote => l10n.sourceRemote,
      KernelSource.external => l10n.sourceExternal,
      KernelSource.bundled => l10n.sourceBundled,
    };
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
