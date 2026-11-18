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

const _arabicSession = Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: User(
    id: 'user-1',
    email: 'layla@test.local',
    displayName: 'ليلى حداد',
    platformAdmin: false,
    totpEnabled: false,
  ),
  memberships: [
    Membership(
      workshopId: 'workshop-1',
      workshopName: 'ورشة المارينا',
      role: Role.workshopAdmin,
    ),
  ],
);

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

Iterable<String> _dashboardTexts(WidgetTester tester) => find
    .descendant(of: find.byType(DashboardTab), matching: find.byType(Text))
    .evaluate()
    .map((element) => (element.widget as Text).data ?? '')
    .where((text) => text.trim().isNotEmpty);

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

  testWidgets('Arabic dashboard renders no English words', (tester) async {
    await _pump(tester, locale: const Locale('ar'), session: _arabicSession);

    final texts = _dashboardTexts(tester).toList();
    expect(texts, isNotEmpty);

    // No ASCII letters anywhere on the dashboard: copy, labels and the eyebrow
    // are all Arabic (digits are numbers, not English).
    final latin = texts
        .where((text) => RegExp('[A-Za-z]').hasMatch(text))
        .toList(growable: false);
    expect(latin, isEmpty, reason: 'English left on the AR dashboard: $latin');

    // The page itself no longer names the workshop (the shell's identity strip
    // does), so the only copy on this surface is the empty state.
    final l10n = AppLocalizations.of(tester.element(find.byType(DashboardTab)));
    expect(texts, contains(l10n.dashFloorEmpty));
    expect(l10n.dashFloorEmpty, isNot('No jobs on the floor'));
  });

  testWidgets('Arabic dashboard uses localized section copy', (tester) async {
    await _pump(tester, locale: const Locale('ar'), session: _arabicSession);
    final l10n = AppLocalizations.of(tester.element(find.byType(DashboardTab)));

    for (final label in [l10n.dashFloorEmpty, l10n.newJob]) {
      expect(find.text(label), findsWidgets, reason: 'missing copy $label');
    }
    // The AR labels are genuinely Arabic, not the English string reused.
    for (final pair in <(String, String)>[
      (l10n.dashGroupWaiting, 'Waiting for you'),
      (l10n.dashGroupInBay, 'In the bay'),
      (l10n.dashGroupReady, 'Ready to publish'),
      (l10n.dashNothingWaiting, 'Nothing is waiting for your decision'),
    ]) {
      expect(pair.$1, isNot(pair.$2));
      expect(RegExp('[A-Za-z]').hasMatch(pair.$1), isFalse, reason: pair.$1);
    }
  });
}
