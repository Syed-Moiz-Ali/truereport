import 'ui_message_catalog.dart';
import 'ui_message_manifest.dart';

typedef UiMessageFetcher = Future<Map<String, dynamic>> Function(
  String path,
  Map<String, String> query,
);

class UiMessageApi {
  const UiMessageApi(this._fetch);

  static const String manifestPath = '/api/v1/i18n/ui-messages/manifest';
  static const String bundlePath = '/api/v1/i18n/ui-messages/bundle';
  static const List<String> namespaces = <String>['platform_admin', 'common'];
  static const String namespacesQuery = 'platform_admin,common';

  final UiMessageFetcher _fetch;

  Future<UiMessageManifest> manifest() async {
    final json = await _fetch(manifestPath, const <String, String>{
      'namespaces': namespacesQuery,
    });
    return UiMessageManifest.fromJson(json);
  }

  Future<UiMessageBundle> bundle(String language) async {
    final json = await _fetch(bundlePath, <String, String>{
      'namespaces': namespacesQuery,
      'lang': language,
    });
    return UiMessageBundle.fromJson(json);
  }
}
