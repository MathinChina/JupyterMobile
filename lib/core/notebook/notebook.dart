import 'dart:convert';
import 'dart:math';

/// nbformat（Jupyter Notebook 文件格式）的数据模型与解析/序列化。
///
/// 严格对齐 nbformat 4.x 的 JSON 结构，保证解析出的 .ipynb 能被
/// Jupyter 打开、序列化结果能被 Jupyter 读取。
/// 内部 `source` 统一用完整字符串，序列化时按行无损拆分回 `List<String>`。

/// 生成标准 UUID v4（nbformat 4.5+ 的 cell `id` 字段）。
String notebookNewId() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// cell 基类。
sealed class NotebookCell {
  NotebookCell({
    required this.id,
    required this.metadata,
    required this.source,
  });

  final String id;
  final Map<String, dynamic> metadata;
  String source;

  /// 编辑用：替换源文本。
  void setSource(String value) => source = value;

  Map<String, dynamic> toJson() => {
        'id': id,
        'cell_type': cellType,
        'metadata': metadata,
        'source': sourceToList(source),
      };

  String get cellType;
}

class MarkdownCell extends NotebookCell {
  MarkdownCell({
    required super.id,
    required super.metadata,
    required super.source,
  });

  @override
  String get cellType => 'markdown';
}

class RawCell extends NotebookCell {
  RawCell({
    required super.id,
    required super.metadata,
    required super.source,
  });

  @override
  String get cellType => 'raw';
}

class CodeCell extends NotebookCell {
  CodeCell({
    required super.id,
    required super.metadata,
    required super.source,
    this.executionCount,
    List<CellOutput> outputs = const [],
  }) : outputs = List.of(outputs);

  int? executionCount;
  final List<CellOutput> outputs;

  @override
  String get cellType => 'code';

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'execution_count': executionCount,
        'outputs': outputs.map((o) => o.toJson()).toList(),
      };
}

/// cell 输出基类。
sealed class CellOutput {
  const CellOutput();

  Map<String, dynamic> toJson();
}

/// `stream`：stdout/stderr 文本流。
class StreamOutput extends CellOutput {
  const StreamOutput({required this.name, required this.text});

  final String name;
  final String text;

  @override
  Map<String, dynamic> toJson() => {
        'output_type': 'stream',
        'name': name,
        'text': sourceToList(text),
      };
}

/// `execute_result`：表达式求值结果。
class ExecuteResultOutput extends CellOutput {
  const ExecuteResultOutput({
    required this.data,
    required this.executionCount,
    this.metadata = const {},
  });

  final Map<String, dynamic> data;
  final int? executionCount;
  final Map<String, dynamic> metadata;

  @override
  Map<String, dynamic> toJson() => {
        'output_type': 'execute_result',
        'execution_count': executionCount,
        'data': data,
        'metadata': metadata,
      };
}

/// `display_data`：富媒体输出（图片/HTML 等）。
class DisplayDataOutput extends CellOutput {
  const DisplayDataOutput({required this.data, this.metadata = const {}});

  final Map<String, dynamic> data;
  final Map<String, dynamic> metadata;

  @override
  Map<String, dynamic> toJson() => {
        'output_type': 'display_data',
        'data': data,
        'metadata': metadata,
      };
}

/// `error`：执行出错。
class ErrorOutput extends CellOutput {
  const ErrorOutput({
    required this.ename,
    required this.evalue,
    required this.traceback,
  });

  final String ename;
  final String evalue;
  final List<String> traceback;

  @override
  Map<String, dynamic> toJson() => {
        'output_type': 'error',
        'ename': ename,
        'evalue': evalue,
        'traceback': traceback,
      };
}

/// 一个完整的 notebook 文档。
class NotebookDocument {
  NotebookDocument({
    required this.nbformat,
    required this.nbformatMinor,
    required this.metadata,
    required this.cells,
  });

  int nbformat;
  int nbformatMinor;
  Map<String, dynamic> metadata;
  final List<NotebookCell> cells;

  /// 解析 .ipynb JSON 字符串。
  ///
  /// 对缺失字段做宽容处理，但不会吞掉结构错误（抛 [FormatException]）。
  factory NotebookDocument.parse(String json) {
    final root = jsonDecode(json) as Map<String, dynamic>;
    return NotebookDocument(
      nbformat: root['nbformat'] as int? ?? 4,
      nbformatMinor: root['nbformat_minor'] as int? ?? 5,
      metadata: _asMap(root['metadata']),
      cells: (root['cells'] as List? ?? const [])
          .map((c) => parseCell(c as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 序列化为 .ipynb JSON 字符串。
  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  Map<String, dynamic> toJson() => {
        'cells': cells.map((c) => c.toJson()).toList(),
        'metadata': metadata,
        'nbformat': nbformat,
        'nbformat_minor': nbformatMinor,
      };

  /// 新建一个空 notebook（含默认 kernelspec，指向 Python 3）。
  factory NotebookDocument.empty() {
    return NotebookDocument(
      nbformat: 4,
      nbformatMinor: 5,
      metadata: {
        'kernelspec': {
          'display_name': 'Python 3',
          'language': 'python',
          'name': 'python3',
        },
        'language_info': {'name': 'python'},
      },
      cells: [],
    );
  }
}

/// 解析单个 cell。
NotebookCell parseCell(Map<String, dynamic> map) {
  final type = map['cell_type'] as String? ?? 'code';
  final source = listToSource(map['source']);
  final metadata = _asMap(map['metadata']);
  final id = map['id'] as String? ?? notebookNewId();

  switch (type) {
    case 'markdown':
      return MarkdownCell(id: id, metadata: metadata, source: source);
    case 'raw':
      return RawCell(id: id, metadata: metadata, source: source);
    case 'code':
      return CodeCell(
        id: id,
        metadata: metadata,
        source: source,
        executionCount: map['execution_count'] as int?,
        outputs: (map['outputs'] as List? ?? const [])
            .map((o) => parseOutput(o as Map<String, dynamic>))
            .toList(),
      );
    default:
      // 未知类型按 raw 处理，保证不丢数据。
      return RawCell(id: id, metadata: metadata, source: source);
  }
}

/// 解析单个 output。
CellOutput parseOutput(Map<String, dynamic> map) {
  final type = map['output_type'] as String? ?? '';
  switch (type) {
    case 'stream':
      return StreamOutput(
        name: map['name'] as String? ?? 'stdout',
        text: listToSource(map['text']),
      );
    case 'execute_result':
      return ExecuteResultOutput(
        data: _asMap(map['data']),
        executionCount: map['execution_count'] as int?,
        metadata: _asMap(map['metadata']),
      );
    case 'display_data':
      return DisplayDataOutput(
        data: _asMap(map['data']),
        metadata: _asMap(map['metadata']),
      );
    case 'error':
      return ErrorOutput(
        ename: map['ename'] as String? ?? 'Error',
        evalue: map['evalue'] as String? ?? '',
        traceback: (map['traceback'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
    default:
      // 未知输出类型：保留原始数据，避免丢失。
      return DisplayDataOutput(data: _asMap(map['data']));
  }
}

/// nbformat 的 source/text 是 `List<String>`（每行一个，可能带换行符）。
String listToSource(Object? value) {
  if (value is List) {
    return value.map((e) => e.toString()).join();
  }
  if (value is String) return value;
  return '';
}

/// 把完整字符串无损拆回 `List<String>`。
///
/// 规则：每行（除最后一行）末尾补 `\n`；末尾换行保留为空串；空串返回空列表。
List<String> sourceToList(String source) {
  if (source.isEmpty) return const [];
  final lines = source.split('\n');
  final result = <String>[];
  for (var i = 0; i < lines.length; i++) {
    result.add(i == lines.length - 1 ? lines[i] : '${lines[i]}\n');
  }
  return result;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return const {};
}
