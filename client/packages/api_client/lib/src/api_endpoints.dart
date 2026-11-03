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

  String get workshopMasterCategories => '$_root/workshop/master/categories';
  String get workshopMasterItems => '$_root/workshop/master/items';
  String workshopMasterItem(String versionId) =>
      '$_root/workshop/master/items/$versionId';

  String get workshopStaff => '$_root/workshop/staff';
  String get workshopJobs => '$_root/workshop/jobs';
  String workshopJob(String id) => '$_root/workshop/jobs/$id';
  String assignWorkshopJob(String id) => '$_root/workshop/jobs/$id/assign';
  String cancelWorkshopJob(String id) => '$_root/workshop/jobs/$id/cancel';
  String workshopJobAssignments(String id) =>
      '$_root/workshop/jobs/$id/assignments';
  String get technicianJobs => '$_root/technician/jobs';
  String technicianJob(String id) => '$_root/technician/jobs/$id';
  String get technicianTemplateVersions => '$_root/technician/templates/versions';
  String technicianChecklist(String id) => '$_root/technician/jobs/$id/checklist';
  String technicianStart(String id) => '$_root/technician/jobs/$id/start';
  String technicianCustomer(String id) => '$_root/technician/jobs/$id/customer';
  String technicianVehicle(String id) => '$_root/technician/jobs/$id/vehicle';
  String technicianConsent(String id) => '$_root/technician/jobs/$id/consent';
  String technicianEquipment(String id) => '$_root/technician/jobs/$id/equipment';
  String technicianAssessment(String jobId, String itemId) =>
      '$_root/technician/jobs/$jobId/items/$itemId/assessment';
  String technicianReview(String id) => '$_root/technician/jobs/$id/review';
  String technicianReady(String id) => '$_root/technician/jobs/$id/ready';
  String technicianFinalize(String id) => '$_root/technician/jobs/$id/finalize';
  String technicianEvidenceInit(String jobId, String itemId) =>
      '$_root/technician/jobs/$jobId/items/$itemId/evidence/init';
  String technicianEvidenceComplete(
    String jobId,
    String itemId,
    String evidenceId,
  ) => '$_root/technician/jobs/$jobId/items/$itemId/evidence/$evidenceId/complete';
  String technicianEvidence(String jobId, String itemId) =>
      '$_root/technician/jobs/$jobId/items/$itemId/evidence';
  String technicianGuideImage(String jobId, String itemId) =>
      '$_root/technician/jobs/$jobId/items/$itemId/guide-image';

  String get workshopTemplates => '$_root/workshop/templates';
  String get workshopTemplateVersions => '$_root/workshop/templates/versions';
  String workshopTemplate(String id) => '$_root/workshop/templates/$id';
  String workshopTemplateDraft(String id) =>
      '$_root/workshop/templates/$id/draft';
  String publishWorkshopTemplate(String id) =>
      '$_root/workshop/templates/$id/publish';
  String retireWorkshopTemplate(String id) =>
      '$_root/workshop/templates/$id/retire';
  String workshopTemplateVersion(String id, String versionId) =>
      '$_root/workshop/templates/$id/versions/$versionId';
  String workshopTemplatePreview(String id) =>
      '$_root/workshop/templates/$id/preview';
}
