/// 内核连接层对外发出的流式事件。
///
/// 前端只消费这一个事件流。新增事件类型是「向后兼容的扩展」，不会破坏
/// 已有消费方。这些类型对应 Jupyter Messaging Protocol v5 的 IOPub 消息。
sealed class KernelEvent {
  const KernelEvent();
}

/// 内核状态变化（idle / busy / starting / dead ...）。
class KernelStatusEvent extends KernelEvent {
  const KernelStatusEvent(this.status);

  /// 执行状态：'idle'、'busy'、'starting'、'dead' 等。
  final String status;
}

/// stdout / stderr 流输出。
class KernelStreamEvent extends KernelEvent {
  const KernelStreamEvent(this.name, this.text);

  /// 'stdout' 或 'stderr'。
  final String name;
  final String text;
}

/// `display_data` 消息：富媒体输出（MIME bundle）。
class KernelDisplayDataEvent extends KernelEvent {
  const KernelDisplayDataEvent(this.data, [this.metadata = const {}]);

  /// MIME 类型 -> 内容，例如 {'text/html': '...', 'image/png': '...'}。
  final Map<String, dynamic> data;
  final Map<String, dynamic> metadata;
}

/// `execute_result` 消息：表达式求值结果。
class KernelExecuteResultEvent extends KernelEvent {
  const KernelExecuteResultEvent(this.data, this.executionCount,
      [this.metadata = const {}]);

  final Map<String, dynamic> data;
  final int? executionCount;
  final Map<String, dynamic> metadata;
}

/// `error` 消息：执行出错。
class KernelErrorEvent extends KernelEvent {
  const KernelErrorEvent(this.ename, this.evalue, this.traceback);

  /// 异常类型名，例如 'ZeroDivisionError'。
  final String ename;

  /// 异常描述。
  final String evalue;

  /// 逐行 traceback。
  final List<String> traceback;
}

/// 连接层自身的异常（区别于内核执行错误）。
class KernelConnectionException implements Exception {
  const KernelConnectionException(this.message);

  final String message;

  @override
  String toString() => 'KernelConnectionException: $message';
}
