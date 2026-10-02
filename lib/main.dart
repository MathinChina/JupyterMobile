import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/gen/app_localizations.dart';
import 'state/locale_provider.dart';
import 'ui/connection_screen.dart';

void main() {
  runApp(const ProviderScope(child: JupyterMobileApp()));
}

class JupyterMobileApp extends ConsumerWidget {
  const JupyterMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: 'JupyterMobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Jupyter 品牌色。
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF37726)),
        useMaterial3: true,
      ),
      home: const ConnectionScreen(),
    );
  }
}
