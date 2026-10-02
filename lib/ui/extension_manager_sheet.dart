import 'dart:async';

import 'package:flutter/material.dart';

import '../core/ansi.dart';
import '../core/kernel/kernel_connection.dart';
import '../core/kernel/kernel_event.dart';
import '../l10n/gen/app_localizations.dart';

/// 扩展管理：在已连接的内核里安装 Python 包，并流式显示 pip 输出。
///
/// 通过 [KernelConnection.execute] 执行 `!pip install`，把
/// [KernelStreamEvent]（stdout / stderr）与 [KernelErrorEvent] 逐条追加到
/// 输出区。它持有独立的 [StreamSubscription]，与 cell 执行互不干扰。
class ExtensionManagerSheet extends StatefulWidget {
  const ExtensionManagerSheet({super.key, required this.connection});

  final KernelConnection connection;

  @override
  State<ExtensionManagerSheet> createState() => _ExtensionManagerSheetState();
}

class _ExtensionManagerSheetState extends State<ExtensionManagerSheet> {
  final TextEditingController _controller = TextEditingController();
  StreamSubscription<KernelEvent>? _sub;
  bool _installing = false;
  String _output = '';

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// 只保留 PyPI 合法包名字符，避免 shell 注入。
  static String _sanitizePackage(String raw) =>
      raw.replaceAll(RegExp(r'[^a-zA-Z0-9._+\-]'), '');

  Future<void> _install() async {
    final l10n = AppLocalizations.of(context);
    if (_installing) return;
    final pkg = _sanitizePackage(_controller.text.trim());
    if (pkg.isEmpty) return;

    setState(() {
      _installing = true;
      _output = '';
    });

    // 通过 IPython 的 `!` shell 魔法流式转发 pip 输出；`--no-input`
    // 避免交互提示卡住内核。
    final code = 'import sys\n'
        '!{sys.executable} -m pip install --no-input "$pkg"';
    _sub = widget.connection.execute(code).listen(
      (event) {
        if (!mounted) return;
        switch (event) {
          case KernelStreamEvent(:final text):
            setState(() => _output += stripAnsi(text));
          case KernelErrorEvent(:final ename, :final evalue, :final traceback):
            setState(() {
              _output += '$ename: $evalue\n';
              if (traceback.isNotEmpty) _output += traceback.join('\n');
            });
          default:
            break;
        }
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() => _output += l10n.extensionFailed('$e'));
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _installing = false;
          if (_output.isEmpty) _output = l10n.extensionSuccess;
        });
      },
    );
  }

  void _interrupt() {
    widget.connection.interrupt();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.extensionPipTitle,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_installing,
                  decoration: InputDecoration(
                    hintText: l10n.extensionPackageHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _install(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _installing ? null : _install,
                icon: _installing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(
                    _installing ? l10n.extensionInstalling : l10n.extensionInstall),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(l10n.extensionOutput,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_installing)
                TextButton.icon(
                  onPressed: _interrupt,
                  icon: const Icon(Icons.stop, size: 18),
                  label: Text(l10n.interrupt),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _output.isEmpty ? l10n.extensionOutputEmpty : _output,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'DejaVuSansMono',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
