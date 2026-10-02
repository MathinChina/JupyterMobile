/// 内核来源类型。
///
/// 这是抽象层的关键：前端只依赖 [KernelConnection]，具体来源通过本枚举
/// 选择对应的 Provider 实现。将来新增「内置解压 Python」只需加一个枚举值 +
/// 一个实现类，前端零改动。
enum KernelSource {
  /// 远程服务器（用户自己的服务器 / 公网）。
  remote('远程服务器'),

  /// 本机 Termux / Pydroid 起的 jupyter_server（127.0.0.1）。
  external('本机 Termux'),

  /// 内置解压 Python（阶段⑥，预留扩展点，尚未实现）。
  bundled('内置 Python');

  const KernelSource(this.label);

  /// 界面展示用中文标签。
  final String label;
}
