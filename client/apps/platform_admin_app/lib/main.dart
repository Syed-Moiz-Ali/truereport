import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'src/platform_providers.dart';
import 'src/platform_router.dart';
import 'src/web_url_strategy_stub.dart'
    if (dart.library.html) 'src/web_url_strategy_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureWebUrlStrategy();
  runApp(
    const ProviderScope(
      child: PlatformAdminApp(),
    ),
  );
}

class PlatformAdminApp extends ConsumerWidget {
  const PlatformAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(platformLocaleProvider);
    final router = ref.watch(platformRouterProvider);
    ref.read(apiClientProvider).acceptLanguage = locale.languageCode;

    return MaterialApp.router(
      onGenerateTitle: (context) =>
          Localizations.of<AppLocalizations>(context, AppLocalizations)?.platformAdminTitle ??
          'Platform Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
