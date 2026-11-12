import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import 'src/platform_providers.dart';
import 'src/platform_router.dart';
import 'src/platform_theme.dart';
import 'src/web_url_strategy_stub.dart'
    if (dart.library.html) 'src/web_url_strategy_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureWebUrlStrategy();
  runApp(const ProviderScope(child: PlatformAdminApp()));
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
          Localizations.of<AppLocalizations>(
            context,
            AppLocalizations,
          )?.platformAdminTitle ??
          'Platform Admin',
      debugShowCheckedModeBanner: false,
      theme: _platformTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
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
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: PtTheme.font(13, weight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PtTheme.deepGreen,
        foregroundColor: PtTheme.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        elevation: 0,
        textStyle: PtTheme.font(13, weight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PtTheme.deepGreen,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        side: const BorderSide(color: PtTheme.border),
        textStyle: PtTheme.font(13, weight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PtTheme.deepGreen,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: PtTheme.font(13, weight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: PtTheme.font(13, color: PtTheme.muted),
      labelStyle: PtTheme.font(
        12,
        weight: FontWeight.w600,
        color: PtTheme.muted,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PtTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PtTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PtTheme.deepGreen, width: 1.4),
      ),
    ),
  );
}
