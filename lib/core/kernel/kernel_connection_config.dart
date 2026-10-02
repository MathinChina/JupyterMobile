import 'dart:convert';

import 'kernel_source.dart';

/// 内核连接配置：连接界面唯一需要收集并持久化的数据。
///
/// 远程与「本机 Termux」共用同一份结构——区别只在 [host] 是否强制为
/// 127.0.0.1。将来内置 Python 甚至不需要 host/port，但为了接口统一，
/// 仍保留这些字段（此时由 Provider 忽略）。
class KernelConnectionConfig {
  const KernelConnectionConfig({
    required this.source,
    required this.host,
    required this.port,
    required this.token,
  });

  final KernelSource source;
  final String host;
  final int port;
  final String token;

  /// 形如 `http://127.0.0.1:8888`。
  String get baseUrl => 'http://$host:$port';

  Map<String, dynamic> toJson() => {
        'source': source.name,
        'host': host,
        'port': port,
        'token': token,
      };

  factory KernelConnectionConfig.fromJson(Map<String, dynamic> json) {
    return KernelConnectionConfig(
      source: KernelSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => KernelSource.external,
      ),
      host: json['host'] as String? ?? '127.0.0.1',
      port: json['port'] as int? ?? 8888,
      token: json['token'] as String? ?? '',
    );
  }

  /// 默认值：本机 Termux + 8888 端口。
  static const defaults = KernelConnectionConfig(
    source: KernelSource.external,
    host: '127.0.0.1',
    port: 8888,
    token: '',
  );

  KernelConnectionConfig copyWith({
    KernelSource? source,
    String? host,
    int? port,
    String? token,
  }) {
    return KernelConnectionConfig(
      source: source ?? this.source,
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KernelConnectionConfig &&
      other.source == source &&
      other.host == host &&
      other.port == port &&
      other.token == token;

  @override
  int get hashCode => Object.hash(source, host, port, token);

  /// 序列化为 JSON 字符串（持久化用）。
  String encode() => jsonEncode(toJson());

  /// 从 JSON 字符串反序列化。
  static KernelConnectionConfig decode(String s) =>
      KernelConnectionConfig.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
