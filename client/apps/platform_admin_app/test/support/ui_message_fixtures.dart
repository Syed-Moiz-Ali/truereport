import 'dart:convert';
import 'dart:io';

import 'package:l10n/l10n.dart';

const String _catalogDir =
    '../../../server/src/main/resources/i18n/platform_admin';

Map<String, Map<String, String>> _loadCatalog(String file) {
  final decoded = jsonDecode(
    File('$_catalogDir/$file').readAsStringSync(),
  ) as Map<String, dynamic>;
  final catalogs = <String, Map<String, String>>{};
  for (final entry in decoded.entries) {
    final dot = entry.key.indexOf('.');
    if (dot <= 0 || dot == entry.key.length - 1) {
      throw StateError(
        'Catalog key "${entry.key}" must be namespace-qualified.',
      );
    }
    final namespace = entry.key.substring(0, dot);
    final key = entry.key.substring(dot + 1);
    catalogs.putIfAbsent(namespace, () => <String, String>{})[key] =
        entry.value as String;
  }
  return catalogs;
}

final Map<String, Map<String, String>> platformEnCatalogs = _loadCatalog(
  'en.json',
);
final Map<String, Map<String, String>> platformArCatalogs = _loadCatalog(
  'ar.json',
);
final Map<String, Map<String, String>> platformZhHansCatalogs = _loadCatalog(
  'zh-Hans.json',
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
