import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

import 'admin_providers.dart';

/// Keeps the shared [ApiClient] aligned with the app's active language.
///
/// Without this the workshop app sends no `Accept-Language` and no `X-Client`,
/// so server-localized content and error text stay English and audit
/// attribution is wrong for every workshop request.
///
/// It must follow the interface language, not `localeProvider` (which is the
/// product default), or content keeps coming back in English.
final apiLanguageSyncProvider = Provider<void>((ref) {
  final api = ref.watch(apiClientProvider);
  api.clientName = 'workshop_admin';
  api.acceptLanguage = ref
      .watch(languageSelectionProvider(adminUiMessageClient))
      .activeLanguage;
});
