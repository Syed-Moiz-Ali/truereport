import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/technician_api.dart';

class FakeTechnicianApi implements TechnicianApi {
  static const sampleJob = TechnicianJob(
    id: 'job-1',
    reference: 'JOB-5A0001',
    status: 'ASSIGNED',
    version: 1,
    templateVersionId: 'template-version-1',
    templateName: 'Full inspection',
    templateVersionNo: 1,
    assignedTechnicianId: 'tech-1',
    assignedTechnicianName: 'Technician A',
    scheduledAt: '2026-11-05T09:00:00',
    customerName: 'Customer A',
    customerPhone: '+971500000000',
    customerEmail: 'customer@test.local',
    vehicleMake: 'Toyota',
    vehicleModel: 'Camry',
    vehicleYear: 2022,
    vehicleVin: 'TESTVIN00000000001',
    vehiclePlate: 'A12345',
    vehicleType: 'CAR',
    odometerValue: 82902,
    odometerUnit: 'KM',
    scope: 'Full inspection',
    startedAt: '',
    readyAt: '',
    finalizedAt: '',
  );

  static const sampleItem = InspectionItem(
    inspectionItemId: 'inspection-item-1',
    masterItemVersionId: 'master-version-1',
    sortOrder: 0,
    stableCode: 'SAMPLE-5A-001',
    categoryLabelEn: 'Exterior',
    categoryLabelAr: 'الهيكل الخارجي',
    labelEn: 'Body panel check',
    labelAr: 'فحص هيكل السيارة',
    instructionEn: 'Inspect the panel.',
    instructionAr: 'افحص الهيكل.',
    versionNo: 1,
    resultOptions: [
      'NO_ISSUE_OBSERVED',
      'DEFECT_FOUND',
      'NOT_CHECKED',
      'NOT_APPLICABLE',
    ],
    severityPolicy: '{}',
    applicability: '{}',
    reasonCodes: [],
    noteRequirement: 'OPTIONAL',
    evidenceRequirement: 'NONE',
    minPhotos: 0,
    equipmentIds: [],
    guideImageId: null,
    sampleData: true,
    assessment: null,
  );

  static const sampleChecklist = InspectionChecklist(
    job: sampleJob,
    items: [sampleItem],
    completed: 0,
    total: 1,
  );

  @override
  Future<List<TechnicianJob>> jobs() async => const [sampleJob];

  @override
  Future<TechnicianJob> job(String id) async => sampleJob;

  @override
  Future<List<TemplateVersionOption>> templateVersions() async => const [
    TemplateVersionOption(
      versionId: 'template-version-1',
      templateId: 'template-1',
      templateName: 'Full inspection',
      versionNo: 1,
      serviceType: 'FULL',
      vehicleType: 'CAR',
    ),
  ];

  @override
  Future<InspectionChecklist> checklist(String jobId) async => sampleChecklist;

  @override
  Future<ReviewResult> review(String jobId) async => const ReviewResult(
    ready: true,
    completed: 1,
    total: 1,
    blocking: [],
    warnings: [
      ReviewIssue(
        code: 'EVIDENCE_PENDING_5B',
        inspectionItemId: 'inspection-item-1',
        label: 'Body panel check',
        detail: 'Evidence capture is not available in Phase 5A',
      ),
    ],
  );

  @override
  Future<List<String>> equipment(String jobId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
