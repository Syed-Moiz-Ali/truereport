import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void _noop() {}

void _ignoreString(String value) {}

class _TableRow {
  const _TableRow(this.id, this.status);

  final String id;
  final String status;
}

class _MatrixContent extends StatefulWidget {
  const _MatrixContent();

  @override
  State<_MatrixContent> createState() => _MatrixContentState();
}

class _MatrixContentState extends State<_MatrixContent> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _segment = 'Week';
  bool _isArabic = false;
  InspectionResult _result = InspectionResult.noIssueObserved;

  @override
  void dispose() {
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(label: 'Primary', onPressed: _noop),
              AppButton(
                label: 'Tonal',
                onPressed: _noop,
                variant: AppButtonVariant.tonal,
              ),
              AppButton(
                label: 'Text',
                onPressed: _noop,
                variant: AppButtonVariant.text,
              ),
              AppButton(
                label: 'Delete',
                onPressed: _noop,
                variant: AppButtonVariant.destructive,
              ),
              AppButton(label: 'Loading', onPressed: _noop, isLoading: true),
              AppButton(label: 'Disabled', onPressed: null),
              AppIconButton(
                icon: Icons.edit_outlined,
                semanticLabel: 'Edit',
                onPressed: _noop,
              ),
              AppIconButton(
                icon: Icons.delete_outline,
                semanticLabel: 'Delete',
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'name@example.com',
          ),
          const SizedBox(height: 16),
          AppTextField(controller: _noteController, label: 'Note', maxLines: 3),
          const SizedBox(height: 16),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inspection summary'),
                SizedBox(height: 8),
                Text('Coverage and findings for the current job.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppTonalCard(child: Text('Offline ready')),
          const SizedBox(height: 16),
          const AppStatCard(
            label: 'Coverage',
            value: '62%',
            caption: '12 of 19 items',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tone in StatusTone.values)
                StatusChip(label: tone.name, tone: tone),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final severity in AppSeverity.values)
                SeverityBadge(label: severity.name, appSeverity: severity),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const AppSelectableText(
                label: 'Selected',
                selected: true,
                onTap: _noop,
              ),
              const AppSelectableText(
                label: 'Unselected',
                selected: false,
                onTap: _noop,
              ),
              AppFilterChip(
                label: 'Filter',
                selected: true,
                onSelected: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSegmentedControl<String>(
            segments: const [
              AppSegment<String>(value: 'Day', label: 'Day'),
              AppSegment<String>(value: 'Week', label: 'Week'),
              AppSegment<String>(value: 'Month', label: 'Month'),
            ],
            selected: _segment,
            onChanged: (value) => setState(() => _segment = value),
          ),
          const SizedBox(height: 16),
          AppLanguageSwitch(
            englishLabel: 'English',
            arabicLabel: 'العربية',
            isArabic: _isArabic,
            onChanged: (value) => setState(() => _isArabic = value),
          ),
          const SizedBox(height: 16),
          InspectionResultSelector(
            groupLabel: 'Inspection result',
            selected: _result,
            labelBuilder: (result) => result.name,
            onChanged: (value) => setState(() => _result = value),
          ),
          const SizedBox(height: 16),
          const AppProgressRing(value: 0.62, label: '62%'),
          const SizedBox(height: 16),
          const AppCoverageBar(covered: 12, total: 19, label: 'Coverage'),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Section', subtitle: 'Subtitle'),
          const AppListTile(
            title: 'List row',
            subtitle: 'Subtitle',
            onTap: _noop,
          ),
          const SizedBox(height: 16),
          const EmptyState(
            title: 'No jobs yet',
            body: 'Assign a job to start an inspection.',
            action: AppButton(
              label: 'Refresh',
              onPressed: _noop,
              variant: AppButtonVariant.tonal,
            ),
          ),
          const SizedBox(height: 16),
          const ErrorState(
            title: 'Could not load jobs',
            body: 'Check your connection and try again.',
            retryLabel: 'Retry',
            onRetry: _noop,
          ),
          const SizedBox(height: 16),
          const OfflineBanner(
            message: 'Offline. Changes are saved on this device.',
          ),
          const SizedBox(height: 16),
          const LoadingSkeleton(lines: 3),
          const SizedBox(height: 16),
          AppBottomNavDock(
            selectedIndex: 0,
            onSelected: (_) {},
            items: const [
              AppBottomNavItem(label: 'Jobs', icon: Icons.work_outline),
              AppBottomNavItem(
                label: 'Inspect',
                icon: Icons.checklist_outlined,
              ),
              AppBottomNavItem(label: 'Sync', icon: Icons.cloud_outlined),
              AppBottomNavItem(label: 'Profile', icon: Icons.person_outline),
            ],
          ),
          const SizedBox(height: 16),
          AppDataTable<_TableRow>(
            columns: [
              AppDataColumn<_TableRow>(
                label: 'Job',
                cellBuilder: (context, row, index) => Text(row.id),
              ),
              AppDataColumn<_TableRow>(
                label: 'Status',
                cellBuilder: (context, row, index) =>
                    StatusChip(label: row.status, tone: StatusTone.info),
              ),
            ],
            rows: const [
              _TableRow('TR-1042', 'In progress'),
              _TableRow('TR-1043', 'Finalized'),
            ],
          ),
          const SizedBox(height: 16),
          const AppTreeView<String>(
            initiallyExpanded: {'root'},
            onSelected: _ignoreString,
            roots: [
              AppTreeNode<String>(
                data: 'root',
                label: 'Root',
                children: [AppTreeNode<String>(data: 'child', label: 'Child')],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(
            height: 400,
            child: AdminShell(
              title: 'TrueReport Admin',
              brand: Text('TrueReport'),
              items: [
                AdminNavItem(
                  label: 'Overview',
                  icon: Icons.space_dashboard_outlined,
                  selected: true,
                  onTap: _noop,
                ),
                AdminNavItem(
                  label: 'Jobs',
                  icon: Icons.work_outline,
                  selected: false,
                  onTap: _noop,
                ),
              ],
              child: Text('Admin content'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  bool isArabic = false,
  double textScale = 1,
  Size size = const Size(390, 844),
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final theme = AppTheme.build(brightness: brightness, isArabic: isArabic);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('en'),
      home: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            devicePixelRatio: 1,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _GoldenVariant {
  const _GoldenVariant(this.name, this.isArabic, this.brightness);

  final String name;
  final bool isArabic;
  final Brightness brightness;
}

const _goldenVariants = <_GoldenVariant>[
  _GoldenVariant('en_light', false, Brightness.light),
  _GoldenVariant('en_dark', false, Brightness.dark),
  _GoldenVariant('ar_light', true, Brightness.light),
  _GoldenVariant('ar_dark', true, Brightness.dark),
];

const _goldenBoundaryKey = ValueKey<String>('golden-boundary');

Future<void> _pumpGolden(
  WidgetTester tester,
  Widget child,
  _GoldenVariant variant,
) async {
  const width = 390.0;
  const height = 200.0;
  tester.view.physicalSize = const Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final theme = AppTheme.build(
    brightness: variant.brightness,
    isArabic: variant.isArabic,
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('en'),
      home: Directionality(
        textDirection: variant.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(width, height),
            devicePixelRatio: 1,
          ),
          child: RepaintBoundary(
            key: _goldenBoundaryKey,
            child: Material(
              color: theme.colorScheme.surface,
              child: SizedBox(width: width, height: height, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _goldenButton(_GoldenVariant variant) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 300,
        child: AppButton(
          label: variant.isArabic ? 'متابعة' : 'Sign In',
          icon: Icons.arrow_forward,
          onPressed: _noop,
          expand: true,
        ),
      ),
    ),
  );
}

Widget _goldenCard(_GoldenVariant variant) {
  return Center(
    child: SizedBox(
      width: 320,
      child: Builder(
        builder: (context) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                variant.isArabic ? 'حالة التسليم' : 'Delivery status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                variant.isArabic ? 'رابط التقرير' : 'Report link',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              StatusChip(
                label: variant.isArabic ? 'أُرسل' : 'Sent',
                tone: StatusTone.success,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _goldenChips(_GoldenVariant variant) {
  return Center(
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StatusChip(
          label: variant.isArabic ? 'نجاح' : 'Success',
          tone: StatusTone.success,
        ),
        SeverityBadge(
          label: variant.isArabic ? 'رئيسي' : 'Major',
          appSeverity: AppSeverity.major,
        ),
        SeverityBadge(
          label: variant.isArabic ? 'حرج' : 'Safety critical',
          appSeverity: AppSeverity.safetyCritical,
        ),
      ],
    ),
  );
}

Widget _goldenSelector(_GoldenVariant variant) {
  final labels = <InspectionResult, String>{
    InspectionResult.noIssueObserved: variant.isArabic
        ? 'لا توجد ملاحظة'
        : 'No issue observed',
    InspectionResult.attentionRecommended: variant.isArabic
        ? 'انتباه'
        : 'Attention recommended',
    InspectionResult.defectFound: variant.isArabic ? 'عيب' : 'Defect found',
  };
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: InspectionResultSelector(
        results: const [
          InspectionResult.noIssueObserved,
          InspectionResult.attentionRecommended,
          InspectionResult.defectFound,
        ],
        selected: InspectionResult.noIssueObserved,
        labelBuilder: (result) => labels[result]!,
        onChanged: (_) {},
      ),
    ),
  );
}

Widget _goldenDock(_GoldenVariant variant) {
  return Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: AppBottomNavDock(
        selectedIndex: 0,
        onSelected: (_) {},
        items: [
          AppBottomNavItem(
            label: variant.isArabic ? 'المهام' : 'Jobs',
            icon: Icons.work_outline,
          ),
          AppBottomNavItem(
            label: variant.isArabic ? 'فحص' : 'Inspect',
            icon: Icons.checklist_outlined,
          ),
          AppBottomNavItem(
            label: variant.isArabic ? 'مزامنة' : 'Sync',
            icon: Icons.cloud_outlined,
          ),
          AppBottomNavItem(
            label: variant.isArabic ? 'الملف' : 'Profile',
            icon: Icons.person_outline,
          ),
        ],
      ),
    ),
  );
}

Directory _repoRoot() {
  var directory = Directory.current;
  for (var attempt = 0; attempt < 12; attempt += 1) {
    final hasClient = Directory(
      '${directory.path}${Platform.pathSeparator}client',
    ).existsSync();
    final hasDocs = Directory('${directory.path}${Platform.pathSeparator}docs')
        .existsSync();
    if (hasClient && hasDocs) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      break;
    }
    directory = parent;
  }
  throw StateError('Could not find the repository root.');
}

String? _familyFor(String fileName) {
  if (fileName.startsWith('PlusJakartaSans')) return 'Plus Jakarta Sans';
  if (fileName.startsWith('NotoSansArabic')) return 'Noto Sans Arabic';
  if (fileName.startsWith('IBMPlexSansArabic')) {
    return 'IBM Plex Sans Arabic';
  }
  if (fileName.startsWith('NotoSans-')) return 'Noto Sans';
  return null;
}

Future<void> _loadBundledFonts() async {
  final fontDirectory = Directory(
    '${_repoRoot().path}${Platform.pathSeparator}client'
    '${Platform.pathSeparator}packages${Platform.pathSeparator}design_system'
    '${Platform.pathSeparator}assets${Platform.pathSeparator}fonts',
  );
  if (!fontDirectory.existsSync()) {
    return;
  }
  final loaders = <String, FontLoader>{};
  for (final entity in fontDirectory.listSync()) {
    if (entity is! File) {
      continue;
    }
    final family = _familyFor(entity.uri.pathSegments.last);
    if (family == null) {
      continue;
    }
    final bytes = entity.readAsBytesSync();
    loaders
        .putIfAbsent(family, () => FontLoader(family))
        .addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  for (final loader in loaders.values) {
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadBundledFonts);

  group('component matrix', () {
    const widths = <double>[390, 600, 900, 1280];
    const scales = <double>[1, 1.5, 2];
    for (final isArabic in const <bool>[false, true]) {
      for (final brightness in Brightness.values) {
        for (final width in widths) {
          for (final scale in scales) {
            final name =
                '${isArabic ? 'ar' : 'en'} ${brightness.name} '
                'w${width.toInt()} scale$scale';
            testWidgets('$name renders without exceptions', (tester) async {
              await _pump(
                tester,
                const _MatrixContent(),
                brightness: brightness,
                isArabic: isArabic,
                textScale: scale,
                size: Size(width, 844),
              );
              expect(tester.takeException(), isNull);
              if (isArabic) {
                expect(
                  Directionality.of(
                    tester.element(find.byType(_MatrixContent)),
                  ),
                  TextDirection.rtl,
                );
              }
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump();
            });
          }
        }
      }
    }
  });

  group('target sizes', () {
    testWidgets('AppButton is at least 56 high', (tester) async {
      await _pump(
        tester,
        const Center(
          child: AppButton(label: 'Continue', onPressed: _noop),
        ),
      );
      expect(
        tester.getSize(find.byType(AppButton)).height,
        greaterThanOrEqualTo(56),
      );
    });

    testWidgets('AppIconButton is at least 48 high', (tester) async {
      await _pump(
        tester,
        const Center(
          child: AppIconButton(
            icon: Icons.edit_outlined,
            semanticLabel: 'Edit',
            onPressed: _noop,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AppIconButton)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('AppTextField is at least 56 high', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 320,
            child: AppTextField(controller: controller, label: 'Email'),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AppTextField)).height,
        greaterThanOrEqualTo(56),
      );
    });

    testWidgets('AppSegmentedControl is at least 48 high', (tester) async {
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 360,
            child: AppSegmentedControl<String>(
              segments: const [
                AppSegment<String>(value: 'Day', label: 'Day'),
                AppSegment<String>(value: 'Week', label: 'Week'),
                AppSegment<String>(value: 'Month', label: 'Month'),
              ],
              selected: 'Week',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AppSegmentedControl<String>)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('AppLanguageSwitch is at least 48 high', (tester) async {
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 320,
            child: AppLanguageSwitch(
              englishLabel: 'English',
              arabicLabel: 'العربية',
              isArabic: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AppLanguageSwitch)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('AppBottomNavDock items are at least 48 high', (tester) async {
      await _pump(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: AppBottomNavDock(
            selectedIndex: 0,
            onSelected: (_) {},
            items: const [
              AppBottomNavItem(label: 'Jobs', icon: Icons.work_outline),
              AppBottomNavItem(
                label: 'Inspect',
                icon: Icons.checklist_outlined,
              ),
              AppBottomNavItem(label: 'Sync', icon: Icons.cloud_outlined),
              AppBottomNavItem(label: 'Profile', icon: Icons.person_outline),
            ],
          ),
        ),
      );
      final items = find.descendant(
        of: find.byType(AppBottomNavDock),
        matching: find.byType(InkWell),
      );
      expect(items, findsNWidgets(4));
      for (var index = 0; index < 4; index += 1) {
        expect(
          tester.getSize(items.at(index)).height,
          greaterThanOrEqualTo(48),
        );
      }
    });

    testWidgets('AppListTile is at least 48 high', (tester) async {
      await _pump(
        tester,
        const Center(
          child: SizedBox(
            width: 320,
            child: AppListTile(title: 'Row', onTap: _noop),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AppListTile)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('InspectionResultSelector options are at least 48 high', (
      tester,
    ) async {
      await _pump(
        tester,
        InspectionResultSelector(
          selected: InspectionResult.noIssueObserved,
          labelBuilder: (result) => result.name,
          onChanged: (_) {},
        ),
      );
      final options = find.descendant(
        of: find.byType(InspectionResultSelector),
        matching: find.byType(InkWell),
      );
      expect(options, findsNWidgets(InspectionResult.values.length));
      for (var index = 0; index < InspectionResult.values.length; index += 1) {
        expect(
          tester.getSize(options.at(index)).height,
          greaterThanOrEqualTo(48),
        );
      }
    });
  });

  group('RTL', () {
    testWidgets('known Arabic labels render without overflow', (tester) async {
      await _pump(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(label: 'متابعة', onPressed: _noop),
            SizedBox(height: 8),
            StatusChip(label: 'نجاح', tone: StatusTone.success),
          ],
        ),
        isArabic: true,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('متابعة'), findsOneWidget);
      expect(find.text('نجاح'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('متابعة'))),
        TextDirection.rtl,
      );
    });
  });

  group('reduced motion', () {
    testWidgets('LoadingSkeleton stops repeating and settles', (tester) async {
      await _pump(
        tester,
        const SizedBox(width: 320, child: LoadingSkeleton(lines: 4)),
        disableAnimations: true,
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('focus', () {
    testWidgets('AppTextField focus is applied and shows the focus token', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 320,
            child: AppTextField(
              controller: controller,
              label: 'Email',
              focusNode: focusNode,
            ),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
      final containers = tester.widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(AppTextField),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(containers, isNotEmpty);
      final hasFocusRing = containers.any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration &&
            decoration.boxShadow != null &&
            decoration.boxShadow!.isNotEmpty;
      });
      expect(
        hasFocusRing,
        isTrue,
        reason: 'AppTextField should paint the focus token while focused.',
      );
    });
  });

  group('semantics', () {
    testWidgets('labels and selected states are exposed', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StatusChip(label: 'Success', tone: StatusTone.success),
            const AppSelectableText(
              label: 'No issue',
              selected: true,
              onTap: _noop,
            ),
            InspectionResultSelector(
              groupLabel: 'Inspection result',
              selected: InspectionResult.noIssueObserved,
              labelBuilder: (result) =>
                  result == InspectionResult.noIssueObserved
                  ? 'No issue observed'
                  : result.name,
              onChanged: (_) {},
            ),
          ],
        ),
      );

      final status = tester
          .getSemantics(find.byType(StatusChip))
          .getSemanticsData();
      expect(status.label, 'Success');

      final selectable = tester
          .getSemantics(find.byType(AppSelectableText))
          .getSemanticsData();
      expect(selectable.label, contains('No issue'));
      expect(selectable.flagsCollection.isSelected, Tristate.isTrue);

      final group = tester
          .getSemantics(find.byType(InspectionResultSelector))
          .getSemanticsData();
      expect(group.label, 'Inspection result');

      final option = tester
          .getSemantics(find.bySemanticsLabel('No issue observed'))
          .getSemanticsData();
      expect(option.label, 'No issue observed');
      expect(option.flagsCollection.isSelected, Tristate.isTrue);

      handle.dispose();
    });
  });

  group('goldens', () {
    for (final variant in _goldenVariants) {
      testWidgets('AppButton ${variant.name}', (tester) async {
        await _pumpGolden(tester, _goldenButton(variant), variant);
        await expectLater(
          find.byKey(_goldenBoundaryKey),
          matchesGoldenFile('goldens/app_button_${variant.name}.png'),
        );
      });

      testWidgets('AppCard ${variant.name}', (tester) async {
        await _pumpGolden(tester, _goldenCard(variant), variant);
        await expectLater(
          find.byKey(_goldenBoundaryKey),
          matchesGoldenFile('goldens/app_card_${variant.name}.png'),
        );
      });

      testWidgets('StatusChip and SeverityBadge ${variant.name}', (
        tester,
      ) async {
        await _pumpGolden(tester, _goldenChips(variant), variant);
        await expectLater(
          find.byKey(_goldenBoundaryKey),
          matchesGoldenFile('goldens/status_chip_${variant.name}.png'),
        );
      });

      testWidgets('InspectionResultSelector ${variant.name}', (tester) async {
        await _pumpGolden(tester, _goldenSelector(variant), variant);
        await expectLater(
          find.byKey(_goldenBoundaryKey),
          matchesGoldenFile(
            'goldens/inspection_result_selector_${variant.name}.png',
          ),
        );
      });

      testWidgets('AppBottomNavDock ${variant.name}', (tester) async {
        await _pumpGolden(tester, _goldenDock(variant), variant);
        await expectLater(
          find.byKey(_goldenBoundaryKey),
          matchesGoldenFile('goldens/app_bottom_nav_dock_${variant.name}.png'),
        );
      });
    }
  });
}
