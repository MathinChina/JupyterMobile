import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/kernel/kernel_connection.dart';
import '../core/kernel/kernel_connection_config.dart';
import '../core/kernel/kernel_event.dart';
import '../core/kernel/kernel_source.dart';
import '../providers/external_kernel_provider.dart';
import '../providers/remote_kernel_provider.dart';
import 'connection_persistence.dart';

/// 连接配置持久化实例。
final connectionPersistenceProvider =
    Provider<ConnectionPersistence>((ref) => ConnectionPersistence());

/// 内核连接工厂：连接界面只依赖它，不直接 import 具体 Provider。
///
/// 这是「前端只依赖统一接口」的落点——将来加 BundledKernelProvider
/// 只需在 switch 里加一个分支。
final kernelConnectionFactoryProvider =
    Provider<KernelConnectionFactory>((ref) {
  return (KernelConnectionConfig config) {
    return switch (config.source) {
      KernelSource.remote => RemoteKernelProvider(config),
      KernelSource.external => ExternalKernelProvider(config),
      KernelSource.bundled =>
        throw UnimplementedError('内置 Python（阶段⑥）尚未实现'),
    };
  };
});

/// 连接流程的界面状态。
sealed class ConnectionUiState {
  const ConnectionUiState();
}

class ConnectionIdle extends ConnectionUiState {
  const ConnectionIdle();
}

class ConnectionConnecting extends ConnectionUiState {
  const ConnectionConnecting();
}

class ConnectionConnected extends ConnectionUiState {
  const ConnectionConnected(this.connection);
  final KernelConnection connection;
}

class ConnectionError extends ConnectionUiState {
  const ConnectionError(this.message);
  final String message;
}

/// 连接流程控制器。
class ConnectionController extends Notifier<ConnectionUiState> {
  @override
  ConnectionUiState build() => const ConnectionIdle();

  /// 发起连接，成功返回 true。
  Future<bool> connect(KernelConnectionConfig config) async {
    state = const ConnectionConnecting();
    final factory = ref.read(kernelConnectionFactoryProvider);
    final connection = factory(config);
    try {
      await connection.connect();
      state = ConnectionConnected(connection);
      return true;
    } on KernelConnectionException catch (e) {
      state = ConnectionError(e.message);
      return false;
    } catch (e) {
      state = ConnectionError('未知错误：$e');
      return false;
    }
  }

  void reset() => state = const ConnectionIdle();
}

final connectionControllerProvider =
    NotifierProvider<ConnectionController, ConnectionUiState>(
        ConnectionController.new);
