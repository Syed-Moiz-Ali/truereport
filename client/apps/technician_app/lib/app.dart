import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/technician_router.dart';

class TechnicianApp extends ConsumerWidget {
  const TechnicianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final messages = ref.watch(
      uiMessageMessagesProvider(technicianUiMessageClient),
    );
    // Reference `labelKey` lookups still resolve through the shared flat map.
    setRemoteEnglish(messages);
    final strings = UiStrings.fromMessages(messages);
    final router = ref.watch(technicianRouterProvider);
    return UiStringsScope(
      strings: strings,
      child: MaterialApp.router(
        onGenerateTitle: (context) =>
            UiStrings.of(context)(TechnicianKeys.appTitleTechnician),
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
          client: technicianUiMessageClient,
          loadingBuilder: (context) => const Center(
            child: Padding(
              padding: EdgeInsetsDirectional.all(24),
              child: LoadingSkeleton(lines: 8),
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
