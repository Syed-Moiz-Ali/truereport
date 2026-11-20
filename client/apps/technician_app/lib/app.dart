import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/technician_router.dart';

class TechnicianApp extends ConsumerWidget {
  const TechnicianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    // English text stays backend-owned: generated getters read this map.
    setRemoteEnglish(
      ref.watch(uiMessageMessagesProvider(technicianUiMessageClient)),
    );
    final router = ref.watch(technicianRouterProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context).appTitleTechnician,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => UiMessageBootstrap(
        client: technicianUiMessageClient,
        onAuthFailure: () {
          final auth = ref.read(authControllerProvider);
          if (auth.isLoading || auth.value == null) return;
          ref.read(authControllerProvider.notifier).signOut();
        },
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: router,
    );
  }
}
