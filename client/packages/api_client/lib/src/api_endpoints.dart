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
  String get authChangePassword => '$_root/auth/change-password';

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
  String get auditEventsExport => '$_root/platform/audit-events/export';

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
  String get workshopAvailableTemplates =>
      '$_root/workshop/template-versions/available';
  String workshopTemplateDetail(String versionId) =>
      '$_root/workshop/template-versions/$versionId';
  String get workshopCleanJobs => '$_root/workshop/jobs';
  String get workshopCleanJobCounts => '$_root/workshop/jobs/counts';
  String workshopCleanJob(String id) => '$_root/workshop/jobs/$id';
  String workshopJobConsent(String id) => '$_root/workshop/jobs/$id/consent';
  String assignCleanWorkshopJob(String id) => '$_root/workshop/jobs/$id/assign';
  String cancelCleanWorkshopJob(String id) => '$_root/workshop/jobs/$id/cancel';
  String workshopCleanJobAssignments(String id) =>
      '$_root/workshop/jobs/$id/assignments';
  String workshopJobReview(String id) => '$_root/workshop/jobs/$id/review';
  String workshopJobPublishChecklist(String id) =>
      '$_root/workshop/jobs/$id/publish-checklist';
  String workshopJobApprove(String id) => '$_root/workshop/jobs/$id/approve';
  String workshopJobReject(String id) => '$_root/workshop/jobs/$id/reject';
  String workshopJobPublish(String id) => '$_root/workshop/jobs/$id/publish';
  String workshopJobUnpublish(String id) =>
      '$_root/workshop/jobs/$id/unpublish';
  String workshopJobRotateToken(String id) =>
      '$_root/workshop/jobs/$id/rotate-token';
  String workshopJobRevoke(String id) => '$_root/workshop/jobs/$id/revoke';
  String workshopJobPublicLink(String id) =>
      '$_root/workshop/jobs/$id/public-link';
  String workshopJobQr(String id) => '$_root/workshop/jobs/$id/qr';
  String workshopJobDocuments(String id) =>
      '$_root/workshop/jobs/$id/documents';
  String workshopJobDocumentRetry(String id, String type) =>
      '$_root/workshop/jobs/$id/documents/$type/retry';
  String get workshopNotifications => '$_root/workshop/notifications';
  String readWorkshopNotification(String id) =>
      '$_root/workshop/notifications/$id/read';

  /// Legacy `inspection_jobs` archive only.
  ///
  /// TODO(phase6): backend `/workshop/legacy/jobs` has no clean equivalent;
  /// it lists unmigrated `inspection_jobs` rows for the read-only archive.
  String get workshopJobs => '$_root/workshop/legacy/jobs';
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
  // ------------------------------------------------- clean technician API
  String get technicianCleanJobs => '$_root/technician/jobs';
  String technicianCleanJob(String id) => '$_root/technician/jobs/$id';
  String technicianCleanChecklist(String id) =>
      '$_root/technician/jobs/$id/checklist';
  String technicianCleanItem(String jobId, String itemCode) =>
      '$_root/technician/jobs/$jobId/items/$itemCode';
  String technicianCleanSummary(String id) =>
      '$_root/technician/jobs/$id/summary';
  String technicianCleanReview(String id) =>
      '$_root/technician/jobs/$id/review';
  String technicianCleanSignature(String id) =>
      '$_root/technician/jobs/$id/signature';
  String technicianCleanComplete(String id) =>
      '$_root/technician/jobs/$id/complete';
  String technicianCleanSync(String id) => '$_root/technician/jobs/$id/sync';
  String technicianCleanEvidenceInit(String jobId, String itemCode) =>
      '$_root/technician/jobs/$jobId/items/$itemCode/evidence/init';
  String technicianCleanEvidence(
    String jobId,
    String itemCode,
    String evidenceId,
  ) => '$_root/technician/jobs/$jobId/items/$itemCode/evidence/$evidenceId';
  String technicianCleanEvidenceContent(
    String jobId,
    String itemCode,
    String evidenceId,
  ) =>
      '$_root/technician/jobs/$jobId/items/$itemCode/evidence/$evidenceId/content';
  String technicianCleanEvidenceComplete(
    String jobId,
    String itemCode,
    String evidenceId,
  ) =>
      '$_root/technician/jobs/$jobId/items/$itemCode/evidence/$evidenceId/complete';
  String technicianCleanEvidenceList(String jobId, String itemCode) =>
      '$_root/technician/jobs/$jobId/items/$itemCode/evidence';
  String technicianCleanVehiclePhoto(String jobId) =>
      '$_root/technician/jobs/$jobId/vehicle-photo';
  String technicianCleanVehiclePhotoContent(String jobId) =>
      '$_root/technician/jobs/$jobId/vehicle-photo/content';
  String technicianCleanVehiclePhotoUpload(String jobId, String photoId) =>
      '$_root/technician/jobs/$jobId/vehicle-photo/$photoId/content';
  String technicianCleanVehiclePhotoComplete(String jobId, String photoId) =>
      '$_root/technician/jobs/$jobId/vehicle-photo/$photoId/complete';

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
  String get platformLanguageCatalog =>
      '$_root/platform/i18n/languages/catalog';
  String platformLanguageApps(String code) =>
      '$_root/platform/i18n/languages/$code/apps';
  String platformLanguage(String code) =>
      '$_root/platform/i18n/languages/$code';
  String get platformLanguageCoverage => '$_root/platform/i18n/coverage';
  String get platformContentLanguages =>
      '$_root/platform/i18n/content/languages';
  String platformLanguageReadiness(String code) =>
      '$_root/platform/i18n/languages/$code/readiness';
  String platformLanguageBacklog(String code) =>
      '$_root/platform/i18n/languages/$code/backlog';
  String platformLanguageCoverageFor(String code) =>
      '$_root/platform/i18n/coverage?language=$code';
  String get platformTranslations => '$_root/platform/i18n/translations';
  String get platformContentUnits => '$_root/platform/i18n/content/units';
  String platformContentTranslation(
    String entityType,
    String entityId,
    String field,
  ) => '$_root/platform/i18n/content/$entityType/$entityId/$field';
  String get contentReview => '$_root/platform/i18n/content/review';
  String get contentReviewSummary =>
      '$_root/platform/i18n/content/review/summary';
  String get contentReviewBulkApprove =>
      '$_root/platform/i18n/content/review/bulk-approve';
  String get contentReviewApproveSelected =>
      '$_root/platform/i18n/content/review/approve-selected';
  String get contentFailedJobs => '$_root/platform/i18n/content/jobs/failed';
  String get contentRetryFailed => '$_root/platform/i18n/content/jobs/retry';
  String get contentBackfill => '$_root/platform/i18n/content/backfill';
  String contentReviewAction(
    String entityType,
    String entityId,
    String field,
  ) => '$_root/platform/i18n/content/$entityType/$entityId/$field/review';
  String get platformOverview => '$_root/platform/overview';
  String platformWorkshop(String workshopId) =>
      '$_root/platform/workshops/$workshopId';
  String deactivatePlatformWorkshop(String workshopId) =>
      '$_root/platform/workshops/$workshopId/deactivate';
  String reactivatePlatformWorkshop(String workshopId) =>
      '$_root/platform/workshops/$workshopId/reactivate';

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
  String masterTemplateVersion(String id, String versionId) =>
      '$_root/platform/master/templates/$id/versions/$versionId';
  String masterTemplateVersionItems(String id, String versionId) =>
      '$_root/platform/master/templates/$id/versions/$versionId/items';
  String masterTemplateVersionCategories(String id, String versionId) =>
      '$_root/platform/master/templates/$id/versions/$versionId/categories';
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
  String reportDocumentType(String id) => '$_root/platform/document-types/$id';
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
