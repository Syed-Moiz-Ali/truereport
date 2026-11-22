import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_create.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/models.dart';

import 'support/fake_admin_api.dart';
import 'support/real_fonts.dart';
import 'support/ui_strings_harness.dart';

/// Visual-token pass evidence: job detail and the create wizard at desktop and
/// phone widths, rendered with the bundled real fonts (see
/// `flutter_test_config.dart`) and fixture data.
///
/// Files are written outside the repo so the committed tree stays clean:
/// `${Directory.systemTemp.path}/truereport-visual-pass`.
const List<ReferenceRecord> _jobStatuses = <ReferenceRecord>[
  ReferenceRecord(
    code: 'PENDING_REVIEW',
    labelKey: 'jobsStatusPendingReview',
    tone: 'warning',
  ),
  ReferenceRecord(
    code: 'APPROVED',
    labelKey: 'jobsStatusApproved',
    tone: 'success',
  ),
  ReferenceRecord(
    code: 'PUBLISHED',
    labelKey: 'jobsStatusPublished',
    tone: 'success',
  ),
];

const List<ReferenceRecord> _reviewStatuses = <ReferenceRecord>[
  ReferenceRecord(
    code: 'PENDING_REVIEW',
    labelKey: 'jobsStatusPendingReview',
    tone: 'warning',
  ),
  ReferenceRecord(
    code: 'APPROVED',
    labelKey: 'jobsStatusApproved',
    tone: 'success',
  ),
];

const List<ReferenceRecord> _publicationStatuses = <ReferenceRecord>[
  ReferenceRecord(code: 'NOT_PUBLISHED', labelKey: '', tone: 'neutral'),
  ReferenceRecord(
    code: 'PUBLISHED',
    labelKey: 'jobsStatusPublished',
    tone: 'success',
  ),
];

const List<ReferenceRecord> _consentStatuses = <ReferenceRecord>[
  ReferenceRecord(code: 'GRANTED', labelKey: '', tone: 'success'),
  ReferenceRecord(code: 'NOT_GRANTED', labelKey: '', tone: 'neutral'),
];

const List<ReferenceRecord> _resultEnums = <ReferenceRecord>[
  ReferenceRecord(code: 'PASS', labelKey: '', tone: 'success'),
  ReferenceRecord(code: 'ATTENTION', labelKey: '', tone: 'warning'),
  ReferenceRecord(code: 'FAIL', labelKey: '', tone: 'danger'),
];

List<WorkshopLanguage> _languages() => const <WorkshopLanguage>[
  WorkshopLanguage(
    code: 'en',
    nativeName: 'English',
    direction: 'ltr',
    status: 'LIVE',
    active: true,
  ),
  WorkshopLanguage(
    code: 'ar',
    nativeName: 'العربية',
    direction: 'rtl',
    status: 'LIVE',
    active: true,
  ),
];

class _ManifestSelection extends UiMessageController {
  _ManifestSelection() : super(adminUiMessageClient);

  @override
  UiMessageState build() => const UiMessageState(
    manifest: UiMessageManifest(
      defaultLanguage: 'en',
      namespaceVersions: <String, int>{'common': 1, 'workshop_admin': 1},
      languages: <UiMessageLanguage>[
        UiMessageLanguage(code: 'en', direction: 'ltr', nativeName: 'English'),
        UiMessageLanguage(code: 'ar', direction: 'rtl', nativeName: 'العربية'),
      ],
    ),
    activeLanguage: 'en',
    defaultLanguage: 'en',
    ready: true,
  );

  @override
  Future<void> bootstrap() async {}
}

List<Override> _overrides() => <Override>[
  adminApiProvider.overrideWithValue(FakeAdminApi()),
  languageSelectionProvider(adminUiMessageClient)
      .overrideWith(_ManifestSelection.new),
  workshopLanguagesProvider.overrideWith((ref) async => _languages()),
  statusesProvider('job').overrideWith((ref) async => _jobStatuses),
  statusesProvider('review').overrideWith((ref) async => _reviewStatuses),
  statusesProvider('publication')
      .overrideWith((ref) async => _publicationStatuses),
  statusesProvider('consent').overrideWith((ref) async => _consentStatuses),
  enumsProvider('result').overrideWith((ref) async => _resultEnums),
];

Future<void> _capture(
  WidgetTester tester,
  String name,
  Size size, {
  required Widget Function() screen,
}) async {
  expect(RealFonts.isLoaded, isTrue);
  expect(RealFonts.missingFamilies, isEmpty);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('visual-pass-root');
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) =>
            uiStringsScope(child: child ?? const SizedBox.shrink()),
        home: RepaintBoundary(
          key: rootKey,
          child: MediaQuery(
            data: MediaQueryData(size: size, devicePixelRatio: 1),
            child: SizedBox.fromSize(size: size, child: screen()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull, reason: '$name rendered cleanly');

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(rootKey),
  );
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (data == null) {
    throw StateError('PNG encoding returned no data for $name');
  }
  final directory = Directory(
    '${Directory.systemTemp.path}/truereport-visual-pass',
  )..createSync(recursive: true);
  final file = File('${directory.path}/$name.png')
    ..writeAsBytesSync(data.buffer.asUint8List(), flush: true);
  // ignore: avoid_print
  print('VISUAL_PASS_SCREENSHOT ${file.absolute.path}');
}

void main() {
  testWidgets('workshop job detail at 1280', (tester) async {
    await _capture(
      tester,
      'workshop_job_detail_1280',
      const Size(1280, 1200),
      screen: () => const JobDetailPage(jobId: 'job-1'),
    );
  });

  testWidgets('workshop job detail at 390', (tester) async {
    await _capture(
      tester,
      'workshop_job_detail_390',
      const Size(390, 1900),
      screen: () => const JobDetailPage(jobId: 'job-1'),
    );
  });

  testWidgets('workshop create wizard at 1280', (tester) async {
    await _capture(
      tester,
      'workshop_create_wizard_1280',
      const Size(1280, 900),
      screen: () => const DispatchCreateJob(),
    );
  });

  testWidgets('workshop create wizard at 390', (tester) async {
    await _capture(
      tester,
      'workshop_create_wizard_390',
      const Size(390, 844),
      screen: () => const DispatchCreateJob(),
    );
  });
}
