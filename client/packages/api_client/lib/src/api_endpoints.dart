class ApiEndpoints {
  const ApiEndpoints({required this.baseUrl});

  final String baseUrl;

  static const String _root = '/api/v1';

  String absolute(String path) => '$baseUrl$path';

  String get authMe => '$_root/auth/me';
  String get authLogin => '$_root/auth/login';
  String get authVerifyTwoFactor => '$_root/auth/2fa/verify';
  String get authRefresh => '$_root/auth/refresh';
  String get authLogout => '$_root/auth/logout';

  String get hierarchy => '$_root/platform/hierarchy';
  String workshopHierarchy(String workshopId) =>
      '$_root/platform/workshops/$workshopId/hierarchy';
  String get platformUsers => '$_root/platform/users';
  String get platformInvitations => '$_root/platform/invitations';
  String disableUser(String userId) => '$_root/platform/users/$userId/disable';
  String reactivateUser(String userId) =>
      '$_root/platform/users/$userId/reactivate';
  String transferUser(String userId) =>
      '$_root/platform/users/$userId/transfer';
  String get auditEvents => '$_root/platform/audit-events';

  String get categories => '$_root/platform/master/categories';
  String category(String id) => '$_root/platform/master/categories/$id';
  String retireCategory(String id) =>
      '$_root/platform/master/categories/$id/retire';
  String get items => '$_root/platform/master/items';
  String item(String id) => '$_root/platform/master/items/$id';
  String itemVersions(String itemId) =>
      '$_root/platform/master/items/$itemId/versions';
  String itemVersion(String itemId, String versionId) =>
      '$_root/platform/master/items/$itemId/versions/$versionId';
  String itemVersionTranslation(
    String itemId,
    String versionId,
    String locale,
  ) =>
      '$_root/platform/master/items/$itemId/versions/$versionId/translations/$locale';
  String itemVersionRules(String itemId, String versionId) =>
      '$_root/platform/master/items/$itemId/versions/$versionId/rules';
  String publishItemVersion(String itemId, String versionId) =>
      '$_root/platform/master/items/$itemId/versions/$versionId/publish';
  String retireItem(String itemId) =>
      '$_root/platform/master/items/$itemId/retire';

  String get reasons => '$_root/platform/master/reasons';
  String get equipment => '$_root/platform/master/equipment';
  String get dropdowns => '$_root/platform/master/dropdowns';
  String dropdownValues(String dropdownId) =>
      '$_root/platform/master/dropdowns/$dropdownId/values';
  String get guideImages => '$_root/platform/master/guide-images';
  String guideImageContent(String id) =>
      '$_root/platform/master/guide-images/$id/content';
  String retireGuideImage(String id) =>
      '$_root/platform/master/guide-images/$id/retire';
}
