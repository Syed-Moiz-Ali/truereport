/// Real-font screenshot evidence for the signature screen.
library;

import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:technician_app/src/features/review/signature/signature_pad.dart';
import 'package:technician_app/src/features/review/signature_screen.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/technician_api.dart';
import 'package:technician_app/src/technician_providers.dart';

import '../support/fixtures.dart' as fixtures;

const Map<String, String> _bundle = <String, String>{
  'technicianSignatureTitle': 'Customer signature',
  'technicianSignatureHint': 'Sign inside the box.',
  'fullNameHint': 'Enter your full name',
  'technicianSignerName': 'Signer name',
  'technicianSignerNameRequired': "Enter the signer's full name.",
  'technicianSignHere': 'Sign here',
  'technicianUndo': 'Undo',
  'technicianClearSignature': 'Clear',
  'technicianSignatureRequired': 'Add a signature and signer name.',
  'technicianSignatureCaptured': 'Signature captured',
  'technicianSignatureSuccess': 'Signature saved.',
  'technicianSaveSignature': 'Save signature',
  'technicianBackToSummary': 'Back to summary',
  'technicianSignatureReadOnly':
      "This job is view-only, so the signature can't be changed.",
  'commonBack': 'Back',
  'commonActionFailed': 'Action failed. Try again.',
  'retryAction': 'Retry',
};

class _FakeApi implements TechnicianApi {
  _FakeApi({this.submit});

  Future<Signature> Function()? submit;

  @override
  Future<Signature> submitSignature(
    String jobId,
    SignatureRequest request, {
    String? idempotencyKey,
  }) async {
    final fn = submit;
    if (fn != null) {
      return fn();
    }
    return Signature(
      jobId: jobId,
      signerName: request.signerName,
      signedAt: '2026-03-12T09:31:00',
      deviceId: request.deviceId,
      method: request.method,
      signatureHash: 'hash-1',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _shot(
  WidgetTester tester,
  String name, {
  required double width,
  required double height,
  Locale locale = const Locale('en'),
  TextDirection direction = TextDirection.ltr,
  TextScaler scaler = TextScaler.noScaling,
  String jobStatus = 'IN_PROGRESS',
  _FakeApi? api,
  Future<void> Function(WidgetTester)? interact,
  // In-flight states (spinner) never settle: pump a bounded run instead.
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        technicianJobSummaryProvider(
          'job-1001',
        ).overrideWith((ref) async => fixtures.jobSummary(status: jobStatus)),
        technicianApiProvider.overrideWith((ref) => api ?? _FakeApi()),
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
                textDirection: direction,
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
                        child: const TechnicianSignaturePage(jobId: 'job-1001'),
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

Future<void> _draw(WidgetTester tester) async {
  final pad = find.byType(SignaturePad);
  // A real stroke streams moves: a single jump leaves only the tap-down dot.
  await tester.timedDragFrom(
    tester.getCenter(pad),
    const Offset(70, 14),
    const Duration(milliseconds: 300),
  );
}

Future<void> _sign(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('signature-name')),
    'Ahmed Al Mansoori',
  );
  await _draw(tester);
}

void main() {
  setUpAll(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
    setRemoteEnglish(_bundle);
  });

  testWidgets('signature_390_data', (tester) async {
    await _shot(tester, 'signature_390_data', width: 390, height: 844);
  });

  testWidgets('signature_768_data', (tester) async {
    await _shot(tester, 'signature_768_data', width: 768, height: 1024);
  });

  testWidgets('signature_1024_data', (tester) async {
    await _shot(tester, 'signature_1024_data', width: 1024, height: 768);
  });

  testWidgets('signature_390_rtl', (tester) async {
    await _shot(
      tester,
      'signature_390_rtl',
      width: 390,
      height: 844,
      locale: const Locale('ar'),
      direction: TextDirection.rtl,
    );
  });

  testWidgets('signature_390_empty', (tester) async {
    await _shot(
      tester,
      'signature_390_empty',
      width: 390,
      height: 844,
      interact: (tester) async {
        await tester.tap(find.byKey(const Key('signature-name')));
        await tester.pump();
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  });

  testWidgets('signature_390_drawing', (tester) async {
    await _shot(
      tester,
      'signature_390_drawing',
      width: 390,
      height: 844,
      interact: _draw,
    );
  });

  testWidgets('signature_390_signed', (tester) async {
    await _shot(
      tester,
      'signature_390_signed',
      width: 390,
      height: 844,
      interact: _sign,
    );
  });

  testWidgets('signature_390_submitting', (tester) async {
    final gate = Completer<Signature>();
    await _shot(
      tester,
      'signature_390_submitting',
      width: 390,
      height: 844,
      api: _FakeApi(submit: () => gate.future),
      settle: false,
      interact: (tester) async {
        await _sign(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save signature'));
        // The export rasterizes in real time: wait outside fake async so
        // the spinner state is actually reached before capturing.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
      },
    );
  });

  testWidgets('signature_390_error', (tester) async {
    await _shot(
      tester,
      'signature_390_error',
      width: 390,
      height: 844,
      api: _FakeApi(submit: () async => throw Exception('offline')),
      settle: false,
      interact: (tester) async {
        await _sign(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save signature'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
      },
    );
  });

  testWidgets('signature_390_15x', (tester) async {
    await _shot(
      tester,
      'signature_390_15x',
      width: 390,
      height: 844,
      scaler: const TextScaler.linear(1.5),
      interact: _sign,
    );
  });
}
