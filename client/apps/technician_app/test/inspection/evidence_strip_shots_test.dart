/// Real-font screenshot evidence for the evidence thumbnail strip.
library;

import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/assessment/evidence_strip.dart';
import 'package:technician_app/src/features/inspection/evidence_upload_queue.dart';
import 'package:technician_app/src/inspection_models.dart';

const Map<String, String> _bundle = <String, String>{
  'technicianPhoto': 'Photo',
  'technicianVideo': 'Video',
  'technicianDocument': 'Document',
  'technicianEvidenceStateUploading': 'Uploading',
  'technicianEvidenceStateQueued': 'Queued',
  'technicianEvidenceStateFailed': 'Failed',
  'technicianDeleteEvidence': 'Delete evidence',
};

/// A 1x1 transparent PNG: decodes in the test engine, no assets needed.
final Uint8List _png = Uint8List.fromList(const <int>[
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

Evidence _evidence({
  required String type,
  required String id,
  String? sha,
  int? durationMs,
}) => Evidence(
  id: id,
  jobId: 'job-1001',
  itemCode: 'brake_pads_front',
  type: type,
  status: id.startsWith('local-') ? 'PENDING' : 'RECEIVED',
  mime: type == 'PHOTO' ? 'image/jpeg' : 'video/mp4',
  bytes: 42,
  sha256: sha ?? 'sha-$id',
  capturedAt: '2026-03-12T09:31:00',
  captureSource: 'CAMERA',
  deviceId: 'test-device',
  width: 100,
  height: 100,
  durationMs: durationMs,
  captionEn: null,
  captionAr: null,
  posterAvailable: false,
  qualityStatus: null,
  contentUrl: null,
  createdAt: '2026-03-12T09:31:00',
);

Future<void> _shot(
  WidgetTester tester,
  String name, {
  required double width,
  required double height,
  required List<Evidence> items,
  EvidenceUploadState upload = const EvidenceUploadState(),
  String? uploadingSha,
  String? failedSha,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Directionality(
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Scaffold(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerLow,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: EvidenceStrip(
                      items: items,
                      upload: upload,
                      uploadingSha: uploadingSha,
                      failedSha: failedSha,
                      onOpen: (_) {},
                      onDelete: (_) {},
                      loadBytes: (item) async => item.isPhoto ? _png : null,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  testWidgets('strip_390_mixed', (tester) async {
    await _shot(
      tester,
      'strip_390_mixed',
      width: 390,
      height: 200,
      items: [
        _evidence(type: 'PHOTO', id: 'ev-1'),
        _evidence(type: 'VIDEO', id: 'ev-2', durationMs: 15000),
        _evidence(type: 'DOCUMENT', id: 'ev-3'),
      ],
    );
  });

  testWidgets('strip_390_states', (tester) async {
    await _shot(
      tester,
      'strip_390_states',
      width: 390,
      height: 200,
      items: [
        _evidence(type: 'VIDEO', id: 'local-q1', durationMs: 45000),
        _evidence(type: 'PHOTO', id: 'ev-2', sha: 'sha-up'),
        _evidence(type: 'PHOTO', id: 'ev-3', sha: 'sha-bad'),
      ],
      upload: const EvidenceUploadState(
        stage: EvidenceUploadStage.uploading,
        type: 'PHOTO',
      ),
      uploadingSha: 'sha-up',
      failedSha: 'sha-bad',
    );
  });

  testWidgets('strip_768_states', (tester) async {
    await _shot(
      tester,
      'strip_768_states',
      width: 768,
      height: 200,
      items: [
        _evidence(type: 'VIDEO', id: 'local-q1', durationMs: 45000),
        _evidence(type: 'PHOTO', id: 'ev-2', sha: 'sha-up'),
        _evidence(type: 'PHOTO', id: 'ev-3', sha: 'sha-bad'),
      ],
      upload: const EvidenceUploadState(
        stage: EvidenceUploadStage.uploading,
        type: 'PHOTO',
      ),
      uploadingSha: 'sha-up',
      failedSha: 'sha-bad',
    );
  });

  testWidgets('strip_390_rtl', (tester) async {
    await _shot(
      tester,
      'strip_390_rtl',
      width: 390,
      height: 200,
      locale: const Locale('ar'),
      items: [
        _evidence(type: 'PHOTO', id: 'ev-1'),
        _evidence(type: 'VIDEO', id: 'ev-2', durationMs: 15000),
        _evidence(type: 'DOCUMENT', id: 'ev-3'),
      ],
    );
  });
}
