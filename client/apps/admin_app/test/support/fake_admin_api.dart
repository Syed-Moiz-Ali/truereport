import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/models.dart';

class FakeAdminApi implements AdminApi {
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
    const pending = PlatformAccount(
      userId: 'pending-1',
      displayName: 'Pending Tech',
      email: 'pending@test.local',
      emailMasked: 'p***@test.local',
      role: 'TECHNICIAN',
      status: 'PENDING_INVITATION',
      workshopId: 'workshop-1',
      primary: false,
      invitationExpiresAt: '2026-11-06T10:00:00',
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
          pendingInvitations: [pending],
        ),
      ],
      totalWorkshops: 1,
      totalAccounts: 3,
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
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
