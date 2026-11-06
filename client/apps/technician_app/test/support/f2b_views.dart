import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:l10n/l10n.dart';
import 'package:l10n/l10n/gen/app_localizations_en.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/screens/f2b/defect_detail_view.dart';
import 'package:technician_app/src/screens/f2b/dense_mechanical_view.dart';
import 'package:technician_app/src/screens/f2b/final_review_view.dart';
import 'package:technician_app/src/screens/f2b/finalize_view.dart';
import 'package:technician_app/src/screens/f2b/offline_sync_view.dart';
import 'package:technician_app/src/screens/f2b/success_view.dart';

import 'f2a_fixture_data.dart';
import 'figma_l10n_override.dart';

const f2bScreenIds = <String>[
  'defect-detail',
  'dense-mechanical',
  'final-review',
  'finalize',
  'offline-sync',
  'success',
];

/// Figma frame heights at 390 logical width (from docs/ui/figma/f2b-nodes).
const f2bHeights = <String, double>{
  'defect-detail': 1032,
  'dense-mechanical': 1080,
  'final-review': 1008,
  'finalize': 1232,
  'offline-sync': 1362,
  'success': 884,
};

/// Test-only Figma wording for F2-B chrome copy.
///
/// Data wording (names, labels, references) travels through the normal model
/// fields (see [f2bScreen] `figma: true`). Chrome copy travels here through
/// the regular [AppLocalizations] API so production widgets render Figma text
/// without any `figmaText` switch in `lib/`. English only.
abstract final class F2bFigmaStrings {
  // Defect detail (09).
  static const inspectionStatus = 'Inspection Status';
  static const defectClassification = 'Defect Classification';
  static const photographicEvidence = 'Photographic Evidence';
  static const saveDefect = 'Save Defect';
  static const takePhoto = 'Take a photo';
  static const tapToCapture = 'Tap to capture';
  static const defectNoteHint = 'Add defect notes (e.g. 2.5cm door ding)...';
  static const ofRequired = '1 of 4 Required';
  static const oneSelected = '1 Selected';

  // Dense mechanical (11).
  static const confirmFluidLevels = 'Confirm Fluid Levels';
  static const checkpointsLogged = '3 of 6 checkpoints logged';

  // Final review (13).
  static const reviewFindings = 'Review Findings';
  static const resolveToContinue = 'Resolve to Continue';

  // Finalize (14).
  static const reviewFinalizeTitle = 'Review & Finalize';
  static const finalizeAction = 'Slide to Finalize Inspection';
  static const slideToFinalize = 'Slide to Finalize Inspection';
  static const flaggedSummary = 'Flagged Items Summary';

  // Offline sync (15).
  static const syncStatus = 'Sync Status';
  static const uploadQueue = 'Upload Queue';
  static const retrySyncNow = 'Retry Sync Now';

  // Success (16).
  static const inspectionFinalizedTitle = 'Inspection Finalized';
  static const backToJobs = 'Back to Job List';
}

class F2bFigmaTestLocalizations extends AppLocalizationsEn {
  F2bFigmaTestLocalizations() : super('en');

  @override
  String get result => F2bFigmaStrings.inspectionStatus;

  @override
  String get severity => F2bFigmaStrings.defectClassification;

  @override
  String get attachments => F2bFigmaStrings.photographicEvidence;

  @override
  String get saveAnswer => F2bFigmaStrings.saveDefect;

  @override
  String get addPhoto => F2bFigmaStrings.takePhoto;

  @override
  String get photoRequired => F2bFigmaStrings.tapToCapture;

  @override
  String get note => F2bFigmaStrings.defectNoteHint;

  @override
  String get reviewAndFinalize => F2bFigmaStrings.reviewFinalizeTitle;

  @override
  String get finalize => F2bFigmaStrings.finalizeAction;

  @override
  String get syncQueue => F2bFigmaStrings.uploadQueue;

  @override
  String get syncNow => F2bFigmaStrings.retrySyncNow;

  @override
  String get finalizedSuccessfully => F2bFigmaStrings.inspectionFinalizedTitle;

  @override
  String get technicianJobsTitle => F2bFigmaStrings.backToJobs;

  @override
  String get technicianSyncTitle => F2bFigmaStrings.syncStatus;

  @override
  String get noIssueObserved => 'Pass';

  @override
  String get attentionRecommended => 'Minor';

  @override
  String get defectFound => 'Major';

  @override
  String get checklist => 'Diagnostic Checklist';
}

class F2bFigmaTestLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const F2bFigmaTestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      F2bFigmaTestLocalizations();

  @override
  bool shouldReload(F2bFigmaTestLocalizationsDelegate old) => false;
}

const f2bFigmaLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  F2bFigmaTestLocalizationsDelegate(),
  // Fall back to the F2-A Figma override for any key not covered above would
  // need chaining; instead keep product English for the rest via the real
  // delegate order: Figma delegate first, then globals. Keys not overridden
  // fall through to AppLocalizationsEn defaults? No — the delegate replaces
  // AppLocalizations entirely, so every non-overridden getter returns real
  // English copy from AppLocalizationsEn. That is exactly what we want.
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

InspectionItem _f2bFigmaItem() => const InspectionItem(
  inspectionItemId: 'item-door-fl',
  masterItemVersionId: 'master-door-fl',
  sortOrder: 0,
  stableCode: 'F2B-DOOR-FL',
  categoryLabelEn: 'EXTERIOR BODYWORK',
  categoryLabelAr: 'EXTERIOR BODYWORK',
  labelEn: 'Front Left Door',
  labelAr: 'Front Left Door',
  instructionEn: 'Inspect the front left door.',
  instructionAr: 'افحص الباب الأمامي الأيسر.',
  versionNo: 1,
  resultOptions: [
    'NO_ISSUE_OBSERVED',
    'ATTENTION_RECOMMENDED',
    'DEFECT_FOUND',
    'NOT_CHECKED',
    'NOT_APPLICABLE',
    'COULD_NOT_VERIFY',
  ],
  severityPolicy: '{}',
  applicability: '{}',
  reasonCodes: [],
  noteRequirement: 'NONE',
  evidenceRequirement: 'NONE',
  minPhotos: 4,
  equipmentIds: [],
  guideImageId: null,
  sampleData: true,
  assessment: null,
);

InspectionItem _f2bProductItem() => const InspectionItem(
  inspectionItemId: 'item-brake-pad',
  masterItemVersionId: 'master-brake-pad',
  sortOrder: 0,
  stableCode: 'F2B-BRAKE-PAD',
  categoryLabelEn: 'Braking',
  categoryLabelAr: 'الفرامل',
  labelEn: 'Brake pad thickness',
  labelAr: 'سماكة وسادة الفرامل',
  instructionEn: 'Measure pad thickness.',
  instructionAr: 'قس سماكة الوسادة.',
  versionNo: 1,
  resultOptions: [
    'NO_ISSUE_OBSERVED',
    'ATTENTION_RECOMMENDED',
    'DEFECT_FOUND',
    'NOT_CHECKED',
    'NOT_APPLICABLE',
    'COULD_NOT_VERIFY',
  ],
  severityPolicy: '{}',
  applicability: '{}',
  reasonCodes: [],
  noteRequirement: 'NONE',
  evidenceRequirement: 'NONE',
  minPhotos: 1,
  equipmentIds: [],
  guideImageId: null,
  sampleData: false,
  assessment: null,
);

InspectionChecklist _f2bChecklist({required bool figma}) {
  if (figma) {
    final base = figmaChecklist();
    final items = <InspectionItem>[
      const InspectionItem(
        inspectionItemId: 'mech-oil',
        masterItemVersionId: 'master-mech-oil',
        sortOrder: 0,
        stableCode: 'F2B-OIL',
        categoryLabelEn: 'INSPECTION ZONE 04',
        categoryLabelAr: 'INSPECTION ZONE 04',
        labelEn: 'Engine Oil Level',
        labelAr: 'Engine Oil Level',
        instructionEn: 'Dipstick at optimal line.',
        instructionAr: 'مستوى الزيت.',
        versionNo: 1,
        resultOptions: [
          'NO_ISSUE_OBSERVED',
          'ATTENTION_RECOMMENDED',
          'DEFECT_FOUND',
        ],
        severityPolicy: '{}',
        applicability: '{}',
        reasonCodes: [],
        noteRequirement: 'NONE',
        evidenceRequirement: 'NONE',
        minPhotos: 0,
        equipmentIds: [],
        guideImageId: null,
        sampleData: true,
        assessment: InspectionAssessment(
          id: 'a-oil',
          resultCode: 'NO_ISSUE_OBSERVED',
          severityCode: null,
          note: null,
          noteLanguage: null,
          reasonCode: null,
          reasonText: null,
          clientRevision: 1,
          serverRevision: 1,
          version: 1,
        ),
      ),
      const InspectionItem(
        inspectionItemId: 'mech-coolant',
        masterItemVersionId: 'master-mech-coolant',
        sortOrder: 1,
        stableCode: 'F2B-COOLANT',
        categoryLabelEn: 'INSPECTION ZONE 04',
        categoryLabelAr: 'INSPECTION ZONE 04',
        labelEn: 'Coolant',
        labelAr: 'Coolant',
        instructionEn: 'Expansion reservoir inspection.',
        instructionAr: 'فحص الخزان.',
        versionNo: 1,
        resultOptions: [
          'NO_ISSUE_OBSERVED',
          'ATTENTION_RECOMMENDED',
          'DEFECT_FOUND',
        ],
        severityPolicy: '{}',
        applicability: '{}',
        reasonCodes: [],
        noteRequirement: 'NONE',
        evidenceRequirement: 'NONE',
        minPhotos: 0,
        equipmentIds: [],
        guideImageId: null,
        sampleData: true,
        assessment: null,
      ),
      const InspectionItem(
        inspectionItemId: 'mech-brake',
        masterItemVersionId: 'master-mech-brake',
        sortOrder: 2,
        stableCode: 'F2B-BRAKE',
        categoryLabelEn: 'INSPECTION ZONE 04',
        categoryLabelAr: 'INSPECTION ZONE 04',
        labelEn: 'Brake Fluid Level',
        labelAr: 'Brake Fluid Level',
        instructionEn: 'DOT 4 standard.',
        instructionAr: 'معيار DOT 4.',
        versionNo: 1,
        resultOptions: [
          'NO_ISSUE_OBSERVED',
          'ATTENTION_RECOMMENDED',
          'DEFECT_FOUND',
        ],
        severityPolicy: '{}',
        applicability: '{}',
        reasonCodes: [],
        noteRequirement: 'NONE',
        evidenceRequirement: 'NONE',
        minPhotos: 0,
        equipmentIds: [],
        guideImageId: null,
        sampleData: true,
        assessment: null,
      ),
      const InspectionItem(
        inspectionItemId: 'mech-trans',
        masterItemVersionId: 'master-mech-trans',
        sortOrder: 3,
        stableCode: 'F2B-TRANS',
        categoryLabelEn: 'INSPECTION ZONE 04',
        categoryLabelAr: 'INSPECTION ZONE 04',
        labelEn: 'Transmission Fluid',
        labelAr: 'Transmission Fluid',
        instructionEn: 'Sealed system.',
        instructionAr: 'نظام مغلق.',
        versionNo: 1,
        resultOptions: [
          'NO_ISSUE_OBSERVED',
          'ATTENTION_RECOMMENDED',
          'DEFECT_FOUND',
        ],
        severityPolicy: '{}',
        applicability: '{}',
        reasonCodes: [],
        noteRequirement: 'NONE',
        evidenceRequirement: 'NONE',
        minPhotos: 0,
        equipmentIds: [],
        guideImageId: null,
        sampleData: true,
        assessment: null,
      ),
      const InspectionItem(
        inspectionItemId: 'mech-washer',
        masterItemVersionId: 'master-mech-washer',
        sortOrder: 4,
        stableCode: 'F2B-WASHER',
        categoryLabelEn: 'INSPECTION ZONE 04',
        categoryLabelAr: 'INSPECTION ZONE 04',
        labelEn: 'Washer Fluid',
        labelAr: 'Washer Fluid',
        instructionEn: 'Topped to max line.',
        instructionAr: 'حتى الخط الأقصى.',
        versionNo: 1,
        resultOptions: [
          'NO_ISSUE_OBSERVED',
          'ATTENTION_RECOMMENDED',
          'DEFECT_FOUND',
        ],
        severityPolicy: '{}',
        applicability: '{}',
        reasonCodes: [],
        noteRequirement: 'NONE',
        evidenceRequirement: 'NONE',
        minPhotos: 0,
        equipmentIds: [],
        guideImageId: null,
        sampleData: true,
        assessment: InspectionAssessment(
          id: 'a-washer',
          resultCode: 'NO_ISSUE_OBSERVED',
          severityCode: null,
          note: null,
          noteLanguage: null,
          reasonCode: null,
          reasonText: null,
          clientRevision: 1,
          serverRevision: 1,
          version: 1,
        ),
      ),
    ];
    return InspectionChecklist(job: base.job, items: items, completed: 3, total: 6);
  }
  return productChecklist();
}

ReviewResult _f2bReview({required bool figma}) {
  if (figma) {
    return const ReviewResult(
      ready: false,
      completed: 28,
      total: 31,
      blocking: [
        ReviewIssue(
          code: 'EVIDENCE_REQUIRED',
          inspectionItemId: 'mech-brake',
          label: 'Brake Fluid',
          detail: 'EVIDENCE_REQUIRED',
        ),
        ReviewIssue(
          code: 'EVIDENCE_REQUIRED',
          inspectionItemId: 'tread-fl',
          label: 'Tread Photo',
          detail: 'EVIDENCE_REQUIRED',
        ),
        ReviewIssue(
          code: 'NOTE_REQUIRED',
          inspectionItemId: 'sig',
          label: 'Signature',
          detail: 'NOTE_REQUIRED',
        ),
      ],
      warnings: [],
    );
  }
  return const ReviewResult(
    ready: false,
    completed: 17,
    total: 40,
    blocking: [
      ReviewIssue(
        code: 'ITEM_UNANSWERED',
        inspectionItemId: 'item-1',
        label: null,
        detail: null,
      ),
      ReviewIssue(
        code: 'EVIDENCE_REQUIRED',
        inspectionItemId: 'item-2',
        label: null,
        detail: null,
      ),
    ],
    warnings: [],
  );
}

List<SyncOperation> _f2bOperations({required bool figma}) {
  final now = DateTime.utc(2026, 11, 5, 8);
  if (figma) {
    return [
      SyncOperation(
        id: 'op-evidence',
        jobId: 'JOB-5A0001',
        type: 'evidence',
        payload: const {},
        state: 'PENDING',
        attempts: 0,
        lastError: null,
        createdAt: now,
      ),
      SyncOperation(
        id: 'op-answer',
        jobId: 'JOB-5A0001',
        type: 'answer',
        payload: const {},
        state: 'PENDING',
        attempts: 0,
        lastError: null,
        createdAt: now,
      ),
      SyncOperation(
        id: 'op-answer-2',
        jobId: 'JOB-5A0002',
        type: 'answer',
        payload: const {},
        state: 'PENDING',
        attempts: 0,
        lastError: null,
        createdAt: now,
      ),
    ];
  }
  return [
    SyncOperation(
      id: 'op-1',
      jobId: 'JOB-2601',
      type: 'answer',
      payload: const {},
      state: 'PENDING',
      attempts: 0,
      lastError: null,
      createdAt: now,
    ),
    SyncOperation(
      id: 'op-2',
      jobId: 'JOB-2601',
      type: 'evidence',
      payload: const {},
      state: 'FAILED',
      attempts: 1,
      lastError: 'network',
      createdAt: now,
    ),
  ];
}

/// Builds an F2-B screen for tests.
///
/// [figma] selects *data* fixtures only. Screens always render product
/// widgets; there is no `figmaText` switch in `lib/`. To render Figma *copy*,
/// pump the result with [f2bHost] and `figmaStrings: true` (English only),
/// which swaps in the test-only [F2bFigmaTestLocalizations] override.
/// The F2-A [figmaLocalizationsDelegates] are not used here; F2-B chrome copy
/// differs per screen (see [F2bFigmaStrings]).
Widget f2bScreen(String id, {bool figma = true}) {
  switch (id) {
    case 'defect-detail':
      return DefectDetailView(
        job: figma
            ? figmaJob(status: 'IN_PROGRESS', reference: 'JOB-5A0001')
            : productJobs.first,
        item: figma ? _f2bFigmaItem() : _f2bProductItem(),
        photos: const [],
        noteController: TextEditingController(),
        selectedResult: 'ATTENTION_RECOMMENDED',
        selectedSeverity: 'MINOR',
        onResult: (_) {},
        onSeverity: (_) {},
        onSave: () {},
        onAddPhoto: () {},
        onClose: () {},
      );
    case 'dense-mechanical':
      return DenseMechanicalView(
        checklist: _f2bChecklist(figma: figma),
        onResult: (_, _) {},
        onSaveItem: (_, _, _, _) async {},
        onOpenItem: (_) {},
        onContinue: () {},
        onBack: () {},
        onProfile: () {},
      );
    case 'final-review':
      return FinalReviewView(
        job: figma
            ? figmaJob(status: 'IN_PROGRESS', reference: 'JOB-5A0001')
            : productJobs.first,
        review: _f2bReview(figma: figma),
        onOpenIssue: (_) {},
        onContinue: () {},
        onBack: () {},
        onProfile: () {},
      );
    case 'finalize':
      final checklist = _f2bChecklist(figma: figma);
      return FinalizeView(
        job: figma
            ? figmaJob(
                status: 'READY_TO_FINALIZE',
                reference: 'JOB-5A0001',
                make: 'Ford',
                model: 'Transit 350',
                year: 2024,
                vin: '1FTBR1Y85RKB92104',
                plate: 'LV71 XZP',
              )
            : productJobs.first,
        review: ReviewResult(
          ready: true,
          completed: checklist.completed,
          total: checklist.total,
          blocking: const [],
          warnings: const [],
        ),
        checklist: checklist,
        onFinalize: () async {},
        onBack: () {},
        onProfile: () {},
      );
    case 'offline-sync':
      final ops = _f2bOperations(figma: figma);
      return OfflineSyncView(
        operations: ops,
        pendingCount: ops.length,
        online: false,
        onRetry: () {},
        onBack: () {},
        onProfile: () {},
      );
    case 'success':
      final checklist = _f2bChecklist(figma: figma);
      return SuccessView(
        job: figma
            ? figmaJob(
                status: 'FINALIZED',
                reference: 'JOB-5A0001',
                vin: 'VF1KZ040647192831',
              )
            : TechnicianJob(
                id: productJobs.first.id,
                reference: productJobs.first.reference,
                status: 'FINALIZED',
                version: productJobs.first.version,
                templateVersionId: productJobs.first.templateVersionId,
                templateName: productJobs.first.templateName,
                templateVersionNo: productJobs.first.templateVersionNo,
                assignedTechnicianId:
                    productJobs.first.assignedTechnicianId,
                assignedTechnicianName:
                    productJobs.first.assignedTechnicianName,
                scheduledAt: productJobs.first.scheduledAt,
                customerName: productJobs.first.customerName,
                customerPhone: productJobs.first.customerPhone,
                customerEmail: productJobs.first.customerEmail,
                vehicleMake: productJobs.first.vehicleMake,
                vehicleModel: productJobs.first.vehicleModel,
                vehicleYear: productJobs.first.vehicleYear,
                vehicleVin: productJobs.first.vehicleVin,
                vehiclePlate: productJobs.first.vehiclePlate,
                vehicleType: productJobs.first.vehicleType,
                odometerValue: productJobs.first.odometerValue,
                odometerUnit: productJobs.first.odometerUnit,
                scope: productJobs.first.scope,
                startedAt: productJobs.first.startedAt,
                readyAt: productJobs.first.readyAt,
                finalizedAt: productJobs.first.finalizedAt,
              ),
        checklist: checklist,
        onBackToJobs: () {},
        report: const TechnicianReportStatus(
          reportNumber: 'R-2601',
          version: 1,
          generationStatus: 'READY',
          ready: true,
          finalizedAt: '2026-11-05T08:00:00Z',
        ),
        deliveries: const [
          TechnicianDelivery(
            id: 'd-1',
            channel: 'WHATSAPP',
            recipientMasked: '***',
            language: 'en',
            status: 'SENT',
            attempts: 1,
            maxAttempts: 3,
            pdfAttached: true,
            lastErrorMessage: null,
            nextAttemptAt: '',
            createdAt: '',
          ),
        ],
      );
    default:
      throw ArgumentError('Unknown F2-B screen: $id');
  }
}

Widget f2bHost({
  required Widget child,
  required Locale locale,
  required ThemeData theme,
  double textScale = 1,
  bool figmaStrings = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: figmaStrings
        ? f2bFigmaLocalizationsDelegates
        : AppLocalizations.localizationsDelegates,
    theme: theme,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: appChild ?? const SizedBox.shrink(),
    ),
    home: child,
  );
}
