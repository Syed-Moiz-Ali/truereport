import 'package:workshop_admin_app/src/admin_router.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/api_language_sync.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps Accept-Language / X-Client on the shared API client in sync with
    // the active locale (see api_language_sync.dart).
    ref.watch(apiLanguageSyncProvider);
    final locale = ref.watch(localeProvider);
    // English text stays backend-owned: generated getters read this map.
    setRemoteEnglish(
      ref.watch(uiMessageMessagesProvider(adminUiMessageClient)),
    );
    final router = ref.watch(adminRouterProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitleAdmin,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => UiMessageBootstrap(
        client: adminUiMessageClient,
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: router,
    );
  }
}
