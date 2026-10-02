import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jupyter_mobile/core/kernel/jupyter_protocol.dart';

/// 按 jupyter_server `serialize_binary_message` 的格式构造 binary 消息，
/// 验证我们的 [JupyterProtocol.decode] 能正确解析。
Uint8List _serializeBinaryMessage(Map<String, dynamic> msg, List<List<int>> buffers) {
  final jsonBytes = utf8.encode(jsonEncode(msg));
  final all = <List<int>>[jsonBytes, ...buffers];
  final nbufs = all.length;
  final offsets = <int>[4 * (nbufs + 1)];
  for (final buf in all.take(nbufs - 1)) {
    offsets.add(offsets.last + buf.length);
  }
  final header = ByteData(4 * (nbufs + 1));
  header.setUint32(0, nbufs, Endian.big);
  for (var i = 0; i < offsets.length; i++) {
    header.setUint32(4 + 4 * i, offsets[i], Endian.big);
  }
  return Uint8List.fromList([...header.buffer.asUint8List(), ...all.expand((b) => b)]);
}

void main() {
  test('buildMessage 生成合法 header', () {
    final proto = JupyterProtocol();
    final msg = proto.buildMessage(
      msgType: 'execute_request',
      content: const {'code': '1+1'},
    );
    final header = msg['header'] as Map<String, dynamic>;
    expect(header['msg_type'], 'execute_request');
    expect(header['version'], '5.3');
    expect(header['username'], isNotEmpty);
    expect(header['session'], proto.session);
    expect(header['msg_id'], isNotEmpty);
    expect(msg['content']['code'], '1+1');
  });

  test('encode 附加 channel 字段', () {
    final proto = JupyterProtocol();
    final msg = proto.buildMessage(
      msgType: 'kernel_info_request',
      content: const {},
    );
    final encoded = proto.encode('shell', msg);
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    expect(decoded['channel'], 'shell');
    expect(decoded['header']['msg_type'], 'kernel_info_request');
  });

  test('decode 解析 JSON 字符串消息', () {
    final raw = jsonEncode({
      'channel': 'iopub',
      'header': {'msg_type': 'status'},
      'parent_header': {'msg_id': 'parent-1'},
      'content': {'execution_state': 'busy'},
    });
    final msg = JupyterProtocol.decode(raw);
    expect(msg.channel, 'iopub');
    expect(msg.msgType, 'status');
    expect(msg.parentMsgId, 'parent-1');
    expect(msg.content['execution_state'], 'busy');
  });

  test('decode 解析带 buffers 的 binary 消息', () {
    final msg = {
      'channel': 'iopub',
      'header': {'msg_type': 'display_data'},
      'parent_header': {'msg_id': 'parent-2'},
      'metadata': {},
      'content': {'data': {'image/png': 'base64...'}},
    };
    final binary = _serializeBinaryMessage(msg, [
      [1, 2, 3, 4, 5],
    ]);
    final decoded = JupyterProtocol.decode(binary);
    expect(decoded.channel, 'iopub');
    expect(decoded.msgType, 'display_data');
    expect(decoded.parentMsgId, 'parent-2');
    expect(decoded.content['data']['image/png'], 'base64...');
    expect(decoded.buffers.length, 1);
    expect(decoded.buffers.first, [1, 2, 3, 4, 5]);
  });
}
