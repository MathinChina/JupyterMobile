import 'kernel_connection_config.dart';
import 'kernel_event.dart';

/// 内核连接抽象层（本大纲最重要的设计）。
///
/// 前端只依赖这个接口；「内核从哪来」由 [RemoteKernelProvider]、
/// [ExternalKernelProvider]、以及将来的 [BundledKernelProvider] 各自实现。
/// 三个实现最终都收敛为「连一个 jupyter_server 的 REST + WebSocket」，
/// 因此接口天然统一，扩展时前端零改动。
abstract class KernelConnection {
  /// 本次连接使用的配置。
  KernelConnectionConfig get config;

  /// 是否已连接（REST 可达 + token 有效）。
  bool get isConnected;

  /// 连接内核：先做 REST 连通性验证，再建立 WebSocket channels。
  ///
  /// 失败时抛出 [KernelConnectionException]。
  Future<void> connect();

  /// 断开连接并释放资源。
  Future<void> disconnect();

  /// 执行代码，返回流式事件流。
  ///
  /// 事件依次为 [KernelStatusEvent]（busy）、[KernelStreamEvent] /
  /// [KernelDisplayDataEvent] / [KernelExecuteResultEvent] / [KernelErrorEvent]、
  /// 最后 [KernelStatusEvent]（idle）。
  Stream<KernelEvent> execute(String code);

  /// 中断当前执行（发送 `interrupt_request`）。
  Future<void> interrupt();

  /// 重启内核。
  Future<void> restart();

  /// 关闭内核（发送 `shutdown_request`）。
  Future<void> shutdown();

  /// 内核状态流（idle / busy ...），用于界面显示执行状态。
  Stream<KernelStatusEvent> get statusStream;
}

/// 内核连接工厂：根据配置来源创建对应的 Provider 实现。
///
/// 连接界面只依赖这个工厂，不直接 import 具体 Provider 类，
/// 从而真正实现「前端只依赖统一接口」。
typedef KernelConnectionFactory =
    KernelConnection Function(KernelConnectionConfig config);
