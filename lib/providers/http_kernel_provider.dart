import 'dart:async';

import 'package:http/http.dart' as http;

import '../core/kernel/kernel_connection.dart';
import '../core/kernel/kernel_connection_config.dart';
import '../core/kernel/kernel_event.dart';

/// 所有「连 jupyter_server REST + WebSocket」的 Provider 的公共基类。
///
/// 三个来源（远程 / 本机 Termux / 将来内置）最终都收敛为同一件事——
/// 连一个 jupyter_server，因此公共逻辑收敛到这里，子类只做薄适配。
abstract class HttpKernelProvider implements KernelConnection {
  HttpKernelProvider(this.config);

  @override
  final KernelConnectionConfig config;

  bool _connected = false;

  final StreamController<KernelStatusEvent> _statusController =
      StreamController<KernelStatusEvent>.broadcast();

  @override
  bool get isConnected => _connected;

  @override
  Stream<KernelStatusEvent> get statusStream => _statusController.stream;

  /// 连接：先用 REST 做最小连通性验证（服务在跑 + token 有效）。
  ///
  /// 真正的 WebSocket channels 建立属于阶段②协议实现；这里先验证 REST
  /// 可达，避免界面给出「假连接成功」。
  @override
  Future<void> connect() async {
    final url = Uri.parse('${config.baseUrl}/api/kernels?token=${config.token}');
    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        _connected = true;
        _statusController.add(const KernelStatusEvent('connected'));
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        throw const KernelConnectionException('认证失败：token 无效或缺失');
      } else {
        throw KernelConnectionException('连接失败 (HTTP ${resp.statusCode})');
      }
    } on KernelConnectionException {
      rethrow;
    } catch (e) {
      throw KernelConnectionException('无法连接到 ${config.baseUrl}：$e');
    }
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _statusController.add(const KernelStatusEvent('disconnected'));
    await _statusController.close();
  }

  // 以下协议方法属于阶段②（手写 Jupyter Messaging Protocol v5）。
  // 目前尚未实现，明确抛出而非返回假成功。
  @override
  Stream<KernelEvent> execute(String code) {
    throw UnimplementedError('execute() 待阶段② WebSocket 协议实现');
  }

  @override
  Future<void> interrupt() {
    throw UnimplementedError('interrupt() 待阶段② WebSocket 协议实现');
  }

  @override
  Future<void> restart() {
    throw UnimplementedError('restart() 待阶段② WebSocket 协议实现');
  }

  @override
  Future<void> shutdown() {
    throw UnimplementedError('shutdown() 待阶段② WebSocket 协议实现');
  }
}
