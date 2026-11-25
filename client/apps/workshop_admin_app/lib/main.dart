import 'package:auth/auth.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/app.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/ui_strings.dart';

import 'src/web_url_strategy_stub.dart'
    if (dart.library.html) 'src/web_url_strategy_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Shared backend url: packages/auth/.env (same for every app).
  await AppEnv.load();
  // Material's own copy (date pickers, dialogs) is localized per locale; the
  // symbols must exist before the app can render a non-English locale.
  await initializeDateFormatting();
  configureWebUrlStrategy();
  final uiMessageStore = await createUiMessageStore();
  runApp(
    ProviderScope(
      overrides: [
        // Durable selection + catalogs: a chosen language survives a reload.
        uiMessageStoreProvider.overrideWithValue(uiMessageStore),
        // One shared fetcher; the app owns no language implementation.
        uiMessageFetcherProvider.overrideWith(
          (ref) => ref.watch(adminUiMessageFetcherProvider),
        ),
        // Reference taxonomy uses the same authenticated client.
        referenceApiProvider.overrideWith(
          (ref) => ref.watch(apiClientProvider),
        ),
      ],
      child: const AdminApp(),
    ),
  );
}
