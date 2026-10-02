import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/notebook/notebook.dart';
import '../../l10n/gen/app_localizations.dart';

/// 渲染单个 [CellOutput]，按 MIME 优先级选择最「丰富」的可渲染形式。
///
/// 优先级（从高到低）：text/html > image/png > image/jpeg > image/svg+xml
/// > text/latex > text/markdown > text/plain。
class CellOutputView extends StatelessWidget {
  const CellOutputView({super.key, required this.output});

  final CellOutput output;

  @override
  Widget build(BuildContext context) {
    return switch (output) {
      StreamOutput(:final name, :final text) => _mono(
          text,
          color: name == 'stderr'
              ? Theme.of(context).colorScheme.error
              : Colors.black87,
        ),
      ErrorOutput(:final ename, :final evalue, :final traceback) => _mono(
          traceback.isEmpty ? '$ename: $evalue' : traceback.join('\n'),
          color: Theme.of(context).colorScheme.error,
        ),
      ExecuteResultOutput(:final data, :final executionCount) =>
        _renderData(context, data, prefix: 'Out[$executionCount]: '),
      DisplayDataOutput(:final data) => _renderData(context, data),
    };
  }

  Widget _renderData(
    BuildContext context,
    Map<String, dynamic> data, {
    String? prefix,
  }) {
    // text/html：内嵌 WebView 渲染（固定高度，可内部滚动）。
    if (data['text/html'] != null) {
      return _HtmlView(html: data['text/html'].toString());
    }
    if (data['image/png'] != null) {
      return _safeImage(context, () => base64Decode(data['image/png'].toString()),
          gaplessPlayback: true);
    }
    if (data['image/jpeg'] != null) {
      return _safeImage(context, () => base64Decode(data['image/jpeg'].toString()));
    }
    if (data['image/svg+xml'] != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SvgPicture.string(data['image/svg+xml'].toString()),
      );
    }
    if (data['text/latex'] != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _LatexView(tex: _stripDollars(data['text/latex'].toString())),
      );
    }
    if (data['text/markdown'] != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: MarkdownBody(data: data['text/markdown'].toString()),
      );
    }
    // 兜底：text/plain 或任意键的字符串形式。
    final text = _pickPlain(data);
    return _mono(prefix == null ? text : '$prefix$text');
  }

  Widget _safeImage(
    BuildContext context,
    List<int> Function() decode, {
    bool gaplessPlayback = false,
  }) {
    try {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Image.memory(
          Uint8List.fromList(decode()),
          gaplessPlayback: gaplessPlayback,
          errorBuilder: (context, error, stack) =>
              _mono(AppLocalizations.of(context).imageUnavailable,
                  color: Colors.grey),
        ),
      );
    } catch (_) {
      return _mono(AppLocalizations.of(context).imageInvalid,
          color: Colors.grey);
    }
  }

  String _pickPlain(Map<String, dynamic> data) {
    for (final key in const ['text/plain', 'text/markdown', 'text/html']) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return data.toString();
  }

  /// Jupyter 的 text/latex 常带 `$...$` 或 `$$...$$`，去掉外层分隔符。
  String _stripDollars(String tex) {
    var t = tex.trim();
    if (t.startsWith(r'$$') && t.endsWith(r'$$')) {
      return t.substring(2, t.length - 2);
    }
    if (t.startsWith(r'$') && t.endsWith(r'$')) {
      return t.substring(1, t.length - 1);
    }
    return t;
  }

  Widget _mono(String text, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SelectableText(
        text.isEmpty ? ' ' : text,
        style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: color),
      ),
    );
  }
}

/// LaTeX 渲染（行内样式，失败回退纯文本）。
class _LatexView extends StatelessWidget {
  const _LatexView({required this.tex});
  final String tex;

  @override
  Widget build(BuildContext context) {
    return Math.tex(
      tex,
      mathStyle: MathStyle.text,
      textStyle: const TextStyle(fontSize: 15),
      onErrorFallback: (_) => SelectableText(
        tex,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }
}

/// text/html 输出的 WebView 渲染。
class _HtmlView extends StatefulWidget {
  const _HtmlView({required this.html});
  final String html;

  @override
  State<_HtmlView> createState() => _HtmlViewState();
}

class _HtmlViewState extends State<_HtmlView> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _controller!),
    );
  }
}
