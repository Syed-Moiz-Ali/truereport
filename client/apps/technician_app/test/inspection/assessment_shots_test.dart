/// Real-font screenshot evidence for the item screen (round 1).
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:drift/native.dart';
import 'package:technician_app/src/features/inspection/assessment/mark_prompt.dart';
import 'package:technician_app/src/features/inspection/assessment_screen.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_database.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/offline/offline_store.dart';
import 'package:technician_app/src/technician_providers.dart';

import '../support/fixtures.dart' as fixtures;

const Map<String, String> _bundle = <String, String>{
  'technicianResult': 'Result',
  'details': 'Details',
  'notChecked': 'Not checked',
  'technicianSuggestedResult': 'Suggested result',
  'technicianScore': 'Score',
  'technicianEvidence': 'Evidence',
  'technicianSessionNoPhoto': 'No photo yet',
  'technicianPhoto': 'Photo',
  'technicianVideo': 'Video',
  'technicianDocument': 'Document',
  'technicianEvidenceCancel': 'Cancel upload',
  'technicianRetryUpload': 'Retry upload',
  'technicianEvidenceQueued': 'Saved on this phone.',
  'technicianEvidenceStateCapturing': 'Capturing…',
  'technicianEvidenceStateUploading': 'Uploading {type}…',
  'technicianEvidenceFailed': 'Evidence upload failed.',
  'technicianSessionMarkPrompt': 'Mark this photo?',
  'technicianMarkDamage': 'Mark damage',
  'technicianSessionUseAsIs': 'Use as is',
  'technicianSessionItemOf': 'Item {number} of {total}',
  'technicianNotes': 'Notes',
  'technicianNotesCount': '{done} of {required} characters',
  'technicianCaptionsEn': 'Caption (English)',
  'technicianCaptionsAr': 'Caption (Arabic)',
  'technicianSaveAndNext': 'Save & next',
  'technicianSaveAndFinish': 'Save & finish',
  'technicianSafetyCritical': 'Safety critical',
  'commonActionFailed': 'Action failed. Try again.',
  'technicianIssueFieldRequired': 'This field is required.',
  'commonBack': 'Back',
  'addPhoto': 'Add photo',
  'addVideo': 'Add video',
};

ChecklistItem _item({List<EvidenceRule>? evidenceRules}) {
  final seed = fixtures.inspectionItems().firstWhere(
    (value) => value.itemCode == 'brake_pads_front',
  );
  return ChecklistItem(
    itemCode: seed.itemCode,
    itemVersionId: seed.itemVersionId,
    categoryCode: seed.categoryCode,
    sortOrder: seed.sortOrder,
    labelEn: seed.labelEn,
    labelAr: seed.labelAr,
    instructionEn: seed.instructionEn,
    instructionAr: seed.instructionAr,
    standardSpecEn: seed.standardSpecEn,
    standardSpecAr: seed.standardSpecAr,
    measurementUnit: seed.measurementUnit,
    sensorTool: seed.sensorTool,
    safetyCritical: seed.safetyCritical,
    multiPoint: seed.multiPoint,
    multiPointIndexes: seed.multiPointIndexes,
    allowFreeTextNote: seed.allowFreeTextNote,
    noteRequirement: seed.noteRequirement,
    resultOptions: const [
      'NO_ISSUE_OBSERVED',
      'ATTENTION_RECOMMENDED',
      'DEFECT_FOUND',
    ],
    scoreBands: seed.scoreBands,
    evidenceRules: evidenceRules ?? seed.evidenceRules,
    issueFields: seed.issueFields,
    measurementBands: seed.measurementBands,
    assessment: null,
  );
}

Checklist _checklist({ChecklistItem? item, String status = 'SCHEDULED'}) {
  final base = fixtures.checklist(job: fixtures.jobSummary(status: status));
  final one = item ?? _item();
  return Checklist(
    job: base.job,
    pinned: base.pinned,
    categories: base.categories,
    items: [one],
    progress: const ChecklistProgress(completed: 0, total: 30),
    serverRevision: base.serverRevision,
  );
}

Evidence _evidence({required String type, String id = 'ev-1'}) => Evidence(
  id: id,
  jobId: 'job-1001',
  itemCode: 'brake_pads_front',
  type: type,
  status: 'RECEIVED',
  mime: type == 'PHOTO' ? 'image/jpeg' : 'video/mp4',
  bytes: 42,
  sha256: 'sha-$id',
  capturedAt: '2026-03-12T09:31:00',
  captureSource: 'CAMERA',
  deviceId: 'test-device',
  width: 100,
  height: 100,
  durationMs: null,
  captionEn: null,
  captionAr: null,
  posterAvailable: false,
  qualityStatus: null,
  contentUrl: null,
  createdAt: '2026-03-12T09:31:00',
);

/// Offline store that never touches the database in tests.
class _FakeOfflineStore extends OfflineStore {
  _FakeOfflineStore() : super(OfflineDatabase(NativeDatabase.memory()));

  @override
  Future<List<LocalEvidence>> evidenceForItem(
    String jobId,
    String itemId,
  ) async => [];
}

Future<void> _shot(
  WidgetTester tester,
  String name,
  Checklist checklist, {
  required double width,
  required double height,
  Locale locale = const Locale('en'),
  TextScaler scaler = TextScaler.noScaling,
  List<Evidence> evidence = const [],
  Future<void> Function(WidgetTester)? interact,
}) async {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final offline = _FakeOfflineStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        technicianChecklistProvider('job-1001')
            .overrideWith((ref) async => checklist),
        technicianEvidenceListProvider((
          jobId: 'job-1001',
          itemCode: 'brake_pads_front',
        )).overrideWith((ref) async => evidence),
        enumsProvider('result')
            .overrideWith((ref) async => <ReferenceRecord>[]),
        enumsProvider('evidence-type')
            .overrideWith((ref) async => <ReferenceRecord>[]),
        connectivityProvider.overrideWith((ref) => const Stream<bool>.empty()),
        offlineStoreProvider.overrideWith((ref) => offline),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: scaler, disableAnimations: true),
              child: Directionality(
                textDirection: locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Scaffold(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerLow,
                  body: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: SizedBox(
                        width: width > 900 ? 900 : width,
                        height: height,
                        child: const TechnicianItemPage(
                          jobId: 'job-1001',
                          itemCode: 'brake_pads_front',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (interact != null) {
    await interact(tester);
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  testWidgets('item_390_data', (tester) async {
    await _shot(tester, 'item_390_data', _checklist(), width: 390, height: 844);
  });

  testWidgets('item_768_data', (tester) async {
    await _shot(
      tester,
      'item_768_data',
      _checklist(),
      width: 768,
      height: 1024,
    );
  });

  testWidgets('item_1024_data', (tester) async {
    await _shot(
      tester,
      'item_1024_data',
      _checklist(),
      width: 1024,
      height: 768,
    );
  });

  testWidgets('item_390_rtl', (tester) async {
    await _shot(
      tester,
      'item_390_rtl',
      _checklist(),
      width: 390,
      height: 844,
      locale: const Locale('ar'),
    );
  });

  testWidgets('item_390_mark_prompt', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppTheme.light.colorScheme.surfaceContainerLow,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MarkPrompt(
                  photoBytes: null,
                  defect: true,
                  onMark: () {},
                  onDismiss: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/item_390_mark_prompt.png'),
    );
  });

  testWidgets('item_390_partially_captured', (tester) async {
    await _shot(
      tester,
      'item_390_partially_captured',
      _checklist(),
      width: 390,
      height: 844,
      evidence: [_evidence(type: 'PHOTO')],
    );
  });

  testWidgets('item_390_ready', (tester) async {
    await _shot(
      tester,
      'item_390_ready',
      _checklist(),
      width: 390,
      height: 844,
      evidence: [_evidence(type: 'PHOTO')],
      interact: (tester) async {
        await tester.tap(find.text('No Issue Observed'));
      },
    );
  });

  testWidgets('item_390_error', (tester) async {
    await _shot(
      tester,
      'item_390_error',
      _checklist(),
      width: 390,
      height: 844,
      interact: (tester) async {
        await tester.tap(find.text('Save & finish'));
      },
    );
  });

  testWidgets('item_390_read_only', (tester) async {
    await _shot(
      tester,
      'item_390_read_only',
      _checklist(status: 'PENDING_REVIEW'),
      width: 390,
      height: 844,
    );
  });

  testWidgets('item_390_15x', (tester) async {
    await _shot(
      tester,
      'item_390_15x',
      _checklist(),
      width: 390,
      height: 844,
      scaler: const TextScaler.linear(1.5),
    );
  });
}
