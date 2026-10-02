import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jupyter_mobile/core/notebook/notebook.dart';

void main() {
  const sample = '''
{
  "cells": [
    {
      "cell_type": "markdown",
      "metadata": {},
      "source": ["# 标题\\n", "\\n", "这是 **markdown**"]
    },
    {
      "cell_type": "code",
      "execution_count": 1,
      "metadata": {"collapsed": false},
      "source": ["print('hello')\\n", "1 + 1"],
      "outputs": [
        {
          "output_type": "stream",
          "name": "stdout",
          "text": ["hello\\n"]
        },
        {
          "output_type": "execute_result",
          "execution_count": 1,
          "data": {"text/plain": "2"},
          "metadata": {}
        }
      ]
    },
    {
      "cell_type": "code",
      "execution_count": 2,
      "metadata": {},
      "source": ["1 / 0"],
      "outputs": [
        {
          "output_type": "error",
          "ename": "ZeroDivisionError",
          "evalue": "division by zero",
          "traceback": ["Traceback...", "ZeroDivisionError: division by zero"]
        }
      ]
    }
  ],
  "metadata": {
    "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
    "language_info": {"name": "python"}
  },
  "nbformat": 4,
  "nbformat_minor": 5
}
''';

  test('解析真实 nbformat 结构', () {
    final doc = NotebookDocument.parse(sample);

    expect(doc.nbformat, 4);
    expect(doc.nbformatMinor, 5);
    expect(doc.cells.length, 3);

    final markdown = doc.cells[0];
    expect(markdown, isA<MarkdownCell>());
    expect(markdown.source, '# 标题\n\n这是 **markdown**');

    final code = doc.cells[1] as CodeCell;
    expect(code.source, "print('hello')\n1 + 1");
    expect(code.executionCount, 1);
    expect(code.metadata['collapsed'], false);
    expect(code.outputs.length, 2);
    expect(code.outputs[0], isA<StreamOutput>());
    expect((code.outputs[0] as StreamOutput).text, 'hello\n');
    expect(code.outputs[1], isA<ExecuteResultOutput>());
    expect((code.outputs[1] as ExecuteResultOutput).data['text/plain'], '2');

    final error = doc.cells[2] as CodeCell;
    expect(error.outputs[0], isA<ErrorOutput>());
    expect((error.outputs[0] as ErrorOutput).ename, 'ZeroDivisionError');
  });

  test('序列化往返无损', () {
    final doc = NotebookDocument.parse(sample);
    final encoded = doc.encode();
    final decoded = NotebookDocument.parse(encoded);

    expect(decoded.cells.length, doc.cells.length);
    // 逐 cell 对比 source 与类型。
    for (var i = 0; i < doc.cells.length; i++) {
      expect(decoded.cells[i].runtimeType, doc.cells[i].runtimeType);
      expect(decoded.cells[i].source, doc.cells[i].source);
    }
    final code1 = decoded.cells[1] as CodeCell;
    expect(code1.outputs.length, 2);
    expect((code1.outputs[0] as StreamOutput).text, 'hello\n');
    expect((code1.outputs[1] as ExecuteResultOutput).data['text/plain'], '2');
  });

  test('sourceToList 无损往返（含末尾换行/空串）', () {
    expect(sourceToList(''), const []);
    expect(sourceToList('abc'), ['abc']);
    expect(sourceToList('a\nb'), ['a\n', 'b']);
    expect(sourceToList('a\n'), ['a\n', '']);
    expect(sourceToList('a\n\nb'), ['a\n', '\n', 'b']);
    // 反向验证：join 后等于原串。
    for (final s in ['', 'abc', 'a\nb', 'a\n', 'a\n\nb', '尾行无换行']) {
      expect(sourceToList(s).join(), s);
    }
  });

  test('空 notebook 与 cell 编辑', () {
    final doc = NotebookDocument.empty();
    expect(doc.cells, isEmpty);
    expect(doc.metadata['kernelspec']['name'], 'python3');

    final cell = CodeCell(
      id: notebookNewId(),
      metadata: const {},
      source: 'x = 1',
    );
    expect(cell.cellType, 'code');
    cell.setSource('x = 2');
    expect(cell.source, 'x = 2');
    doc.cells.add(cell);
    expect(doc.cells.length, 1);

    // id 必须是标准 UUID 格式。
    expect(cell.id, matches(RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
  });

  test('容错：缺失字段不崩溃', () {
    final doc = NotebookDocument.parse(
        jsonEncode({'cells': [{'cell_type': 'code', 'source': '1'}], 'nbformat': 4}));
    expect(doc.cells.length, 1);
    expect(doc.cells[0], isA<CodeCell>());
    expect(doc.nbformatMinor, 5);
    expect(doc.metadata, isEmpty);
  });
}
