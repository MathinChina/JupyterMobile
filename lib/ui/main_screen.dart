import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/kernel/kernel_connection.dart';
import '../state/connection_providers.dart';

/// 主界面占位：连接成功后的落点。
///
/// 阶段①（解析/渲染/编辑）与阶段②（代码执行）将在这里展开。
/// 目前仅展示连接状态与断开入口。
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key, required this.connection});

  final KernelConnection connection;

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    await connection.disconnect();
    ref.read(connectionControllerProvider.notifier).reset();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JupyterMobile'),
        actions: [
          IconButton(
            tooltip: '断开连接',
            icon: const Icon(Icons.power_settings_new),
            onPressed: () => _disconnect(context, ref),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                '已连接到内核',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                connection.config.baseUrl,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Text(
                'notebook 编辑与代码执行将在阶段①/②实现',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
