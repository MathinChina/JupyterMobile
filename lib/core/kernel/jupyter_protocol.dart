import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Jupyter Messaging Protocol v5 的 WebSocket「legacy」协议编解码。
///
/// jupyter_server 的 legacy WebSocket 通道（客户端不协商
/// `v1.kernel.websocket.jupyter.org` 子协议时）约定：
/// - 客户端 → 服务端：JSON 字符串 `{channel, header, parent_header, metadata,
///   content}`，**不含 HMAC 签名**（签名由服务端在 ZMQ 层自行补上）。
/// - 服务端 → 客户端：无 buffers 时为 JSON 字符串；带 buffers 时为 binary
///   （`serialize_binary_message` 的 offset 头格式）。
class JupyterProtocol {
  static const protocolVersion = '5.3';
  static const _username = 'jupyter_mobile';
  static final Random _random = Random.secure();

  /// 本次 WS 会话的 session 标识，也作为 `session_id` 查询参数。
  final String session;

  JupyterProtocol() : session = _newId();

  static String _newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 生成新的 `msg_id`。
  String newMsgId() => _newId();

  /// 构建一条不带 channel 的消息体（channel 在发送时由 [encode] 附加）。
  Map<String, dynamic> buildMessage({
    required String msgType,
    required Map<String, dynamic> content,
    Map<String, dynamic>? parentHeader,
    Map<String, dynamic> metadata = const {},
  }) {
    return {
      'header': {
        'msg_id': newMsgId(),
        'username': _username,
        'session': session,
        'date': DateTime.now().toUtc().toIso8601String(),
        'msg_type': msgType,
        'version': protocolVersion,
      },
      'parent_header': parentHeader ?? const <String, dynamic>{},
      'metadata': metadata,
      'content': content,
    };
  }

  /// 编码发送消息（附加 channel 字段）。
  String encode(String channel, Map<String, dynamic> message) {
    return jsonEncode(<String, dynamic>{...message, 'channel': channel});
  }

  /// 解码服务端消息。
  static DecodedMessage decode(Object data) {
    if (data is String) {
      return DecodedMessage.fromMap(jsonDecode(data) as Map<String, dynamic>);
    }
    // binary：`serialize_binary_message` 的 offset 头格式。
    final bytes = data is Uint8List ? data : Uint8List.fromList(data as List<int>);
    final byteData = ByteData.sublistView(bytes);
    final nbufs = byteData.getUint32(0, Endian.big);
    final offsets = <int>[
      for (var i = 0; i < nbufs; i++) byteData.getUint32(4 + 4 * i, Endian.big),
    ];
    if (nbufs < 2 || offsets.length < 2) {
      // 服务端不会发送 nbufs<2 的 binary；防御性当作纯 JSON 处理。
      return DecodedMessage.fromMap(
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
    }
    final jsonBytes = bytes.sublist(offsets[0], offsets[1]);
    final map = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
    final buffers = <List<int>>[
      for (var i = 1; i < nbufs; i++)
        bytes.sublist(offsets[i], i + 1 < nbufs ? offsets[i + 1] : bytes.length),
    ];
    map['buffers'] = buffers;
    return DecodedMessage.fromMap(map);
  }
}

/// 已解码的服务端消息。
class DecodedMessage {
  DecodedMessage({
    required this.channel,
    required this.header,
    required this.parentHeader,
    required this.content,
    required this.buffers,
  });

  factory DecodedMessage.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> asMap(Object? v) =>
        (v is Map) ? v.map((k, e) => MapEntry(k.toString(), e)) : const {};
    return DecodedMessage(
      channel: map['channel'] as String? ?? '',
      header: asMap(map['header']),
      parentHeader: asMap(map['parent_header']),
      content: asMap(map['content']),
      buffers: (map['buffers'] as List?)
              ?.map((b) => List<int>.from(b as List))
              .toList() ??
          const [],
    );
  }

  final String channel;
  final Map<String, dynamic> header;
  final Map<String, dynamic> parentHeader;
  final Map<String, dynamic> content;
  final List<List<int>> buffers;

  String get msgType => header['msg_type'] as String? ?? '';
  String? get parentMsgId => parentHeader['msg_id'] as String?;
}
