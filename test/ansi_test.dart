import 'package:flutter_test/flutter_test.dart';
import 'package:jupyter_mobile/core/ansi.dart';

void main() {
  test('剥离 CSI 颜色/光标序列', () {
    const input = '\x1b[32m绿色\x1b[0m 普通 \x1b[1m加粗\x1b[22m';
    expect(stripAnsi(input), '绿色 普通 加粗');
  });

  test('剥离 OSC 终端标题序列', () {
    const input = '\x1b]0;pip install\x07安装中...';
    expect(stripAnsi(input), '安装中...');
  });

  test('回车归一化为换行（进度条回行覆盖）', () {
    expect(stripAnsi('a\rb'), 'a\nb');
    expect(stripAnsi('a\r\nb'), 'a\nb');
  });

  test('保留 box-drawing 与符号字符（不误删）', () {
    const box = '┌─────┐\n│ 100% │\n└─────┘ ✓ → ✗ •';
    expect(stripAnsi(box), box);
  });

  test('空串与纯文本原样返回', () {
    expect(stripAnsi(''), '');
    expect(stripAnsi('hello world'), 'hello world');
  });
}
