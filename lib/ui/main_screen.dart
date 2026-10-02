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
import '../l10n/gen/app_localizations.dart';
import '../state/connection_providers.dart';
import 'extension_manager_sheet.dart';
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
  String _fileName = '';
  bool _markdownPreview = false;
  final Set<int> _collapsed = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _editController.addListener(_onEditChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _doc.cells.add(MarkdownCell(
      id: notebookNewId(),
      metadata: const {},
      source: AppLocalizations.of(context).newNotebookContent,
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

  // ---- 命名 ----

  /// 当前显示用文件名；未命名时回退到本地化默认名。
  String get _currentFileName {
    final name = _fileName;
    if (name.isNotEmpty) return name;
    return AppLocalizations.of(context).untitled;
  }

  /// 重命名当前 notebook 文件名（点击 AppBar 标题触发）。
  Future<void> _renameNotebook() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initialName: _currentFileName),
    );
    if (result == null) return;

    var name = result.trim();
    if (name.isEmpty) return;
    if (!name.toLowerCase().endsWith('.ipynb')) {
      name = '$name.ipynb';
    }
    if (!mounted) return;
    setState(() => _fileName = name);
  }

  // ---- 文件操作 ----

  Future<void> _openFile() async {
    final l10n = AppLocalizations.of(context);
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
      if (mounted) _showSnack(l10n.openFailed('$e'));
    }
  }

  Future<void> _saveFile() async {
    final bytes = Uint8List.fromList(utf8.encode(_doc.encode()));
    final uri = await FilePicker.saveFile(
      fileName: _currentFileName,
      bytes: bytes,
      mimeType: 'application/x-ipynb+json',
      type: FileType.custom,
      allowedExtensions: const ['ipynb'],
    );
    if (uri != null) {
      _fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : _fileName;
      if (mounted) _showSnack(AppLocalizations.of(context).saved);
    }
  }

  void _newNotebook() {
    setState(() {
      _doc = NotebookDocument.empty();
      _doc.cells.add(MarkdownCell(
        id: notebookNewId(),
        metadata: const {},
        source: AppLocalizations.of(context).newNotebookContent,
      ));
      _fileName = '';
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
        _showSnack(AppLocalizations.of(context).kernelRestarted);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(AppLocalizations.of(context).restartFailed('$e'));
      }
    }
  }

  /// 打开扩展管理（pip 包安装，流式显示输出）。
  void _openExtensionManager() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          ExtensionManagerSheet(connection: widget.connection),
    );
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
    final l10n = AppLocalizations.of(context);
    final baseUrl = widget.connection.config.baseUrl;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _renameNotebook,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _currentFileName,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, size: 14),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.open,
            icon: const Icon(Icons.folder_open),
            onPressed: _openFile,
          ),
          IconButton(
            tooltip: l10n.save,
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
                case 'extensions':
                  _openExtensionManager();
                case 'disconnect':
                  _disconnect();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'new', child: Text(l10n.newNotebook)),
              PopupMenuItem(value: 'restart', child: Text(l10n.restartKernel)),
              PopupMenuItem(value: 'extensions', child: Text(l10n.extensions)),
              PopupMenuItem(value: 'disconnect', child: Text(l10n.disconnect)),
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
    final l10n = AppLocalizations.of(context);
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
                label: Text(l10n.code),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addMarkdownCell,
                icon: const Icon(Icons.text_fields, size: 18),
                label: Text(l10n.markdown),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(NotebookCell cell, int index) {
    final isEditing = _editingIndex == index;
    final isCollapsed = _collapsed.contains(index);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCellHeader(cell, index),
          if (!isCollapsed) ...[
            const Divider(height: 1),
            if (isEditing)
              _buildCellEditor(cell)
            else
              _buildCellBody(cell, index),
          ],
        ],
      ),
    );
  }

  Widget _buildCellHeader(NotebookCell cell, int index) {
    final l10n = AppLocalizations.of(context);
    final isCode = cell is CodeCell;
    final isCollapsed = _collapsed.contains(index);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          IconButton(
            tooltip: isCollapsed ? l10n.expand : l10n.collapse,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isCollapsed ? Icons.expand_more : Icons.expand_less,
              size: 18,
            ),
            onPressed: () => _toggleCollapse(index),
          ),
          Text(
            isCode ? l10n.code : l10n.markdown,
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
            tooltip: l10n.moveUp,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_upward, size: 18),
            onPressed: index > 0 ? () => _moveCell(index, -1) : null,
          ),
          IconButton(
            tooltip: l10n.moveDown,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_downward, size: 18),
            onPressed: index < _doc.cells.length - 1
                ? () => _moveCell(index, 1)
                : null,
          ),
          IconButton(
            tooltip: l10n.delete,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _deleteCell(index),
          ),
          if (isCode)
            IconButton(
              tooltip: _runningIndex == index ? l10n.interrupt : l10n.run,
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

  void _toggleCollapse(int index) {
    setState(() {
      if (!_collapsed.remove(index)) {
        _collapsed.add(index);
      }
    });
  }

  Widget _buildCellBody(NotebookCell cell, int index) {
    final l10n = AppLocalizations.of(context);
    if (cell is MarkdownCell) {
      return InkWell(
        onTap: () => _startEdit(index),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: cell.source.trim().isEmpty
              ? Text(l10n.emptyMarkdown,
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
                      l10n.tapToCode,
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
      child: Text(
        cell.source,
        style: const TextStyle(fontFamily: 'DejaVuSansMono'),
      ),
    );
  }

  Widget _buildCellEditor(NotebookCell cell) {
    final l10n = AppLocalizations.of(context);
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
              fontFamily: isCode ? 'DejaVuSansMono' : null,
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
                  label: Text(_markdownPreview ? l10n.edit : l10n.preview),
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
              label: Text(l10n.done),
            ),
          ),
        ],
      ),
    );
  }
}

/// 重命名对话框。自己持有 [TextEditingController]，在其 [dispose] 中释放，
/// 避免在对话框退场动画期间释放控制器导致崩溃。
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.renameNotebook),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.pop(context, v),
        decoration: InputDecoration(
          labelText: l10n.fileName,
          hintText: l10n.fileNameHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
