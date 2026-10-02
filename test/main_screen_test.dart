import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jupyter_mobile/core/kernel/kernel_connection.dart';
import 'package:jupyter_mobile/core/kernel/kernel_connection_config.dart';
import 'package:jupyter_mobile/core/kernel/kernel_event.dart';
import 'package:jupyter_mobile/core/kernel/kernel_source.dart';
import 'package:jupyter_mobile/ui/main_screen.dart';

class _FakeConnection implements KernelConnection {
  @override
  KernelConnectionConfig get config => const KernelConnectionConfig(
        source: KernelSource.external,
        host: '127.0.0.1',
        port: 8888,
        token: '',
      );

  @override
  bool get isConnected => true;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<KernelEvent> execute(String code) => const Stream.empty();

  @override
  Future<void> interrupt() async {}

  @override
  Future<void> restart() async {}

  @override
  Future<void> shutdown() async {}

  @override
  Stream<KernelStatusEvent> get statusStream => const Stream.empty();
}

void main() {
  testWidgets('主界面 notebook 渲染 + 添加代码单元 smoke test',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: MainScreen(connection: _FakeConnection())),
      ),
    );
    await tester.pumpAndSettle();

    // 初始 markdown cell 的标题渲染。
    expect(find.text('新 Notebook'), findsWidgets);
    // 顶部/底部工具按钮。
    expect(find.text('代码'), findsWidgets);
    expect(find.text('Markdown'), findsWidgets);
    // 初始只有 1 个运行按钮（markdown cell 无运行按钮）。
    expect(find.byIcon(Icons.play_arrow), findsNothing);

    // 添加一个代码单元。
    await tester.tap(find.widgetWithText(OutlinedButton, '代码'));
    await tester.pumpAndSettle();

    // 新增 code cell 后出现运行按钮（play_arrow）。
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });
}
