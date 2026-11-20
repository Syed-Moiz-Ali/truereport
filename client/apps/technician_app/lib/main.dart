import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/app.dart';
import 'package:technician_app/src/technician_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Real web URLs (/jobs) instead of hash fragments (/#/jobs).
  usePathUrlStrategy();
  runApp(
    ProviderScope(
      overrides: [
        // One shared fetcher; the app owns no language implementation.
        uiMessageFetcherProvider.overrideWith(
          (ref) => ref.watch(technicianUiMessageFetcherProvider),
        ),
      ],
      child: const TechnicianApp(),
    ),
  );
}
