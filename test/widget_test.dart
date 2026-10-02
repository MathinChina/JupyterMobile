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
}
