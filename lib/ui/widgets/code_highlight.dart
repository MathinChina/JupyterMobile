import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

/// 把 Python 代码着色为 [TextSpan] 树。
///
/// 复用 highlight.js 的语法分析（`highlight` 包），自行把 [Node] 树
/// 映射成 Flutter 富文本。class 名对应一套简洁的配色表。
class CodeHighlight {
  CodeHighlight._();

  /// hljs 语义 class -> 颜色。
  static const Map<String, Color> _colors = {
    'keyword': Color(0xFF0000FF),
    'built_in': Color(0xFF0086B3),
    'string': Color(0xFFA31515),
    'number': Color(0xFF098658),
    'comment': Color(0xFF6A9955),
    'title': Color(0xFF795E26),
    'function': Color(0xFF795E26),
    'class': Color(0xFF267F99),
    'literal': Color(0xFF0000FF),
    'meta': Color(0xFF795E26),
    'params': Color(0xFF001080),
    'attribute': Color(0xFF001080),
    'decorator': Color(0xFFAF00DB),
    'operator': Color(0xFF000000),
  };

  /// 高亮并返回富文本 span。失败时回退为纯文本（不抛异常）。
  static TextSpan highlightCode(
    String code, {
    double fontSize = 13,
    Color baseColor = const Color(0xFF24292E),
    String language = 'python',
  }) {
    try {
      final result = highlight.parse(code, language: language);
      final nodes = result.nodes;
      if (nodes == null) return _plain(code, baseColor, fontSize);
      return TextSpan(
        style: TextStyle(
          fontFamily: 'DejaVuSansMono',
          fontSize: fontSize,
          color: baseColor,
        ),
        children: nodes.map((n) => _span(n)).toList(),
      );
    } catch (_) {
      return _plain(code, baseColor, fontSize);
    }
  }

  static TextSpan _plain(String code, Color color, double fontSize) {
    return TextSpan(
      text: code,
      style: TextStyle(
        fontFamily: 'DejaVuSansMono',
        fontSize: fontSize,
        color: color,
      ),
    );
  }

  static TextSpan _span(Node node) {
    final color = node.className == null
        ? null
        : _colors[node.className!];
    final style = color == null ? null : TextStyle(color: color);

    if (node.value != null) {
      return TextSpan(text: node.value, style: style);
    }
    if (node.children != null) {
      return TextSpan(
        style: style,
        children: node.children!.map(_span).toList(),
      );
    }
    return const TextSpan();
  }
}
