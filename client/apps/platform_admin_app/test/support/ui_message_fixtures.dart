import 'dart:convert';
import 'dart:io';

import 'package:l10n/l10n.dart';

const String _catalogDir =
    '../../../server/src/main/resources/i18n/platform_admin';
const String _fixtureCatalogDir = 'test/support/catalogs';

Map<String, Map<String, String>> _loadCatalog(String file, {String? fromDir}) {
  final decoded = jsonDecode(
    File('${fromDir ?? _catalogDir}/$file').readAsStringSync(),
  ) as Map<String, dynamic>;
  final catalogs = <String, Map<String, String>>{};
  final qualified = RegExp(
    r'^(common|platform_admin|workshop_admin|technician)\.',
  );
  for (final entry in decoded.entries) {
    final match = qualified.firstMatch(entry.key);
    // EN bundles are namespace-scoped with flat keys (`dashboard.alert...`);
    // the AR fixture is fully qualified (`platform_admin.dashboard.alert...`).
    final namespace = match?.group(1) ?? 'platform_admin';
    final key = match == null
        ? entry.key
        : entry.key.substring(match.group(0)!.length);
    catalogs.putIfAbsent(namespace, () => <String, String>{})[key] =
        entry.value as String;
  }
  return catalogs;
}

final Map<String, Map<String, String>> platformEnCatalogs = _loadCatalog(
  'en.json',
);
final Map<String, Map<String, String>> platformArCatalogs = _loadCatalog(
  'platform_admin_ar.json',
  fromDir: _fixtureCatalogDir,
);

UiMessageStrings fakeEnUiStrings() => UiMessageStrings(
  catalogs: {'en': platformEnCatalogs},
  activeLanguage: 'en',
  defaultLanguage: 'en',
);

UiMessageStrings fakeArUiStrings() => UiMessageStrings(
  catalogs: {'ar': platformArCatalogs, 'en': platformEnCatalogs},
  activeLanguage: 'ar',
  defaultLanguage: 'en',
);
