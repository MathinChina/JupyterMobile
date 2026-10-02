import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jupyter_mobile/core/notebook/notebook.dart';
import 'package:jupyter_mobile/ui/widgets/cell_output_view.dart';
import 'package:jupyter_mobile/ui/widgets/code_highlight.dart';

void main() {
  testWidgets('CellOutputView 渲染各 MIME 类型不崩溃', (WidgetTester tester) async {
    final outputs = <CellOutput>[
      const StreamOutput(name: 'stdout', text: 'hello\n'),
      const ExecuteResultOutput(
        data: {'text/plain': '2'},
        executionCount: 1,
      ),
      const DisplayDataOutput(data: {
        'text/markdown': '**加粗** 文本',
      }),
      const DisplayDataOutput(data: {
        'image/svg+xml':
            '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10" fill="red"/></svg>',
      }),
      const ErrorOutput(
        ename: 'ValueError',
        evalue: 'boom',
        traceback: ['Traceback', 'ValueError: boom'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final o in outputs) CellOutputView(output: o),
            ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // 纯文本、错误、markdown 内容应能渲染出来。
    expect(find.text('hello\n'), findsOneWidget);
    expect(find.text('Out[1]: 2'), findsOneWidget);
    expect(find.textContaining('加粗'), findsWidgets);
    expect(find.textContaining('ValueError: boom'), findsOneWidget);
    // SVG 渲染成功（无异常即通过）。
  });

  test('CodeHighlight 高亮含关键字/字符串/注释的代码', () {
    final span = CodeHighlight.highlightCode('import os\nx = 1  # comment');
    final text = span.toPlainText();
    expect(text, 'import os\nx = 1  # comment');
    // 应产生多个着色节点（不是单一纯文本 span）。
    expect(span.children, isNotNull);
    expect(span.children!.length, greaterThan(1));
  });
}
