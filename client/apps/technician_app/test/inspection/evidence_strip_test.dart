/// Widget contract for the evidence thumbnail strip: one tile per capture,
/// type and state badges, open on tile tap, delete on the trailing ×.
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

Evidence _evidence({
  required String type,
  String id = 'ev-1',
  String? sha,
  int? durationMs,
}) => Evidence(
  id: id,
  jobId: 'job-1001',
  itemCode: 'brake_pads_front',
  type: type,
  status: 'RECEIVED',
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

Future<void> _pumpStrip(
  WidgetTester tester, {
  required List<Evidence> items,
  EvidenceUploadState upload = const EvidenceUploadState(),
  String? uploadingSha,
  String? failedSha,
  bool interactive = true,
  ValueChanged<Evidence>? onOpen,
  ValueChanged<Evidence>? onDelete,
  Future<Uint8List?> Function(Evidence item)? loadBytes,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            child: EvidenceStrip(
              items: items,
              upload: upload,
              uploadingSha: uploadingSha,
              failedSha: failedSha,
              interactive: interactive,
              onOpen: onOpen ?? (_) {},
              onDelete: onDelete ?? (_) {},
              loadBytes: loadBytes ?? (_) async => null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  group('EvidenceStrip', () {
    testWidgets('renders one tile per capture with its type', (tester) async {
      await _pumpStrip(
        tester,
        items: [
          _evidence(type: 'PHOTO'),
          _evidence(type: 'VIDEO', id: 'ev-2'),
          _evidence(type: 'DOCUMENT', id: 'ev-3'),
        ],
      );

      expect(find.bySemanticsLabel('Photo'), findsOneWidget);
      expect(find.bySemanticsLabel('Video'), findsOneWidget);
      expect(find.bySemanticsLabel('Document'), findsOneWidget);
      expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
      // The document tile repeats its glyph as the large placeholder.
      expect(find.byIcon(Icons.description_outlined), findsNWidgets(2));
    });

    testWidgets('served rows carry no state badge', (tester) async {
      await _pumpStrip(tester, items: [_evidence(type: 'PHOTO')]);

      expect(find.text('Uploading'), findsNothing);
      expect(find.text('Queued'), findsNothing);
      expect(find.text('Failed'), findsNothing);
    });

    testWidgets('offline-queued rows badge as queued', (tester) async {
      await _pumpStrip(
        tester,
        items: [_evidence(type: 'VIDEO', id: 'local-abc', durationMs: 15000)],
      );

      expect(find.text('Queued'), findsOneWidget);
      expect(find.text('0:15'), findsOneWidget);
    });

    testWidgets('in-flight rows badge as uploading', (tester) async {
      await _pumpStrip(
        tester,
        items: [
          _evidence(type: 'PHOTO', id: 'ev-1', sha: 'sha-a'),
          _evidence(type: 'PHOTO', id: 'ev-2', sha: 'sha-b'),
        ],
        upload: const EvidenceUploadState(
          stage: EvidenceUploadStage.uploading,
          type: 'PHOTO',
        ),
        uploadingSha: 'sha-b',
      );

      expect(find.text('Uploading'), findsOneWidget);
      expect(find.bySemanticsLabel('Photo, Uploading'), findsOneWidget);
      expect(find.bySemanticsLabel('Photo'), findsOneWidget);
    });

    testWidgets('failed rows badge as failed', (tester) async {
      await _pumpStrip(
        tester,
        items: [_evidence(type: 'PHOTO', id: 'ev-1', sha: 'sha-a')],
        upload: const EvidenceUploadState(stage: EvidenceUploadStage.failed),
        failedSha: 'sha-a',
      );

      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('tile tap opens, × deletes without opening', (tester) async {
      Evidence? opened;
      Evidence? deleted;
      await _pumpStrip(
        tester,
        items: [_evidence(type: 'PHOTO')],
        onOpen: (item) => opened = item,
        onDelete: (item) => deleted = item,
      );

      await tester.tap(find.bySemanticsLabel('Photo'));
      await tester.pumpAndSettle();
      expect(opened?.id, 'ev-1');
      expect(deleted, isNull);

      opened = null;
      await tester.tap(find.bySemanticsLabel('Delete evidence'));
      await tester.pumpAndSettle();
      expect(deleted?.id, 'ev-1');
      expect(opened, isNull);
    });

    testWidgets('read-only hides the delete affordance', (tester) async {
      await _pumpStrip(
        tester,
        items: [_evidence(type: 'PHOTO')],
        interactive: false,
      );

      expect(find.bySemanticsLabel('Delete evidence'), findsNothing);
      expect(find.bySemanticsLabel('Photo'), findsOneWidget);
    });

    testWidgets('photo bytes render the captured thumbnail', (tester) async {
      // A 1x1 transparent PNG: decodes in the test engine, no assets needed.
      const png = <int>[
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
      ];
      await _pumpStrip(
        tester,
        items: [_evidence(type: 'PHOTO')],
        loadBytes: (_) async => Uint8List.fromList(png),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
