import 'package:workshop_admin_app/app.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import 'src/web_url_strategy_stub.dart'
    if (dart.library.html) 'src/web_url_strategy_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureWebUrlStrategy();
  runApp(
    ProviderScope(
      overrides: [
        // One shared fetcher; the app owns no language implementation.
        uiMessageFetcherProvider.overrideWith(
          (ref) => ref.watch(adminUiMessageFetcherProvider),
        ),
      ],
      child: const AdminApp(),
    ),
  );
}
