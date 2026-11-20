import 'ui_message_catalog.dart';
import 'ui_message_manifest.dart';

typedef UiMessageFetcher = Future<Map<String, dynamic>> Function(
  String path,
  Map<String, String> query,
);

/// The three clients that consume backend UI messages.
abstract final class UiMessageClients {
  static const String platformAdmin = 'platform_admin';
  static const String workshopAdmin = 'workshop_admin';
  static const String technician = 'technician';

  static const List<String> all = <String>[
    platformAdmin,
    workshopAdmin,
    technician,
  ];

  static bool isKnown(String client) => all.contains(client);

  /// Namespaces a client bundle can contain: shared `common` plus the client.
  static List<String> namespacesFor(String client) => <String>[
    'common',
    client,
  ];
}

/// Talks to the single UI-message API for one client.
///
/// ```dart
/// final api = UiMessageApi.forClient(UiMessageClients.workshopAdmin, fetch);
/// final manifest = await api.manifest();
/// final bundle = await api.bundle('es');
/// ```
class UiMessageApi {
  UiMessageApi.forClient(this.client, this._fetch)
    : assert(
        UiMessageClients.isKnown(client),
        'Unknown UI message client "$client"',
      );

  final String client;
  final UiMessageFetcher _fetch;

  static String manifestPathFor(String client) =>
      '/api/v1/i18n/ui-messages/$client/manifest';

  static String bundlePathFor(String client) =>
      '/api/v1/i18n/ui-messages/$client/bundle';

  Future<UiMessageManifest> manifest() async {
    final json = await _fetch(
      manifestPathFor(client),
      const <String, String>{},
    );
    return UiMessageManifest.fromJson(json);
  }

  Future<UiMessageBundle> bundle(String language) async {
    final json = await _fetch(bundlePathFor(client), <String, String>{
      'lang': language,
    });
    return UiMessageBundle.fromJson(json);
  }
}
