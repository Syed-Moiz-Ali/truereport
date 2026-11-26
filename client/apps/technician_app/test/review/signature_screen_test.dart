/// Widget contract for the signature screen: name validation, pad states,
/// signed row, submit gate, error retry and the read-only shell.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_item.dart';
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

/// API double with a scripted submit outcome.
class _FakeApi implements TechnicianApi {
  _FakeApi({this.submit});

  Future<Signature> Function()? submit;
  int submits = 0;
  String? lastSignerName;

  @override
  Future<Signature> submitSignature(
    String jobId,
    SignatureRequest request, {
    String? idempotencyKey,
  }) async {
    submits += 1;
    lastSignerName = request.signerName;
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

ProviderScope _scope({
  required Widget child,
  required _FakeApi api,
  String jobStatus = 'SCHEDULED',
}) {
  return ProviderScope(
    overrides: [
      technicianJobSummaryProvider('job-1001')
          .overrideWith((ref) async => fixtures.jobSummary(status: jobStatus)),
      technicianApiProvider.overrideWith((ref) => api),
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

Finder get _pad => find.byType(SignaturePad);

Future<void> _draw(WidgetTester tester) async {
  expect(_pad, findsOneWidget);
  final center = tester.getCenter(_pad);
  // A real stroke streams moves: a single jump leaves only the tap-down dot.
  await tester.timedDragFrom(
    center,
    const Offset(70, 14),
    const Duration(milliseconds: 300),
  );
  await tester.pumpAndSettle();
}

/// Pumps the page on a pushed route so a successful submit can pop it.
Future<void> _pumpPushed(
  WidgetTester tester, {
  required _FakeApi api,
  String jobStatus = 'SCHEDULED',
}) async {
  await tester.pumpWidget(
    _scope(
      api: api,
      jobStatus: jobStatus,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: AppTheme.light.colorScheme.surfaceContainerLow,
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const TechnicianSignaturePage(jobId: 'job-1001'),
                    ),
                  ),
                  child: const Text('go'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

/// The export rasterizes in real time, which fake async never advances:
/// let the engine catch up outside the fake zone, then settle the UI.
Future<void> _waitForSubmit(WidgetTester tester, _FakeApi api) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
  await tester.pumpAndSettle();
  if (api.submits == 0) {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(() {
    // Device identity reads SharedPreferences: keep it in memory so the
    // submit path never touches a platform channel in tests.
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
    setRemoteEnglish(_bundle);
  });

  group('signature screen', () {
    testWidgets('empty name shows the specific message after blur', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scope(
          api: _FakeApi(),
          child: _host(const TechnicianSignaturePage(jobId: 'job-1001')),
        ),
      );
      await tester.pumpAndSettle();

      // Focus the name field, then leave it empty: the message names the fix.
      await tester.tap(find.byKey(const Key('signature-name')));
      await tester.pumpAndSettle();
      await tester.tap(_pad);
      await tester.pumpAndSettle();

      expect(find.text("Enter the signer's full name."), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('save stays disabled until a name and a stroke exist', (
      tester,
    ) async {
      final api = _FakeApi();
      await _pumpPushed(tester, api: api);

      await _draw(tester);
      await tester.tap(find.text('Save signature'));
      await tester.pumpAndSettle();
      expect(api.submits, 0);

      await tester.enterText(
        find.byKey(const Key('signature-name')),
        'Ahmed Al Mansoori',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Ahmed Al Mansoori · Signature captured'),
        findsOneWidget,
      );

      await tester.tap(find.text('Save signature'));
      await _waitForSubmit(tester, api);
      expect(find.text('Add a signature and signer name.'), findsNothing);
      expect(api.submits, 1);
      expect(api.lastSignerName, 'Ahmed Al Mansoori');
      expect(find.byType(TechnicianSignaturePage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('undo and clear remove strokes newest first', (tester) async {
      await tester.pumpWidget(
        _scope(
          api: _FakeApi(),
          child: _host(const TechnicianSignaturePage(jobId: 'job-1001')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('signature-name')),
        'Ahmed Al Mansoori',
      );
      await tester.pumpAndSettle();

      await _draw(tester);
      await _draw(tester);
      expect(
        find.text('Ahmed Al Mansoori · Signature captured'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('signature-undo')));
      await tester.pumpAndSettle();
      expect(
        find.text('Ahmed Al Mansoori · Signature captured'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('signature-clear')));
      await tester.pumpAndSettle();
      expect(find.text('Ahmed Al Mansoori · Signature captured'), findsNothing);
      expect(find.text('Sign here'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed submit keeps strokes and retries', (tester) async {
      var fail = true;
      final api = _FakeApi(
        submit: () async {
          if (fail) {
            throw Exception('offline');
          }
          return const Signature(
            jobId: 'job-1001',
            signerName: 'Ahmed Al Mansoori',
            signedAt: '2026-03-12T09:31:00',
            deviceId: 'device-1',
            method: 'DRAWN',
            signatureHash: 'hash-1',
          );
        },
      );
      await _pumpPushed(tester, api: api);
      await tester.enterText(
        find.byKey(const Key('signature-name')),
        'Ahmed Al Mansoori',
      );
      await tester.pumpAndSettle();
      await _draw(tester);

      await tester.tap(find.text('Save signature'));
      await _waitForSubmit(tester, api);
      expect(find.text('Add a signature and signer name.'), findsNothing);
      expect(api.submits, 1);
      expect(find.text('Action failed. Try again.'), findsOneWidget);
      // The ink survives the failure: the signed row is still up.
      expect(
        find.text('Ahmed Al Mansoori · Signature captured'),
        findsOneWidget,
      );

      fail = false;
      await tester.ensureVisible(find.text('Retry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await _waitForSubmit(tester, api);
      expect(api.submits, 2);
      expect(find.byType(TechnicianSignaturePage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('read-only shows the reason and a single way back', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scope(
          api: _FakeApi(),
          jobStatus: 'COMPLETED',
          child: _host(const TechnicianSignaturePage(jobId: 'job-1001')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("This job is view-only, so the signature can't be changed."),
        findsOneWidget,
      );
      expect(find.byKey(const Key('signature-name')), findsNothing);
      expect(_pad, findsNothing);
      expect(find.text('Save signature'), findsNothing);
      expect(find.text('Back to summary'), findsNothing);
      final footer = find.byType(ItemFooter);
      expect(footer, findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
