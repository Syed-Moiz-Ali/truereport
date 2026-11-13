import '../ui_message_key.dart';

abstract final class PlatformAdminKeys {
  static const alertTranslationIncomplete = UiMessageKey.platformAdmin(
    'alert.translation.incomplete',
  );
  static const alertVersionImmutable = UiMessageKey.platformAdmin(
    'alert.version.immutable',
  );
  static const badgeSafetyCritical = UiMessageKey.platformAdmin(
    'badge.safetyCritical',
  );
  static const buttonAuditExportCsv = UiMessageKey.platformAdmin(
    'button.audit.exportCsv',
  );
  static const buttonAuditExportJson = UiMessageKey.platformAdmin(
    'button.audit.exportJson',
  );
  static const buttonCategoryAdd = UiMessageKey.platformAdmin(
    'button.category.add',
  );
  static const buttonDocumentTypeAdd = UiMessageKey.platformAdmin(
    'button.documentType.add',
  );
  static const buttonHealthReview = UiMessageKey.platformAdmin(
    'button.health.review',
  );
  static const buttonItemAdd = UiMessageKey.platformAdmin('button.item.add');
  static const buttonItemPublish = UiMessageKey.platformAdmin(
    'button.item.publish',
  );
  static const buttonItemRetire = UiMessageKey.platformAdmin(
    'button.item.retire',
  );
  static const buttonItemSaveDraft = UiMessageKey.platformAdmin(
    'button.item.saveDraft',
  );
  static const buttonLanguageAdd = UiMessageKey.platformAdmin(
    'button.language.add',
  );
  static const buttonLanguageCancelGeneration = UiMessageKey.platformAdmin(
    'button.language.cancelGeneration',
  );
  static const buttonLanguageCompleteTranslations = UiMessageKey.platformAdmin(
    'button.language.completeTranslations',
  );
  static const buttonLanguageGenerate = UiMessageKey.platformAdmin(
    'button.language.generate',
  );
  static const buttonLanguagePublish = UiMessageKey.platformAdmin(
    'button.language.publish',
  );
  static const buttonLanguageRetryFailed = UiMessageKey.platformAdmin(
    'button.language.retryFailed',
  );
  static const buttonLanguageReview = UiMessageKey.platformAdmin(
    'button.language.review',
  );
  static const buttonOptionSetAdd = UiMessageKey.platformAdmin(
    'button.optionSet.add',
  );
  static const buttonOptionValueAdd = UiMessageKey.platformAdmin(
    'button.optionValue.add',
  );
  static const buttonPublish = UiMessageKey.platformAdmin('button.publish');
  static const buttonQueueApproveSelected = UiMessageKey.platformAdmin(
    'button.queue.approveSelected',
  );
  static const buttonQueueExport = UiMessageKey.platformAdmin(
    'button.queue.export',
  );
  static const buttonQueuePublishLanguage = UiMessageKey.platformAdmin(
    'button.queue.publishLanguage',
  );
  static const buttonReleaseApprove = UiMessageKey.platformAdmin(
    'button.release.approve',
  );
  static const buttonReleaseCreate = UiMessageKey.platformAdmin(
    'button.release.create',
  );
  static const buttonReleaseDeprecate = UiMessageKey.platformAdmin(
    'button.release.deprecate',
  );
  static const buttonReleasePublish = UiMessageKey.platformAdmin(
    'button.release.publish',
  );
  static const buttonReleaseSubmit = UiMessageKey.platformAdmin(
    'button.release.submit',
  );
  static const buttonRetire = UiMessageKey.platformAdmin('button.retire');
  static const buttonSeedLoadDefault = UiMessageKey.platformAdmin(
    'button.seed.loadDefault',
  );
  static const buttonTemplateAddItem = UiMessageKey.platformAdmin(
    'button.template.addItem',
  );
  static const buttonTemplateApprove = UiMessageKey.platformAdmin(
    'button.template.approve',
  );
  static const buttonTemplateDuplicate = UiMessageKey.platformAdmin(
    'button.template.duplicate',
  );
  static const buttonTemplatePublish = UiMessageKey.platformAdmin(
    'button.template.publish',
  );
  static const buttonTemplateReject = UiMessageKey.platformAdmin(
    'button.template.reject',
  );
  static const buttonUiMessagesReviewApprove = UiMessageKey.platformAdmin(
    'button.uiMessagesReview.approve',
  );
  static const buttonUiMessagesReviewDownload = UiMessageKey.platformAdmin(
    'button.uiMessagesReview.download',
  );
  static const buttonUiMessagesReviewSave = UiMessageKey.platformAdmin(
    'button.uiMessagesReview.save',
  );
  static const buttonViewAll = UiMessageKey.platformAdmin('button.viewAll');
  static const buttonWorkshopAddStaff = UiMessageKey.platformAdmin(
    'button.workshop.addStaff',
  );
  static const buttonWorkshopDeactivate = UiMessageKey.platformAdmin(
    'button.workshop.deactivate',
  );
  static const buttonWorkshopReactivate = UiMessageKey.platformAdmin(
    'button.workshop.reactivate',
  );
  static const chartJobsByStatus = UiMessageKey.platformAdmin(
    'chart.jobs.byStatus',
  );
  static const chartReportsByMonth = UiMessageKey.platformAdmin(
    'chart.reports.byMonth',
  );
  static const dialogCategoryEditTitle = UiMessageKey.platformAdmin(
    'dialog.category.edit.title',
  );
  static const dialogCategoryRetireTitle = UiMessageKey.platformAdmin(
    'dialog.category.retire.title',
  );
  static const dialogImpactAffectedItems = UiMessageKey.platformAdmin(
    'dialog.impact.affectedItems',
  );
  static const dialogImpactAffectedJobs = UiMessageKey.platformAdmin(
    'dialog.impact.affectedJobs',
  );
  static const dialogImpactAffectedTemplates = UiMessageKey.platformAdmin(
    'dialog.impact.affectedTemplates',
  );
  static const dialogImpactTitle = UiMessageKey.platformAdmin(
    'dialog.impact.title',
  );
  static const dialogQueueEditTitle = UiMessageKey.platformAdmin(
    'dialog.queue.edit.title',
  );
  static const dialogRetireConfirm = UiMessageKey.platformAdmin(
    'dialog.retire.confirm',
  );
  static const dialogSeedConfirm = UiMessageKey.platformAdmin(
    'dialog.seed.confirm',
  );
  static const dialogTemplateCreateTitle = UiMessageKey.platformAdmin(
    'dialog.template.create.title',
  );
  static const dialogWorkshopDeactivateConfirm = UiMessageKey.platformAdmin(
    'dialog.workshop.deactivate.confirm',
  );
  static const emptyAlertsBody = UiMessageKey.platformAdmin(
    'empty.alerts.body',
  );
  static const emptyDashboardTitle = UiMessageKey.platformAdmin(
    'empty.dashboard.title',
  );
  static const emptyQueueBody = UiMessageKey.platformAdmin('empty.queue.body');
  static const emptyQueueTitle = UiMessageKey.platformAdmin(
    'empty.queue.title',
  );
  static const emptyTemplateCategory = UiMessageKey.platformAdmin(
    'empty.template.category',
  );
  static const emptyUiMessagesReviewTitle = UiMessageKey.platformAdmin(
    'empty.uiMessagesReview.title',
  );
  static const emptyWorkshopTemplatesBody = UiMessageKey.platformAdmin(
    'empty.workshopTemplates.body',
  );
  static const emptyWorkshopTemplatesTitle = UiMessageKey.platformAdmin(
    'empty.workshopTemplates.title',
  );
  static const emptyWorkshopsBody = UiMessageKey.platformAdmin(
    'empty.workshops.body',
  );
  static const emptyWorkshopsTitle = UiMessageKey.platformAdmin(
    'empty.workshops.title',
  );
  static const fieldCategoryCode = UiMessageKey.platformAdmin(
    'field.category.code',
  );
  static const fieldCategoryNameAr = UiMessageKey.platformAdmin(
    'field.category.nameAr',
  );
  static const fieldCategoryNameEn = UiMessageKey.platformAdmin(
    'field.category.nameEn',
  );
  static const fieldCategoryOrder = UiMessageKey.platformAdmin(
    'field.category.order',
  );
  static const fieldDocumentTypeCode = UiMessageKey.platformAdmin(
    'field.documentType.code',
  );
  static const fieldEvidenceMinNotes = UiMessageKey.platformAdmin(
    'field.evidence.minNotes',
  );
  static const fieldEvidenceMinPhotos = UiMessageKey.platformAdmin(
    'field.evidence.minPhotos',
  );
  static const fieldEvidenceMinVideos = UiMessageKey.platformAdmin(
    'field.evidence.minVideos',
  );
  static const fieldEvidenceRequiredEvidenceType = UiMessageKey.platformAdmin(
    'field.evidence.requiredEvidenceType',
  );
  static const fieldIssueAllowMultiple = UiMessageKey.platformAdmin(
    'field.issue.allowMultiple',
  );
  static const fieldIssueAllowedValues = UiMessageKey.platformAdmin(
    'field.issue.allowedValues',
  );
  static const fieldIssueCode = UiMessageKey.platformAdmin('field.issue.code');
  static const fieldIssueDecimalPlaces = UiMessageKey.platformAdmin(
    'field.issue.decimalPlaces',
  );
  static const fieldIssueDependsOn = UiMessageKey.platformAdmin(
    'field.issue.dependsOn',
  );
  static const fieldIssueDependsOnValue = UiMessageKey.platformAdmin(
    'field.issue.dependsOnValue',
  );
  static const fieldIssueInputType = UiMessageKey.platformAdmin(
    'field.issue.inputType',
  );
  static const fieldIssueOptionSet = UiMessageKey.platformAdmin(
    'field.issue.optionSet',
  );
  static const fieldIssueRequiredForStatuses = UiMessageKey.platformAdmin(
    'field.issue.requiredForStatuses',
  );
  static const fieldItemAllowFreeText = UiMessageKey.platformAdmin(
    'field.item.allowFreeText',
  );
  static const fieldItemCode = UiMessageKey.platformAdmin('field.item.code');
  static const fieldItemInstructionAr = UiMessageKey.platformAdmin(
    'field.item.instructionAr',
  );
  static const fieldItemInstructionEn = UiMessageKey.platformAdmin(
    'field.item.instructionEn',
  );
  static const fieldItemLabelAr = UiMessageKey.platformAdmin(
    'field.item.labelAr',
  );
  static const fieldItemLabelEn = UiMessageKey.platformAdmin(
    'field.item.labelEn',
  );
  static const fieldItemMaxTyreAge = UiMessageKey.platformAdmin(
    'field.item.maxTyreAge',
  );
  static const fieldItemMeasurementUnit = UiMessageKey.platformAdmin(
    'field.item.measurementUnit',
  );
  static const fieldItemMultiPoint = UiMessageKey.platformAdmin(
    'field.item.multiPoint',
  );
  static const fieldItemSensorTool = UiMessageKey.platformAdmin(
    'field.item.sensorTool',
  );
  static const fieldItemStandardSpecAr = UiMessageKey.platformAdmin(
    'field.item.standardSpecAr',
  );
  static const fieldItemStandardSpecEn = UiMessageKey.platformAdmin(
    'field.item.standardSpecEn',
  );
  static const fieldLanguageCode = UiMessageKey.platformAdmin(
    'field.language.code',
  );
  static const fieldLanguageDirection = UiMessageKey.platformAdmin(
    'field.language.direction',
  );
  static const fieldLanguageNativeName = UiMessageKey.platformAdmin(
    'field.language.nativeName',
  );
  static const fieldLanguageUiMessagesPath = UiMessageKey.platformAdmin(
    'field.language.uiMessagesPath',
  );
  static const fieldMeasureDirection = UiMessageKey.platformAdmin(
    'field.measure.direction',
  );
  static const fieldMeasureMax = UiMessageKey.platformAdmin(
    'field.measure.max',
  );
  static const fieldMeasureMin = UiMessageKey.platformAdmin(
    'field.measure.min',
  );
  static const fieldReleaseEntityId = UiMessageKey.platformAdmin(
    'field.release.entityId',
  );
  static const fieldReleaseEntityType = UiMessageKey.platformAdmin(
    'field.release.entityType',
  );
  static const fieldReleaseNotes = UiMessageKey.platformAdmin(
    'field.release.notes',
  );
  static const fieldTemplateCode = UiMessageKey.platformAdmin(
    'field.template.code',
  );
  static const fieldTemplateDescription = UiMessageKey.platformAdmin(
    'field.template.description',
  );
  static const fieldTemplateDescriptionAr = UiMessageKey.platformAdmin(
    'field.template.descriptionAr',
  );
  static const fieldTemplateDescriptionEn = UiMessageKey.platformAdmin(
    'field.template.descriptionEn',
  );
  static const fieldTemplateName = UiMessageKey.platformAdmin(
    'field.template.name',
  );
  static const fieldTemplateNameAr = UiMessageKey.platformAdmin(
    'field.template.nameAr',
  );
  static const fieldTemplateNameEn = UiMessageKey.platformAdmin(
    'field.template.nameEn',
  );
  static const fieldWorkshopBranch = UiMessageKey.platformAdmin(
    'field.workshop.branch',
  );
  static const fieldWorkshopCapacity = UiMessageKey.platformAdmin(
    'field.workshop.capacity',
  );
  static const fieldWorkshopContactEmail = UiMessageKey.platformAdmin(
    'field.workshop.contactEmail',
  );
  static const fieldWorkshopCreatedOn = UiMessageKey.platformAdmin(
    'field.workshop.createdOn',
  );
  static const fieldWorkshopName = UiMessageKey.platformAdmin(
    'field.workshop.name',
  );
  static const filterAllCategories = UiMessageKey.platformAdmin(
    'filter.allCategories',
  );
  static const filterAuditAction = UiMessageKey.platformAdmin(
    'filter.audit.action',
  );
  static const filterAuditActor = UiMessageKey.platformAdmin(
    'filter.audit.actor',
  );
  static const filterAuditDateFrom = UiMessageKey.platformAdmin(
    'filter.audit.dateFrom',
  );
  static const filterAuditDateTo = UiMessageKey.platformAdmin(
    'filter.audit.dateTo',
  );
  static const filterAuditEntityType = UiMessageKey.platformAdmin(
    'filter.audit.entityType',
  );
  static const filterAuditNewestFirst = UiMessageKey.platformAdmin(
    'filter.audit.newestFirst',
  );
  static const filterAuditOldestFirst = UiMessageKey.platformAdmin(
    'filter.audit.oldestFirst',
  );
  static const filterAuditSearch = UiMessageKey.platformAdmin(
    'filter.audit.search',
  );
  static const filterCategory = UiMessageKey.platformAdmin('filter.category');
  static const filterCategorySearch = UiMessageKey.platformAdmin(
    'filter.category.search',
  );
  static const filterOptionSetsSearch = UiMessageKey.platformAdmin(
    'filter.optionSets.search',
  );
  static const filterOptionValuesSearch = UiMessageKey.platformAdmin(
    'filter.optionValues.search',
  );
  static const filterQueueMissingOnly = UiMessageKey.platformAdmin(
    'filter.queue.missingOnly',
  );
  static const filterQueueSearch = UiMessageKey.platformAdmin(
    'filter.queue.search',
  );
  static const filterTemplateSearchCategories = UiMessageKey.platformAdmin(
    'filter.template.searchCategories',
  );
  static const filterTemplateSearchItems = UiMessageKey.platformAdmin(
    'filter.template.searchItems',
  );
  static const filterUiMessagesReviewAll = UiMessageKey.platformAdmin(
    'filter.uiMessagesReview.all',
  );
  static const filterUiMessagesReviewChanged = UiMessageKey.platformAdmin(
    'filter.uiMessagesReview.changed',
  );
  static const filterUiMessagesReviewMissing = UiMessageKey.platformAdmin(
    'filter.uiMessagesReview.missing',
  );
  static const filterUiMessagesReviewSearch = UiMessageKey.platformAdmin(
    'filter.uiMessagesReview.search',
  );
  static const filterUiMessagesReviewUntranslated = UiMessageKey.platformAdmin(
    'filter.uiMessagesReview.untranslated',
  );
  static const filterWorkshopsSearch = UiMessageKey.platformAdmin(
    'filter.workshops.search',
  );
  static const headerAccount = UiMessageKey.platformAdmin('header.account');
  static const headerHelp = UiMessageKey.platformAdmin('header.help');
  static const headerHelpBody = UiMessageKey.platformAdmin('header.help.body');
  static const headerHelpContact = UiMessageKey.platformAdmin(
    'header.help.contact',
  );
  static const headerHelpDocs = UiMessageKey.platformAdmin('header.help.docs');
  static const headerHelpTitle = UiMessageKey.platformAdmin(
    'header.help.title',
  );
  static const headerLanguage = UiMessageKey.platformAdmin('header.language');
  static const headerNotifications = UiMessageKey.platformAdmin(
    'header.notifications',
  );
  static const headerNotificationsEmpty = UiMessageKey.platformAdmin(
    'header.notifications.empty',
  );
  static const headerNotificationsEmptyBody = UiMessageKey.platformAdmin(
    'header.notifications.emptyBody',
  );
  static const headerNotificationsTitle = UiMessageKey.platformAdmin(
    'header.notifications.title',
  );
  static const headerSearchHint = UiMessageKey.platformAdmin(
    'header.search.hint',
  );
  static const headerSearchHintCompact = UiMessageKey.platformAdmin(
    'header.search.hintCompact',
  );
  static const headerSwitchToArabic = UiMessageKey.platformAdmin(
    'header.switchToArabic',
  );
  static const headerSwitchToEnglish = UiMessageKey.platformAdmin(
    'header.switchToEnglish',
  );
  static const headerTitle = UiMessageKey.platformAdmin('header.title');
  static const helpStepBasics = UiMessageKey.platformAdmin('help.step.basics');
  static const helpStepContent = UiMessageKey.platformAdmin(
    'help.step.content',
  );
  static const helpStepEvidence = UiMessageKey.platformAdmin(
    'help.step.evidence',
  );
  static const helpStepIssueOptions = UiMessageKey.platformAdmin(
    'help.step.issueOptions',
  );
  static const helpStepMeasurements = UiMessageKey.platformAdmin(
    'help.step.measurements',
  );
  static const helpStepReview = UiMessageKey.platformAdmin('help.step.review');
  static const kpiChecklistHealth = UiMessageKey.platformAdmin(
    'kpi.checklist.health',
  );
  static const kpiJobsActive = UiMessageKey.platformAdmin('kpi.jobs.active');
  static const kpiLanguagesLive = UiMessageKey.platformAdmin(
    'kpi.languages.live',
  );
  static const kpiReportsPublished = UiMessageKey.platformAdmin(
    'kpi.reports.published',
  );
  static const kpiReviewsPending = UiMessageKey.platformAdmin(
    'kpi.reviews.pending',
  );
  static const kpiTechnicians = UiMessageKey.platformAdmin('kpi.technicians');
  static const kpiWorkshopsActive = UiMessageKey.platformAdmin(
    'kpi.workshops.active',
  );
  static const kpiWorkshopsTotal = UiMessageKey.platformAdmin(
    'kpi.workshops.total',
  );
  static const labelDirectionLtr = UiMessageKey.platformAdmin(
    'label.direction.ltr',
  );
  static const labelDirectionRtl = UiMessageKey.platformAdmin(
    'label.direction.rtl',
  );
  static const labelEntityTypeCategory = UiMessageKey.platformAdmin(
    'label.entityType.category',
  );
  static const labelEntityTypeItem = UiMessageKey.platformAdmin(
    'label.entityType.item',
  );
  static const labelEntityTypeScoringRule = UiMessageKey.platformAdmin(
    'label.entityType.scoringRule',
  );
  static const labelEntityTypeTemplate = UiMessageKey.platformAdmin(
    'label.entityType.template',
  );
  static const labelEvidenceTypeDocument = UiMessageKey.platformAdmin(
    'label.evidenceType.document',
  );
  static const labelEvidenceTypeNone = UiMessageKey.platformAdmin(
    'label.evidenceType.none',
  );
  static const labelEvidenceTypePhoto = UiMessageKey.platformAdmin(
    'label.evidenceType.photo',
  );
  static const labelEvidenceTypeVideo = UiMessageKey.platformAdmin(
    'label.evidenceType.video',
  );
  static const labelInputTypeBoolean = UiMessageKey.platformAdmin(
    'label.inputType.boolean',
  );
  static const labelInputTypeMultiSelect = UiMessageKey.platformAdmin(
    'label.inputType.multiSelect',
  );
  static const labelInputTypeNumber = UiMessageKey.platformAdmin(
    'label.inputType.number',
  );
  static const labelInputTypeSelect = UiMessageKey.platformAdmin(
    'label.inputType.select',
  );
  static const labelInputTypeText = UiMessageKey.platformAdmin(
    'label.inputType.text',
  );
  static const labelMeasureDirectionHigherIsBetter = UiMessageKey.platformAdmin(
    'label.measureDirection.higherIsBetter',
  );
  static const labelMeasureDirectionLowerIsBetter = UiMessageKey.platformAdmin(
    'label.measureDirection.lowerIsBetter',
  );
  static const labelNamespace = UiMessageKey.platformAdmin('label.namespace');
  static const labelOptionValue = UiMessageKey.platformAdmin(
    'label.optionValue',
  );
  static const labelResultCodeAttentionRecommended = UiMessageKey.platformAdmin(
    'label.resultCode.attentionRecommended',
  );
  static const labelResultCodeDefectFound = UiMessageKey.platformAdmin(
    'label.resultCode.defectFound',
  );
  static const labelResultCodeNoIssueObserved = UiMessageKey.platformAdmin(
    'label.resultCode.noIssueObserved',
  );
  static const labelUiMessages = UiMessageKey.platformAdmin('label.uiMessages');
  static const loginAppName = UiMessageKey.platformAdmin('login.appName');
  static const loginAuthorizedEyebrow = UiMessageKey.platformAdmin(
    'login.authorizedEyebrow',
  );
  static const loginChallengeBody = UiMessageKey.platformAdmin(
    'login.challengeBody',
  );
  static const loginChallengeTitle = UiMessageKey.platformAdmin(
    'login.challengeTitle',
  );
  static const loginCodeHint = UiMessageKey.platformAdmin('login.codeHint');
  static const loginCodeLabel = UiMessageKey.platformAdmin('login.codeLabel');
  static const loginEmailHint = UiMessageKey.platformAdmin('login.emailHint');
  static const loginEmailLabel = UiMessageKey.platformAdmin('login.emailLabel');
  static const loginFeatureChecklistDesc = UiMessageKey.platformAdmin(
    'login.featureChecklistDesc',
  );
  static const loginFeatureChecklistTitle = UiMessageKey.platformAdmin(
    'login.featureChecklistTitle',
  );
  static const loginFeatureLedgerDesc = UiMessageKey.platformAdmin(
    'login.featureLedgerDesc',
  );
  static const loginFeatureLedgerTitle = UiMessageKey.platformAdmin(
    'login.featureLedgerTitle',
  );
  static const loginFeatureWorkshopsDesc = UiMessageKey.platformAdmin(
    'login.featureWorkshopsDesc',
  );
  static const loginFeatureWorkshopsTitle = UiMessageKey.platformAdmin(
    'login.featureWorkshopsTitle',
  );
  static const loginFooter = UiMessageKey.platformAdmin('login.footer');
  static const loginLanguageLabel = UiMessageKey.platformAdmin(
    'login.languageLabel',
  );
  static const loginNeedHelp = UiMessageKey.platformAdmin('login.needHelp');
  static const loginPasswordHint = UiMessageKey.platformAdmin(
    'login.passwordHint',
  );
  static const loginPasswordLabel = UiMessageKey.platformAdmin(
    'login.passwordLabel',
  );
  static const loginPortalBadge = UiMessageKey.platformAdmin(
    'login.portalBadge',
  );
  static const loginPortalTitle = UiMessageKey.platformAdmin(
    'login.portalTitle',
  );
  static const loginRememberTerminal = UiMessageKey.platformAdmin(
    'login.rememberTerminal',
  );
  static const loginShowcaseEyebrow = UiMessageKey.platformAdmin(
    'login.showcaseEyebrow',
  );
  static const loginShowcaseHeadline = UiMessageKey.platformAdmin(
    'login.showcaseHeadline',
  );
  static const loginShowcaseSubtitle = UiMessageKey.platformAdmin(
    'login.showcaseSubtitle',
  );
  static const loginSignInButton = UiMessageKey.platformAdmin(
    'login.signInButton',
  );
  static const loginSignInSubtitle = UiMessageKey.platformAdmin(
    'login.signInSubtitle',
  );
  static const loginSignInTitle = UiMessageKey.platformAdmin(
    'login.signInTitle',
  );
  static const loginStatusDetails = UiMessageKey.platformAdmin(
    'login.statusDetails',
  );
  static const loginStatusLabel = UiMessageKey.platformAdmin(
    'login.statusLabel',
  );
  static const loginStatusSecured = UiMessageKey.platformAdmin(
    'login.statusSecured',
  );
  static const loginVerifyButton = UiMessageKey.platformAdmin(
    'login.verifyButton',
  );
  static const navChecklist = UiMessageKey.platformAdmin('nav.checklist');
  static const navDashboard = UiMessageKey.platformAdmin('nav.dashboard');
  static const navReports = UiMessageKey.platformAdmin('nav.reports');
  static const navWorkshops = UiMessageKey.platformAdmin('nav.workshops');
  static const pageAuditEyebrow = UiMessageKey.platformAdmin(
    'page.audit.eyebrow',
  );
  static const pageAuditSubtitle = UiMessageKey.platformAdmin(
    'page.audit.subtitle',
  );
  static const pageAuditTitle = UiMessageKey.platformAdmin('page.audit.title');
  static const pageChecklistHelper = UiMessageKey.platformAdmin(
    'page.checklist.helper',
  );
  static const pageChecklistItemsResultCount = UiMessageKey.platformAdmin(
    'page.checklist.items.resultCount',
  );
  static const pageChecklistItemsTitle = UiMessageKey.platformAdmin(
    'page.checklist.items.title',
  );
  static const pageChecklistTitle = UiMessageKey.platformAdmin(
    'page.checklist.title',
  );
  static const pageDashboardSubtitle = UiMessageKey.platformAdmin(
    'page.dashboard.subtitle',
  );
  static const pageDashboardTitle = UiMessageKey.platformAdmin(
    'page.dashboard.title',
  );
  static const pageDocumentTypesTitle = UiMessageKey.platformAdmin(
    'page.documentTypes.title',
  );
  static const pageHealthTitle = UiMessageKey.platformAdmin(
    'page.health.title',
  );
  static const pageIssueOptionsHelper = UiMessageKey.platformAdmin(
    'page.issueOptions.helper',
  );
  static const pageIssueOptionsInlineHint = UiMessageKey.platformAdmin(
    'page.issueOptions.inlineHint',
  );
  static const pageItemEditorTitle = UiMessageKey.platformAdmin(
    'page.item.editor.title',
  );
  static const pageLanguagesCoverage = UiMessageKey.platformAdmin(
    'page.languages.coverage',
  );
  static const pageLanguagesDefaultLanguage = UiMessageKey.platformAdmin(
    'page.languages.defaultLanguage',
  );
  static const pageLanguagesMissingTranslations = UiMessageKey.platformAdmin(
    'page.languages.missingTranslations',
  );
  static const pageLanguagesTitle = UiMessageKey.platformAdmin(
    'page.languages.title',
  );
  static const pageMasterLibraryHeading = UiMessageKey.platformAdmin(
    'page.masterLibrary.heading',
  );
  static const pageReleasesTitle = UiMessageKey.platformAdmin(
    'page.releases.title',
  );
  static const pageReportsTitle = UiMessageKey.platformAdmin(
    'page.reports.title',
  );
  static const pageSettingsHeading = UiMessageKey.platformAdmin(
    'page.settings.heading',
  );
  static const pageSettingsSubtitle = UiMessageKey.platformAdmin(
    'page.settings.subtitle',
  );
  static const pageSettingsTitle = UiMessageKey.platformAdmin(
    'page.settings.title',
  );
  static const pageTemplateBuilderTitle = UiMessageKey.platformAdmin(
    'page.template.builder.title',
  );
  static const pageTemplateProgressCategories = UiMessageKey.platformAdmin(
    'page.template.progress.categories',
  );
  static const pageTemplateProgressItems = UiMessageKey.platformAdmin(
    'page.template.progress.items',
  );
  static const pageTemplatesCreate = UiMessageKey.platformAdmin(
    'page.templates.create',
  );
  static const pageTemplatesHelper = UiMessageKey.platformAdmin(
    'page.templates.helper',
  );
  static const pageTemplatesTitle = UiMessageKey.platformAdmin(
    'page.templates.title',
  );
  static const pageTemplatesUpdatedOn = UiMessageKey.platformAdmin(
    'page.templates.updatedOn',
  );
  static const pageTranslationQueueTitle = UiMessageKey.platformAdmin(
    'page.translationQueue.title',
  );
  static const pageUiMessagesReviewSubtitle = UiMessageKey.platformAdmin(
    'page.uiMessagesReview.subtitle',
  );
  static const pageUiMessagesReviewTitle = UiMessageKey.platformAdmin(
    'page.uiMessagesReview.title',
  );
  static const pageWorkshopTemplatesHelper = UiMessageKey.platformAdmin(
    'page.workshopTemplates.helper',
  );
  static const pageWorkshopsAdd = UiMessageKey.platformAdmin(
    'page.workshops.add',
  );
  static const pageWorkshopsEdit = UiMessageKey.platformAdmin(
    'page.workshops.edit',
  );
  static const pageWorkshopsRegister = UiMessageKey.platformAdmin(
    'page.workshops.register',
  );
  static const pageWorkshopsResultCount = UiMessageKey.platformAdmin(
    'page.workshops.resultCount',
  );
  static const pageWorkshopsSubtitle = UiMessageKey.platformAdmin(
    'page.workshops.subtitle',
  );
  static const paginationOf = UiMessageKey.platformAdmin('pagination.of');
  static const paginationPageInfo = UiMessageKey.platformAdmin(
    'pagination.pageInfo',
  );
  static const queueApproved = UiMessageKey.platformAdmin('queue.approved');
  static const queueDraft = UiMessageKey.platformAdmin('queue.draft');
  static const queueMissing = UiMessageKey.platformAdmin('queue.missing');
  static const queueReviewed = UiMessageKey.platformAdmin('queue.reviewed');
  static const queueTotal = UiMessageKey.platformAdmin('queue.total');
  static const sectionDashboardAlerts = UiMessageKey.platformAdmin(
    'section.dashboard.alerts',
  );
  static const sectionDashboardKpis = UiMessageKey.platformAdmin(
    'section.dashboard.kpis',
  );
  static const sectionDashboardQuickActions = UiMessageKey.platformAdmin(
    'section.dashboard.quickActions',
  );
  static const sectionDashboardRecentActivity = UiMessageKey.platformAdmin(
    'section.dashboard.recentActivity',
  );
  static const sectionItemAdvanced = UiMessageKey.platformAdmin(
    'section.item.advanced',
  );
  static const sectionItemBasics = UiMessageKey.platformAdmin(
    'section.item.basics',
  );
  static const sectionItemEvidenceRules = UiMessageKey.platformAdmin(
    'section.item.evidenceRules',
  );
  static const sectionItemGuideImage = UiMessageKey.platformAdmin(
    'section.item.guideImage',
  );
  static const sectionItemIssueFields = UiMessageKey.platformAdmin(
    'section.item.issueFields',
  );
  static const sectionItemMeasurementBands = UiMessageKey.platformAdmin(
    'section.item.measurementBands',
  );
  static const sectionLanguagesCoverage = UiMessageKey.platformAdmin(
    'section.languages.coverage',
  );
  static const sectionOptionSetValues = UiMessageKey.platformAdmin(
    'section.optionSet.values',
  );
  static const sectionReportsDocuments = UiMessageKey.platformAdmin(
    'section.reports.documents',
  );
  static const sectionTemplateVersionHistory = UiMessageKey.platformAdmin(
    'section.template.versionHistory',
  );
  static const sectionWorkshopAdmins = UiMessageKey.platformAdmin(
    'section.workshop.admins',
  );
  static const sectionWorkshopContact = UiMessageKey.platformAdmin(
    'section.workshop.contact',
  );
  static const sectionWorkshopPendingInvitations = UiMessageKey.platformAdmin(
    'section.workshop.pendingInvitations',
  );
  static const sectionWorkshopTechnicians = UiMessageKey.platformAdmin(
    'section.workshop.technicians',
  );
  static const settingsScopeBadge = UiMessageKey.platformAdmin(
    'settings.scopeBadge',
  );
  static const statusLanguageDraft = UiMessageKey.platformAdmin(
    'status.language.draft',
  );
  static const statusLanguageLive = UiMessageKey.platformAdmin(
    'status.language.live',
  );
  static const statusLanguageRetired = UiMessageKey.platformAdmin(
    'status.language.retired',
  );
  static const statusLanguageReview = UiMessageKey.platformAdmin(
    'status.language.review',
  );
  static const statusLanguageTranslating = UiMessageKey.platformAdmin(
    'status.language.translating',
  );
  static const statusPublished = UiMessageKey.platformAdmin('status.published');
  static const stepCounter = UiMessageKey.platformAdmin('step.counter');
  static const stepItemBasics = UiMessageKey.platformAdmin('step.item.basics');
  static const stepItemContent = UiMessageKey.platformAdmin(
    'step.item.content',
  );
  static const stepItemEvidence = UiMessageKey.platformAdmin(
    'step.item.evidence',
  );
  static const stepItemIssueOptions = UiMessageKey.platformAdmin(
    'step.item.issueOptions',
  );
  static const stepItemMeasurements = UiMessageKey.platformAdmin(
    'step.item.measurements',
  );
  static const stepItemReview = UiMessageKey.platformAdmin('step.item.review');
  static const stepTemplateCategories = UiMessageKey.platformAdmin(
    'step.template.categories',
  );
  static const stepTemplateDetails = UiMessageKey.platformAdmin(
    'step.template.details',
  );
  static const stepTemplateReview = UiMessageKey.platformAdmin(
    'step.template.review',
  );
  static const tabChecklistCategories = UiMessageKey.platformAdmin(
    'tab.checklist.categories',
  );
  static const tabChecklistHealth = UiMessageKey.platformAdmin(
    'tab.checklist.health',
  );
  static const tabChecklistIssueOptions = UiMessageKey.platformAdmin(
    'tab.checklist.issueOptions',
  );
  static const tabChecklistItems = UiMessageKey.platformAdmin(
    'tab.checklist.items',
  );
  static const tabChecklistOptionSets = UiMessageKey.platformAdmin(
    'tab.checklist.optionSets',
  );
  static const tabChecklistTemplates = UiMessageKey.platformAdmin(
    'tab.checklist.templates',
  );
  static const tabItemArabic = UiMessageKey.platformAdmin('tab.item.arabic');
  static const tabItemEnglish = UiMessageKey.platformAdmin('tab.item.english');
  static const tabTemplates = UiMessageKey.platformAdmin('tab.templates');
  static const tabWorkshopActivity = UiMessageKey.platformAdmin(
    'tab.workshop.activity',
  );
  static const tabWorkshopOverview = UiMessageKey.platformAdmin(
    'tab.workshop.overview',
  );
  static const tabWorkshopStaff = UiMessageKey.platformAdmin(
    'tab.workshop.staff',
  );
  static const tabWorkshopTemplates = UiMessageKey.platformAdmin(
    'tab.workshop.templates',
  );
  static const tableAuditActor = UiMessageKey.platformAdmin(
    'table.audit.actor',
  );
  static const tableAuditEntity = UiMessageKey.platformAdmin(
    'table.audit.entity',
  );
  static const tableAuditOccurredAt = UiMessageKey.platformAdmin(
    'table.audit.occurredAt',
  );
  static const tableItemEvidence = UiMessageKey.platformAdmin(
    'table.item.evidence',
  );
  static const tableItemUpdated = UiMessageKey.platformAdmin(
    'table.item.updated',
  );
  static const tableOptionValueUsedBy = UiMessageKey.platformAdmin(
    'table.optionValue.usedBy',
  );
  static const tableQueueDefaultText = UiMessageKey.platformAdmin(
    'table.queue.defaultText',
  );
  static const tableQueueEntityType = UiMessageKey.platformAdmin(
    'table.queue.entityType',
  );
  static const tableQueueTranslation = UiMessageKey.platformAdmin(
    'table.queue.translation',
  );
  static const tableUiMessagesReviewKey = UiMessageKey.platformAdmin(
    'table.uiMessagesReview.key',
  );
  static const tableUiMessagesReviewSource = UiMessageKey.platformAdmin(
    'table.uiMessagesReview.source',
  );
  static const tableUiMessagesReviewTarget = UiMessageKey.platformAdmin(
    'table.uiMessagesReview.target',
  );
  static const toastItemCreated = UiMessageKey.platformAdmin(
    'toast.item.created',
  );
  static const toastItemPublished = UiMessageKey.platformAdmin(
    'toast.item.published',
  );
  static const toastItemRetired = UiMessageKey.platformAdmin(
    'toast.item.retired',
  );
  static const toastSeedFailed = UiMessageKey.platformAdmin(
    'toast.seed.failed',
  );
  static const toastSeedSuccess = UiMessageKey.platformAdmin(
    'toast.seed.success',
  );
  static const toastUiMessagesReviewApproved = UiMessageKey.platformAdmin(
    'toast.uiMessagesReview.approved',
  );
  static const toastUiMessagesReviewSaved = UiMessageKey.platformAdmin(
    'toast.uiMessagesReview.saved',
  );
  static const validationLanguagePublishBlocked = UiMessageKey.platformAdmin(
    'validation.language.publishBlocked',
  );
}
