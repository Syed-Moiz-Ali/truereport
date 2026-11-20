import 'package:auth/auth.dart';
import 'package:workshop_admin_app/src/admin_router.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/api_language_sync.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps Accept-Language / X-Client on the shared API client in sync with
    // the active locale (see api_language_sync.dart).
    ref.watch(apiLanguageSyncProvider);
    final locale = ref.watch(localeProvider);
    final messages = ref.watch(uiMessageMessagesProvider(adminUiMessageClient));
    // Reference `labelKey` lookups still resolve through the shared flat map.
    setRemoteEnglish(messages);
    final router = ref.watch(adminRouterProvider);
    return UiStringsScope(
      strings: UiStrings.fromMessages(messages),
      child: MaterialApp.router(
        onGenerateTitle: (context) =>
            UiStrings.of(context)(WorkshopAdminKeys.appTitleAdmin),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        themeMode: ThemeMode.light,
        locale: locale,
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        builder: (context, child) => UiMessageBootstrap(
          client: adminUiMessageClient,
          loadingBuilder: (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const Padding(
                padding: EdgeInsetsDirectional.all(24),
                child: WorkshopSkeleton(lines: 6, card: true),
              ),
            ),
          ),
          onAuthFailure: () {
            final auth = ref.read(authControllerProvider);
            if (auth.isLoading || auth.value == null) return;
            ref.read(authControllerProvider.notifier).signOut();
          },
          child: child ?? const SizedBox.shrink(),
        ),
        routerConfig: router,
      ),
    );
  }
}
