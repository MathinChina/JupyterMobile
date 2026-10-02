/// 赞助信息集中配置。
///
/// 拿到真实的赞助链接 / 收款码图片后，只需修改本文件即可，无需改 UI。
library;

class DonateConfig {
  const DonateConfig._();

  /// Buy Me a Coffee 链接。
  ///
  /// 获取方式：buymeacoffee.com 注册后得到 `buymeacoffee.com/<用户名>`，
  /// 把下面的 YOUR_USERNAME 替换成你的用户名。
  static const String buyMeACoffeeUrl =
      'https://buymeacoffee.com/MathinChina';

  /// B站充电链接（UP 主充电页）。
  ///
  /// 获取方式：B站开通充电计划后，在「创作中心 → 充电计划」得到充电页链接，
  /// 或直接使用你的个人空间链接 `space.bilibili.com/<UID>`。
  static const String bilibiliUrl =
      'https://space.bilibili.com/1854424625';

  /// 未配置链接时的占位提示（判断依据）。
  static bool get isBuyMeACoffeeConfigured =>
      !buyMeACoffeeUrl.contains('YOUR_USERNAME');

  static bool get isBilibiliConfigured => !bilibiliUrl.contains('YOUR_UID');
}
