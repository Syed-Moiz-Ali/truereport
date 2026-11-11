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
  String get platformWorkshops => '$_root/platform/workshops';
  String workshopHierarchy(String workshopId) =>
      '$_root/platform/workshops/$workshopId/hierarchy';
  String get platformUsers => '$_root/platform/users';
  String platformPasswordReset(String userId) =>
      '$_root/platform/users/$userId/password-reset';
  String get platformInvitations => '$_root/platform/invitations';
  String get workshopTechnicians => '$_root/workshop/technicians';
  String workshopTechnicianPasswordReset(String userId) =>
      '$_root/workshop/technicians/$userId/password-reset';
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
  String get workshopJobCounts => '$_root/workshop/jobs/counts';
  String workshopJob(String id) => '$_root/workshop/jobs/$id';
  String assignWorkshopJob(String id) => '$_root/workshop/jobs/$id/assign';
  String cancelWorkshopJob(String id) => '$_root/workshop/jobs/$id/cancel';
  String workshopJobAssignments(String id) =>
      '$_root/workshop/jobs/$id/assignments';
  String workshopReport(String jobId) => '$_root/workshop/jobs/$jobId/report';
  String workshopReportRetry(String jobId) =>
      '$_root/workshop/jobs/$jobId/report/retry';
  String workshopReportLink(String jobId) =>
      '$_root/workshop/jobs/$jobId/report/link';
  String workshopReportLinkRevoke(String jobId) =>
      '$_root/workshop/jobs/$jobId/report/link/revoke';
  String workshopReportPdfSetting(String jobId) =>
      '$_root/workshop/jobs/$jobId/report/pdf-download';
  String workshopReportPdf(String jobId) =>
      '$_root/workshop/jobs/$jobId/report/pdf';
  String workshopJobDeliveries(String jobId) =>
      '$_root/workshop/jobs/$jobId/deliveries';
  String workshopJobDeliveryRetry(String jobId, String deliveryId) =>
      '$_root/workshop/jobs/$jobId/deliveries/$deliveryId/retry';
  String technicianReport(String jobId) =>
      '$_root/technician/jobs/$jobId/report';
  String technicianJobDeliveries(String jobId) =>
      '$_root/technician/jobs/$jobId/deliveries';
  String get technicianJobs => '$_root/technician/jobs';
  String technicianJob(String id) => '$_root/technician/jobs/$id';
  String get technicianTemplateVersions =>
      '$_root/technician/templates/versions';
  String technicianChecklist(String id) =>
      '$_root/technician/jobs/$id/checklist';
  String technicianStart(String id) => '$_root/technician/jobs/$id/start';
  String technicianCustomer(String id) => '$_root/technician/jobs/$id/customer';
  String technicianVehicle(String id) => '$_root/technician/jobs/$id/vehicle';
  String technicianConsent(String id) => '$_root/technician/jobs/$id/consent';
  String technicianEquipment(String id) =>
      '$_root/technician/jobs/$id/equipment';
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
  ) =>
      '$_root/technician/jobs/$jobId/items/$itemId/evidence/$evidenceId/complete';
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

  // ---------------------------------------------------------------- i18n
  String get i18nLanguages => '$_root/i18n/languages';
  String get i18nMe => '$_root/i18n/me';
  String get platformLanguages => '$_root/platform/i18n/languages';
  String platformLanguage(String code) =>
      '$_root/platform/i18n/languages/$code';
  String platformLanguageActivate(String code) =>
      '$_root/platform/i18n/languages/$code/activate';
  String platformLanguageDeactivate(String code) =>
      '$_root/platform/i18n/languages/$code/deactivate';
  String get platformLanguagesReorder =>
      '$_root/platform/i18n/languages/reorder';
  String get platformLanguagesDefault =>
      '$_root/platform/i18n/languages/default';
  String get platformLanguageCoverage => '$_root/platform/i18n/coverage';

  // ------------------------------------------------------- master config
  String get categoryWeightCheck =>
      '$_root/platform/master/categories/weight-check';
  String get categoriesReorder => '$_root/platform/master/categories/reorder';
  String get itemsReorder => '$_root/platform/master/items/reorder';
  String itemDraft(String itemId) =>
      '$_root/platform/master/items/$itemId/draft';
  String itemMetadata(String itemId) =>
      '$_root/platform/master/items/$itemId/metadata';
  String itemVersionConfig(String itemId, String versionId) =>
      '$_root/platform/master/items/$itemId/versions/$versionId/config';
  String itemVersionBands(String itemId, String versionId) =>
      '$_root/platform/master/items/$itemId/versions/$versionId/bands';
  String itemVersionEvidenceRules(String itemId, String versionId) =>
      '$_root/platform/master/items/$itemId/versions/$versionId/evidence-rules';
  String itemVersionIssueFields(String itemId, String versionId) =>
      '$_root/platform/master/items/$itemId/versions/$versionId/issue-fields';
  String itemVersionMeasurementBands(String itemId, String versionId) =>
      '$_root/platform/master/items/$itemId/versions/$versionId/measurement-bands';

  String get optionSets => '$_root/platform/master/option-sets';
  String optionSet(String id) => '$_root/platform/master/option-sets/$id';
  String retireOptionSet(String id) =>
      '$_root/platform/master/option-sets/$id/retire';
  String optionSetValues(String id) =>
      '$_root/platform/master/option-sets/$id/values';
  String optionSetValue(String id, String valueId) =>
      '$_root/platform/master/option-sets/$id/values/$valueId';
  String retireOptionSetValue(String id, String valueId) =>
      '$_root/platform/master/option-sets/$id/values/$valueId/retire';
  String reorderOptionSetValues(String id) =>
      '$_root/platform/master/option-sets/$id/values/reorder';

  String get masterTemplates => '$_root/platform/master/templates';
  String masterTemplate(String id) => '$_root/platform/master/templates/$id';
  String masterTemplateVersions(String id) =>
      '$_root/platform/master/templates/$id/versions';
  String masterTemplateVersionItems(String id, String versionId) =>
      '$_root/platform/master/templates/$id/versions/$versionId/items';
  String masterTemplateWeightPreview(String id, String versionId) =>
      '$_root/platform/master/templates/$id/versions/$versionId/weight-preview';
  String publishMasterTemplate(String id, String versionId) =>
      '$_root/platform/master/templates/$id/versions/$versionId/publish';
  String approveMasterTemplate(String id, String versionId) =>
      '$_root/platform/master/templates/$id/versions/$versionId/approve';
  String rejectMasterTemplate(String id, String versionId) =>
      '$_root/platform/master/templates/$id/versions/$versionId/reject';
  String retireMasterTemplate(String id) =>
      '$_root/platform/master/templates/$id/retire';

  String get scoringRules => '$_root/platform/scoring-rules';
  String scoringRule(String id) => '$_root/platform/scoring-rules/$id';
  String approveScoringRule(String id) =>
      '$_root/platform/scoring-rules/$id/approve';
  String rejectScoringRule(String id) =>
      '$_root/platform/scoring-rules/$id/reject';
  String gradeBoundaries(String id) =>
      '$_root/platform/scoring-rules/$id/grade-boundaries';
  String approveGradeBoundaries(String id) =>
      '$_root/platform/scoring-rules/$id/grade-boundaries/approve';

  String get reportDocumentTypes => '$_root/platform/document-types';
  String reportDocumentType(String id) =>
      '$_root/platform/document-types/$id';
  String retireReportDocumentType(String id) =>
      '$_root/platform/document-types/$id/retire';
  String get reportDocumentTypesReorder =>
      '$_root/platform/document-types/reorder';

  String get seedDefaultChecklist => '$_root/platform/seed/default-checklist';
  String get configHealth => '$_root/platform/config-health';
  String configHealthEntity(String entityType) =>
      '$_root/platform/config-health/$entityType';
  String impactAnalysis(String entityType, String id) =>
      '$_root/platform/master/$entityType/$id/impact';
  String get configReleases => '$_root/platform/releases';
  String configReleaseTransition(String id, String action) =>
      '$_root/platform/releases/$id/$action';
}
