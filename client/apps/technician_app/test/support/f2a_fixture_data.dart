import 'package:technician_app/src/models.dart';

const figmaScheduled = '2026-11-05T06:42:00Z';
final figmaNow = DateTime.utc(2026, 11, 5, 8);

TechnicianJob figmaJob({
  String status = 'ASSIGNED',
  String reference = 'JOB-5A0001',
  String make = 'Renault',
  String model = 'Megane 3',
  int? year = 2021,
  int? odometer = 34180,
  String? unit = 'MI',
  String? vin = 'VF1KZ040647192831',
  String? plate = 'LV71 XZP',
  String customer = 'Arthur Pendelton',
  String? phone = '+44 7700 900077',
  String? email = 'arthur@example.test',
  String template = 'Full Pre-Delivery Inspection',
}) => TechnicianJob(
  id: 'job-figma-1',
  reference: reference,
  status: status,
  version: 1,
  templateVersionId: 'template-version-1',
  templateName: template,
  templateVersionNo: 1,
  assignedTechnicianId: 'tech-1',
  assignedTechnicianName: 'David Vance',
  scheduledAt: figmaScheduled,
  customerName: customer,
  customerPhone: phone,
  customerEmail: email,
  vehicleMake: make,
  vehicleModel: model,
  vehicleYear: year,
  vehicleVin: vin,
  vehiclePlate: plate,
  vehicleType: 'Hatchback',
  odometerValue: odometer,
  odometerUnit: unit,
  scope: 'Full inspection',
  startedAt: '',
  readyAt: '',
  finalizedAt: '',
);

final figmaJobs = <TechnicianJob>[
  figmaJob(status: 'Ready'),
  figmaJob(
    status: 'High Priority',
    reference: 'JOB-5A0002',
    make: 'Nissan',
    model: 'Patrol',
    year: 2020,
    odometer: 61200,
    unit: 'MI',
    vin: 'JN8AY2NC5L9410002',
    plate: 'XYZ 882',
    customer: 'Mariam Al Suwaidi',
    phone: '+971 50 000 0002',
    template: 'Brake Fluid & Tire Diagnostics',
  ),
  figmaJob(
    status: 'Scheduled',
    reference: 'JOB-5A0003',
    make: 'Toyota',
    model: 'Land Cruiser',
    year: 2019,
    odometer: 98400,
    unit: 'MI',
    vin: 'JTMHU01J0K4000003',
    plate: 'KLO 904',
    customer: 'Omar Haddad',
    phone: '+971 50 000 0003',
    template: 'Routine 60-Point Audit',
  ),
];

final productJobs = <TechnicianJob>[
  figmaJob(
    status: 'ASSIGNED',
    reference: 'JOB-2601',
    make: 'Honda',
    model: 'Accord',
    year: 2022,
    odometer: 48210,
    unit: 'KM',
    vin: '1HGCM82633A004352',
    plate: 'A 12345',
    customer: 'Ahmed Al Mansoori',
    phone: '+971 50 123 4567',
    email: 'ahmed@example.test',
    template: 'Full inspection',
  ),
  figmaJob(
    status: 'IN_PROGRESS',
    reference: 'JOB-2602',
    make: 'Toyota',
    model: 'Camry',
    year: 2020,
    odometer: 92100,
    unit: 'KM',
    vin: '4T1BF1FK5CU500002',
    plate: 'B 67890',
    customer: 'Sara Khalifa',
    phone: '+971 50 765 4321',
    email: 'sara@example.test',
    template: 'Full inspection',
  ),
];

InspectionItem fixtureItem({
  required String id,
  required String category,
  int sortOrder = 0,
  String? result,
  String label = 'Inspection point',
}) => InspectionItem(
  inspectionItemId: id,
  masterItemVersionId: 'master-$id',
  sortOrder: sortOrder,
  stableCode: 'F2A-$id',
  categoryLabelEn: category,
  categoryLabelAr: category,
  labelEn: label,
  labelAr: label,
  instructionEn: 'Inspect the item.',
  instructionAr: 'افحص العنصر.',
  versionNo: 1,
  resultOptions: const [
    'NO_ISSUE_OBSERVED',
    'ATTENTION_RECOMMENDED',
    'DEFECT_FOUND',
    'NOT_CHECKED',
    'NOT_APPLICABLE',
    'COULD_NOT_VERIFY',
  ],
  severityPolicy: '{}',
  applicability: '{}',
  reasonCodes: const [],
  noteRequirement: 'NONE',
  evidenceRequirement: 'NONE',
  minPhotos: 0,
  equipmentIds: const [],
  guideImageId: null,
  sampleData: true,
  assessment: result == null
      ? null
      : InspectionAssessment(
          id: 'assessment-$id',
          resultCode: result,
          severityCode: null,
          note: null,
          noteLanguage: null,
          reasonCode: null,
          reasonText: null,
          clientRevision: 1,
          serverRevision: 1,
          version: 1,
        ),
);

List<InspectionItem> _category({
  required String category,
  required int total,
  required int noIssue,
  required int attention,
}) {
  final items = <InspectionItem>[];
  for (var index = 0; index < total; index++) {
    final result = index < noIssue
        ? 'NO_ISSUE_OBSERVED'
        : index < noIssue + attention
        ? 'ATTENTION_RECOMMENDED'
        : null;
    items.add(
      fixtureItem(
        id: '${category.toLowerCase()}-$index',
        category: category,
        sortOrder: index,
        result: result,
        label: '$category check ${index + 1}',
      ),
    );
  }
  return items;
}

InspectionChecklist figmaChecklist() {
  final items = <InspectionItem>[
    ..._category(category: 'Exterior', total: 28, noIssue: 28, attention: 0),
    ..._category(category: 'Interior', total: 32, noIssue: 14, attention: 3),
    ..._category(category: 'Engine', total: 24, noIssue: 0, attention: 0),
    ..._category(category: 'Underbody', total: 26, noIssue: 0, attention: 0),
  ];
  return InspectionChecklist(
    job: figmaJob(status: 'IN_PROGRESS'),
    items: items,
    completed: 45,
    total: 110,
  );
}

InspectionChecklist productChecklist() {
  final items = <InspectionItem>[
    ..._category(category: 'Exterior', total: 10, noIssue: 10, attention: 0),
    ..._category(category: 'Interior', total: 10, noIssue: 5, attention: 2),
    ..._category(category: 'Engine', total: 10, noIssue: 0, attention: 0),
    ..._category(category: 'Underbody', total: 10, noIssue: 0, attention: 0),
  ];
  return InspectionChecklist(
    job: productJobs.first,
    items: items,
    completed: 17,
    total: 40,
  );
}

