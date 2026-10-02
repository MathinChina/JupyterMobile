import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../core/kernel/kernel_connection.dart';
import '../core/kernel/kernel_event.dart';
import '../core/notebook/notebook.dart';
import '../state/connection_providers.dart';
import 'widgets/cell_output_view.dart';
import 'widgets/code_highlight.dart';

/// 主界面：notebook 渲染 / 编辑 / 执行。
///
/// 阶段①（解析/渲染/编辑）与阶段②（代码执行）将在这里展开。
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, required this.connection});

  final KernelConnection connection;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  NotebookDocument _doc = NotebookDocument.empty();
  final TextEditingController _editController = TextEditingController();

  StreamSubscription<KernelEvent>? _execSub;
  int? _editingIndex;
  int? _runningIndex;
  String _fileName = '未命名.ipynb';
  bool _markdownPreview = false;

  @override
  void initState() {
    super.initState();
    _editController.addListener(_onEditChanged);
    _doc.cells.add(MarkdownCell(
      id: notebookNewId(),
      metadata: const {},
      source: '# 新 Notebook\n\n点击单元格编辑，运行代码单元执行 Python。',
    ));
  }

  @override
  void dispose() {
    _execSub?.cancel();
    _editController.removeListener(_onEditChanged);
    _editController.dispose();
    super.dispose();
  }

  void _onEditChanged() {
    // markdown 实时预览时，输入变化触发重建。
    if (_markdownPreview && mounted) setState(() {});
  }

  // ---- 文件操作 ----

  Future<void> _openFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ipynb'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    try {
      final doc = NotebookDocument.parse(utf8.decode(bytes));
      setState(() {
        _doc = doc;
        _fileName = file.name;
        _editingIndex = null;
      });
    } catch (e) {
      _showSnack('打开失败：$e');
    }
  }

  Future<void> _saveFile() async {
    final bytes = Uint8List.fromList(utf8.encode(_doc.encode()));
    final uri = await FilePicker.saveFile(
      fileName: _fileName,
      bytes: bytes,
      mimeType: 'application/x-ipynb+json',
      type: FileType.custom,
      allowedExtensions: const ['ipynb'],
    );
    if (uri != null) {
      _fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : _fileName;
      if (mounted) _showSnack('已保存');
    }
  }

  void _newNotebook() {
    setState(() {
      _doc = NotebookDocument.empty();
      _doc.cells.add(MarkdownCell(
        id: notebookNewId(),
        metadata: const {},
        source: '# 新 Notebook',
      ));
      _fileName = '未命名.ipynb';
      _editingIndex = null;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- cell 操作 ----

  void _addCodeCell() {
    setState(() {
      _doc.cells.add(CodeCell(
        id: notebookNewId(),
        metadata: const {},
        source: '',
      ));
      _editingIndex = _doc.cells.length - 1;
    });
    _editController.text = '';
  }

  void _addMarkdownCell() {
    setState(() {
      _doc.cells.add(MarkdownCell(
        id: notebookNewId(),
        metadata: const {},
        source: '',
      ));
      _editingIndex = _doc.cells.length - 1;
    });
    _editController.text = '';
  }

  void _deleteCell(int index) {
    setState(() {
      _doc.cells.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = null;
      } else if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
    });
  }

  void _moveCell(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _doc.cells.length) return;
    setState(() {
      final cell = _doc.cells.removeAt(index);
      _doc.cells.insert(target, cell);
      // 跟随正在编辑的 cell。
      if (_editingIndex == index) {
        _editingIndex = target;
      } else if (_editingIndex != null) {
        final e = _editingIndex!;
        if (delta > 0 && e == target) {
          _editingIndex = index;
        } else if (delta < 0 && e == target) {
          _editingIndex = index;
        }
      }
    });
  }

  void _startEdit(int index) {
    _editController.text = _doc.cells[index].source;
    setState(() {
      _editingIndex = index;
      _markdownPreview = false;
    });
  }

  void _finishEdit() {
    final index = _editingIndex;
    if (index != null && index < _doc.cells.length) {
      _doc.cells[index].setSource(_editController.text);
    }
    setState(() {
      _editingIndex = null;
      _markdownPreview = false;
    });
  }

  // ---- 执行 ----

  void _runCell(int index) {
    final cell = _doc.cells[index];
    if (cell is! CodeCell || _runningIndex != null) return;
    _execSub?.cancel();
    cell.outputs.clear();
    cell.executionCount = null;
    setState(() => _runningIndex = index);

    _execSub = widget.connection.execute(cell.source).listen(
      (event) {
        if (!mounted) return;
        switch (event) {
          case KernelStatusEvent(:final status):
            if (status == 'idle') {
              setState(() => _runningIndex = null);
            }
          case KernelStreamEvent(:final name, :final text):
            setState(() => cell.outputs.add(StreamOutput(name: name, text: text)));
          case KernelDisplayDataEvent(:final data):
            setState(() => cell.outputs.add(DisplayDataOutput(data: data)));
          case KernelExecuteResultEvent(:final data, :final executionCount):
            setState(() {
              cell.executionCount = executionCount;
              cell.outputs.add(
                ExecuteResultOutput(data: data, executionCount: executionCount),
              );
            });
          case KernelErrorEvent(:final ename, :final evalue, :final traceback):
            setState(() {
              cell.outputs.add(
                ErrorOutput(ename: ename, evalue: evalue, traceback: traceback),
              );
            });
        }
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          cell.outputs.add(ErrorOutput(
            ename: 'ConnectionError',
            evalue: e.toString(),
            traceback: const [],
          ));
          _runningIndex = null;
        });
      },
      onDone: () {
        if (mounted) setState(() => _runningIndex = null);
      },
    );
  }

  void _interrupt() {
    widget.connection.interrupt();
  }

  Future<void> _restart() async {
    try {
      await widget.connection.restart();
      if (mounted) {
        _showSnack('内核已重启');
      }
    } catch (e) {
      if (mounted) _showSnack('重启失败：$e');
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
        title: Text(
          _fileName,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: '打开',
            icon: const Icon(Icons.folder_open),
            onPressed: _openFile,
          ),
          IconButton(
            tooltip: '保存',
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveFile,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'new':
                  _newNotebook();
                case 'restart':
                  _restart();
                case 'disconnect':
                  _disconnect();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'new', child: Text('新建')),
              PopupMenuItem(value: 'restart', child: Text('重启内核')),
              PopupMenuItem(value: 'disconnect', child: Text('断开连接')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  _runningIndex != null ? Icons.circle : Icons.check_circle,
                  size: 13,
                  color: _runningIndex != null ? Colors.amber : Colors.green,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    baseUrl,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _doc.cells.length,
              itemBuilder: (context, i) => _buildCell(_doc.cells[i], i),
            ),
          ),
          const Divider(height: 1),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addCodeCell,
                icon: const Icon(Icons.code, size: 18),
                label: const Text('代码'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addMarkdownCell,
                icon: const Icon(Icons.text_fields, size: 18),
                label: const Text('Markdown'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(NotebookCell cell, int index) {
    final isEditing = _editingIndex == index;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCellHeader(cell, index),
          const Divider(height: 1),
          if (isEditing)
            _buildCellEditor(cell)
          else
            _buildCellBody(cell, index),
        ],
      ),
    );
  }

  Widget _buildCellHeader(NotebookCell cell, int index) {
    final isCode = cell is CodeCell;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Text(
            isCode ? '代码' : 'Markdown',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (cell is CodeCell && cell.executionCount != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'In [${cell.executionCount}]',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: '上移',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_upward, size: 18),
            onPressed: index > 0 ? () => _moveCell(index, -1) : null,
          ),
          IconButton(
            tooltip: '下移',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_downward, size: 18),
            onPressed: index < _doc.cells.length - 1
                ? () => _moveCell(index, 1)
                : null,
          ),
          IconButton(
            tooltip: '删除',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _deleteCell(index),
          ),
          if (isCode)
            IconButton(
              tooltip: _runningIndex == index ? '中断' : '运行',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                _runningIndex == index
                    ? Icons.stop_circle_outlined
                    : Icons.play_arrow,
                size: 20,
                color: Colors.green,
              ),
              onPressed: () =>
                  _runningIndex == index ? _interrupt() : _runCell(index),
            ),
        ],
      ),
    );
  }

  Widget _buildCellBody(NotebookCell cell, int index) {
    if (cell is MarkdownCell) {
      return InkWell(
        onTap: () => _startEdit(index),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: cell.source.trim().isEmpty
              ? Text('（空 Markdown，点击编辑）',
                  style: TextStyle(color: Colors.grey.shade400))
              : MarkdownBody(data: cell.source),
        ),
      );
    }
    if (cell is CodeCell) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _startEdit(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: cell.source.isEmpty
                  ? Text(
                      '（点击输入代码）',
                      style: TextStyle(color: Colors.grey.shade400),
                    )
                  : SelectableText.rich(
                      CodeHighlight.highlightCode(cell.source),
                    ),
            ),
          ),
          if (cell.outputs.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final output in cell.outputs) CellOutputView(output: output),
                ],
              ),
            ),
          ],
        ],
      );
    }
    // RawCell
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(cell.source, style: const TextStyle(fontFamily: 'monospace')),
    );
  }

  Widget _buildCellEditor(NotebookCell cell) {
    final isCode = cell is CodeCell;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _editController,
            minLines: isCode ? 4 : 2,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: TextStyle(
              fontFamily: isCode ? 'monospace' : null,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (!isCode) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _markdownPreview = !_markdownPreview),
                  icon: Icon(
                    _markdownPreview ? Icons.edit : Icons.visibility,
                    size: 18,
                  ),
                  label: Text(_markdownPreview ? '编辑' : '预览'),
                ),
                const Spacer(),
              ],
            ),
            if (_markdownPreview) ...[
              const Divider(),
              MarkdownBody(data: _editController.text),
            ],
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _finishEdit,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('完成'),
            ),
          ),
        ],
      ),
    );
  }
}
