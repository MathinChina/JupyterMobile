import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/kernel/kernel_connection.dart';
import '../core/kernel/kernel_event.dart';
import '../state/connection_providers.dart';

/// 主界面：最小执行闭环——代码输入框 + 运行按钮 + 流式输出区。
///
/// 阶段①（解析/渲染/编辑）与阶段②（代码执行）将在这里展开。
/// 当前先跑通 execute 的端到端，后续再扩展 cell 列表与富媒体渲染。
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, required this.connection});

  final KernelConnection connection;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

enum _OutputKind { stdout, stderr, result, error, status }

class _OutputLine {
  const _OutputLine(this.kind, this.text);
  final _OutputKind kind;
  final String text;
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _codeController = TextEditingController();
  final List<_OutputLine> _output = [];
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<KernelEvent>? _execSub;
  bool _running = false;

  @override
  void dispose() {
    _execSub?.cancel();
    _codeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addLine(_OutputLine line) {
    setState(() => _output.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController
            .jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _run() async {
    final code = _codeController.text;
    if (code.trim().isEmpty || _running) return;
    _addLine(_OutputLine(_OutputKind.status, 'In [*]: ${code.trim()}'));
    setState(() => _running = true);

    _execSub = widget.connection.execute(code).listen(
      (event) {
        switch (event) {
          case KernelStatusEvent(:final status):
            if (status == 'idle') {
              _addLine(const _OutputLine(_OutputKind.status, '完成'));
            }
          case KernelStreamEvent(:final name, :final text):
            _addLine(_OutputLine(
              name == 'stderr' ? _OutputKind.stderr : _OutputKind.stdout,
              text,
            ));
          case KernelExecuteResultEvent(:final data):
            _addLine(_OutputLine(_OutputKind.result, _plainText(data)));
          case KernelDisplayDataEvent(:final data):
            _addLine(_OutputLine(_OutputKind.result, _plainText(data)));
          case KernelErrorEvent(:final ename, :final evalue, :final traceback):
            _addLine(_OutputLine(
              _OutputKind.error,
              traceback.isEmpty ? '$ename: $evalue' : traceback.join('\n'),
            ));
        }
      },
      onError: (Object e) {
        _addLine(_OutputLine(_OutputKind.error, e.toString()));
      },
      onDone: () {
        if (mounted) setState(() => _running = false);
      },
    );
  }

  String _plainText(Map<String, dynamic> data) {
    if (data.containsKey('text/plain')) return data['text/plain'].toString();
    // 非纯文本结果：给出可读的键提示。
    final keys = data.keys.where((k) => k.startsWith('text/'));
    if (keys.isNotEmpty) return data[keys.first].toString();
    return data.toString();
  }

  Future<void> _restart() async {
    try {
      await widget.connection.restart();
      _output.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('内核已重启')),
        );
      }
    } catch (e) {
      _addLine(_OutputLine(_OutputKind.error, e.toString()));
    }
  }

  Future<void> _disconnect() async {
    await _execSub?.cancel();
    await widget.connection.disconnect();
    ref.read(connectionControllerProvider.notifier).reset();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = widget.connection.config.baseUrl;
    return Scaffold(
      appBar: AppBar(
        title: const Text('JupyterMobile'),
        actions: [
          IconButton(
            tooltip: '重启内核',
            icon: const Icon(Icons.refresh),
            onPressed: _restart,
          ),
          IconButton(
            tooltip: '中断执行',
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: _running
                ? () => widget.connection.interrupt()
                : null,
          ),
          IconButton(
            tooltip: '断开连接',
            icon: const Icon(Icons.power_settings_new),
            onPressed: _disconnect,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(
                  _running ? Icons.circle : Icons.check_circle,
                  size: 14,
                  color: _running ? Colors.amber : Colors.green,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    baseUrl,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _output.isEmpty
                ? Center(
                    child: Text(
                      '输入代码并点击运行，输出将显示在这里',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _output.length,
                    itemBuilder: (context, i) => _buildOutputLine(_output[i]),
                  ),
          ),
          const Divider(height: 1),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildOutputLine(_OutputLine line) {
    Color color;
    FontStyle style = FontStyle.normal;
    switch (line.kind) {
      case _OutputKind.stdout:
      case _OutputKind.result:
        color = Colors.black87;
      case _OutputKind.stderr:
      case _OutputKind.error:
        color = Colors.red.shade700;
      case _OutputKind.status:
        color = Colors.grey.shade500;
        style = FontStyle.italic;
    }
    final mono = line.kind == _OutputKind.stdout ||
        line.kind == _OutputKind.stderr ||
        line.kind == _OutputKind.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SelectableText(
        line.text,
        style: TextStyle(
          color: color,
          fontStyle: style,
          fontFamily: mono ? 'monospace' : null,
          fontSize: mono ? 13 : 14,
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeController,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: '输入 Python 代码，例如 print("hello")',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  tooltip: '运行',
                  icon: Icon(
                    _running ? Icons.hourglass_top : Icons.play_arrow,
                    color: Colors.green,
                  ),
                  onPressed: _running ? null : _run,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _running ? null : _run,
                icon: const Icon(Icons.play_arrow),
                label: const Text('运行'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
