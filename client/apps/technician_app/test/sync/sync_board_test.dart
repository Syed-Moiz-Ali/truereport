/// Presentational tests for the sync boards' non-data states.
///
/// Loading, error and replay are driven by flags the pages set, so they can be
/// exercised without a backend or a fake sync service.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/sync/fieldwork/conflict_board.dart';
import 'package:technician_app/src/features/sync/fieldwork/sync_board.dart';

const _header = SyncHeaderData(
  title: 'Sync',
  subtitle: 'Omar Haddad',
  stateLabel: 'Online',
  stateTone: StatusTone.success,
  stateIcon: Icons.cloud_done_outlined,
);

const _summary = SyncSummaryData(
  eyebrow: 'Queued changes',
  count: 3,
  countLabel: '3 changes on this phone',
  oldestLabel: '09:12',
  hint: 'Saved safely.',
);

const _noChangesSummary = SyncSummaryData(
  eyebrow: 'Queued changes',
  count: 0,
  countLabel: 'No changes waiting to sync',
  hint: 'Saved safely.',
);

const _empty = SyncEmptyData(
  title: 'No changes waiting to sync',
  body: 'Everything on this phone has reached the server.',
);

const _footer = SyncFooterData(
  hint: 'Saved safely.',
  actionLabel: 'Sync now',
  savedLabel: 'No changes waiting to sync',
);

Future<void> _pumpBoard(
  WidgetTester tester,
  Widget board, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppScaffold(
        backgroundColor: AppTheme.light.colorScheme.surfaceContainerLow,
        body: board,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('loading outbox is a shaped skeleton, not a spinner', (
    tester,
  ) async {
    await _pumpBoard(
      tester,
      SyncBoard(
        header: _header,
        summary: _noChangesSummary,
        empty: _empty,
        footer: _footer,
        loading: true,
        replaying: false,
        canSync: false,
        onBack: () {},
        onSync: () {},
        onOpenConflict: (_) {},
        onRetry: () {},
        onRefresh: () async {},
      ),
      settle: false,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.text('Sync now'), findsNothing);
  });

  testWidgets('outbox error keeps the top bar and retries', (tester) async {
    var retried = false;
    await _pumpBoard(
      tester,
      SyncBoard(
        header: _header,
        summary: _summary,
        empty: _empty,
        footer: _footer,
        error: const SyncErrorData(
          title: 'Something went wrong',
          body: 'Something went wrong. Try again.',
          retryLabel: 'Retry',
        ),
        loading: false,
        replaying: false,
        canSync: false,
        onBack: () {},
        onSync: () {},
        onOpenConflict: (_) {},
        onRetry: () => retried = true,
        onRefresh: () async {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('replaying shows inline progress instead of the label', (
    tester,
  ) async {
    await _pumpBoard(
      tester,
      SyncBoard(
        header: _header,
        summary: _summary,
        empty: _empty,
        footer: _footer,
        loading: false,
        replaying: true,
        canSync: false,
        onBack: () {},
        onSync: () {},
        onOpenConflict: (_) {},
        onRetry: () {},
        onRefresh: () async {},
      ),
      settle: false,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sync now'), findsNothing);
  });

  testWidgets('conflict skeleton and error keep the bar and retry', (
    tester,
  ) async {
    await _pumpBoard(
      tester,
      ConflictBoard(
        header: const ConflictHeaderData(
          title: 'Sync conflict',
          counterLabel: '1 / 2',
        ),
        actionLabel: 'Use the server version',
        busy: false,
        loading: true,
        onBack: () {},
        onUseServer: () {},
        onRetry: () {},
      ),
      settle: false,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.text('Use the server version'), findsNothing);

    var retried = false;
    await _pumpBoard(
      tester,
      ConflictBoard(
        header: const ConflictHeaderData(title: 'Sync conflict'),
        actionLabel: 'Use the server version',
        busy: false,
        loading: false,
        error: const ConflictErrorData(
          title: 'Something went wrong',
          body: 'Something went wrong. Try again.',
          retryLabel: 'Retry',
        ),
        onBack: () {},
        onUseServer: () {},
        onRetry: () => retried = true,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}
