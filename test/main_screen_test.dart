import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jupyter_mobile/core/kernel/kernel_connection.dart';
import 'package:jupyter_mobile/core/kernel/kernel_connection_config.dart';
import 'package:jupyter_mobile/core/kernel/kernel_event.dart';
import 'package:jupyter_mobile/core/kernel/kernel_source.dart';
import 'package:jupyter_mobile/l10n/gen/app_localizations.dart';
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

/// 记录 execute 调用并返回受控流式事件的连接，用于扩展管理测试。
class _StreamingConnection extends _FakeConnection {
  _StreamingConnection(this.stream);

  final Stream<KernelEvent> stream;
  final List<String> executedCodes = [];

  @override
  Stream<KernelEvent> execute(String code) {
    executedCodes.add(code);
    return stream;
  }
}

void main() {
  testWidgets('主界面 notebook 渲染 + 添加代码单元 smoke test',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainScreen(connection: _FakeConnection()),
        ),
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

  testWidgets('重命名 notebook 文件名', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainScreen(connection: _FakeConnection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 初始标题为本地化默认名。
    expect(find.text('未命名.ipynb'), findsOneWidget);

    // 点击标题打开重命名对话框。
    await tester.tap(find.text('未命名.ipynb'));
    await tester.pumpAndSettle();
    expect(find.text('重命名 Notebook'), findsOneWidget);

    // 输入不带后缀的名字，确定后自动补 .ipynb。
    await tester.enterText(find.byType(TextField), '分析');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('分析.ipynb'), findsOneWidget);
  });

  testWidgets('扩展管理：pip 包安装流式显示输出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final conn = _StreamingConnection(
      Stream.fromIterable(const [
        KernelStreamEvent('stdout', 'Collecting numpy\n'),
        KernelStreamEvent('stdout', 'Successfully installed numpy\n'),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainScreen(connection: conn),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 打开菜单 → 扩展管理。
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('扩展管理'));
    await tester.pumpAndSettle();
    expect(find.text('安装 Python 包'), findsOneWidget);

    // 输入包名并安装。
    await tester.enterText(find.byType(TextField), 'numpy');
    await tester.tap(find.text('安装'));
    await tester.pump();

    // 验证 execute 收到 pip install 命令。
    expect(conn.executedCodes, hasLength(1));
    expect(conn.executedCodes.single, contains('pip install'));
    expect(conn.executedCodes.single, contains('numpy'));

    // 流式输出被追加显示。
    expect(find.textContaining('Successfully installed numpy'), findsOneWidget);
  });
}
