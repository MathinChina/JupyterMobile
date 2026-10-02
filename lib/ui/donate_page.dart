import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/donate_config.dart';
import '../l10n/gen/app_localizations.dart';

/// 赞助页面。
///
/// 提供三种赞助方式：
/// - Buy Me a Coffee（点击跳转浏览器）
/// - B站充电（点击跳转浏览器）
/// - 微信 / 支付宝收款码（展示图片，扫码）
///
/// 链接与图片路径集中在 [DonateConfig]，拿到真实信息后只需改那一个文件。
class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.donateLinkFailed(url))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.donateTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.donateIntro,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          _buildLinkCard(
            context,
            icon: Icons.coffee,
            title: l10n.donateBuyMeACoffee,
            subtitle: DonateConfig.isBuyMeACoffeeConfigured
                ? l10n.donateTapToOpen
                : l10n.donateNotConfigured,
            enabled: DonateConfig.isBuyMeACoffeeConfigured,
            onTap: () => _openUrl(context, DonateConfig.buyMeACoffeeUrl),
          ),
          const SizedBox(height: 12),
          _buildLinkCard(
            context,
            icon: Icons.tv,
            title: l10n.donateBilibili,
            subtitle: DonateConfig.isBilibiliConfigured
                ? l10n.donateTapToCharge
                : l10n.donateNotConfigured,
            enabled: DonateConfig.isBilibiliConfigured,
            onTap: () => _openUrl(context, DonateConfig.bilibiliUrl),
          ),
          const SizedBox(height: 24),
          _sectionTitle(l10n.donateScan),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildQr(
                    context, l10n.donateWechat, DonateConfig.wechatQrAsset),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQr(
                    context, l10n.donateAlipay, DonateConfig.alipayQrAsset),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _buildLinkCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          enabled ? Icons.open_in_new : Icons.edit,
          color: enabled ? null : Theme.of(context).disabledColor,
        ),
        enabled: enabled,
        onTap: enabled ? onTap : null,
      ),
    );
  }

  Widget _buildQr(BuildContext context, String label, String assetPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    AppLocalizations.of(context).donatePlaceholder,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}
