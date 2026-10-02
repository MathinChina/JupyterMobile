/// 终端 / 命令输出的文本清洗工具。
///
/// pip、jupyter 等命令行程序会把 ANSI 转义序列（颜色、光标控制等）直接
/// 写入 stdout / stderr。若原样显示在 Flutter 文本里，会出现 `[32m` 之类
/// 的乱码；进度条还会用 `\r` 回到行首覆盖。这里统一剥离控制序列、把回车
/// 归一化为换行，让输出可读。
library;

final RegExp _csiPattern = RegExp(r'\x1B\[[0-9;?]*[A-Za-z]');
final RegExp _oscPattern = RegExp(r'\x1B\][^\x07]*(?:\x07|\x1B\\)');

/// 剥离 ANSI 转义序列（CSI / OSC），并把回车归一化为换行。
///
/// - CSI：`ESC [ ... 字母`，例如 `\x1b[32m`、`\x1b[0m`、`\x1b[?25l`。
/// - OSC：`ESC ] ... BEL` 或 `ESC ] ... ESC \`，例如设置终端标题。
/// - 回车：`\r\n` 归一化为 `\n`；单独的 `\r`（进度条回行覆盖）转为 `\n`。
String stripAnsi(String text) {
  if (text.isEmpty) return text;
  return text
      .replaceAll(_oscPattern, '')
      .replaceAll(_csiPattern, '')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
}
