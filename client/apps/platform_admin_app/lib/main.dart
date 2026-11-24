import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/ui_strings.dart';

import 'src/platform_providers.dart';
import 'src/platform_router.dart';
import 'src/platform_theme.dart';
import 'src/ui_messages_bootstrap.dart';
import 'src/web_url_strategy_stub.dart'
    if (dart.library.html) 'src/web_url_strategy_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Shared backend url: packages/auth/.env (same for every app).
  await AppEnv.load();
  await initializeDateFormatting();
  configureWebUrlStrategy();
  final uiMessageStore = await createPlatformUiMessageStore();
  runApp(
    platformUiMessageScope(
      store: uiMessageStore,
      child: const PlatformAdminApp(),
    ),
  );
}

class PlatformAdminApp extends ConsumerWidget {
  const PlatformAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(platformRouterProvider);
    final title = ref.watch(platformAppTitleProvider);
    ref.read(apiClientProvider).acceptLanguage = 'en';
    ref.read(apiClientProvider).clientName = 'platform_admin';

    return UiStringsScope(
      strings: UiStrings.fromMessages(
        ref.watch(uiMessageMessagesProvider(UiMessageClients.platformAdmin)),
      ),
      child: MaterialApp.router(
        onGenerateTitle: (_) => title,
        debugShowCheckedModeBanner: false,
        theme: _platformTheme(),
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) =>
            UiMessagesBootstrap(child: child ?? const SizedBox.shrink()),
        routerConfig: router,
      ),
    );
  }
}

ThemeData _platformTheme() {
  final base = AppTheme.light;
  return base.copyWith(
    dialogTheme: DialogThemeData(
      backgroundColor: PtTheme.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: PtTheme.font(
        18,
        lineHeight: 24,
        weight: FontWeight.w800,
        color: PtTheme.ink,
      ),
      contentTextStyle: PtTheme.body,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PtTheme.deepGreen,
        foregroundColor: PtTheme.white,
        disabledBackgroundColor: PtTheme.border,
        disabledForegroundColor: PtTheme.muted,
        minimumSize: const Size(44, PtTheme.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: PtTheme.font(13, weight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PtTheme.controlRadius),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PtTheme.deepGreen,
        foregroundColor: PtTheme.white,
        minimumSize: const Size(44, PtTheme.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
        textStyle: PtTheme.font(13, weight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PtTheme.controlRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PtTheme.deepGreen,
        minimumSize: const Size(44, PtTheme.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: const BorderSide(color: PtTheme.border),
        textStyle: PtTheme.font(13, weight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PtTheme.controlRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PtTheme.deepGreen,
        minimumSize: const Size(44, PtTheme.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: PtTheme.font(13, weight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PtTheme.controlRadius),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: PtTheme.canvas,
      selectedColor: PtTheme.deepGreen.withValues(alpha: 0.12),
      side: const BorderSide(color: PtTheme.border),
      shape: const StadiumBorder(),
      labelStyle: PtTheme.font(12, weight: FontWeight.w600, color: PtTheme.ink),
      secondaryLabelStyle: PtTheme.font(
        12,
        weight: FontWeight.w600,
        color: PtTheme.deepGreen,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      constraints: const BoxConstraints(minHeight: PtTheme.fieldHeight),
      hintStyle: PtTheme.font(13, color: PtTheme.muted),
      labelStyle: PtTheme.font(
        12,
        weight: FontWeight.w600,
        color: PtTheme.muted,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PtTheme.fieldRadius),
        borderSide: const BorderSide(color: PtTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PtTheme.fieldRadius),
        borderSide: const BorderSide(color: PtTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PtTheme.fieldRadius),
        borderSide: const BorderSide(color: PtTheme.deepGreen, width: 1.4),
      ),
    ),
  );
}
