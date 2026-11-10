import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/inspection/assessment_page.dart';
import 'package:technician_app/src/features/inspection/checklist_page.dart';
import 'package:technician_app/src/features/review/finalized_page.dart';
import 'package:technician_app/src/features/jobs/job_detail_page.dart';
import 'package:technician_app/src/features/review/review_page.dart';
import 'package:technician_app/src/features/jobs/technician_jobs_page.dart';
import 'package:technician_app/src/features/jobs/walk_in_job_page.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'support/fake_technician_api.dart';
import 'support/test_offline_store.dart';

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.home,
    required this.locale,
    required this.brightness,
    this.textScale = 1,
  });

  final Widget home;
  final Locale locale;
  final Brightness brightness;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    );
  }
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required Locale locale,
  required Brightness brightness,
  required Size size,
  double textScale = 1,
}) async {
  _setSize(tester, size);
  final store = createTestOfflineStore();
  addTearDown(store.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        technicianApiProvider.overrideWithValue(FakeTechnicianApi()),
        offlineStoreProvider.overrideWithValue(store),
      ],
      child: _TestApp(
        home: screen,
        locale: locale,
        brightness: brightness,
        textScale: textScale,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final screens = <String, Widget>{
    'jobs': const TechnicianJobsPage(),
    'job detail': const JobDetailPage(jobId: 'job-1'),
    'checklist': const ChecklistPage(jobId: 'job-1'),
    'assessment': const AssessmentPage(
      jobId: 'job-1',
      itemId: 'inspection-item-1',
    ),
    'review': const ReviewPage(jobId: 'job-1'),
    'finalized': const FinalizedPage(jobId: 'job-1'),
    'walk-in': const WalkInJobPage(),
  };
  const phone = Size(390, 844);
  const tablet = Size(1024, 900);

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders EN/AR light/dark phone/tablet', (
      tester,
    ) async {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        for (final brightness in Brightness.values) {
          for (final size in const [phone, tablet]) {
            await _pump(
              tester,
              entry.value,
              locale: locale,
              brightness: brightness,
              size: size,
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('${entry.key} renders at 2.0 text scale', (tester) async {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        for (final size in const [phone, tablet]) {
          await _pump(
            tester,
            entry.value,
            locale: locale,
            brightness: Brightness.light,
            size: size,
            textScale: 2,
          );
          expect(tester.takeException(), isNull);
        }
      }
    });
  }
}
