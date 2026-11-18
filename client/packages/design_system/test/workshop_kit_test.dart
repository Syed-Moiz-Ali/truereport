import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1280, 800),
  bool isArabic = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(isArabic: isArabic),
      home: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkshopTokens', () {
    testWidgets('registers the workshop palette and type scale', (
      tester,
    ) async {
      late WorkshopTokens tokens;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            tokens = context.ws;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(tokens.canvas, const Color(0xFFF7F5F1));
      expect(tokens.surface, const Color(0xFFFFFFFF));
      expect(tokens.ink, const Color(0xFF1B1C19));
      expect(tokens.border, const Color(0xFFE6E2DA));
      expect(tokens.accent, const Color(0xFF0B6B4F));
      expect(tokens.cardRadius, 14);
      expect(tokens.controlRadius, 10);
      expect(tokens.controlHeight, 46);
      expect(tokens.touchTarget, 44);
      expect(tokens.pageTitle.fontSize, 30);
      expect(tokens.pageTitle.fontWeight, FontWeight.w700);
      expect(tokens.meta.fontSize, 12.5);
      expect(tokens.eyebrow.letterSpacing, 0.6);
      // The token is the source of truth: pageGutterDesktop = 32.
      expect(tokens.pageGutter(1200), 32);
      expect(tokens.pageGutter(800), 20);
      expect(tokens.pageGutter(390), 16);
    });

    testWidgets('Arabic drops letter spacing', (tester) async {
      late WorkshopTokens tokens;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            tokens = context.ws;
            return const SizedBox.shrink();
          },
        ),
        isArabic: true,
      );
      expect(tokens.eyebrow.letterSpacing, 0);
      expect(tokens.pageTitle.letterSpacing, 0);
    });
  });

  group('WorkshopButton', () {
    testWidgets('primary renders 46 high and taps', (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        Center(
          child: WorkshopButton(
            key: const Key('primary'),
            label: 'Create job',
            onPressed: () => pressed++,
          ),
        ),
      );
      final size = tester.getSize(find.byKey(const Key('primary')));
      expect(size.height, 46);
      expect(find.text('Create job'), findsOneWidget);
      await tester.tap(find.byKey(const Key('primary')));
      expect(pressed, 1);
    });

    testWidgets('loading disables the action and shows progress', (
      tester,
    ) async {
      var pressed = 0;
      await _pump(
        tester,
        Center(
          child: WorkshopButton(
            key: const Key('loading'),
            label: 'Saving',
            isLoading: true,
            onPressed: () => pressed++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('loading')));
      expect(pressed, 0);
    });

    testWidgets('variants expand full width', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: WorkshopButton(
            key: const Key('expand'),
            label: 'Continue',
            expand: true,
            variant: WorkshopButtonVariant.secondary,
            onPressed: () {},
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('expand'))).width, 320);
    });
  });

  group('WorkshopFilterChip', () {
    testWidgets('renders the count inside the label', (tester) async {
      await _pump(
        tester,
        Center(
          child: WorkshopFilterChip(
            label: 'All',
            count: 3,
            selected: true,
            onTap: () {},
          ),
        ),
      );
      expect(find.text('All (3)'), findsOneWidget);
    });
  });

  group('WorkshopStatusBadge', () {
    testWidgets('renders the label next to the dot', (tester) async {
      await _pump(
        tester,
        const Center(
          child: WorkshopStatusBadge(
            label: 'Ready',
            tone: WorkshopStatusTone.success,
          ),
        ),
      );
      expect(find.text('Ready'), findsOneWidget);
    });

    testWidgets('uses an icon when provided', (tester) async {
      await _pump(
        tester,
        const Center(
          child: WorkshopStatusBadge(
            label: 'Overdue',
            tone: WorkshopStatusTone.danger,
            icon: Icons.warning_amber_rounded,
          ),
        ),
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });
  });

  group('WorkshopAccountMenu', () {
    testWidgets('opens with full account data and wired actions', (
      tester,
    ) async {
      var settings = 0;
      var signOut = 0;
      var toggled = 0;
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 280,
            child: WorkshopAccountMenu(
              initials: 'LH',
              displayName: 'Layla Haddad',
              email: 'layla.haddad@example-workshop.test',
              onSettings: () => settings++,
              onSignOut: () => signOut++,
              onToggleLanguage: () => toggled++,
              languageLabel: 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(WorkshopAvatar));
      await tester.pumpAndSettle();

      expect(find.text('Layla Haddad'), findsWidgets);
      expect(find.text('layla.haddad@example-workshop.test'), findsWidgets);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(settings, 1);

      await tester.tap(find.byType(WorkshopAvatar));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©'));
      await tester.pumpAndSettle();
      expect(toggled, 1);

      await tester.tap(find.byType(WorkshopAvatar));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(signOut, 1);
    });
  });

  group('WorkshopTextField', () {
    testWidgets('forwards its key to the inner TextFormField', (tester) async {
      final controller = TextEditingController(text: 'typed');
      addTearDown(controller.dispose);
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 360,
            child: WorkshopTextField(
              key: const Key('email-field'),
              controller: controller,
              label: 'Email',
            ),
          ),
        ),
      );
      final field = tester.widget<TextFormField>(
        find.byKey(const Key('email-field')),
      );
      expect(field.controller, controller);
    });

    testWidgets('shows the validator error', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: WorkshopTextField(
                controller: controller,
                label: 'Email',
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
            ),
          ),
        ),
      );
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
    });
  });

  group('WorkshopSearchField', () {
    testWidgets('is capped at 360 px', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        Row(
          children: [
            WorkshopSearchField(
              controller: controller,
              hint: 'Search jobs',
              semanticLabel: 'Search jobs',
            ),
          ],
        ),
      );
      expect(
        tester.getSize(find.byType(WorkshopSearchField)).width,
        lessThanOrEqualTo(360),
      );
    });
  });

  group('WorkshopMetricStrip', () {
    testWidgets('renders one strip with every metric', (tester) async {
      await _pump(
        tester,
        const Center(
          child: SizedBox(
            width: 900,
            child: WorkshopMetricStrip(
              items: [
                WorkshopMetric(label: 'Active', value: '12'),
                WorkshopMetric(label: 'Ready', value: '4'),
                WorkshopMetric(label: 'Done', value: '9'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
    });
  });

  group('WorkshopPageHeader', () {
    testWidgets('keeps actions beside the title when wide', (tester) async {
      await _pump(
        tester,
        Padding(
          padding: const EdgeInsets.all(24),
          child: WorkshopPageHeader(
            title: 'Jobs',
            subtitle: 'All workshop jobs',
            primaryAction: WorkshopButton(
              key: const Key('primary-action'),
              label: 'New job',
              onPressed: () {},
            ),
          ),
        ),
      );
      final titleY = tester.getCenter(find.text('Jobs')).dy;
      final actionY = tester
          .getCenter(find.byKey(const Key('primary-action')))
          .dy;
      expect((titleY - actionY).abs(), lessThan(24));
    });

    testWidgets('stacks and stretches the primary action on phones', (
      tester,
    ) async {
      await _pump(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: WorkshopPageHeader(
            title: 'Jobs',
            primaryAction: WorkshopButton(
              key: const Key('primary-action'),
              label: 'New job',
              onPressed: () {},
            ),
          ),
        ),
        size: const Size(390, 844),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('primary-action'))).dy,
        greaterThan(tester.getBottomLeft(find.text('Jobs')).dy),
      );
      expect(
        tester.getSize(find.byKey(const Key('primary-action'))).width,
        358,
      );
    });
  });

  group('WorkshopPageScroll', () {
    testWidgets('centres content at the token width and applies the page gutter', (
      tester,
    ) async {
      await _pump(
        tester,
        const WorkshopPageScroll(
          children: [
            SizedBox(key: Key('content'), height: 400, child: SizedBox()),
          ],
        ),
        size: const Size(1600, 900),
      );
      expect(tester.getSize(find.byKey(const Key('content'))).width, 1200);
      final left = tester.getTopLeft(find.byKey(const Key('content'))).dx;
      expect(left, (1600 - 1200) / 2);
    });
  });

  group('WorkshopToolbar', () {
    testWidgets('stacks search above filters on phones', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: WorkshopToolbar(
            search: WorkshopSearchField(
              controller: controller,
              hint: 'Search',
              semanticLabel: 'Search',
            ),
            filters: [
              WorkshopFilterChip(label: 'All', selected: true, onTap: () {}),
            ],
          ),
        ),
        size: const Size(390, 844),
      );
      expect(
        tester.getTopLeft(find.byType(WorkshopFilterChip)).dy,
        greaterThan(tester.getBottomLeft(find.byType(WorkshopSearchField)).dy),
      );
    });
  });

  group('Workshop states', () {
    testWidgets('empty state renders title, body and action', (tester) async {
      await _pump(
        tester,
        WorkshopEmptyState(
          title: 'No jobs',
          body: 'Create a job to start.',
          action: WorkshopButton(label: 'New job', onPressed: () {}),
        ),
      );
      expect(find.text('No jobs'), findsOneWidget);
      expect(find.text('Create a job to start.'), findsOneWidget);
      expect(find.text('New job'), findsOneWidget);
    });

    testWidgets('error state retries', (tester) async {
      var retried = 0;
      await _pump(
        tester,
        WorkshopErrorState(
          title: 'Could not load',
          body: 'Try again.',
          retryLabel: 'Retry',
          onRetry: () => retried++,
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });

    testWidgets('skeleton renders line blocks', (tester) async {
      await _pump(tester, const WorkshopSkeleton(lines: 3));
      expect(find.byType(Container), findsWidgets);
    });
  });
}
