import 'dart:async';

import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/app.dart';
import 'package:workshop_admin_app/src/features/auth/workshop_login_page.dart';

/// The first paint must never be a page of empty strings: while the backend
/// bundle is loading the gate shows the loading surface, and a failed bundle
/// shows an error + retry that runs a real fetch.
void main() {
  testWidgets('pending bundle shows the loading gate, not the route', (
    tester,
  ) async {
    final fetcher = _PendingFetcher();
    await _pumpApp(tester, fetcher);

    expect(find.byKey(UiMessageLoadingGate.gateKey), findsOneWidget);
    expect(find.byKey(UiMessageErrorGate.gateKey), findsNothing);
    expect(find.byType(WorkshopLoginPage), findsNothing);
  });

  testWidgets('failed bundle shows the error gate with retry', (tester) async {
    final fetcher = _FailingFetcher();
    await _pumpApp(tester, fetcher);

    expect(find.byKey(UiMessageErrorGate.gateKey), findsOneWidget);
    expect(find.byKey(UiMessageErrorGate.retryKey), findsOneWidget);
    expect(find.byKey(UiMessageLoadingGate.gateKey), findsNothing);
    expect(find.byType(WorkshopLoginPage), findsNothing);
  });

  testWidgets('retry re-runs the fetch and opens /signin when it succeeds', (
    tester,
  ) async {
    final fetcher = _RecoveringFetcher();
    await _pumpApp(tester, fetcher);

    expect(find.byKey(UiMessageErrorGate.retryKey), findsOneWidget);
    expect(fetcher.calls, greaterThan(0));

    final failingCalls = fetcher.calls;
    fetcher.online = true;

    await tester.tap(find.byKey(UiMessageErrorGate.retryKey));
    await tester.pump();
    await _pumpUntil(
      tester,
      () => find.byType(WorkshopLoginPage).evaluate().isNotEmpty,
    );

    expect(
      fetcher.calls,
      greaterThan(failingCalls),
      reason: 'retry must issue a fresh bundle request',
    );
    expect(find.byKey(UiMessageErrorGate.gateKey), findsNothing);
    expect(find.byType(WorkshopLoginPage), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester, _BaseFetcher fetcher) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        uiMessageFetcherProvider.overrideWithValue(fetcher.fetch),
        sessionStoreProvider.overrideWithValue(_MemorySessionStore()),
      ],
      child: const AdminApp(),
    ),
  );
  // First frame schedules the bootstrap; the next pumps let it settle.
  await tester.pump();
  await _pumpUntil(
    tester,
    () =>
        find.byKey(UiMessageLoadingGate.gateKey).evaluate().isNotEmpty ||
        find.byKey(UiMessageErrorGate.gateKey).evaluate().isNotEmpty,
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 25));
  }
}

abstract class _BaseFetcher {
  int calls = 0;

  Future<Map<String, dynamic>> fetch(String path, Map<String, String> query) {
    calls += 1;
    return respond(path, query);
  }

  Future<Map<String, dynamic>> respond(String path, Map<String, String> query);
}

class _PendingFetcher extends _BaseFetcher {
  final Completer<Map<String, dynamic>> _never =
      Completer<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> respond(
    String path,
    Map<String, String> query,
  ) => _never.future;
}

class _FailingFetcher extends _BaseFetcher {
  @override
  Future<Map<String, dynamic>> respond(String path, Map<String, String> query) {
    throw StateError('backend unreachable');
  }
}

class _RecoveringFetcher extends _BaseFetcher {
  bool online = false;

  @override
  Future<Map<String, dynamic>> respond(String path, Map<String, String> query) {
    if (!online) throw StateError('backend unreachable');
    return Future<Map<String, dynamic>>.value(
      path.endsWith('/manifest') ? _manifest : _bundle,
    );
  }
}

class _MemorySessionStore implements SessionStore {
  Map<String, dynamic>? _session;

  @override
  Future<void> save(Map<String, dynamic> session) async => _session = session;

  @override
  Future<Map<String, dynamic>?> read() async => _session;

  @override
  Future<void> clear() async => _session = null;
}

const Map<String, dynamic> _manifest = <String, dynamic>{
  'defaultLanguage': 'en',
  'namespaces': <String, dynamic>{'common': 1, 'workshop_admin': 1},
  'languages': <dynamic>[
    <String, dynamic>{
      'code': 'en',
      'direction': 'ltr',
      'versions': <String, dynamic>{'common': 1, 'workshop_admin': 1},
    },
  ],
};

const Map<String, dynamic> _bundle = <String, dynamic>{
  'language': 'en',
  'fallbackLanguage': 'en',
  'versions': <String, dynamic>{'common': 1, 'workshop_admin': 1},
  'catalogs': <String, dynamic>{
    'common': <String, dynamic>{'jobsTab': 'Jobs'},
    'workshop_admin': <String, dynamic>{
      'jobsTab': 'Jobs',
      'appTitleAdmin': 'TrueReport Admin',
    },
  },
  'missingKeys': <String, dynamic>{},
};
