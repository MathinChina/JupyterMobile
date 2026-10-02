import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jupyter_mobile/main.dart';

void main() {
  testWidgets('连接界面渲染 smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'locale_preference': 'zh'});

    // 连接界面内容较高，用更高的视口让底部按钮完整可见。
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: JupyterMobileApp()),
    );
    await tester.pumpAndSettle();

    // 标题与连接按钮应存在。
    expect(find.text('JupyterMobile'), findsWidgets);
    expect(find.text('内核来源'), findsOneWidget);
    expect(find.text('连接'), findsOneWidget);
  });

  testWidgets('赞助页：从连接界面进入并展示赞助链接', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'locale_preference': 'zh'});

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: JupyterMobileApp()),
    );
    await tester.pumpAndSettle();

    // 点击标题行右侧的赞助爱心按钮。
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();

    // 赞助页标题与文案。
    expect(find.text('赞助支持'), findsOneWidget);
    expect(find.text('Buy Me a Coffee'), findsOneWidget);
    expect(find.text('B站充电'), findsOneWidget);

    // 不再打包收款码图片，赞助页不应出现图片资产。
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('令牌可随机生成且非空', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'locale_preference': 'zh'});

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: JupyterMobileApp()),
    );
    await tester.pumpAndSettle();

    // 令牌输入框初始即填入随机令牌（32 位 hex）。
    final tokenField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (w) => w is TextField && w.obscureText == true,
      ),
    );
    expect(tokenField.controller!.text, isNotEmpty);
    expect(tokenField.controller!.text.length, 32);

    // 点击「随机生成」按钮后令牌仍为 32 位 hex。
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(tokenField.controller!.text.length, 32);
  });
}
