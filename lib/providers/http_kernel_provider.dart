import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/kernel/kernel_connection.dart';
import '../core/kernel/kernel_connection_config.dart';
import '../core/kernel/kernel_event.dart';
import '../core/kernel/jupyter_protocol.dart';

/// 所有「连 jupyter_server REST + WebSocket」的 Provider 的公共基类。
///
/// 三个来源（远程 / 本机 Termux / 将来内置）最终都收敛为同一件事——
/// 连一个 jupyter_server，因此公共逻辑收敛到这里，子类只做薄适配。
///
/// 阶段②实现 Jupyter Messaging Protocol v5 的 legacy WebSocket 通道：
/// REST 负责生命周期（列内核 / 建内核 / 重启），WS 负责消息收发。
abstract class HttpKernelProvider implements KernelConnection {
  HttpKernelProvider(this.config);

  @override
  final KernelConnectionConfig config;

  final JupyterProtocol _protocol = JupyterProtocol();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSub;

  bool _connected = false;
  String? _kernelId;

  final StreamController<KernelStatusEvent> _statusController =
      StreamController<KernelStatusEvent>.broadcast();

  /// 等待 shell 回复的请求：msg_id -> 事件流控制器。
  final Map<String, StreamController<KernelEvent>> _pending = {};

  /// 等待 kernel_info 握手的 Completer。
  Completer<void>? _infoCompleter;

  @override
  bool get isConnected => _connected;

  @override
  Stream<KernelStatusEvent> get statusStream => _statusController.stream;

  /// `GET /api/kernels?token=...` 返回的地址。
  Uri _restUri(String path) => Uri.parse(
      '${config.baseUrl}$path${path.contains('?') ? '&' : '?'}token=${config.token}');

  /// 连接：验证 REST 可达 → 选择/创建内核 → 建立 WS → kernel_info 握手。
  ///
  /// 任一步失败都抛出 [KernelConnectionException]，绝不给出假成功。
  @override
  Future<void> connect() async {
    try {
      final kernelId = await _ensureKernel();
      _kernelId = kernelId;
      await _openChannel(kernelId);
      _connected = true;
      _statusController.add(const KernelStatusEvent('connected'));
    } on KernelConnectionException {
      rethrow;
    } catch (e) {
      await _teardown();
      throw KernelConnectionException('Connection failed: $e');
    }
  }

  /// 选一个正在运行的 idle 内核，否则 POST 新建一个。
  Future<String> _ensureKernel() async {
    final listResp =
        await http.get(_restUri('/api/kernels')).timeout(const Duration(seconds: 8));
    if (listResp.statusCode == 401 || listResp.statusCode == 403) {
      throw const KernelConnectionException('Authentication failed: invalid or missing token');
    }
    if (listResp.statusCode != 200) {
      throw KernelConnectionException('Failed to list kernels (HTTP ${listResp.statusCode})');
    }
    final body = jsonDecode(listResp.body) as List<dynamic>;
    for (final k in body) {
      final kernel = k as Map<String, dynamic>;
      if (kernel['execution_state'] == 'idle') {
        return kernel['id'] as String;
      }
    }
    // 无可用内核则启动一个。
    final createResp = await http
        .post(_restUri('/api/kernels'))
        .timeout(const Duration(seconds: 12));
    if (createResp.statusCode == 201 || createResp.statusCode == 200) {
      final created = jsonDecode(createResp.body) as Map<String, dynamic>;
      return created['id'] as String;
    }
    if (createResp.statusCode == 401 || createResp.statusCode == 403) {
      throw const KernelConnectionException('Authentication failed: invalid or missing token');
    }
    throw KernelConnectionException('Failed to start kernel (HTTP ${createResp.statusCode})');
  }

  /// 建立 WS 并等待 kernel_info 握手。
  Future<void> _openChannel(String kernelId) async {
    final wsUri = Uri.parse(
      'ws://${config.host}:${config.port}/api/kernels/$kernelId/channels'
      '?session_id=${_protocol.session}&token=${config.token}',
    );
    final channel = WebSocketChannel.connect(wsUri);
    _channel = channel;
    _wsSub = channel.stream.listen(
      _onWsMessage,
      onError: (Object e) => _statusController.add(const KernelStatusEvent('error')),
      onDone: _onWsDone,
    );

    // 握手：发 kernel_info_request，等待 shell 上的 kernel_info_reply。
    _infoCompleter = Completer<void>();
    final info = _protocol.buildMessage(
      msgType: 'kernel_info_request',
      content: const <String, dynamic>{},
    );
    channel.sink.add(_protocol.encode('shell', info));
    await _infoCompleter!.future
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw KernelConnectionException('Kernel handshake timed out (no kernel_info reply)');
    });
  }

  void _onWsMessage(dynamic data) {
    final DecodedMessage msg;
    try {
      msg = JupyterProtocol.decode(data);
    } catch (_) {
      return; // 无法解析的消息直接忽略。
    }
    switch (msg.channel) {
      case 'iopub':
        _handleIopub(msg);
      case 'shell':
        _handleShell(msg);
      case 'control':
        break; // interrupt/shutdown 回复无需处理。
    }
  }

  void _onWsDone() {
    _connected = false;
    _statusController.add(const KernelStatusEvent('disconnected'));
    _failAllPending(const KernelConnectionException('Connection lost'));
  }

  void _handleIopub(DecodedMessage msg) {
    switch (msg.msgType) {
      case 'status':
        final status = msg.content['execution_state'] as String? ?? 'idle';
        _statusController.add(KernelStatusEvent(status));
        _emit(msg, KernelStatusEvent(status));
      case 'stream':
        _emit(
          msg,
          KernelStreamEvent(
            msg.content['name'] as String? ?? 'stdout',
            msg.content['text'] as String? ?? '',
          ),
        );
      case 'display_data':
        _emit(
          msg,
          KernelDisplayDataEvent(
            _asMap(msg.content['data']),
            _asMap(msg.content['metadata']),
          ),
        );
      case 'execute_result':
        final count = msg.content['execution_count'];
        _emit(
          msg,
          KernelExecuteResultEvent(
            _asMap(msg.content['data']),
            count is int ? count : null,
            _asMap(msg.content['metadata']),
          ),
        );
      case 'error':
        _emit(
          msg,
          KernelErrorEvent(
            msg.content['ename'] as String? ?? 'Error',
            msg.content['evalue'] as String? ?? '',
            (msg.content['traceback'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
          ),
        );
    }
  }

  void _handleShell(DecodedMessage msg) {
    if (msg.msgType == 'kernel_info_reply') {
      if (!(_infoCompleter?.isCompleted ?? true)) {
        _infoCompleter!.complete();
      }
      return;
    }
    if (msg.msgType == 'execute_reply') {
      final parentId = msg.parentMsgId;
      if (parentId != null) {
        final controller = _pending.remove(parentId);
        controller?.close();
      }
    }
  }

  /// 把 IOPub 事件投递给对应的 execute 流。
  void _emit(DecodedMessage msg, KernelEvent event) {
    final parentId = msg.parentMsgId;
    if (parentId != null) {
      _pending[parentId]?.add(event);
    }
  }

  void _failAllPending(KernelConnectionException e) {
    for (final controller in _pending.values) {
      controller.addError(e);
      controller.close();
    }
    _pending.clear();
  }

  void _send(String channel, Map<String, dynamic> message) {
    final ws = _channel;
    if (ws == null || !_connected) {
      throw const KernelConnectionException('Not connected to a kernel');
    }
    ws.sink.add(_protocol.encode(channel, message));
  }

  /// 执行代码，返回流式事件流。
  @override
  Stream<KernelEvent> execute(String code) {
    final msg = _protocol.buildMessage(
      msgType: 'execute_request',
      content: <String, dynamic>{
        'code': code,
        'silent': false,
        'store_history': true,
        'user_expressions': const <String, dynamic>{},
        'allow_stdin': false,
        'stop_on_error': true,
      },
    );
    final msgId = msg['header']['msg_id'] as String;
    final controller = StreamController<KernelEvent>();
    _pending[msgId] = controller;
    _send('shell', msg);
    return controller.stream;
  }

  @override
  Future<void> interrupt() async {
    final msg = _protocol.buildMessage(
      msgType: 'interrupt_request',
      content: const <String, dynamic>{},
    );
    _send('control', msg);
  }

  @override
  Future<void> restart() async {
    final kernelId = _kernelId;
    if (kernelId == null) return;
    final resp = await http
        .post(_restUri('/api/kernels/$kernelId/restart'))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        throw const KernelConnectionException('Authentication failed: invalid or missing token');
      }
      throw KernelConnectionException('Restart failed (HTTP ${resp.statusCode})');
    }
  }

  @override
  Future<void> shutdown() async {
    try {
      _send(
        'control',
        _protocol.buildMessage(
          msgType: 'shutdown_request',
          content: const <String, dynamic>{'restart': false},
        ),
      );
    } on KernelConnectionException {
      // 已断开则无需发送。
    }
    await _teardown();
  }

  @override
  Future<void> disconnect() async {
    await _teardown();
  }

  Future<void> _teardown() async {
    _connected = false;
    _failAllPending(const KernelConnectionException('Connection closed'));
    await _wsSub?.cancel();
    await _channel?.sink.close();
    _wsSub = null;
    _channel = null;
    _kernelId = null;
    if (!_statusController.isClosed) {
      _statusController.add(const KernelStatusEvent('disconnected'));
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }
}
