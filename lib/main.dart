import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/connection_screen.dart';

void main() {
  runApp(const ProviderScope(child: JupyterMobileApp()));
}

class JupyterMobileApp extends StatelessWidget {
  const JupyterMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JupyterMobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Jupyter 品牌色。
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF37726)),
        useMaterial3: true,
      ),
      home: const ConnectionScreen(),
    );
  }
}
