/// Shared fixtures for technician app tests.
///
/// Values are realistic on purpose: a 2023 Toyota Land Cruiser, plate
/// `AUD-354626` and the app's 30-item inspection template. Builders use the
/// real model constructors from `inspection_models.dart`, so a new required
/// field breaks the fixtures instead of silently producing a hollow object.
library;

import 'package:technician_app/src/inspection_models.dart';

/// Fixed Dubai wall-clock instant used by queue tests: Thursday 12 March 2026,
/// 10:15 in Asia/Dubai (UTC+4). Never use `DateTime.now()` in a test.
DateTime fixedNow() => DateTime.utc(2026, 3, 12, 6, 15);

/// Local-midnight key for [fixedNow]'s Dubai day.
DateTime fixedTodayKey() => DateTime(2026, 3, 12);

/// Builds a realistic job summary.
///
/// Every required field is filled; the defaults describe the same Land Cruiser
/// so tests can override only what they care about.
JobSummary jobSummary({
  String id = 'job-1001',
  String reference = 'TR-2026-0412',
  String status = 'SCHEDULED',
  String? reviewStatus,
  String templateVersionId = 'tplv-pre-purchase-2026-03',
  String templateNameEn = 'Pre-purchase inspection',
  String templateNameAr = 'فحص ما قبل الشراء',
  int? templateVersionNo = 3,
  String? assignedTechnicianId = 'tech-17',
  String customerName = 'Ahmed Al Mansoori',
  String customerPhone = '+971502148890',
  String customerEmail = 'ahmed.almansoori@example.ae',
  String? vehicleVin = 'JTMHV05J204123456',
  String vehicleMake = 'Toyota',
  String vehicleModel = 'Land Cruiser',
  int? vehicleYear = 2023,
  String? vehiclePlate = 'AUD-354626',
  int? odometerValue = 34180,
  String? odometerUnit = 'KM',
  String? transmission = 'Automatic',
  String? fuelType = 'Petrol',
  String? vehicleType = 'SUV',
  String? preferredLanguage = 'en',
  String? scheduledAt = '2026-03-12T09:30:00',
  String? startedAt,
  String? assessmentState,
  int completedItems = 0,
  int totalItems = 30,
  int version = 4,
}) => JobSummary(
  id: id,
  reference: reference,
  status: status,
  reviewStatus: reviewStatus,
  templateVersionId: templateVersionId,
  templateNameEn: templateNameEn,
  templateNameAr: templateNameAr,
  templateVersionNo: templateVersionNo,
  assignedTechnicianId: assignedTechnicianId,
  customerName: customerName,
  customerPhone: customerPhone,
  customerEmail: customerEmail,
  vehicleVin: vehicleVin,
  vehicleMake: vehicleMake,
  vehicleModel: vehicleModel,
  vehicleYear: vehicleYear,
  vehiclePlate: vehiclePlate,
  odometerValue: odometerValue,
  odometerUnit: odometerUnit,
  transmission: transmission,
  fuelType: fuelType,
  vehicleType: vehicleType,
  preferredLanguage: preferredLanguage,
  scheduledAt: scheduledAt,
  startedAt: startedAt,
  assessmentState: assessmentState,
  completedItems: completedItems,
  totalItems: totalItems,
  version: version,
);

/// Builds one summary blocker (the reason completion is refused).
Blocker blocker({
  String code = 'SIGNATURE_MISSING',
  String? itemCode,
  String messageEn = 'Customer signature is missing.',
  String messageAr = 'توقيع العميل مفقود.',
}) => Blocker(
  code: code,
  itemCode: itemCode,
  messageEn: messageEn,
  messageAr: messageAr,
);

/// The six categories of the pre-purchase template.
List<Category> inspectionCategories() => const <Category>[
  Category(
    code: 'ac',
    nameEn: 'Air conditioning',
    nameAr: 'التكييف',
    iconCode: 'ac_unit',
    sortOrder: 1,
  ),
  Category(
    code: 'brakes',
    nameEn: 'Brakes',
    nameAr: 'الفرامل',
    iconCode: 'brake',
    sortOrder: 2,
  ),
  Category(
    code: 'engine',
    nameEn: 'Engine bay',
    nameAr: 'حجرة المحرك',
    iconCode: 'engine',
    sortOrder: 3,
  ),
  Category(
    code: 'electrical',
    nameEn: 'Electrical',
    nameAr: 'الكهرباء',
    iconCode: 'bolt',
    sortOrder: 4,
  ),
  Category(
    code: 'suspension',
    nameEn: 'Steering & suspension',
    nameAr: 'التوجيه والتعليق',
    iconCode: 'settings_input_component',
    sortOrder: 5,
  ),
  Category(
    code: 'tyres',
    nameEn: 'Tyres & wheels',
    nameAr: 'الإطارات والعجلات',
    iconCode: 'tire_repair',
    sortOrder: 6,
  ),
];

/// The 30 checklist items, in template order.
List<ChecklistItem> inspectionItems() => <ChecklistItem>[
  for (var index = 0; index < _seeds.length; index += 1)
    _itemFromSeed(_seeds[index], index),
];

ChecklistItem _itemFromSeed(_ItemSeed seed, int index) {
  final code = seed.code;
  return ChecklistItem(
    itemCode: code,
    itemVersionId: 'iv-$code-3',
    categoryCode: seed.category,
    sortOrder: index + 1,
    labelEn: seed.labelEn,
    labelAr: seed.labelAr,
    instructionEn: 'Inspect and record the ${seed.labelEn.toLowerCase()}.',
    instructionAr: 'افحص وسجّل ${seed.labelAr}.',
    standardSpecEn: seed.standardSpecEn,
    standardSpecAr: seed.standardSpecAr,
    measurementUnit: seed.measurementUnit,
    sensorTool: seed.measurementUnit == null ? null : 'calibrated-gauge',
    safetyCritical: seed.safetyCritical,
    multiPoint: seed.multiPoint,
    multiPointIndexes: seed.multiPoint
        ? const <String>['L', 'R']
        : const <String>[],
    allowFreeTextNote: true,
    noteRequirement: seed.safetyCritical ? 'required' : null,
    resultOptions: const <String>['PASS', 'ADVISORY', 'FAIL', 'NA'],
    scoreBands: const <ScoreBand>[],
    evidenceRules: const <EvidenceRule>[],
    issueFields: const <IssueField>[],
    measurementBands: const <MeasurementBand>[],
    assessment: null,
  );
}

/// Builds the checklist served for [job], defaulting to the 30-item template.
Checklist checklist({
  JobSummary? job,
  int itemCount = 30,
  int completed = 0,
  int serverRevision = 7,
}) {
  final summary = job ?? jobSummary();
  final all = inspectionItems();
  final limited = itemCount < all.length ? all.sublist(0, itemCount) : all;
  return Checklist(
    job: summary,
    pinned: PinnedTemplate(
      templateVersionId: summary.templateVersionId,
      templateVersionNo: summary.templateVersionNo,
      snapshotHash: 'sha256:9f2c41d0e7',
    ),
    categories: inspectionCategories(),
    items: limited,
    progress: ChecklistProgress(completed: completed, total: limited.length),
    serverRevision: serverRevision,
  );
}

class _ItemSeed {
  const _ItemSeed({
    required this.code,
    required this.category,
    required this.labelEn,
    required this.labelAr,
    this.measurementUnit,
    this.standardSpecEn,
    this.standardSpecAr,
    this.safetyCritical = false,
    this.multiPoint = false,
  });

  final String code;
  final String category;
  final String labelEn;
  final String labelAr;
  final String? measurementUnit;
  final String? standardSpecEn;
  final String? standardSpecAr;
  final bool safetyCritical;
  final bool multiPoint;
}

const List<_ItemSeed> _seeds = <_ItemSeed>[
  _ItemSeed(
    code: 'ac_cooling',
    category: 'ac',
    labelEn: 'AC cooling performance',
    labelAr: 'أداء تبريد المكيف',
  ),
  _ItemSeed(
    code: 'ac_blower_speeds',
    category: 'ac',
    labelEn: 'Blower speeds 1-4',
    labelAr: 'سرعات المروحة ١-٤',
  ),
  _ItemSeed(
    code: 'ac_cabin_filter',
    category: 'ac',
    labelEn: 'Cabin filter condition',
    labelAr: 'حالة فلتر المقصورة',
  ),
  _ItemSeed(
    code: 'ac_compressor_belt',
    category: 'ac',
    labelEn: 'Compressor drive belt',
    labelAr: 'سير ضاغط المكيف',
  ),
  _ItemSeed(
    code: 'ac_vent_temperature',
    category: 'ac',
    labelEn: 'Vent outlet temperature',
    labelAr: 'درجة حرارة فتحة التهوية',
    measurementUnit: '°C',
    standardSpecEn: '4-10 °C at idle',
    standardSpecAr: '٤-١٠ °م عند الخمول',
  ),
  _ItemSeed(
    code: 'brake_pads_front',
    category: 'brakes',
    labelEn: 'Front brake pads',
    labelAr: 'فحمات الفرامل الأمامية',
    measurementUnit: 'mm',
    standardSpecEn: 'Min 3 mm',
    standardSpecAr: 'الحد الأدنى ٣ مم',
    safetyCritical: true,
    multiPoint: true,
  ),
  _ItemSeed(
    code: 'brake_pads_rear',
    category: 'brakes',
    labelEn: 'Rear brake pads',
    labelAr: 'فحمات الفرامل الخلفية',
    measurementUnit: 'mm',
    standardSpecEn: 'Min 3 mm',
    standardSpecAr: 'الحد الأدنى ٣ مم',
    safetyCritical: true,
    multiPoint: true,
  ),
  _ItemSeed(
    code: 'brake_discs_front',
    category: 'brakes',
    labelEn: 'Front brake discs',
    labelAr: 'أقراص الفرامل الأمامية',
    measurementUnit: 'mm',
    standardSpecEn: 'Min 28 mm',
    standardSpecAr: 'الحد الأدنى ٢٨ مم',
    safetyCritical: true,
  ),
  _ItemSeed(
    code: 'brake_fluid',
    category: 'brakes',
    labelEn: 'Brake fluid condition',
    labelAr: 'حالة سائل الفرامل',
    safetyCritical: true,
  ),
  _ItemSeed(
    code: 'parking_brake',
    category: 'brakes',
    labelEn: 'Parking brake travel',
    labelAr: 'مشوار فرامل اليد',
  ),
  _ItemSeed(
    code: 'engine_oil',
    category: 'engine',
    labelEn: 'Engine oil level and condition',
    labelAr: 'مستوى وحالة زيت المحرك',
  ),
  _ItemSeed(
    code: 'coolant',
    category: 'engine',
    labelEn: 'Coolant level and condition',
    labelAr: 'مستوى وحالة سائل التبريد',
  ),
  _ItemSeed(
    code: 'engine_idle',
    category: 'engine',
    labelEn: 'Engine idle quality',
    labelAr: 'جودة عمل المحرك عند الخمول',
  ),
  _ItemSeed(
    code: 'serpentine_belt',
    category: 'engine',
    labelEn: 'Serpentine belt condition',
    labelAr: 'حالة سير المحرك',
  ),
  _ItemSeed(
    code: 'oil_leaks',
    category: 'engine',
    labelEn: 'Engine oil leaks',
    labelAr: 'تسريبات زيت المحرك',
    safetyCritical: true,
  ),
  _ItemSeed(
    code: 'battery_soc',
    category: 'electrical',
    labelEn: 'Battery state of charge',
    labelAr: 'حالة شحن البطارية',
    measurementUnit: 'V',
    standardSpecEn: 'Min 12.4 V at rest',
    standardSpecAr: 'الحد الأدنى ١٢٫٤ فولت',
  ),
  _ItemSeed(
    code: 'alternator_voltage',
    category: 'electrical',
    labelEn: 'Alternator charging voltage',
    labelAr: 'جهد شحن الدينامو',
    measurementUnit: 'V',
    standardSpecEn: '13.5-14.8 V',
    standardSpecAr: '١٣٫٥-١٤٫٨ فولت',
  ),
  _ItemSeed(
    code: 'headlamps',
    category: 'electrical',
    labelEn: 'Headlamp operation',
    labelAr: 'عمل المصابيح الأمامية',
  ),
  _ItemSeed(
    code: 'indicators',
    category: 'electrical',
    labelEn: 'Indicators and hazard lights',
    labelAr: 'الإشارات وأضواء التحذير',
  ),
  _ItemSeed(
    code: 'horn',
    category: 'electrical',
    labelEn: 'Horn operation',
    labelAr: 'عمل آلة التنبيه',
  ),
  _ItemSeed(
    code: 'front_shocks',
    category: 'suspension',
    labelEn: 'Front shock absorbers',
    labelAr: 'ممتصات الصدمات الأمامية',
  ),
  _ItemSeed(
    code: 'rear_shocks',
    category: 'suspension',
    labelEn: 'Rear shock absorbers',
    labelAr: 'ممتصات الصدمات الخلفية',
  ),
  _ItemSeed(
    code: 'steering_play',
    category: 'suspension',
    labelEn: 'Steering play',
    labelAr: 'خلوص التوجيه',
    safetyCritical: true,
  ),
  _ItemSeed(
    code: 'ball_joints',
    category: 'suspension',
    labelEn: 'Ball joints',
    labelAr: 'مفاصل الكرة',
    safetyCritical: true,
    multiPoint: true,
  ),
  _ItemSeed(
    code: 'wheel_alignment',
    category: 'suspension',
    labelEn: 'Wheel alignment evidence',
    labelAr: 'مؤشرات ضبط الاتجاه',
  ),
  _ItemSeed(
    code: 'tyre_tread_front',
    category: 'tyres',
    labelEn: 'Front tyre tread depth',
    labelAr: 'عمق نقشة الإطارات الأمامية',
    measurementUnit: 'mm',
    standardSpecEn: 'Min 1.6 mm',
    standardSpecAr: 'الحد الأدنى ١٫٦ مم',
    safetyCritical: true,
    multiPoint: true,
  ),
  _ItemSeed(
    code: 'tyre_tread_rear',
    category: 'tyres',
    labelEn: 'Rear tyre tread depth',
    labelAr: 'عمق نقشة الإطارات الخلفية',
    measurementUnit: 'mm',
    standardSpecEn: 'Min 1.6 mm',
    standardSpecAr: 'الحد الأدنى ١٫٦ مم',
    safetyCritical: true,
    multiPoint: true,
  ),
  _ItemSeed(
    code: 'tyre_pressures',
    category: 'tyres',
    labelEn: 'Tyre pressures',
    labelAr: 'ضغوط الإطارات',
    measurementUnit: 'bar',
    standardSpecEn: '2.4 bar cold',
    standardSpecAr: '٢٫٤ بار على البارد',
    safetyCritical: true,
    multiPoint: true,
  ),
  _ItemSeed(
    code: 'spare_wheel',
    category: 'tyres',
    labelEn: 'Spare wheel and tools',
    labelAr: 'الإطار الاحتياطي والأدوات',
  ),
  _ItemSeed(
    code: 'wheel_nuts',
    category: 'tyres',
    labelEn: 'Wheel nut torque',
    labelAr: 'عزم صواميل العجلات',
    measurementUnit: 'Nm',
    standardSpecEn: '131 Nm',
    standardSpecAr: '١٣١ نيوتن متر',
    safetyCritical: true,
    multiPoint: true,
  ),
];
