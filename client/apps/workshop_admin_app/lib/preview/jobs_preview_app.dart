import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/archive/legacy_archive_page.dart';
import 'package:workshop_admin_app/src/features/jobs/public_link_page.dart';
import 'package:workshop_admin_app/src/features/jobs/workshop_notifications_page.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Throwaway capture harness for the three jobs surfaces. Not shipped.
enum PreviewSurface { publicLink, notifications, archive }

class _PreviewApi implements AdminApi {
  static const _link = PublicLink(
    jobId: 'job-preview',
    status: 'ACTIVE',
    publicUrl:
        'https://reports.truereport.app/r/9f2c41ab7d5e4c0e8b3a6f1d2c9e5a70',
    token: '9f2c41ab7d5e4c0e8b3a6f1d2c9e5a70',
    qrUrl: null,
    pdfDownloadEnabled: true,
    activatedAt: '2026-11-18T14:12:00',
    revokedAt: null,
    revocationReason: null,
  );

  static const _notifications = <WorkshopNotification>[
    WorkshopNotification(
      id: 'n-1',
      type: 'JOB_PENDING_REVIEW',
      payloadJson: '{"jobId":"job-1","reference":"JOB-2026-0148","customer":"Mariam Abdulrahman Al Suwaidi"}',
      readAt: null,
      createdAt: '2026-11-19T09:42:00',
    ),
    WorkshopNotification(
      id: 'n-2',
      type: 'JOB_APPROVED',
      payloadJson: '{"jobId":"job-2","reference":"JOB-2026-0141","approvedBy":"Layla Haddad"}',
      readAt: null,
      createdAt: '2026-11-19T08:15:00',
    ),
    WorkshopNotification(
      id: 'n-3',
      type: 'DOCUMENT_READY',
      payloadJson: '{"jobId":"job-3","reference":"JOB-2026-0139","document":"Inspection report · AR"}',
      readAt: null,
      createdAt: '2026-11-18T17:05:00',
    ),
    WorkshopNotification(
      id: 'n-4',
      type: 'JOB_PUBLISHED',
      payloadJson: '{"jobId":"job-3","reference":"JOB-2026-0139","channel":"public-link"}',
      readAt: '2026-11-18T16:40:00',
      createdAt: '2026-11-18T16:20:00',
    ),
    WorkshopNotification(
      id: 'n-5',
      type: 'JOB_REJECTED',
      payloadJson: '{"jobId":"job-4","reference":"JOB-2026-0131","reason":"Brake measurement missing"}',
      readAt: '2026-11-17T11:05:00',
      createdAt: '2026-11-17T10:52:00',
    ),
  ];

  static const _archive = <WorkshopJob>[
    WorkshopJob(
      id: 'legacy-1',
      reference: 'LEG-0001',
      status: 'FINALIZED',
      templateVersionId: 'version-1',
      templateName: 'Legacy inspection',
      templateVersionNo: 1,
      assignedTechnicianId: 'tech-1',
      assignedTechnicianName: 'Ahmed Al Mansoori',
      scheduledAt: '2026-11-05T09:00:00',
      customerName: 'Mariam Abdulrahman Al Suwaidi',
      customerPhone: '+971500000001',
      customerEmail: 'mariam@example.test',
      vehicleMake: 'Toyota',
      vehicleModel: 'Land Cruiser Prado VXR',
      vehicleYear: 2020,
      vehicleVin: 'TESTVIN00000000001',
      vehiclePlate: 'DXB 78421',
      scope: 'Legacy inspection',
    ),
    WorkshopJob(
      id: 'legacy-2',
      reference: 'LEG-0002',
      status: 'IN_PROGRESS',
      templateVersionId: 'version-1',
      templateName: 'Legacy inspection',
      templateVersionNo: 1,
      assignedTechnicianId: null,
      assignedTechnicianName: null,
      scheduledAt: '2026-11-04T09:00:00',
      customerName: 'Khalid Ibrahim Al Hashimi',
      customerPhone: '+971500000002',
      customerEmail: 'khalid@example.test',
      vehicleMake: 'Nissan',
      vehicleModel: 'Patrol Platinum',
      vehicleYear: 2021,
      vehicleVin: 'TESTVIN00000000002',
      vehiclePlate: 'AUH 11904',
      scope: 'Legacy inspection',
    ),
    WorkshopJob(
      id: 'legacy-3',
      reference: 'LEG-0003',
      status: 'FINALIZED',
      templateVersionId: 'version-1',
      templateName: 'Legacy inspection',
      templateVersionNo: 1,
      assignedTechnicianId: 'tech-2',
      assignedTechnicianName: 'Sara Nasser',
      scheduledAt: '2026-11-02T11:30:00',
      customerName: 'Fatima Hassan Al Zaabi',
      customerPhone: '+971500000003',
      customerEmail: 'fatima@example.test',
      vehicleMake: 'Mercedes-Benz',
      vehicleModel: 'G 63 AMG',
      vehicleYear: 2019,
      vehicleVin: 'TESTVIN00000000003',
      vehiclePlate: 'SHJ 55210',
      scope: 'Legacy inspection',
    ),
    WorkshopJob(
      id: 'legacy-4',
      reference: 'LEG-0004',
      status: 'CANCELLED',
      templateVersionId: 'version-1',
      templateName: 'Legacy inspection',
      templateVersionNo: 1,
      assignedTechnicianId: null,
      assignedTechnicianName: null,
      scheduledAt: '2026-10-29T08:00:00',
      customerName: 'Omar Saeed Al Marri',
      customerPhone: '+971500000004',
      customerEmail: 'omar@example.test',
      vehicleMake: 'Ford',
      vehicleModel: 'F-150 Raptor',
      vehicleYear: 2022,
      vehicleVin: 'TESTVIN00000000004',
      vehiclePlate: 'DXB 90877',
      scope: 'Legacy inspection',
    ),
    WorkshopJob(
      id: 'legacy-5',
      reference: 'LEG-0005',
      status: 'FINALIZED',
      templateVersionId: 'version-1',
      templateName: 'Legacy inspection',
      templateVersionNo: 1,
      assignedTechnicianId: 'tech-1',
      assignedTechnicianName: 'Ahmed Al Mansoori',
      scheduledAt: '2026-10-27T13:45:00',
      customerName: 'Noura Rashid Al Ketbi',
      customerPhone: '+971500000005',
      customerEmail: 'noura@example.test',
      vehicleMake: 'Porsche',
      vehicleModel: '911 GT3',
      vehicleYear: 2023,
      vehicleVin: 'TESTVIN00000000005',
      vehiclePlate: 'DXB 00231',
      scope: 'Legacy inspection',
    ),
  ];

  @override
  Future<PublicLink> publicLink(String jobId) async => _link;

  @override
  Future<List<int>> jobQr(String jobId) async => const <int>[];

  @override
  Future<List<WorkshopNotification>> notifications({
    bool unreadOnly = false,
  }) async => unreadOnly
      ? _notifications.where((item) => !item.isRead).toList(growable: false)
      : _notifications;

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async => _archive;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Widget buildPreview(PreviewSurface surface) {
  return ProviderScope(
    overrides: [adminApiProvider.overrideWithValue(_PreviewApi())],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: switch (surface) {
        PreviewSurface.publicLink => const PublicLinkPage(jobId: 'job-preview'),
        PreviewSurface.notifications => const WorkshopNotificationsPage(),
        PreviewSurface.archive => const LegacyArchivePage(),
      },
    ),
  );
}
