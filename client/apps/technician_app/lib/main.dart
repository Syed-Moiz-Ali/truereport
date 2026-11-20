import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
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
        // Reference taxonomy is cached on device so a technician can start
        // a job offline.
        referenceApiProvider.overrideWith(
          (ref) => ref.watch(apiClientProvider),
        ),
        referenceStoreProvider.overrideWithValue(
          SharedPreferencesReferenceStore(),
        ),
      ],
      child: const TechnicianApp(),
    ),
  );
}
