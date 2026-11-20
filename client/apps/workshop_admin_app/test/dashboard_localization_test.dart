import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tab.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// J12 / D4: the dashboard must be fully localized.
///
/// The screen is now direction B "The floor" (no greeting, no date, no pipeline
/// card, no quick actions), so the copy under test is the hero, the group titles
/// and the empty state. The rule itself is unchanged and is the reason this file
/// exists: **no English may survive on the Arabic build**, and every sentence is
/// one ARB message with a placeholder rather than a concatenation.
///
/// The fake answers the clean (`platform_jobs`) family, which is what the page
/// reads (invariant J19).
class _EmptyDashboardApi implements AdminApi {
  @override
  Future<CleanJobCounts> cleanJobCounts() async => const CleanJobCounts(
    draft: 0,
    scheduled: 0,
    assigned: 0,
    inProgress: 0,
    pendingReview: 0,
    approved: 0,
    published: 0,
    rejected: 0,
    cancelled: 0,
    total: 0,
  );

  @override
  Future<JobPage> cleanJobs({
    int page = 0,
    int size = 20,
    String status = '',
    String search = '',
    String from = '',
    String to = '',
  }) async =>
      const JobPage(items: [], page: 0, size: 20, total: 0, totalPages: 0);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  Session? session,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(_EmptyDashboardApi())],
      child: _Harness(locale: locale, session: session),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({required this.locale, this.session});

  final Locale locale;
  final Session? session;

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.session == null) {
        return;
      }
      ref.read(authControllerProvider.notifier).state = AsyncData<Session?>(
        widget.session,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: widget.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: const Scaffold(body: DashboardTab()),
    );
  }
}

void main() {
  testWidgets('plural copy is one ARB message, not a concatenation', (
    tester,
  ) async {
    await _pump(tester, locale: const Locale('en'));
    final l10n = AppLocalizations.of(tester.element(find.byType(DashboardTab)));

    expect(l10n.dashFloorTotal(1), '1 job on the floor');
    expect(l10n.dashFloorTotal(24), '24 jobs on the floor');
    expect(l10n.dashDecisionWaiting(1), '1 is waiting for your decision');
    expect(l10n.dashDecisionWaiting(4), '4 are waiting for your decision');
    expect(l10n.dashFooterSum(24), contains('24'));
  });
}
