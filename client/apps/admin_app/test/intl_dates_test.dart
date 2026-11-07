import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/job_counts.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/dashboard_tab.dart';
import 'package:admin_app/src/pages/jobs_tab.dart';
import 'package:admin_app/src/pages/report_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

// F3-B Step 0 (Q3): raw ISO `scheduledAt`/`finalizedAt` strings must never
// reach users. Display uses the Asia/Dubai (UTC+4) wall-clock instant —
// offset-less ISO is treated as UTC, mirroring the technician app's
// `scheduledTimeUtc4` instant interpretation — formatted with
// `DateFormat.yMd(locale).add_Hm()`, and counts with
// `NumberFormat.decimalPattern(locale)`.
const _isoScheduled = '2026-11-05T09:00:00';
const _isoFinalized = '2026-11-04T10:30:00';

// Offset-less ISO is UTC: 09:00 UTC -> 13:00 Dubai; 10:30 UTC -> 14:30 Dubai.
String _expectedInstant(String iso, String localeName) {
  final parsed = DateTime.tryParse(iso)!;
  final dubai = DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
  ).add(const Duration(hours: 4));
  return DateFormat.yMd(localeName).add_Hm().format(dubai);
}

const _job = WorkshopJob(
  id: 'job-1',
  reference: 'JOB-0001',
  status: 'SCHEDULED',
  templateVersionId: 'version-1',
  templateName: 'Full inspection',
  templateVersionNo: 1,
  assignedTechnicianId: null,
  assignedTechnicianName: null,
  scheduledAt: _isoScheduled,
  customerName: 'Customer A',
  customerPhone: '+971500000001',
  customerEmail: 'customer.a@test.local',
  vehicleMake: 'Toyota',
  vehicleModel: 'Camry',
  vehicleYear: 2022,
  vehicleVin: 'TESTVIN00000000001',
  vehiclePlate: 'A12345',
  scope: 'Full inspection',
);

const _counts = JobCounts(
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

class _IntlFakeApi implements AdminApi {
  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async {
    const all = [_job];
    final query = search.trim().toLowerCase();
    return all.where((job) {
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
    }).toList();
  }

  @override
  Future<JobCounts> jobCounts() async => _counts;

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
    // Offset-less ISO treated as UTC, displayed as Dubai wall-clock.
    expect(formatted, '11/5/2026 13:00');
    expect(formatted.contains('T'), isFalse);
  });

  test('fixed instant renders in AR locale shape (yMd + Hm)', () {
    final formatted = _expectedInstant(_isoScheduled, 'ar');
    expect(formatted.contains('T'), isFalse);
    expect(formatted, isNot(_expectedInstant(_isoScheduled, 'en')));
    // The Dubai instant (2026-11-05 13:00) must be encoded in either digit
    // set: normalize Arabic-Indic digits to Latin, then check the fields.
    // (Standalone `initializeDateFormatting` yields Latin digits here while
    // the in-app localizations yield Arabic-Indic ones; the widget tests
    // below pin the true in-app shape.)
    final normalized = formatted.replaceAllMapped(
      RegExp('[\u0660-\u0669]'),
      (match) => String.fromCharCode(
        match.group(0)!.codeUnitAt(0) - 0x0660 + 0x30,
      ),
    );
    expect(normalized.contains('2026'), isTrue);
    expect(normalized.contains('13:00'), isTrue);
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

  testWidgets('jobs details sheet shows formatted date, never raw ISO (EN)',
      (tester) async {
    await _pump(tester, const Scaffold(body: JobsTab()), const Locale('en'));

    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.textContaining(_isoScheduled), findsNothing);
    expect(
      find.text(_expectedInstant(_isoScheduled, 'en')),
      findsOneWidget,
    );
  });

  testWidgets('jobs details sheet shows formatted date, never raw ISO (AR)',
      (tester) async {
    await _pump(tester, const Scaffold(body: JobsTab()), const Locale('ar'));

    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.textContaining(_isoScheduled), findsNothing);
    final formatted = _expectedInstant(_isoScheduled, 'ar');
    expect(find.text(formatted), findsOneWidget);
    // In-app (MaterialApp localizations) context renders AR dates with
    // Arabic-Indic digits: ٥‏/١١‏/٢٠٢٦ ١٣:٠٠.
    expect(RegExp('[\u0660-\u0669]').hasMatch(formatted), isTrue);
  });

  testWidgets('queue chips render locale counts without raw ISO (EN)',
      (tester) async {
    await _pump(tester, const Scaffold(body: JobsTab()), const Locale('en'));
    expect(find.text('All (1)'), findsOneWidget);
    expect(find.textContaining(_isoScheduled), findsNothing);
  });

  testWidgets('queue chips render locale counts without raw ISO (AR)',
      (tester) async {
    await _pump(tester, const Scaffold(body: JobsTab()), const Locale('ar'));
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));
    final arCount = NumberFormat.decimalPattern('ar').format(1);
    expect(find.text('${l10n.filterAll} ($arCount)'), findsOneWidget);
    expect(find.textContaining(_isoScheduled), findsNothing);
  });

  testWidgets('dashboard card meta + stats never show raw ISO (EN)',
      (tester) async {
    await _pump(
      tester,
      const Scaffold(body: DashboardTab()),
      const Locale('en'),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(DashboardTab)),
    );

    expect(find.textContaining(_isoScheduled), findsNothing);
    expect(
      find.text(
        '${l10n.scheduledAt}: ${_expectedInstant(_isoScheduled, 'en')}',
      ),
      findsOneWidget,
    );
    // Stat values use decimalPattern: EN unchanged.
    expect(find.text('23'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboard-job-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining(_isoScheduled), findsNothing);
    expect(
      find.text(_expectedInstant(_isoScheduled, 'en')),
      findsOneWidget,
    );
  });

  testWidgets('dashboard stats use NumberFormat.decimalPattern(locale) (AR)',
      (tester) async {
    await _pump(
      tester,
      const Scaffold(body: DashboardTab()),
      const Locale('ar'),
    );

    expect(find.textContaining(_isoScheduled), findsNothing);
    // Same locale API the widgets use; intl 0.20.3 renders 'ar' counts in
    // Latin digits (see counts unit test), so the EN/AR stat strings match.
    final arActive = NumberFormat.decimalPattern('ar').format(23);
    expect(find.text(arActive), findsOneWidget);
  });

  testWidgets('report page shows formatted finalizedAt, never raw ISO (EN)',
      (tester) async {
    await _pump(
      tester,
      const ReportPage(jobId: 'job-1'),
      const Locale('en'),
    );

    expect(find.textContaining(_isoFinalized), findsNothing);
    expect(
      find.text(_expectedInstant(_isoFinalized, 'en')),
      findsOneWidget,
    );
  });

  testWidgets('report page shows formatted finalizedAt, never raw ISO (AR)',
      (tester) async {
    await _pump(
      tester,
      const ReportPage(jobId: 'job-1'),
      const Locale('ar'),
    );

    expect(find.textContaining(_isoFinalized), findsNothing);
    final formatted = _expectedInstant(_isoFinalized, 'ar');
    expect(find.text(formatted), findsOneWidget);
    expect(RegExp('[\u0660-\u0669]').hasMatch(formatted), isTrue);
  });
}
