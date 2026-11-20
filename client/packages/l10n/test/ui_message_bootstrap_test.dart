import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

class _StatusFailure implements Exception {
  _StatusFailure(this.statusCode);

  final int statusCode;
}

class _FailingController extends UiMessageController {
  _FailingController(this.failure) : super(UiMessageClients.workshopAdmin);

  final Object failure;
  int bootstrapCalls = 0;

  @override
  UiMessageState build() => UiMessageState(
    activeLanguage: 'en',
    defaultLanguage: 'en',
    ready: false,
    booting: false,
    bootError: failure,
  );

  @override
  Future<void> bootstrap() async {
    bootstrapCalls += 1;
  }
}

Future<_FailingController> _pump(
  WidgetTester tester,
  Object failure, {
  VoidCallback? onAuthFailure,
}) async {
  final controller = _FailingController(failure);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        languageSelectionProvider(UiMessageClients.workshopAdmin)
            .overrideWith(() => controller),
      ],
      child: MaterialApp(
        home: UiMessageBootstrap(
          client: UiMessageClients.workshopAdmin,
          onAuthFailure: onAuthFailure,
          child: const Text('content'),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return controller;
}

void main() {
  testWidgets('manifest failure renders the retry surface, not a spinner', (
    tester,
  ) async {
    await _pump(tester, _StatusFailure(500));

    expect(find.byKey(const Key('ui-message-retry')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('content'), findsNothing);
  });

  testWidgets('retry only runs when the user taps', (tester) async {
    final controller = await _pump(tester, _StatusFailure(500));
    expect(controller.bootstrapCalls, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(controller.bootstrapCalls, 1, reason: 'no automatic retry loop');

    await tester.tap(find.byKey(const Key('ui-message-retry')));
    await tester.pump();
    expect(controller.bootstrapCalls, 2);
  });

  testWidgets('401/403 asks the session layer to sign out exactly once', (
    tester,
  ) async {
    var signOuts = 0;
    await _pump(
      tester,
      _StatusFailure(401),
      onAuthFailure: () => signOuts += 1,
    );
    await tester.pump();

    expect(find.byKey(const Key('ui-message-retry')), findsOneWidget);
    expect(signOuts, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(signOuts, 1, reason: 'auth failure must not loop');
  });

  testWidgets('non-auth failures never trigger sign-out', (tester) async {
    var signOuts = 0;
    await _pump(
      tester,
      _StatusFailure(500),
      onAuthFailure: () => signOuts += 1,
    );
    await tester.pump();

    expect(signOuts, 0);
  });

  test('bootstrap retries after a failure instead of staying stuck', () async {
    var manifestCalls = 0;
    final container = ProviderContainer(
      overrides: [
        uiMessageStoreProvider.overrideWithValue(InMemoryUiMessageStore()),
        uiMessageFetcherProvider.overrideWithValue((path, query) async {
          if (path.endsWith('/manifest')) {
            manifestCalls += 1;
            if (manifestCalls == 1) throw _StatusFailure(500);
            return <String, dynamic>{
              'defaultLanguage': 'en',
              'namespaces': <String, dynamic>{'common': 1, 'workshop_admin': 1},
              'languages': <dynamic>[
                <String, dynamic>{
                  'code': 'en',
                  'direction': 'ltr',
                  'versions': <String, dynamic>{
                    'common': 1,
                    'workshop_admin': 1,
                  },
                },
              ],
            };
          }
          return <String, dynamic>{
            'language': 'en',
            'versions': <String, dynamic>{'common': 1, 'workshop_admin': 1},
            'catalogs': <String, dynamic>{
              'common': <String, dynamic>{},
              'workshop_admin': <String, dynamic>{},
            },
            'messages': <String, dynamic>{},
          };
        }),
      ],
    );
    addTearDown(container.dispose);
    final provider = languageSelectionProvider(UiMessageClients.workshopAdmin);

    await container.read(provider.notifier).bootstrap();
    expect(container.read(provider).ready, isFalse);
    expect(container.read(provider).bootError, isNotNull);

    await container.read(provider.notifier).bootstrap();
    expect(manifestCalls, 2);
    expect(container.read(provider).ready, isTrue);
    expect(container.read(provider).bootError, isNull);
  });
}
