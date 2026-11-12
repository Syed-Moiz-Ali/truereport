import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/job_counts.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

class FakeAdminApi implements AdminApi {
  FakeAdminApi({this.checklistReady = true, this.approveSucceeds = true}) {
    _jobs = <CleanJob>[
      const CleanJob(
        id: 'job-1',
        reference: 'JOB-0001',
        status: 'PENDING_REVIEW',
        reviewStatus: 'PENDING_REVIEW',
        publicationStatus: 'NOT_PUBLISHED',
        templateVersionId: 'version-1',
        templateNameEn: 'Full inspection',
        templateNameAr: 'فحص شامل',
        templateVersionNo: 1,
        assignedTechnicianId: 'tech-1',
        assignedTechnicianName: 'Technician A',
        customerName: 'Workshop Customer',
        customerPhone: '+971500000100',
        customerEmail: 'jobs@test.local',
        vehicleVin: 'TESTVIN00000000002',
        vehicleMake: 'Toyota',
        vehicleModel: 'Camry',
        vehicleYear: 2022,
        vehiclePlate: 'JOB-100',
        odometerValue: 45000,
        odometerUnit: 'KM',
        transmission: 'AUTOMATIC',
        fuelType: 'PETROL',
        preferredLanguage: 'en',
        scheduledAt: '2026-11-05T09:00:00',
        startedAt: '2026-11-05T09:15:00',
        completedAt: '2026-11-05T10:00:00',
        approvedAt: null,
        publishedAt: null,
        cancelledAt: null,
        approvedBy: null,
        cancelledBy: null,
        cancelReason: null,
        score: 88,
        gradeCode: 'B',
        safetyCapApplied: false,
        safetyCapReason: null,
        consentGranted: true,
        createdAt: '2026-11-04T08:00:00',
        updatedAt: '2026-11-05T10:00:00',
        version: 3,
      ),
      const CleanJob(
        id: 'job-2',
        reference: 'JOB-0002',
        status: 'APPROVED',
        reviewStatus: 'APPROVED',
        publicationStatus: 'NOT_PUBLISHED',
        templateVersionId: 'version-1',
        templateNameEn: 'Full inspection',
        templateNameAr: 'فحص شامل',
        templateVersionNo: 1,
        assignedTechnicianId: 'tech-1',
        assignedTechnicianName: 'Technician A',
        customerName: 'Approved Customer',
        customerPhone: '+971500000101',
        customerEmail: 'approved@test.local',
        vehicleVin: 'TESTVIN00000000003',
        vehicleMake: 'Honda',
        vehicleModel: 'Civic',
        vehicleYear: 2023,
        vehiclePlate: 'JOB-200',
        odometerValue: 22000,
        odometerUnit: 'KM',
        transmission: 'AUTOMATIC',
        fuelType: 'PETROL',
        preferredLanguage: 'ar',
        scheduledAt: '2026-11-06T09:00:00',
        startedAt: '2026-11-06T09:15:00',
        completedAt: '2026-11-06T10:00:00',
        approvedAt: '2026-11-06T11:00:00',
        publishedAt: null,
        cancelledAt: null,
        approvedBy: 'admin-1',
        cancelledBy: null,
        cancelReason: null,
        score: 92,
        gradeCode: 'A',
        safetyCapApplied: false,
        safetyCapReason: null,
        consentGranted: true,
        createdAt: '2026-11-05T08:00:00',
        updatedAt: '2026-11-06T11:00:00',
        version: 4,
      ),
      const CleanJob(
        id: 'job-3',
        reference: 'JOB-0003',
        status: 'PUBLISHED',
        reviewStatus: 'APPROVED',
        publicationStatus: 'ACTIVE',
        templateVersionId: 'version-1',
        templateNameEn: 'Full inspection',
        templateNameAr: 'فحص شامل',
        templateVersionNo: 1,
        assignedTechnicianId: 'tech-1',
        assignedTechnicianName: 'Technician A',
        customerName: 'Published Customer',
        customerPhone: '+971500000102',
        customerEmail: 'published@test.local',
        vehicleVin: 'TESTVIN00000000004',
        vehicleMake: 'Ford',
        vehicleModel: 'Transit',
        vehicleYear: 2021,
        vehiclePlate: 'JOB-300',
        odometerValue: 91000,
        odometerUnit: 'KM',
        transmission: 'MANUAL',
        fuelType: 'DIESEL',
        preferredLanguage: 'en',
        scheduledAt: '2026-11-07T09:00:00',
        startedAt: '2026-11-07T09:15:00',
        completedAt: '2026-11-07T10:00:00',
        approvedAt: '2026-11-07T11:00:00',
        publishedAt: '2026-11-07T12:00:00',
        cancelledAt: null,
        approvedBy: 'admin-1',
        cancelledBy: null,
        cancelReason: null,
        score: 95,
        gradeCode: 'A',
        safetyCapApplied: true,
        safetyCapReason: 'Safety critical finding',
        consentGranted: true,
        createdAt: '2026-11-06T08:00:00',
        updatedAt: '2026-11-07T12:00:00',
        version: 5,
      ),
    ];
    _assignments['job-1'] = const [
      JobAssignment(
        id: 'assignment-1',
        technicianId: 'tech-1',
        assignedBy: 'admin-1',
        assignedAt: '2026-11-05T08:30:00',
        unassignedAt: null,
        reason: 'Initial assignment',
      ),
    ];
    _links['job-3'] = const PublicLink(
      jobId: 'job-3',
      status: 'ACTIVE',
      publicUrl: 'https://reports.test.local/r/token-3',
      token: 'token-3',
      qrUrl: 'https://reports.test.local/r/token-3/qr',
      pdfDownloadEnabled: true,
      activatedAt: '2026-11-07T12:00:00',
      revokedAt: null,
      revocationReason: null,
    );
    _documents.addAll(const [
      JobDocument(
        id: 'doc-1',
        documentTypeCode: 'REPORT',
        nameEn: 'Inspection report',
        nameAr: 'تقرير الفحص',
        language: 'en',
        status: 'READY',
        bytes: 20480,
        generatedAt: '2026-11-07T12:01:00',
        error: null,
        downloadUrl: 'https://reports.test.local/docs/doc-1',
      ),
      JobDocument(
        id: 'doc-2',
        documentTypeCode: 'REPORT',
        nameEn: 'Inspection report',
        nameAr: 'تقرير الفحص',
        language: 'ar',
        status: 'FAILED',
        bytes: 0,
        generatedAt: null,
        error: 'Generation failed',
        downloadUrl: null,
      ),
    ]);
    _notifications = <WorkshopNotification>[
      const WorkshopNotification(
        id: 'notification-1',
        type: 'JOB_PENDING_REVIEW',
        payloadJson: '{"jobId":"job-1"}',
        readAt: null,
        createdAt: '2026-11-05T10:05:00',
      ),
      const WorkshopNotification(
        id: 'notification-2',
        type: 'REPORT_PUBLISHED',
        payloadJson: '{"jobId":"job-3"}',
        readAt: '2026-11-07T12:30:00',
        createdAt: '2026-11-07T12:05:00',
      ),
    ];
  }

  final bool checklistReady;
  final bool approveSucceeds;
  late List<CleanJob> _jobs;
  final Map<String, List<JobAssignment>> _assignments = {};
  final Map<String, PublicLink> _links = {};
  final List<JobDocument> _documents = [];
  late List<WorkshopNotification> _notifications;
  @override
  Future<HierarchyResponse> hierarchy({
    String search = '',
    String status = '',
  }) async {
    const admin = PlatformAccount(
      userId: 'admin-1',
      displayName: 'Admin A',
      email: 'admin.a@test.local',
      emailMasked: 'a***@test.local',
      role: 'WORKSHOP_ADMIN',
      status: 'ACTIVE',
      workshopId: 'workshop-1',
      primary: true,
      invitationExpiresAt: null,
    );
    const technician = PlatformAccount(
      userId: 'tech-1',
      displayName: 'Technician A',
      email: 'tech.a@test.local',
      emailMasked: 't***@test.local',
      role: 'TECHNICIAN',
      status: 'ACTIVE',
      workshopId: 'workshop-1',
      primary: true,
      invitationExpiresAt: null,
    );
    return const HierarchyResponse(
      workshops: [
        HierarchyWorkshop(
          id: 'workshop-1',
          name: 'Workshop A',
          branchName: 'Dubai',
          status: 'ACTIVE',
          memberCount: 2,
          admins: [admin],
          technicians: [technician],
          pendingInvitations: [],
        ),
      ],
      totalWorkshops: 1,
      totalAccounts: 2,
    );
  }

  @override
  Future<List<Category>> categories() async => const [
    Category(
      id: 'cat-1',
      slug: 'sample-exterior',
      status: 'ACTIVE',
      sortOrder: 1,
      labelEn: 'Sample exterior',
      labelAr: 'Sample exterior AR',
      itemCount: 1,
    ),
  ];

  @override
  Future<List<ItemSummary>> items({
    String search = '',
    String categoryId = '',
    String status = '',
  }) async => const [
    ItemSummary(
      id: 'item-1',
      stableCode: 'SAMPLE-EXT-001',
      categoryId: 'cat-1',
      categoryLabelEn: 'Sample exterior',
      categoryLabelAr: 'Sample exterior AR',
      status: 'DRAFT',
      currentVersion: 1,
      labelEn: 'Sample body panel check',
      labelAr: 'Sample body panel check AR',
      sampleData: true,
      updatedAt: '2026-11-03T10:00:00',
    ),
  ];

  @override
  Future<ItemDetail> itemDetail(String id) async => const ItemDetail(
    item: ItemSummary(
      id: 'item-1',
      stableCode: 'SAMPLE-EXT-001',
      categoryId: 'cat-1',
      categoryLabelEn: 'Sample exterior',
      categoryLabelAr: 'Sample exterior AR',
      status: 'DRAFT',
      currentVersion: 1,
      labelEn: 'Sample body panel check',
      labelAr: 'Sample body panel check AR',
      sampleData: true,
      updatedAt: '2026-11-03T10:00:00',
    ),
    versions: [
      ItemVersion(
        id: 'version-1',
        versionNo: 1,
        status: 'DRAFT',
        resultOptions: ['NO_ISSUE_OBSERVED', 'DEFECT_FOUND'],
        severityPolicy: '{}',
        applicability: '{}',
        reasonCodes: [],
        noteRequirement: 'OPTIONAL',
        evidenceRequirement: 'NONE',
        minPhotos: 0,
        equipmentIds: [],
        guideImageId: null,
        publishedAt: null,
        translations: {
          'en': Translation(
            locale: 'en',
            label: 'Sample body panel check',
            instruction: 'Inspect the panel.',
          ),
          'ar': Translation(
            locale: 'ar',
            label: 'Sample body panel check AR',
            instruction: 'Inspect the panel AR.',
          ),
        },
      ),
    ],
  );

  @override
  Future<List<Reason>> reasons() async => const [
    Reason(
      id: 'reason-1',
      code: 'DAMAGE',
      status: 'ACTIVE',
      sortOrder: 1,
      labelEn: 'Damage',
      labelAr: 'Damage AR',
    ),
  ];

  @override
  Future<List<Equipment>> equipment() async => const [
    Equipment(
      id: 'equipment-1',
      code: 'LIFT',
      status: 'ACTIVE',
      sortOrder: 1,
      labelEn: 'Lift',
      labelAr: 'Lift AR',
    ),
  ];

  @override
  Future<List<GuideImage>> guideImages() async => const [];

  @override
  Future<List<AuditEvent>> auditEvents() async => const [
    AuditEvent(
      id: 'audit-1',
      action: 'MASTER_ITEM_PUBLISHED',
      actorRole: 'PLATFORM_ADMIN',
      entityType: 'MASTER_ITEM',
      occurredAt: '2026-11-03T10:00:00',
      reasonCode: null,
      metadataJson: '{}',
    ),
  ];

  @override
  Future<List<StaffMember>> staff() async => const [
    StaffMember(
      userId: 'tech-1',
      displayName: 'Technician A',
      emailMasked: 't***@test.local',
      role: 'TECHNICIAN',
      status: 'ACTIVE',
    ),
  ];

  @override
  Future<JobCounts> jobCounts() async => const JobCounts(
    draft: 10,
    scheduled: 24,
    newScheduled: 34,
    assigned: 14,
    inProgress: 9,
    readyToFinalize: 45,
    finalized: 60,
    finalizedToday: 56,
    cancelled: 3,
    total: 140,
  );

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async => const [
    WorkshopJob(
      id: 'job-1',
      reference: 'JOB-TEST0001',
      status: 'ASSIGNED',
      templateVersionId: 'version-1',
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
      scope: 'Full inspection',
    ),
  ];

  @override
  Future<List<Category>> workshopCategories() async => const [
    Category(
      id: 'cat-1',
      slug: 'sample-exterior',
      status: 'ACTIVE',
      sortOrder: 1,
      labelEn: 'Sample exterior',
      labelAr: 'Sample exterior AR',
      itemCount: 1,
    ),
  ];

  @override
  Future<List<PublishedItem>> publishedItems({
    String search = '',
    String categoryId = '',
  }) async => const [
    PublishedItem(
      itemId: 'item-1',
      versionId: 'version-1',
      stableCode: 'SAMPLE-EXT-001',
      categoryId: 'cat-1',
      categoryLabelEn: 'Sample exterior',
      categoryLabelAr: 'Sample exterior AR',
      labelEn: 'Sample body panel check',
      labelAr: 'Sample body panel check AR',
      sampleData: true,
      version: ItemVersion(
        id: 'version-1',
        versionNo: 1,
        status: 'PUBLISHED',
        resultOptions: ['NO_ISSUE_OBSERVED', 'DEFECT_FOUND'],
        severityPolicy: '{}',
        applicability: '{}',
        reasonCodes: [],
        noteRequirement: 'OPTIONAL',
        evidenceRequirement: 'NONE',
        minPhotos: 0,
        equipmentIds: [],
        guideImageId: null,
        publishedAt: '2026-11-03T10:00:00',
        translations: {
          'en': Translation(
            locale: 'en',
            label: 'Sample body panel check',
            instruction: 'Inspect the panel.',
          ),
          'ar': Translation(
            locale: 'ar',
            label: 'Sample body panel check AR',
            instruction: 'Inspect the panel AR.',
          ),
        },
      ),
    ),
  ];

  @override
  Future<List<TemplateSummary>> templates() async => const [
    TemplateSummary(
      id: 'template-1',
      name: 'Full inspection',
      serviceType: 'FULL',
      vehicleType: 'CAR',
      status: 'PUBLISHED',
      currentVersion: 1,
      itemCount: 1,
    ),
  ];

  @override
  Future<TemplateDetail> templateDetail(String id) async =>
      const TemplateDetail(
        id: 'template-1',
        name: 'Full inspection',
        description: 'Workshop template',
        serviceType: 'FULL',
        vehicleType: 'CAR',
        status: 'PUBLISHED',
        currentPublishedVersionId: 'version-1',
        versions: [
          TemplateVersionSummary(
            id: 'version-1',
            versionNo: 1,
            status: 'PUBLISHED',
            publishedAt: '2026-11-03T10:00:00',
            itemCount: 1,
          ),
        ],
        draft: TemplateVersionView(
          id: 'version-2',
          versionNo: 2,
          status: 'DRAFT',
          publishedAt: '',
          items: [
            TemplateItemView(
              masterItemVersionId: 'version-1',
              sortOrder: 0,
              stableCode: 'SAMPLE-EXT-001',
              categoryLabelEn: 'Sample exterior',
              categoryLabelAr: 'Sample exterior AR',
              labelEn: 'Sample body panel check',
              labelAr: 'Sample body panel check AR',
              instructionEn: 'Inspect the panel.',
              instructionAr: 'Inspect the panel AR.',
              versionNo: 1,
              resultOptions: ['NO_ISSUE_OBSERVED', 'DEFECT_FOUND'],
              severityPolicy: '{}',
              reasonCodes: [],
              noteRequirement: 'OPTIONAL',
              evidenceRequirement: 'NONE',
              minPhotos: 0,
              equipmentIds: [],
              guideImageId: null,
              sampleData: true,
            ),
          ],
        ),
      );

  @override
  Future<List<TemplateVersionOption>> templateVersionOptions() async => const [
    TemplateVersionOption(
      versionId: 'version-1',
      templateId: 'template-1',
      templateName: 'Full inspection',
      versionNo: 1,
      serviceType: 'FULL',
      vehicleType: 'CAR',
    ),
  ];

  @override
  Future<TemplateVersionView> templateVersion(
    String id,
    String versionId,
  ) async => const TemplateVersionView(
    id: 'version-1',
    versionNo: 1,
    status: 'PUBLISHED',
    publishedAt: '2026-11-03T10:00:00',
    items: [
      TemplateItemView(
        masterItemVersionId: 'version-1',
        sortOrder: 0,
        stableCode: 'SAMPLE-EXT-001',
        categoryLabelEn: 'Sample exterior',
        categoryLabelAr: 'Sample exterior AR',
        labelEn: 'Sample body panel check',
        labelAr: 'Sample body panel check AR',
        instructionEn: 'Inspect the panel.',
        instructionAr: 'Inspect the panel AR.',
        versionNo: 1,
        resultOptions: ['NO_ISSUE_OBSERVED', 'DEFECT_FOUND'],
        severityPolicy: '{}',
        reasonCodes: [],
        noteRequirement: 'OPTIONAL',
        evidenceRequirement: 'NONE',
        minPhotos: 0,
        equipmentIds: [],
        guideImageId: null,
        sampleData: true,
      ),
    ],
  );

  @override
  Future<List<ReportDelivery>> deliveries(String jobId) async => const [];

  @override
  Future<PlatformAccount> createUser({
    required String email,
    required String displayName,
    required String temporaryPassword,
    required String role,
    required String workshopId,
  }) async {
    createdUsers.add(email);
    return PlatformAccount(
      userId: 'user-new',
      displayName: displayName,
      email: email,
      emailMasked: email,
      role: role,
      status: 'ACTIVE',
      workshopId: workshopId,
      primary: false,
      invitationExpiresAt: null,
    );
  }

  @override
  Future<PlatformAccount> createTechnician({
    required String email,
    required String displayName,
    required String initialPassword,
  }) async {
    createdTechnicians.add(email);
    return PlatformAccount(
      userId: 'tech-new',
      displayName: displayName,
      email: email,
      emailMasked: email,
      role: 'TECHNICIAN',
      status: 'ACTIVE',
      workshopId: 'workshop-1',
      primary: false,
      invitationExpiresAt: null,
    );
  }

  @override
  Future<PlatformAccount> resetPlatformPassword(
    String userId,
    String newPassword,
  ) async {
    resetPlatformCalls.add(userId);
    return const PlatformAccount(
      userId: 'admin-1',
      displayName: 'Admin A',
      email: 'admin.a@test.local',
      emailMasked: 'a***@test.local',
      role: 'WORKSHOP_ADMIN',
      status: 'ACTIVE',
      workshopId: 'workshop-1',
      primary: true,
      invitationExpiresAt: null,
    );
  }

  @override
  Future<PlatformAccount> resetTechnicianPassword(
    String userId,
    String newPassword,
  ) async {
    resetTechnicianCalls.add(userId);
    return const PlatformAccount(
      userId: 'tech-1',
      displayName: 'Technician A',
      email: 'tech.a@test.local',
      emailMasked: 't***@test.local',
      role: 'TECHNICIAN',
      status: 'ACTIVE',
      workshopId: 'workshop-1',
      primary: true,
      invitationExpiresAt: null,
    );
  }

  final createdUsers = <String>[];
  final createdTechnicians = <String>[];
  final resetPlatformCalls = <String>[];
  final resetTechnicianCalls = <String>[];

  @override
  Future<List<AvailableTemplate>> availableTemplates() async => const [
    AvailableTemplate(
      versionId: 'version-1',
      templateId: 'template-1',
      code: 'FULL',
      nameEn: 'Full inspection',
      nameAr: 'فحص شامل',
      versionNo: 1,
      itemCount: 2,
    ),
  ];

  @override
  Future<JobTemplateDetail> templateVersionDetail(String versionId) async =>
      const JobTemplateDetail(
        versionId: 'version-1',
        templateId: 'template-1',
        code: 'FULL',
        nameEn: 'Full inspection',
        nameAr: 'فحص شامل',
        versionNo: 1,
        status: 'PUBLISHED',
        items: [
          JobTemplateItem(
            itemVersionId: 'item-version-1',
            stableCode: 'JOB-EXT-001',
            labelEn: 'Body panel check',
            labelAr: 'فحص هيكل المركبة',
            categoryId: 'cat-1',
            categoryNameEn: 'Exterior',
            categoryNameAr: 'الهيكل الخارجي',
            safetyCritical: false,
            measurementUnit: null,
            sortOrder: 1,
          ),
          JobTemplateItem(
            itemVersionId: 'item-version-2',
            stableCode: 'JOB-BRK-001',
            labelEn: 'Brake pad thickness',
            labelAr: 'سمك أقمشة الفرامل',
            categoryId: 'cat-2',
            categoryNameEn: 'Brakes',
            categoryNameAr: 'الفرامل',
            safetyCritical: true,
            measurementUnit: 'mm',
            sortOrder: 2,
          ),
        ],
      );

  @override
  Future<JobPage> cleanJobs({
    int page = 0,
    int size = 20,
    String status = '',
    String search = '',
    String from = '',
    String to = '',
  }) async {
    final query = search.trim().toLowerCase();
    final filtered = _jobs.where((job) {
      if (status.isNotEmpty && job.status != status) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return [
        job.reference,
        job.customerName,
        job.vehicleMake,
        job.vehicleModel,
        job.assignedTechnicianName ?? '',
      ].any((field) => field.toLowerCase().contains(query));
    }).toList(growable: false);
    final safeSize = size <= 0 ? 20 : size;
    final start = (page * safeSize).clamp(0, filtered.length);
    final end = (start + safeSize).clamp(0, filtered.length);
    return JobPage(
      items: filtered.sublist(start, end),
      page: page,
      size: safeSize,
      total: filtered.length,
      totalPages: filtered.isEmpty
          ? 0
          : (filtered.length / safeSize).ceil(),
    );
  }

  @override
  Future<CleanJob> cleanJob(String id) async => _job(id);

  @override
  Future<CleanJob> createCleanJob(NewCleanJob job) async {
    final version = await availableTemplates();
    final template = version.firstWhere(
      (item) => item.versionId == job.templateVersionId,
      orElse: () => version.first,
    );
    final created = CleanJob(
      id: 'job-${_jobs.length + 1}',
      reference: 'JOB-${(_jobs.length + 1).toString().padLeft(4, '0')}',
      status: 'DRAFT',
      reviewStatus: 'NOT_STARTED',
      publicationStatus: 'NOT_PUBLISHED',
      templateVersionId: job.templateVersionId,
      templateNameEn: template.nameEn,
      templateNameAr: template.nameAr,
      templateVersionNo: template.versionNo,
      assignedTechnicianId: job.assignedTechnicianId,
      assignedTechnicianName: job.assignedTechnicianId,
      customerName: job.customerName,
      customerPhone: job.customerPhone,
      customerEmail: job.customerEmail,
      vehicleVin: job.vehicleVin,
      vehicleMake: job.vehicleMake,
      vehicleModel: job.vehicleModel,
      vehicleYear: job.vehicleYear,
      vehiclePlate: job.vehiclePlate,
      odometerValue: job.odometerValue,
      odometerUnit: job.odometerUnit,
      transmission: job.transmission,
      fuelType: job.fuelType,
      preferredLanguage: job.preferredLanguage,
      scheduledAt: job.scheduledAt,
      startedAt: null,
      completedAt: null,
      approvedAt: null,
      publishedAt: null,
      cancelledAt: null,
      approvedBy: null,
      cancelledBy: null,
      cancelReason: null,
      score: null,
      gradeCode: null,
      safetyCapApplied: false,
      safetyCapReason: null,
      consentGranted: false,
      createdAt: '2026-11-08T08:00:00',
      updatedAt: '2026-11-08T08:00:00',
      version: 1,
    );
    _jobs = <CleanJob>[..._jobs, created];
    return created;
  }

  @override
  Future<CleanJob> updateCleanJob(String id, UpdateCleanJob job) async {
    final current = _job(id);
    final updated = current.copyWith(
      customerName: job.customerName,
      customerPhone: job.customerPhone,
      customerEmail: job.customerEmail,
      vehicleVin: job.vehicleVin,
      vehicleMake: job.vehicleMake,
      vehicleModel: job.vehicleModel,
      vehicleYear: job.vehicleYear,
      vehiclePlate: job.vehiclePlate,
      odometerValue: job.odometerValue,
      odometerUnit: job.odometerUnit,
      transmission: job.transmission,
      fuelType: job.fuelType,
      preferredLanguage: job.preferredLanguage,
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<CleanJob> assignCleanJob(
    String jobId,
    String technicianId,
    String? reason, {
    int? version,
  }) async {
    final updated = _job(jobId).copyWith(
      assignedTechnicianId: technicianId,
      assignedTechnicianName: technicianId,
      status: 'ASSIGNED',
    );
    _replace(updated);
    final history = _assignments.putIfAbsent(jobId, () => <JobAssignment>[]);
    history.add(
      JobAssignment(
        id: 'assignment-${history.length + 1}',
        technicianId: technicianId,
        assignedBy: 'admin-1',
        assignedAt: '2026-11-08T09:00:00',
        unassignedAt: null,
        reason: reason,
      ),
    );
    return updated;
  }

  @override
  Future<CleanJob> cancelCleanJob(
    String jobId,
    String reason, {
    int? version,
  }) async {
    final updated = _job(jobId).copyWith(
      status: 'CANCELLED',
      cancelledAt: '2026-11-08T09:30:00',
      cancelledBy: 'admin-1',
      cancelReason: reason,
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<List<JobAssignment>> jobAssignments(String jobId) async =>
      _assignments[jobId] ?? const <JobAssignment>[];

  @override
  Future<JobReview> jobReview(String jobId) async => const JobReview(
    jobId: 'job-1',
    status: 'PENDING_REVIEW',
    itemsAssessed: 2,
    itemsTotal: 2,
    scorePreview: 88,
    gradePreview: 'B',
    safetyCapPreview: null,
    findings: [
      ReviewFinding(
        itemVersionId: 'item-version-1',
        stableCode: 'JOB-EXT-001',
        labelEn: 'Body panel check',
        labelAr: 'فحص هيكل المركبة',
        resultCode: 'NO_ISSUE_OBSERVED',
        score: 100,
        evidencePhotos: ['photo-1'],
        evidenceVideos: [],
        signaturePresent: true,
        completedAt: '2026-11-05T09:40:00',
        issueValues: {},
      ),
      ReviewFinding(
        itemVersionId: 'item-version-2',
        stableCode: 'JOB-BRK-001',
        labelEn: 'Brake pad thickness',
        labelAr: 'سمك أقمشة الفرامل',
        resultCode: 'ATTENTION_RECOMMENDED',
        score: 70,
        evidencePhotos: ['photo-2', 'photo-3'],
        evidenceVideos: ['video-1'],
        signaturePresent: true,
        completedAt: '2026-11-05T09:55:00',
        issueValues: {'THICKNESS': '4.2'},
      ),
    ],
  );

  @override
  Future<PublishChecklist> publishChecklist(String jobId) async {
    final passed = checklistReady;
    return PublishChecklist(
      jobId: jobId,
      ready: passed,
      items: [
        ChecklistEntry(
          code: 'ITEMS_ASSESSED',
          passed: passed,
          messageEn: 'All items assessed',
          messageAr: 'تم تقييم جميع العناصر',
        ),
        ChecklistEntry(
          code: 'EVIDENCE_RULES',
          passed: passed,
          messageEn: 'Evidence rules met',
          messageAr: 'تم استيفاء قواعد الأدلة',
        ),
        ChecklistEntry(
          code: 'CONSENT',
          passed: passed,
          messageEn: 'Consent granted',
          messageAr: 'تمت الموافقة',
        ),
      ],
      itemsAssessed: 2,
      itemsTotal: 2,
      score: 88,
      gradeCode: 'B',
      safetyCapApplied: false,
      safetyCapReason: null,
      consentGranted: passed,
      signaturePresent: true,
      documentsReady: passed,
    );
  }

  @override
  Future<CleanJob> approveJob(
    String jobId, {
    String? reason,
    String? safetyCapReason,
    int? version,
  }) async {
    if (!approveSucceeds) {
      throw StateError('approve failed');
    }
    final updated = _job(jobId).copyWith(
      status: 'APPROVED',
      reviewStatus: 'APPROVED',
      approvedAt: '2026-11-08T10:00:00',
      approvedBy: 'admin-1',
      gradeCode: 'B',
      score: 88,
      safetyCapReason: safetyCapReason,
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<CleanJob> rejectJob(
    String jobId,
    String reason, {
    int? version,
  }) async {
    final updated = _job(jobId).copyWith(
      status: 'REJECTED',
      reviewStatus: 'REJECTED',
      cancelReason: reason,
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<PublicLink> publishJob(
    String jobId, {
    bool? pdfDownloadEnabled,
  }) async {
    final link = PublicLink(
      jobId: jobId,
      status: 'ACTIVE',
      publicUrl: 'https://reports.test.local/r/token-$jobId',
      token: 'token-$jobId',
      qrUrl: 'https://reports.test.local/r/token-$jobId/qr',
      pdfDownloadEnabled: pdfDownloadEnabled ?? true,
      activatedAt: '2026-11-08T11:00:00',
      revokedAt: null,
      revocationReason: null,
    );
    _links[jobId] = link;
    _replace(_job(jobId).copyWith(status: 'PUBLISHED', publicationStatus: 'ACTIVE'));
    return link;
  }

  @override
  Future<PublicLink> unpublishJob(String jobId, String reason) async {
    final link = (_links[jobId] ??
            const PublicLink(
              jobId: 'job-1',
              status: 'ACTIVE',
              publicUrl: null,
              token: null,
              qrUrl: null,
              pdfDownloadEnabled: false,
              activatedAt: null,
              revokedAt: null,
              revocationReason: null,
            ))
        .copyWith(status: 'UNPUBLISHED', revocationReason: reason);
    _links[jobId] = link;
    return link;
  }

  @override
  Future<PublicLink> rotateJobToken(String jobId) async {
    final current = _links[jobId];
    final link = PublicLink(
      jobId: jobId,
      status: current?.status ?? 'ACTIVE',
      publicUrl: 'https://reports.test.local/r/rotated-$jobId',
      token: 'rotated-$jobId',
      qrUrl: 'https://reports.test.local/r/rotated-$jobId/qr',
      pdfDownloadEnabled: current?.pdfDownloadEnabled ?? true,
      activatedAt: current?.activatedAt,
      revokedAt: current?.revokedAt,
      revocationReason: current?.revocationReason,
    );
    _links[jobId] = link;
    return link;
  }

  @override
  Future<PublicLink> revokeJob(String jobId, String reason) async {
    final link = (_links[jobId] ??
            const PublicLink(
              jobId: 'job-1',
              status: 'ACTIVE',
              publicUrl: null,
              token: null,
              qrUrl: null,
              pdfDownloadEnabled: false,
              activatedAt: null,
              revokedAt: null,
              revocationReason: null,
            ))
        .copyWith(
          status: 'REVOKED',
          revokedAt: '2026-11-08T12:00:00',
          revocationReason: reason,
        );
    _links[jobId] = link;
    return link;
  }

  @override
  Future<PublicLink> publicLink(String jobId) async =>
      _links[jobId] ??
      PublicLink(
        jobId: jobId,
        status: 'NOT_PUBLISHED',
        publicUrl: null,
        token: null,
        qrUrl: null,
        pdfDownloadEnabled: false,
        activatedAt: null,
        revokedAt: null,
        revocationReason: null,
      );

  @override
  Future<List<int>> jobQr(String jobId) async => const <int>[];

  @override
  Future<List<JobDocument>> jobDocuments(String jobId) async =>
      List<JobDocument>.unmodifiable(_documents);

  @override
  Future<List<JobDocument>> retryJobDocument(String jobId, String type) async {
    for (var index = 0; index < _documents.length; index++) {
      final document = _documents[index];
      if (document.documentTypeCode == type) {
        _documents[index] = JobDocument(
          id: document.id,
          documentTypeCode: document.documentTypeCode,
          nameEn: document.nameEn,
          nameAr: document.nameAr,
          language: document.language,
          status: 'QUEUED',
          bytes: document.bytes,
          generatedAt: document.generatedAt,
          error: null,
          downloadUrl: document.downloadUrl,
        );
      }
    }
    return jobDocuments(jobId);
  }

  @override
  Future<List<WorkshopNotification>> notifications({
    bool unreadOnly = false,
  }) async => unreadOnly
      ? _notifications.where((item) => !item.isRead).toList(growable: false)
      : List<WorkshopNotification>.unmodifiable(_notifications);

  @override
  Future<WorkshopNotification> readNotification(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0) {
      throw StateError('notification not found');
    }
    final current = _notifications[index];
    final updated = WorkshopNotification(
      id: current.id,
      type: current.type,
      payloadJson: current.payloadJson,
      readAt: '2026-11-08T13:00:00',
      createdAt: current.createdAt,
    );
    _notifications = <WorkshopNotification>[..._notifications]..[index] = updated;
    return updated;
  }

  @override
  Future<CleanJobCounts> cleanJobCounts() async => CleanJobCounts(
    draft: _count('DRAFT'),
    scheduled: _count('SCHEDULED'),
    assigned: _count('ASSIGNED'),
    inProgress: _count('IN_PROGRESS'),
    pendingReview: _count('PENDING_REVIEW'),
    approved: _count('APPROVED'),
    published: _count('PUBLISHED'),
    rejected: _count('REJECTED'),
    cancelled: _count('CANCELLED'),
    total: _jobs.length,
  );

  int _count(String status) =>
      _jobs.where((job) => job.status == status).length;

  CleanJob _job(String id) =>
      _jobs.firstWhere((job) => job.id == id);

  void _replace(CleanJob updated) {
    final index = _jobs.indexWhere((job) => job.id == updated.id);
    if (index >= 0) {
      _jobs = <CleanJob>[..._jobs]..[index] = updated;
    }
  }

  String statusOf(String jobId) => _job(jobId).status;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
