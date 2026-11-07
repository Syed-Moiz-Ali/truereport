import 'dart:async';
import 'dart:ui';

import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/assign_technician_dialog.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/fake_admin_api.dart';

const _job = WorkshopJob(
  id: 'job-7',
  reference: 'JOB-TEST0007',
  status: 'SCHEDULED',
  templateVersionId: 'version-1',
  templateName: 'Full inspection',
  templateVersionNo: 1,
  assignedTechnicianId: null,
  assignedTechnicianName: null,
  scheduledAt: '2026-11-05T09:00:00',
  customerName: 'Customer A',
  customerPhone: '+971500000000',
  customerEmail: 'customer@test.local',
  vehicleMake: 'Toyota',
  vehicleModel: 'Camry',
  vehicleYear: 2022,
  vehicleVin: 'TESTVIN00000000001',
  vehiclePlate: 'A12345',
  scope: 'Full inspection',
);

const _techA = StaffMember(
  userId: 'tech-1',
  displayName: 'Technician A',
  emailMasked: 't***@test.local',
  role: 'TECHNICIAN',
  status: 'ACTIVE',
);

const _techB = StaffMember(
  userId: 'tech-2',
  displayName: 'Technician B',
  emailMasked: 'u***@test.local',
  role: 'TECHNICIAN',
  status: 'ACTIVE',
);

class _AssignFakeApi extends FakeAdminApi {
  _AssignFakeApi({
    this.staffMembers = const [_techA, _techB],
    this.staffError = false,
    this.assignError = false,
    this.job = _job,
  });

  final List<StaffMember> staffMembers;
  final bool assignError;
  final WorkshopJob job;
  final List<Map<String, String?>> assignCalls = [];

  bool staffError;

  @override
  Future<List<StaffMember>> staff() async {
    if (staffError) {
      throw StateError('staff failed');
    }
    return staffMembers;
  }

  @override
  Future<WorkshopJob> assignJob(
    String jobId,
    String technicianId,
    String? reason,
  ) async {
    assignCalls.add({
      'jobId': jobId,
      'technicianId': technicianId,
      'reason': reason,
    });
    if (assignError) {
      throw StateError('assign failed');
    }
    String? technician;
    for (final member in staffMembers) {
      if (member.userId == technicianId) {
        technician = member.displayName;
      }
    }
    return WorkshopJob(
      id: job.id,
      reference: job.reference,
      status: 'ASSIGNED',
      templateVersionId: job.templateVersionId,
      templateName: job.templateName,
      templateVersionNo: job.templateVersionNo,
      assignedTechnicianId: technicianId,
      assignedTechnicianName: technician,
      scheduledAt: job.scheduledAt,
      customerName: job.customerName,
      customerPhone: job.customerPhone,
      customerEmail: job.customerEmail,
      vehicleMake: job.vehicleMake,
      vehicleModel: job.vehicleModel,
      vehicleYear: job.vehicleYear,
      vehicleVin: job.vehicleVin,
      vehiclePlate: job.vehiclePlate,
      scope: job.scope,
    );
  }
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({
    required this.locale,
    required this.textScale,
    required this.job,
    required this.onResult,
    required this.openFocus,
    super.key,
  });

  final Locale locale;
  final double textScale;
  final WorkshopJob job;
  final ValueChanged<String?> onResult;
  final FocusNode openFocus;

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
  late BuildContext _dialogContext;

  FocusNode get openFocus => widget.openFocus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).setLocale(widget.locale);
    });
  }

  /// Opens the dialog without moving pointer focus first, so the opener
  /// keeps primary focus (used by the focus/keyboard tests).
  Future<void> open() async {    final assigned = await WorkshopAssignDialog.show(
      _dialogContext,
      widget.job,
    );
    widget.onResult(assigned);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(widget.textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (dialogContext) {
              _dialogContext = dialogContext;
              return Focus(
                focusNode: widget.openFocus,
                child: ElevatedButton(
                  key: const Key('open-assign-dialog'),
                  onPressed: () async {
                    final assigned = await WorkshopAssignDialog.show(
                      dialogContext,
                      widget.job,
                    );
                    widget.onResult(assigned);
                  },
                  child: const Text('Open dialog'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<({ValueNotifier<String?> result, GlobalKey<_HarnessState> key})>
_openDialog(
  WidgetTester tester, {
  required _AssignFakeApi api,
  required Locale locale,
  required Size size,
  double textScale = 1,
  WorkshopJob job = _job,
  bool tap = true,
}) async {
  _setSize(tester, size);
  final result = ValueNotifier<String?>(null);
  final key = GlobalKey<_HarnessState>();
  final openFocus = FocusNode();
  addTearDown(openFocus.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(api)],
      child: _Harness(
        key: key,
        locale: locale,
        textScale: textScale,
        job: job,
        onResult: (assigned) {
          result.value = assigned;
        },
        openFocus: openFocus,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (tap) {
    await tester.tap(find.byKey(const Key('open-assign-dialog')));
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
  return (result: result, key: key);
}

bool _isInsideDialog(WidgetTester tester) {
  final node = FocusManager.instance.primaryFocus;
  final context = node?.context;
  if (context == null) {
    return false;
  }
  return find
      .ancestor(
        of: find.byWidget(context.widget),
        matching: find.byType(WorkshopDialog),
      )
      .evaluate()
      .isNotEmpty;
}

bool _confirmFocused(WidgetTester tester, String confirmLabel) {
  final node = FocusManager.instance.primaryFocus;
  final context = node?.context;
  if (context == null) {
    return false;
  }
  final buttons = find.ancestor(
    of: find.byWidget(context.widget),
    matching: find.byType(AppButton),
  );
  for (final element in buttons.evaluate()) {
    if (find
        .descendant(
          of: find.byWidget(element.widget),
          matching: find.text(confirmLabel),
        )
        .evaluate()
        .isNotEmpty) {
      return true;
    }
  }
  return false;
}

bool _cardFocused(WidgetTester tester) {
  final node = FocusManager.instance.primaryFocus;
  final context = node?.context;
  if (context == null) {
    return false;
  }
  return find
      .ancestor(
        of: find.byWidget(context.widget),
        matching: find.byType(WorkshopOptionCard<String>),
      )
      .evaluate()
      .isNotEmpty;
}

void main() {
  const wide = Size(1280, 800);
  const phone = Size(390, 844);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final entry in {'wide': wide, 'phone': phone}.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'assign dialog ${locale.languageCode} ${entry.key} scale $scale renders without overflow',
          (tester) async {
            await _openDialog(
              tester,
              api: _AssignFakeApi(),
              locale: locale,
              size: entry.value,
              textScale: scale,
            );
            final dialogContext = tester.element(
              find.byType(WorkshopDialog),
            );
            final l10n = AppLocalizations.of(dialogContext);
            expect(find.text(l10n.assignTechnicianTitle), findsOneWidget);
            expect(find.text(l10n.assignTechnicianSubtitle), findsOneWidget);
            expect(
              find.byKey(const Key('assign-vehicle-strip')),
              findsOneWidget,
            );
            expect(find.text('Technician A'), findsOneWidget);
            expect(find.text('Technician B'), findsOneWidget);
            expect(find.text(l10n.confirm), findsOneWidget);
            expect(find.text(l10n.cancel), findsOneWidget);
          },
        );
      }
    }
  }

  testWidgets('assign dialog uses RTL direction in Arabic', (tester) async {
    await _openDialog(
      tester,
      api: _AssignFakeApi(),
      locale: const Locale('ar'),
      size: phone,
    );
    final dialogContext = tester.element(find.byType(WorkshopDialog));
    final l10n = AppLocalizations.of(dialogContext);
    expect(
      Directionality.of(tester.element(find.text(l10n.assignTechnicianTitle))),
      TextDirection.rtl,
    );
  });

  testWidgets('vehicle strip uses existing job fields only', (tester) async {
    await _openDialog(
      tester,
      api: _AssignFakeApi(),
      locale: const Locale('en'),
      size: wide,
    );
    final strip = find.byKey(const Key('assign-vehicle-strip'));
    expect(strip, findsOneWidget);
    expect(
      find.descendant(of: strip, matching: find.text('Toyota Camry')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: strip, matching: find.textContaining('JOB-TEST0007')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: strip,
        matching: find.textContaining('Full inspection'),
      ),
      findsWidgets,
    );
  });

  testWidgets('selection plus confirm calls assignJob with reason', (
    tester,
  ) async {
    final api = _AssignFakeApi();
    final opened = await _openDialog(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    await tester.tap(find.text('Technician B'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('assign-reason')),
        matching: find.byType(TextFormField),
      ),
      'Counter busy',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('assign-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-confirm')));
    await tester.pumpAndSettle();

    expect(api.assignCalls, hasLength(1));
    expect(api.assignCalls.single, {
      'jobId': 'job-7',
      'technicianId': 'tech-2',
      'reason': 'Counter busy',
    });
    expect(opened.result.value, 'tech-2');
    expect(find.byType(WorkshopDialog), findsNothing);
    expect(find.text('Job assigned'), findsOneWidget);
  });

  testWidgets('empty reason sends null to assignJob', (tester) async {
    final api = _AssignFakeApi();
    await _openDialog(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    await tester.tap(find.text('Technician A'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('assign-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-confirm')));
    await tester.pumpAndSettle();

    expect(api.assignCalls, hasLength(1));
    expect(api.assignCalls.single['reason'], isNull);
  });

  testWidgets('confirm without selection calls nothing', (tester) async {
    final api = _AssignFakeApi();
    await _openDialog(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    await tester.ensureVisible(find.byKey(const Key('assign-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-confirm')));
    await tester.pump();
    expect(api.assignCalls, isEmpty);
    expect(find.byType(WorkshopDialog), findsOneWidget);
  });

  testWidgets('only active technicians are listed', (tester) async {
    final api = _AssignFakeApi(
      staffMembers: const [
        _techA,
        StaffMember(
          userId: 'tech-disabled',
          displayName: 'Disabled Dana',
          emailMasked: 'd***@test.local',
          role: 'TECHNICIAN',
          status: 'DISABLED',
        ),
        StaffMember(
          userId: 'tech-moved',
          displayName: 'Moved Mona',
          emailMasked: 'm***@test.local',
          role: 'TECHNICIAN',
          status: 'TRANSFERRED',
        ),
        StaffMember(
          userId: 'admin-1',
          displayName: 'Admin Arjun',
          emailMasked: 'a***@test.local',
          role: 'WORKSHOP_ADMIN',
          status: 'ACTIVE',
        ),
      ],
    );
    await _openDialog(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    expect(find.text('Technician A'), findsOneWidget);
    expect(find.text('Disabled Dana'), findsNothing);
    expect(find.text('Moved Mona'), findsNothing);
    expect(find.text('Admin Arjun'), findsNothing);
  });

  testWidgets('empty staff shows the empty state', (tester) async {
    await _openDialog(
      tester,
      api: _AssignFakeApi(staffMembers: const []),
      locale: const Locale('en'),
      size: wide,
    );
    expect(find.text('No active technicians'), findsOneWidget);
    expect(find.byKey(const Key('assign-confirm')), findsOneWidget);
  });

  testWidgets('staff error retries into the tech list', (tester) async {
    final api = _AssignFakeApi(staffError: true);
    await _openDialog(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    expect(find.text('Something went wrong. Try again.'), findsWidgets);
    api.staffError = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Technician A'), findsOneWidget);
  });

  testWidgets('assign failure keeps the dialog open with feedback', (
    tester,
  ) async {
    final api = _AssignFakeApi(assignError: true);
    final opened = await _openDialog(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    await tester.tap(find.text('Technician A'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('assign-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-confirm')));
    await tester.pumpAndSettle();

    expect(api.assignCalls, hasLength(1));
    expect(opened.result.value, isNull);
    expect(find.byType(WorkshopDialog), findsOneWidget);
    expect(find.text('Action failed'), findsOneWidget);

    await tester.tap(find.byKey(const Key('assign-cancel')));
    await tester.pumpAndSettle();
    expect(opened.result.value, isNull);
    expect(find.byType(WorkshopDialog), findsNothing);
  });

  testWidgets('finalized jobs are rejected without calling assignJob', (
    tester,
  ) async {
    final api = _AssignFakeApi(
      job: const WorkshopJob(
        id: 'job-9',
        reference: 'JOB-TEST0009',
        status: 'FINALIZED',
        templateVersionId: 'version-1',
        templateName: 'Full inspection',
        templateVersionNo: 1,
        assignedTechnicianId: null,
        assignedTechnicianName: null,
        scheduledAt: '2026-11-05T09:00:00',
        customerName: 'Customer C',
        customerPhone: null,
        customerEmail: null,
        vehicleMake: 'Ford',
        vehicleModel: 'Transit',
        vehicleYear: null,
        vehicleVin: null,
        vehiclePlate: null,
        scope: 'Full inspection',
      ),
    );
    final opened = await _openDialog(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
      job: api.job,
    );
    expect(find.text('Technician A'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('assign-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-confirm')));
    await tester.pump();
    expect(api.assignCalls, isEmpty);
    expect(find.byType(WorkshopDialog), findsOneWidget);
    expect(opened.result.value, isNull);
  });

  testWidgets('escape closes the dialog with null', (tester) async {
    final opened = await _openDialog(
      tester,
      api: _AssignFakeApi(),
      locale: const Locale('en'),
      size: wide,
      tap: false,
    );
    unawaited(opened.key.currentState!.open());
    await tester.pumpAndSettle();
    expect(find.byType(WorkshopDialog), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(WorkshopDialog), findsNothing);
    expect(opened.result.value, isNull);
  });

  testWidgets('focus stays trapped and returns to the opener', (tester) async {
    final opened = await _openDialog(
      tester,
      api: _AssignFakeApi(),
      locale: const Locale('en'),
      size: wide,
      tap: false,
    );
    final state = opened.key.currentState!;
    state.openFocus.requestFocus();
    await tester.pump();
    unawaited(state.open());
    await tester.pumpAndSettle();
    expect(find.byType(WorkshopDialog), findsOneWidget);

    for (var i = 0; i < 60; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        _isInsideDialog(tester),
        isTrue,
        reason: 'focus escaped the dialog on tab $i',
      );
    }

    await tester.tap(find.byKey(const Key('assign-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkshopDialog), findsNothing);
    expect(opened.result.value, isNull);
    expect(state.openFocus.hasFocus, isTrue);
  });

  testWidgets('selected card exposes selected semantics and header', (
    tester,
  ) async {
    await _openDialog(
      tester,
      api: _AssignFakeApi(),
      locale: const Locale('en'),
      size: wide,
    );
    final dialogContext = tester.element(find.byType(WorkshopDialog));
    final l10n = AppLocalizations.of(dialogContext);
    expect(
      tester
          .getSemantics(find.text(l10n.assignTechnicianTitle))
          .flagsCollection
          .isHeader,
      isTrue,
    );
    await tester.tap(find.text('Technician B'));
    await tester.pump();
    final card = find.byKey(const Key('assign-tech-tech-2'));
    expect(
      tester.getSemantics(card).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(find.bySemanticsLabel('Close'), findsWidgets);
  });

  testWidgets('keyboard-only selection and confirm assigns the job', (
    tester,
  ) async {
    final api = _AssignFakeApi();
    final opened = await _openDialog(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
      tap: false,
    );
    final state = opened.key.currentState!;
    state.openFocus.requestFocus();
    await tester.pump();
    unawaited(state.open());
    await tester.pumpAndSettle();
    expect(find.byType(WorkshopDialog), findsOneWidget);

    final dialogContext = tester.element(find.byType(WorkshopDialog));
    final confirmLabel = AppLocalizations.of(dialogContext).confirm;

    var selected = false;
    for (var i = 0; i < 40 && !selected; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      if (_cardFocused(tester)) {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        selected =
            tester
                .getSemantics(find.byKey(const Key('assign-tech-tech-1')))
                .flagsCollection
                .isSelected ==
            Tristate.isTrue;
        if (!selected) {
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pump();
          selected =
              tester
                  .getSemantics(find.byKey(const Key('assign-tech-tech-1')))
                  .flagsCollection
                  .isSelected ==
              Tristate.isTrue;
        }
      }
    }
    expect(selected, isTrue);

    for (var i = 0; i < 80 && api.assignCalls.isEmpty; i++) {
      if (_confirmFocused(tester, confirmLabel)) {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(api.assignCalls, hasLength(1));
    expect(api.assignCalls.single['technicianId'], 'tech-1');
    expect(opened.result.value, 'tech-1');
    expect(find.byType(WorkshopDialog), findsNothing);
  });

  testWidgets('assign dialog renders no forbidden terms', (tester) async {
    await _openDialog(
      tester,
      api: _AssignFakeApi(),
      locale: const Locale('en'),
      size: wide,
    );
    final text = find.byType(Text)
        .evaluate()
        .map((element) => (element.widget as Text).data ?? '')
        .join('\n')
        .toLowerCase();
    const banned = [
      'certif',
      'specialist',
      'lead tech',
      'brakes l2',
      'powertrain',
      'skill',
      'workload',
      'availability',
      'bay 0',
      'auto-assign',
      'auto assign',
      'dispatch',
      'telematics',
      'telemetry',
      'recall',
      'est. ',
      'estimate',
      'stage 01',
      'ticket #',
      'approv',
      'review',
      'score',
      'gps',
    ];
    for (final term in banned) {
      expect(text.contains(term), isFalse, reason: 'forbidden term: $term');
    }
  });
}
