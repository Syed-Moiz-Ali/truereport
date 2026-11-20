import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_style.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_atlas.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_rows.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_states.dart';

import 'support/real_fonts.dart';

/// Phase 5 gallery proof for the dashboard primitives.
///
/// Every primitive this screen needs, in every state it can take, LTR and RTL,
/// light only (waiver W-LIGHT). Real fonts via `flutter_test_config.dart`.
const String _outDir = 'docs/evidence/gallery';

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    expect(boundary, isNotNull, reason: 'no boundary for $name');
    final image = await boundary!.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull);
    final dir = Directory(_outDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('${dir.path}/dashboard_$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  Size size,
  GlobalKey key, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: RepaintBoundary(
        key: key,
        child: Material(
          color: AppTheme.light.scaffoldBackgroundColor,
          child: Directionality(
            textDirection: direction,
            child: SizedBox.fromSize(
              size: size,
              child: MediaQuery(
                data: MediaQueryData(size: size),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<AtlasSegment> _segments(
  BuildContext context, {
  int? Function(String status)? count,
}) {
  final ws = context.ws;
  const labels = <String, String>{
    'DRAFT': 'Draft',
    'SCHEDULED': 'Scheduled',
    'ASSIGNED': 'Assigned',
    'IN_PROGRESS': 'In progress',
    'PENDING_REVIEW': 'Pending review',
    'APPROVED': 'Approved',
    'PUBLISHED': 'Published',
    'REJECTED': 'Rejected',
    'CANCELLED': 'Cancelled',
    '__other__': 'Other',
  };
  const counts = <String, int>{
    'DRAFT': 1,
    'SCHEDULED': 4,
    'ASSIGNED': 3,
    'IN_PROGRESS': 5,
    'PENDING_REVIEW': 4,
    'APPROVED': 2,
    'PUBLISHED': 3,
    'REJECTED': 1,
    'CANCELLED': 1,
  };
  return [
    for (final status in dashboardStatusOrder)
      AtlasSegment(
        status: status,
        label: labels[status]!,
        count: count?.call(status) ?? counts[status]!,
        color: dashboardStatusTint(WorkshopStatusTone.accent, ws),
      ),
    if (count != null)
      AtlasSegment(
        status: '__other__',
        label: labels['__other__']!,
        count: count('__other__') ?? 0,
        color: dashboardStatusTint(WorkshopStatusTone.neutral, ws),
        isRemainder: true,
      ),
  ];
}

Widget _page(BuildContext context, Widget child) {
  final ws = context.ws;
  return Container(
    color: ws.canvas,
    padding: const EdgeInsets.all(24),
    child: child,
  );
}

void main() {
  test('real fonts are loaded for the gallery', () {
    expect(RealFonts.isLoaded, isTrue);
    expect(RealFonts.missingFamilies, isEmpty);
  });

  testWidgets('atlas horizontal + legend', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Builder(
        builder: (context) => _page(
          context,
          Align(
            alignment: Alignment.topLeft,
            child: DashboardAtlas(
              segments: _segments(context),
              total: 24,
              height: 64,
              semanticLabel: 'Jobs by status',
            ),
          ),
        ),
      ),
      const Size(1240, 260),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'atlas_ltr');
  });

  testWidgets('atlas with an unaccounted remainder', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Builder(
        builder: (context) => _page(
          context,
          Align(
            alignment: Alignment.topLeft,
            child: DashboardAtlas(
              segments: _segments(
                context,
                count: (s) => s == '__other__' ? 2 : null,
              ),
              total: 26,
              height: 48,
              semanticLabel: 'Jobs by status, 2 unaccounted',
            ),
          ),
        ),
      ),
      const Size(1240, 220),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'atlas_remainder');
  });

  testWidgets('atlas spine (phone)', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Builder(
        builder: (context) => _page(
          context,
          Align(
            alignment: Alignment.topLeft,
            child: DashboardAtlas(
              segments: _segments(context),
              total: 24,
              height: 0,
            ),
          ),
        ),
      ),
      const Size(390, 520),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'atlas_spine');
  });

  testWidgets('atlas RTL', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Builder(
        builder: (context) => _page(
          context,
          Align(
            alignment: Alignment.topLeft,
            child: DashboardAtlas(
              segments: _segments(context),
              total: 24,
              height: 64,
              semanticLabel: 'المهمات حسب الحالة',
            ),
          ),
        ),
      ),
      const Size(1240, 260),
      key,
      direction: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'atlas_rtl');
  });

  testWidgets('group header + rows', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Builder(
        builder: (context) => _page(
          context,
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DashboardGroupHeader(
                    swatch: context.ws.warning,
                    title: 'Waiting for you',
                    meta: '4 pending review',
                  ),
                  const SizedBox(height: 4),
                  DashboardJobRow(
                    title: 'Nissan Patrol',
                    meta: 'JOB-10482 · Ahmed Al Mansoori · Rashid K.',
                    statusLabel: 'Pending review',
                    statusTone: WorkshopStatusTone.warning,
                    verbLabel: 'Review',
                    onVerb: () {},
                    onTap: () {},
                  ),
                  DashboardJobRow(
                    title: 'Toyota Land Cruiser',
                    meta: 'JOB-10479 · Sara Khalifa · Mohan D.',
                    statusLabel: 'Pending review',
                    statusTone: WorkshopStatusTone.warning,
                    verbLabel: 'Review',
                    onVerb: () {},
                    onTap: () {},
                  ),
                  DashboardJobRow(
                    title: 'Lexus LX 600',
                    meta: 'JOB-10477 · Omar Haddad · Rashid K.',
                    statusLabel: 'Pending review',
                    statusTone: WorkshopStatusTone.warning,
                    verbLabel: 'Review',
                    onVerb: () {},
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const Size(720, 320),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'group_ltr');
  });

  testWidgets('group empty + phone rows', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Builder(
        builder: (context) => _page(
          context,
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 358,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DashboardGroupHeader(
                    swatch: context.ws.accent,
                    title: 'In the bay',
                    meta: '0 in progress',
                  ),
                  const DashboardGroupEmpty(text: 'Nothing here right now'),
                  const SizedBox(height: 12),
                  DashboardGroupHeader(
                    swatch: context.ws.success,
                    title: 'Ready to publish',
                    meta: '2 approved',
                  ),
                  DashboardJobRow(
                    title: 'Porsche Macan',
                    meta: 'JOB-10465 · Hessa Al Suwaidi',
                    statusLabel: 'Approved',
                    statusTone: WorkshopStatusTone.success,
                    verbLabel: 'Publish',
                    verbInline: false,
                    onVerb: () {},
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const Size(390, 340),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'group_phone');
  });

  testWidgets('rows RTL', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Builder(
        builder: (context) => _page(
          context,
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DashboardGroupHeader(
                    swatch: context.ws.warning,
                    title: 'بانتظارك',
                    meta: '4 بانتظار المراجعة',
                  ),
                  const SizedBox(height: 4),
                  DashboardJobRow(
                    title: 'نيسان باترول',
                    meta: 'JOB-10482 · أحمد المنصوري',
                    statusLabel: 'بانتظار المراجعة',
                    statusTone: WorkshopStatusTone.warning,
                    verbLabel: 'مراجعة',
                    onVerb: () {},
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const Size(720, 200),
      key,
      direction: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'group_rtl');
  });

  testWidgets('loading composition', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Builder(
        builder: (context) => _page(
          context,
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DashboardHeroSkeleton(totalHeight: 76),
                  SizedBox(height: 28),
                  DashboardAtlasSkeleton(height: 64),
                  SizedBox(height: 28),
                  DashboardRowsSkeleton(rows: 2),
                ],
              ),
            ),
          ),
        ),
      ),
      const Size(960, 420),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'loading');
  });

  testWidgets('error line', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Builder(
        builder: (context) => _page(
          context,
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 420,
              child: DashboardErrorLine(
                message: 'Could not load. Try again.',
                retryLabel: 'Retry',
                onRetry: () {},
              ),
            ),
          ),
        ),
      ),
      const Size(480, 120),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'error_line');
  });

  testWidgets('hero numeral', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Builder(
        builder: (context) {
          final scale = DashboardScale.byWidth(1200);
          final ws = context.ws;
          return _page(
            context,
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('24', style: scale.totalStyle(context)),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('jobs on the floor', style: ws.sectionTitle),
                      const SizedBox(height: 2),
                      Text(
                        '4 are waiting for your decision',
                        style: ws.meta.copyWith(
                          color: ws.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      const Size(560, 190),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'hero');
  });
}
