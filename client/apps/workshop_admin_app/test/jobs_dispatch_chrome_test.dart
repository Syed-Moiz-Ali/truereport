import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_chrome.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('page bar keeps the reference LTR and shows the status pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const JobPageBar(reference: 'JOB-2026-0148', status: 'PENDING_REVIEW'),
      ),
    );
    final reference = tester.widget<Text>(find.text('JOB-2026-0148'));
    expect(reference.textDirection, TextDirection.ltr);
    expect(find.text('Pending review'), findsOneWidget);
  });

  testWidgets('identity wraps a long name instead of truncating it', (
    tester,
  ) async {
    const longName = 'Mariam Abdulrahman Al Suwaidi';
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 320,
          child: JobIdentityBlock(
            eyebrow: 'Approve and issue certificate',
            title: longName,
            meta: <String>['Toyota Land Cruiser Prado VXR', 'DXB 78421'],
          ),
        ),
      ),
    );
    final title = tester.widget<Text>(find.text(longName));
    expect(title.maxLines, isNull);
    expect(title.overflow, isNull);
    expect(find.text('APPROVE AND ISSUE CERTIFICATE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('split columns stack below 900 and split above it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const leading = Text('leading');
    const trailing = Text('trailing');
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 899,
          child: JobSplitColumns(leading: leading, trailing: trailing),
        ),
      ),
    );
    expect(find.byType(Expanded), findsNothing);

    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 900,
          child: JobSplitColumns(leading: leading, trailing: trailing),
        ),
      ),
    );
    expect(find.byType(Expanded), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('page bar mirrors the back icon in Arabic', (tester) async {
    await tester.pumpWidget(
      _host(
        const JobPageBar(reference: 'JOB-2026-0148', status: 'APPROVED'),
        locale: const Locale('ar'),
      ),
    );
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('title bar carries back, translated title and a trailing pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const JobTitleBar(
          title: 'Public link',
          trailing: JobStatusPill(status: 'PUBLISHED'),
        ),
      ),
    );
    expect(find.text('Public link'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stage rail wraps below 640 so the current stage stays on screen',
    (tester) async {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 390,
              child: JobStageRail(status: 'IN_PROGRESS'),
            ),
            locale: locale,
          ),
        );
        final rail = find.byType(JobStageRail);
        final l10n = AppLocalizations.of(tester.element(rail));
        expect(
          find.descendant(
            of: rail,
            matching: find.byType(SingleChildScrollView),
          ),
          findsNothing,
          reason: '${locale.languageCode} must wrap, not scroll',
        );
        final current = tester.getRect(
          find.descendant(
            of: rail,
            matching: find.text(jobStatusLabel(l10n, 'IN_PROGRESS')),
          ),
        );
        expect(
          current.left,
          greaterThanOrEqualTo(0),
          reason: locale.languageCode,
        );
        expect(
          current.right,
          lessThanOrEqualTo(390),
          reason: locale.languageCode,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
