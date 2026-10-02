import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/donate_config.dart';
import '../l10n/gen/app_localizations.dart';

/// 赞助页面。
///
/// 提供两种赞助方式：
/// - Buy Me a Coffee（点击跳转浏览器）
/// - B站充电（点击跳转浏览器）
///
/// 链接集中在 [DonateConfig]，拿到真实信息后只需改那一个文件。
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
        ],
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
}
