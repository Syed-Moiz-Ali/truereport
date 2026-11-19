import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tab.dart';
import 'package:workshop_admin_app/src/features/jobs/jobs_tab.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:workshop_admin_app/src/workshop_clock.dart';
import 'package:workshop_admin_app/src/workshop_digits.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

// F3-B Step 0 (Q3) + T1: raw ISO `scheduledAt`/`finalizedAt` strings must never
// reach users. Since wave 2 the display policy is `WorkshopClock`: a value with
// no offset is already an Asia/Dubai wall time (never shifted), a value with an
// offset converts to Asia/Dubai. Formatting stays `DateFormat.yMd(locale) +
// add_Hm()`, counts stay `NumberFormat.decimalPattern(locale)`.
const _isoScheduled = '2026-11-05T09:00:00';
const _isoFinalized = '2026-11-04T10:30:00';

/// A real instant for the same Dubai wall clock (09:00 naive == 05:00Z).
const _isoScheduledWithOffset = '2026-11-05T05:00:00Z';

// Naive ISO is a Dubai wall time: 09:00 stays 09:00; 10:30 stays 10:30.
String _expectedInstant(String iso, String localeName) {
  final wall = WorkshopClock.wallTime(iso)!;
  return DateFormat.yMd(localeName).add_Hm().format(wall);
}

/// Clean-family fixtures for the dashboard, which reads `platform_jobs`.
/// `scheduledAt` is a naive Dubai wall time, the exact shape the server sends.
const _cleanPending = CleanJob(
  id: 'job-1',
  reference: 'JOB-10482',
  status: 'PENDING_REVIEW',
  reviewStatus: 'PENDING_REVIEW',
  publicationStatus: 'NOT_PUBLISHED',
  templateVersionId: 'version-1',
  templateNameEn: 'Full inspection',
  templateNameAr: 'فحص شامل',
  templateVersionNo: 1,
  assignedTechnicianId: 'tech-1',
  assignedTechnicianName: 'Rashid K.',
  customerName: 'Ahmed Al Mansoori',
  customerPhone: '+971500000100',
  customerEmail: 'a@test.local',
  vehicleVin: 'TESTVIN00000000002',
  vehicleMake: 'Nissan',
  vehicleModel: 'Patrol',
  vehicleYear: 2022,
  vehiclePlate: 'A12345',
  odometerValue: 45000,
  odometerUnit: 'KM',
  transmission: 'AUTOMATIC',
  fuelType: 'PETROL',
  preferredLanguage: 'en',
  scheduledAt: _isoScheduled,
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
  consentGranted: true,
  createdAt: '2026-11-04T08:00:00',
  updatedAt: '2026-11-05T10:00:00',
  version: 1,
);

const _cleanApproved = CleanJob(
  id: 'job-2',
  reference: 'JOB-10465',
  status: 'APPROVED',
  reviewStatus: 'APPROVED',
  publicationStatus: 'NOT_PUBLISHED',
  templateVersionId: 'version-1',
  templateNameEn: 'Full inspection',
  templateNameAr: 'فحص شامل',
  templateVersionNo: 1,
  assignedTechnicianId: null,
  assignedTechnicianName: null,
  customerName: 'Hessa Al Suwaidi',
  customerPhone: null,
  customerEmail: null,
  vehicleVin: 'TESTVIN00000000003',
  vehicleMake: 'Porsche',
  vehicleModel: 'Macan',
  vehicleYear: 2023,
  vehiclePlate: 'B67890',
  odometerValue: null,
  odometerUnit: null,
  transmission: null,
  fuelType: null,
  preferredLanguage: 'en',
  scheduledAt: null,
  startedAt: null,
  completedAt: null,
  approvedAt: '2026-11-05T11:00:00',
  publishedAt: null,
  cancelledAt: null,
  approvedBy: 'user-1',
  cancelledBy: null,
  cancelReason: null,
  score: 88,
  gradeCode: 'B',
  safetyCapApplied: false,
  safetyCapReason: null,
  consentGranted: true,
  createdAt: '2026-11-04T09:00:00',
  updatedAt: '2026-11-05T11:00:00',
  version: 2,
);

class _IntlFakeApi implements AdminApi {
  @override
  Future<CleanJobCounts> cleanJobCounts() async => const CleanJobCounts(
    draft: 0,
    scheduled: 0,
    assigned: 0,
    inProgress: 0,
    pendingReview: 1,
    approved: 1,
    published: 1,
    rejected: 0,
    cancelled: 0,
    total: 3,
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
    final filtered = <CleanJob>[_cleanPending, _cleanApproved]
        .where((job) {
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
          ].any((field) => field.toLowerCase().contains(query));
        })
        .toList(growable: false);
    final start = (page * size).clamp(0, filtered.length);
    final end = (start + size).clamp(0, filtered.length);
    return JobPage(
      items: filtered.sublist(start, end),
      page: page,
      size: size,
      total: filtered.length,
      totalPages: filtered.isEmpty ? 0 : (filtered.length / size).ceil(),
    );
  }

  @override
  Future<CleanJob> cleanJob(String id) async =>
      id == _cleanPending.id ? _cleanPending : _cleanApproved;

  @override
  Future<ReportAdmin> report(String jobId) async => const ReportAdmin(
    reportId: 'report-1',
    jobId: 'job-1',
    reportNumber: 'TR-0001',
    version: 1,
    generationStatus: 'READY',
    generationError: null,
    attempts: 1,
    reportReady: true,
    pdfReady: true,
    pdfDownloadEnabled: false,
    linkState: 'PENDING_CONSENT',
    consentState: 'GRANTED',
    publicUrl: null,
    finalizedAt: _isoFinalized,
    snapshotHash: 'abc123',
    content: null,
  );

  @override
  Future<List<ReportDelivery>> deliveries(String jobId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({required this.home, required this.locale});

  final Widget home;
  final Locale locale;

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).setLocale(widget.locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: widget.home,
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  Locale locale, {
  Size size = const Size(1280, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final container = ProviderContainer(
    overrides: [adminApiProvider.overrideWithValue(_IntlFakeApi())],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _Harness(home: home, locale: locale),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  // Pure unit tests run outside the widget/localizations binding, so the
  // intl date symbols must be initialized explicitly. Widget tests below
  // run with the real MaterialApp localizations and need no init.
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  test('fixed instant renders in EN locale shape (yMd + Hm)', () {
    final formatted = _expectedInstant(_isoScheduled, 'en');
    // Naive ISO is a Dubai wall time: 09:00 displays as 09:00 (T1 fix).
    expect(formatted, '11/5/2026 09:00');
    expect(formatted.contains('T'), isFalse);
    // The same wall clock expressed as a real instant converts identically.
    expect(_expectedInstant(_isoScheduledWithOffset, 'en'), '11/5/2026 09:00');
  });

  test('fixed instant renders in AR locale shape (yMd + Hm)', () {
    final formatted = _expectedInstant(_isoScheduled, 'ar');
    expect(formatted.contains('T'), isFalse);
    expect(formatted, isNot(_expectedInstant(_isoScheduled, 'en')));
    // The Dubai instant (2026-11-05 09:00) must be encoded in either digit
    // set: normalize Arabic-Indic digits to Latin, then check the fields.
    // (Standalone `initializeDateFormatting` yields Latin digits here while
    // the in-app localizations yield Arabic-Indic ones; the widget tests
    // below pin the true in-app shape.)
    final normalized = formatted.replaceAllMapped(
      RegExp('[\u0660-\u0669]'),
      (match) =>
          String.fromCharCode(match.group(0)!.codeUnitAt(0) - 0x0660 + 0x30),
    );
    expect(normalized.contains('2026'), isTrue);
    expect(normalized.contains('09:00'), isTrue);
  });

  test('counts format per locale via NumberFormat.decimalPattern', () {
    // EN is unchanged plain/grouped Latin digits.
    expect(NumberFormat.decimalPattern('en').format(1234), '1,234');
    expect(NumberFormat.decimalPattern('en').format(23), '23');
    // Observed intl 0.20.3 behaviour (verified 2026-11-07): decimalPattern
    // under 'ar' yields Latin digits ('1,234'), NOT Arabic-Indic digits.
    // The product code and these tests use the locale API verbatim instead
    // of inventing digit conversion, so EN and AR stay consistent with the
    // same NumberFormat call the widgets use.
    expect(NumberFormat.decimalPattern('ar').format(1234), '1,234');
    expect(NumberFormat.decimalPattern('ar').format(23), '23');
  });

  testWidgets('jobs details sheet shows formatted date, never raw ISO (EN)', (
    tester,
  ) async {
    await _pump(tester, const Scaffold(body: JobsTab()), const Locale('en'));

    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.textContaining(_isoScheduled), findsNothing);
    // The queue row behind the sheet and the sheet itself both show the
    // formatted instant.
    expect(find.text(_expectedInstant(_isoScheduled, 'en')), findsWidgets);
  });

  testWidgets('jobs details sheet shows formatted date, never raw ISO (AR)', (
    tester,
  ) async {
    await _pump(tester, const Scaffold(body: JobsTab()), const Locale('ar'));

    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.textContaining(_isoScheduled), findsNothing);
    final formatted = pinDigits(_expectedInstant(_isoScheduled, 'ar'));
    expect(find.text(formatted), findsWidgets);
    // The queue pins the digit set: Arabic renders the date with ASCII digits
    // so the timestamp stays contiguous and matches the dashboard.
    expect(RegExp('[\u0660-\u0669]').hasMatch(formatted), isFalse);
    expect(RegExp('[0-9]').hasMatch(formatted), isTrue);
  });

  testWidgets('queue chips render locale counts without raw ISO (EN)', (
    tester,
  ) async {
    await _pump(tester, const Scaffold(body: JobsTab()), const Locale('en'));
    expect(find.text('All (3)'), findsOneWidget);
    expect(find.textContaining(_isoScheduled), findsNothing);
  });

  testWidgets('queue chips render locale counts without raw ISO (AR)', (
    tester,
  ) async {
    await _pump(tester, const Scaffold(body: JobsTab()), const Locale('ar'));
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));
    final arCount = NumberFormat.decimalPattern('ar').format(3);
    expect(find.text('${l10n.filterAll} ($arCount)'), findsOneWidget);
    expect(find.textContaining(_isoScheduled), findsNothing);
  });

  testWidgets('dashboard row meta + total never show raw ISO (EN)', (
    tester,
  ) async {
    await _pump(
      tester,
      const Scaffold(body: DashboardTab()),
      const Locale('en'),
    );
    expect(find.textContaining(_isoScheduled), findsNothing);
    // The row meta renders the locale-shaped instant (yMd + Hm), not the wire
    // string, and never shifts a naive Dubai wall time.
    expect(
      find.textContaining(_expectedInstant(_isoScheduled, 'en')),
      findsWidgets,
    );
    // The hero total uses decimalPattern for the current locale.
    final total = NumberFormat.decimalPattern('en').format(3);
    expect(find.text(total), findsWidgets);

    await tester.tap(find.byKey(const Key('dashboard-job-waiting-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining(_isoScheduled), findsNothing);
  });

  testWidgets('dashboard stats use NumberFormat.decimalPattern(locale) (AR)', (
    tester,
  ) async {
    await _pump(
      tester,
      const Scaffold(body: DashboardTab()),
      const Locale('ar'),
    );

    expect(find.textContaining(_isoScheduled), findsNothing);
    // Same locale API the widgets use; intl 0.20.3 renders 'ar' counts in
    // Latin digits (see counts unit test), so the formatter is the contract.
    final arTotal = NumberFormat.decimalPattern('ar').format(3);
    expect(find.text(arTotal), findsWidgets);
  });

  testWidgets('report page shows formatted finalizedAt, never raw ISO (EN)', (
    tester,
  ) async {
    await _pump(tester, const ReportPage(jobId: 'job-1'), const Locale('en'));

    expect(find.textContaining(_isoFinalized), findsNothing);
    expect(find.text(_expectedInstant(_isoFinalized, 'en')), findsOneWidget);
  });

  testWidgets('report page shows formatted finalizedAt, never raw ISO (AR)', (
    tester,
  ) async {
    await _pump(tester, const ReportPage(jobId: 'job-1'), const Locale('ar'));

    expect(find.textContaining(_isoFinalized), findsNothing);
    final formatted = _expectedInstant(_isoFinalized, 'ar');
    expect(find.text(formatted), findsOneWidget);
    expect(RegExp('[\u0660-\u0669]').hasMatch(formatted), isTrue);
  });
}
