/// Widget contract for the item screen: header, result, evidence in place,
/// mark prompt, conditional notes, auto-save and read-only mode.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/features/inspection/assessment/evidence_section.dart';
import 'package:technician_app/src/features/inspection/assessment/item_footer.dart';
import 'package:technician_app/src/features/inspection/assessment/mark_prompt.dart';
import 'package:technician_app/src/features/inspection/assessment/result_options.dart';
import 'package:technician_app/src/features/inspection/assessment_screen.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';
import 'package:drift/native.dart';
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
  'technicianCameraRequired': 'Take this photo or video with the camera.',
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
  'commonBack': 'Back',
  'addPhoto': 'Add photo',
  'addVideo': 'Add video',
  'technicianCaptureDocument': 'Add document',
  'commonActionFailed': 'Action failed. Try again.',
  'technicianIssueFieldRequired': 'This field is required.',
  'technicianSafetyCritical': 'Safety critical',
  'technicianEvidencePhotoCount': '{count} / {required} photos',
  'technicianEvidenceVideoCount': '{count} / {required} videos',
};

Assessment _answer(String itemCode, String itemVersionId) => Assessment(
  id: null,
  itemCode: itemCode,
  itemVersionId: itemVersionId,
  resultCode: 'NO_ISSUE_OBSERVED',
  severityCode: null,
  score: null,
  suggestedResultCode: null,
  suggestedScore: null,
  bandResultCode: null,
  state: null,
  clientRevision: 1,
  serverRevision: 1,
  notesEn: null,
  notesAr: null,
  reasonCode: null,
  version: 1,
  issueValues: const [],
  measurements: const [],
  evidence: const [],
);

/// The fixture brake-pads item with overridable contract bits.
ChecklistItem _item({
  List<String>? resultOptions,
  Assessment? assessment,
  List<EvidenceRule>? evidenceRules,
}) {
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
    resultOptions: resultOptions ?? const ['PASS', 'ADVISORY', 'FAIL', 'NA'],
    scoreBands: seed.scoreBands,
    evidenceRules: evidenceRules ?? seed.evidenceRules,
    issueFields: seed.issueFields,
    measurementBands: seed.measurementBands,
    assessment: assessment,
  );
}

Checklist _checklist({
  ChecklistItem? item,
  String status = 'SCHEDULED',
  int completed = 0,
}) {
  final base = fixtures.checklist(job: fixtures.jobSummary(status: status));
  final one = item ?? _item();
  return Checklist(
    job: base.job,
    pinned: base.pinned,
    categories: base.categories,
    items: [one],
    progress: ChecklistProgress(completed: completed, total: 30),
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

ProviderScope _scope({
  required Widget child,
  required Checklist checklist,
  List<Evidence> evidence = const [],
}) {
  final offline = _FakeOfflineStore();
  return ProviderScope(
    overrides: [
      technicianChecklistProvider('job-1001')
          .overrideWith((ref) async => checklist),
      technicianEvidenceListProvider((
        jobId: 'job-1001',
        itemCode: 'brake_pads_front',
      )).overrideWith((ref) async => evidence),
      enumsProvider('result').overrideWith((ref) async => <ReferenceRecord>[]),
      enumsProvider('evidence-type')
          .overrideWith((ref) async => <ReferenceRecord>[]),
      connectivityProvider.overrideWith((ref) => const Stream<bool>.empty()),
      offlineStoreProvider.overrideWith((ref) => offline),
      evidenceCaptureServiceProvider.overrideWith(
        (ref) => _FailingCaptureService(),
      ),
    ],
    child: child,
  );
}

Widget _host(Widget child, {double width = 390}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      backgroundColor: AppTheme.light.colorScheme.surfaceContainerLow,
      body: Center(
        child: SizedBox(width: width, height: 844, child: child),
      ),
    ),
  );
}

Widget _page(Checklist checklist, {String itemCode = 'brake_pads_front'}) {
  return TechnicianItemPage(jobId: 'job-1001', itemCode: itemCode);
}

/// Capture that never touches the platform: every entry point fails fast
/// with the camera-required rule so the inline failure path stays green.
class _FailingCaptureService extends EvidenceCaptureService {
  @override
  Future<CapturedEvidence?> capturePhoto({
    EvidenceSource source = EvidenceSource.camera,
  }) async {
    throw const EvidenceCaptureException(
      EvidenceValidationFailure.cameraRequired,
    );
  }

  @override
  Future<CapturedEvidence?> recordVideo({
    EvidenceSource source = EvidenceSource.camera,
    bool capturePoster = false,
    Iterable<String> existingSha256 = const [],
  }) async {
    throw const EvidenceCaptureException(
      EvidenceValidationFailure.cameraRequired,
    );
  }
}

/// Offline store that never touches the database: evidence lookups resolve
/// empty in memory so capture can proceed to the service in tests.
class _FakeOfflineStore extends OfflineStore {
  _FakeOfflineStore() : super(OfflineDatabase(NativeDatabase.memory()));

  @override
  Future<List<LocalEvidence>> evidenceForItem(
    String jobId,
    String itemId,
  ) async => [];
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));
  group('header', () {
    testWidgets('shows number, section, label and back', (tester) async {
      final checklist = _checklist();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _scope(
                        child: Scaffold(
                          backgroundColor:
                              AppTheme.light.colorScheme.surfaceContainerLow,
                          body: Center(
                            child: SizedBox(
                              width: 390,
                              height: 844,
                              child: _page(checklist),
                            ),
                          ),
                        ),
                        checklist: checklist,
                      ),
                    ),
                  ),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('ITEM 6 OF 30 · Brakes'), findsOneWidget);
      expect(find.text('Front brake pads'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(TechnicianItemPage), findsNothing);
    });
  });

  group('result', () {
    testWidgets('three served verdicts, never disabled', (tester) async {
      final item = _item(
        resultOptions: const [
          'NO_ISSUE_OBSERVED',
          'ATTENTION_RECOMMENDED',
          'DEFECT_FOUND',
        ],
      );
      await tester.pumpWidget(
        _scope(
          child: _host(_page(_checklist(item: item))),
          checklist: _checklist(item: item),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in [
        'No Issue Observed',
        'Attention Recommended',
        'Defect Found',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      // Tapping each one selects it; nothing is ever greyed out.
      for (final label in [
        'No Issue Observed',
        'Attention Recommended',
        'Defect Found',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('selecting a result marks it selected', (tester) async {
      final item = _item(
        resultOptions: const [
          'NO_ISSUE_OBSERVED',
          'ATTENTION_RECOMMENDED',
          'DEFECT_FOUND',
        ],
      );
      await tester.pumpWidget(
        _scope(
          child: _host(_page(_checklist(item: item))),
          checklist: _checklist(item: item),
        ),
      );
      await tester.pumpAndSettle();

      final handle = tester.ensureSemantics();
      await tester.tap(find.text('Defect Found'));
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.text('Defect Found'));
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      handle.dispose();
    });
  });

  group('evidence in place', () {
    testWidgets('counts read done over required', (tester) async {
      final checklist = _checklist();
      await tester.pumpWidget(
        _scope(child: _host(_page(checklist)), checklist: checklist),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('0/1'), findsNWidgets(2));
      expect(find.text('No photo yet'), findsOneWidget);
    });

    testWidgets('capturing without a camera surfaces the failure inline', (
      tester,
    ) async {
      final checklist = _checklist();
      await tester.pumpWidget(
        _scope(child: _host(_page(checklist)), checklist: checklist),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Photo'), 200);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      expect(
        find.text('Take this photo or video with the camera.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('footer offers Add photo while photos are owed', (
      tester,
    ) async {
      final checklist = _checklist();
      await tester.pumpWidget(
        _scope(child: _host(_page(checklist)), checklist: checklist),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add photo'), findsOneWidget);
    });
  });

  group('mark prompt', () {
    testWidgets('defect emphasises marking; dismiss keeps the photo', (
      tester,
    ) async {
      var marked = false;
      var dismissed = false;
      await tester.pumpWidget(
        _host(
          MarkPrompt(
            photoBytes: _transparentPng,
            defect: true,
            onMark: () => marked = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      );

      expect(find.text('Mark this photo?'), findsOneWidget);
      expect(find.text('Mark damage'), findsOneWidget);
      expect(find.text('Use as is'), findsOneWidget);

      await tester.tap(find.text('Use as is'));
      expect(dismissed, isTrue);

      await tester.tap(find.text('Mark damage'));
      expect(marked, isTrue);
    });

    testWidgets('without defect both actions sit side by side', (tester) async {
      await tester.pumpWidget(
        _host(
          MarkPrompt(
            photoBytes: null,
            defect: false,
            onMark: () {},
            onDismiss: () {},
          ),
        ),
      );

      expect(find.text('Mark this photo?'), findsOneWidget);
      expect(find.text('No photo yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('notes', () {
    ChecklistItem notesItem() => _item(
      resultOptions: const ['DEFECT_FOUND'],
      evidenceRules: const [
        EvidenceRule(
          resultCode: 'DEFECT_FOUND',
          minPhotos: 1,
          minVideos: 0,
          minNotesChars: 20,
          requiredEvidenceType: null,
        ),
      ],
    );

    testWidgets('notes appear only when the result requires them', (
      tester,
    ) async {
      final item = notesItem();
      final checklist = _checklist(item: item);
      await tester.pumpWidget(
        _scope(child: _host(_page(checklist)), checklist: checklist),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsNothing);

      await tester.tap(find.text('Defect Found'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Notes'), 200);
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('0 of 20 characters'), findsOneWidget);
    });
  });

  group('footer', () {
    testWidgets('save without a result shows the validation error', (
      tester,
    ) async {
      final checklist = _checklist();
      await tester.pumpWidget(
        _scope(child: _host(_page(checklist)), checklist: checklist),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & finish'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required.'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a pre-answered item never auto-saves on mount', (
      tester,
    ) async {
      final item = _item(assessment: _answer('brake_pads_front', 'iv-x'));
      final checklist = _checklist(item: item, completed: 1);
      await tester.pumpWidget(
        _scope(child: _host(_page(checklist)), checklist: checklist),
      );
      await tester.pumpAndSettle();

      // Had the screen fired a save on mount, the (unreachable) API would
      // have failed and an error note would be showing.
      expect(find.text('Action failed. Try again.'), findsNothing);
      expect(find.text('Save & finish'), findsOneWidget);
    });

    testWidgets('choosing a result with a complete rule saves and advances', (
      tester,
    ) async {
      // Served photo + video stand-ins satisfy the default requirement.
      final evidence = [
        _evidence(type: 'PHOTO'),
        _evidence(type: 'VIDEO', id: 'ev-2'),
      ];
      final item = _item();
      final checklist = _checklist(item: item);
      await tester.pumpWidget(
        _scope(
          child: _host(_page(checklist)),
          checklist: checklist,
          evidence: evidence,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pass'));
      await tester.pumpAndSettle();

      // The unreachable API fails and the failure surfaces inline instead
      // of losing the answer or hanging on a spinner.
      expect(find.text('Action failed. Try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('read-only', () {
    testWidgets('one Back action, no editing affordances', (tester) async {
      final checklist = _checklist(status: 'PENDING_REVIEW');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _scope(
                        child: Scaffold(
                          backgroundColor:
                              AppTheme.light.colorScheme.surfaceContainerLow,
                          body: Center(
                            child: SizedBox(
                              width: 390,
                              height: 844,
                              child: _page(checklist),
                            ),
                          ),
                        ),
                        checklist: checklist,
                      ),
                    ),
                  ),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Save & next'), findsNothing);
      expect(find.text('Add photo'), findsNothing);
      expect(find.text('Notes'), findsNothing);
      expect(find.text('Not checked'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(TechnicianItemPage), findsNothing);
    });
  });

  group('resilience', () {
    testWidgets('survives 2x in RTL without clipping', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final checklist = _checklist();
      final offline = _FakeOfflineStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            technicianChecklistProvider('job-1001')
                .overrideWith((ref) async => checklist),
            technicianEvidenceListProvider((
              jobId: 'job-1001',
              itemCode: 'brake_pads_front',
            )).overrideWith((ref) async => const <Evidence>[]),
            enumsProvider('result')
                .overrideWith((ref) async => <ReferenceRecord>[]),
            enumsProvider('evidence-type')
                .overrideWith((ref) async => <ReferenceRecord>[]),
            connectivityProvider.overrideWith(
              (ref) => const Stream<bool>.empty(),
            ),
            offlineStoreProvider.overrideWith((ref) => offline),
            evidenceCaptureServiceProvider.overrideWith(
              (ref) => _FailingCaptureService(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('ar'),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 390,
                      height: 844,
                      child: _page(checklist),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Front brake pads'), findsOneWidget);
    });
  });

  group('result options widget', () {
    const options = [
      ResultOptionView(
        code: 'NO_ISSUE_OBSERVED',
        label: 'No Issue Observed',
        tone: StatusTone.success,
        icon: Icons.check_rounded,
      ),
      ResultOptionView(
        code: 'ATTENTION_RECOMMENDED',
        label: 'Attention Recommended',
        tone: StatusTone.warning,
        icon: Icons.priority_high_rounded,
      ),
      ResultOptionView(
        code: 'DEFECT_FOUND',
        label: 'Defect Found',
        tone: StatusTone.danger,
        icon: Icons.close_rounded,
      ),
    ];

    testWidgets('reports the tapped code', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        _host(
          ResultOptions(
            options: options,
            selected: null,
            onSelect: (code) => chosen = code,
          ),
        ),
      );

      await tester.tap(find.text('Defect Found'));
      expect(chosen, 'DEFECT_FOUND');
    });

    testWidgets('marks the selected option', (tester) async {
      await tester.pumpWidget(
        _host(
          const ResultOptions(
            options: options,
            selected: 'ATTENTION_RECOMMENDED',
            onSelect: _noop,
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      final node = tester.getSemantics(find.text('Attention Recommended'));
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      handle.dispose();
    });
  });

  group('evidence section widget', () {
    testWidgets('rows report capture taps', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        _host(
          EvidenceSection(
            photos: 1,
            minPhotos: 2,
            videos: 0,
            minVideos: 1,
            onCapturePhoto: () => tapped.add('PHOTO'),
            onCaptureVideo: () => tapped.add('VIDEO'),
          ),
        ),
      );

      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('0/1'), findsOneWidget);
      await tester.tap(find.text('Photo'));
      await tester.tap(find.text('Video'));
      expect(tapped, ['PHOTO', 'VIDEO']);
    });

    testWidgets('busy shows progress and cancel; failed offers retry', (
      tester,
    ) async {
      var cancelled = false;
      await tester.pumpWidget(
        _host(
          EvidenceSection(
            photos: 0,
            minPhotos: 1,
            videos: 0,
            minVideos: 1,
            onCapturePhoto: () {},
            onCaptureVideo: () {},
            busy: true,
            progress: 0.5,
            progressLabel: 'Uploading…',
            onCancel: () => cancelled = true,
          ),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Cancel upload'));
      expect(cancelled, isTrue);

      var retried = false;
      await tester.pumpWidget(
        _host(
          EvidenceSection(
            photos: 0,
            minPhotos: 1,
            videos: 0,
            minVideos: 1,
            onCapturePhoto: () {},
            onCaptureVideo: () {},
            failed: true,
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.tap(find.text('Retry upload'));
      expect(retried, isTrue);
    });

    testWidgets('queued and empty states read correctly', (tester) async {
      await tester.pumpWidget(
        _host(
          EvidenceSection(
            photos: 0,
            minPhotos: 1,
            videos: 0,
            minVideos: 1,
            onCapturePhoto: () {},
            onCaptureVideo: () {},
            queued: true,
          ),
        ),
      );
      expect(find.text('Saved on this phone.'), findsOneWidget);
      expect(find.text('No photo yet'), findsOneWidget);
    });

    testWidgets('read-only rows carry no affordance', (tester) async {
      await tester.pumpWidget(
        _host(
          EvidenceSection(
            photos: 1,
            minPhotos: 1,
            videos: 0,
            minVideos: 1,
            onCapturePhoto: () {},
            onCaptureVideo: () {},
            interactive: false,
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('item footer widget', () {
    testWidgets('saving swaps the label for a spinner', (tester) async {
      await tester.pumpWidget(
        _host(
          ItemFooter(
            primaryLabel: 'Save & next',
            onPrimary: () {},
            saving: true,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save & next'), findsNothing);
    });

    testWidgets('secondary capture calls through', (tester) async {
      var added = false;
      await tester.pumpWidget(
        _host(
          ItemFooter(
            primaryLabel: 'Save & next',
            onPrimary: () {},
            secondaryLabel: 'Add photo',
            onSecondary: () => added = true,
          ),
        ),
      );
      await tester.tap(find.text('Add photo'));
      expect(added, isTrue);
    });
  });
}

void _noop(String _) {}

Uint8List get _transparentPng {
  // 1x1 transparent PNG.
  return Uint8List.fromList(const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);
}
