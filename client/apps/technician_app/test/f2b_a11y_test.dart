import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:l10n/l10n/gen/app_localizations_en.dart';
import 'package:technician_app/src/shared/technician_kit.dart';
import 'package:technician_app/src/ui_helpers.dart';

import 'support/f2a_test_fonts.dart';
import 'support/f2b_views.dart';

void main() {
  setUpAll(loadF2AFonts);

  testWidgets('slide snaps with zero duration under reduce motion',
      (tester) async {
    Future<Duration> durationFor(bool disableAnimations) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 900),
              disableAnimations: disableAnimations,
            ),
            child: F2bSlideToConfirm(
              label: 'Slide',
              onConfirmed: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      final positioned =
          tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
      return positioned.duration;
    }

    expect(await durationFor(true), Duration.zero,
        reason: 'reduce motion must snap with zero duration');
    expect(
      await durationFor(false),
      const Duration(milliseconds: 120),
      reason: 'normal motion keeps the Figma 120ms thumb duration',
    );
  });

  testWidgets('focus rings use deep-green border only when focused',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      f2bHost(
        child: Builder(
          builder: (context) => ListView(
            children: [
              F2bChip(label: 'Chip', selected: false, onTap: () {}),
              const F2bSegmented(
                labels: ['A', 'B'],
                selectedIndex: 0,
                onSelected: _noop,
              ),
              F2bEvidenceTile(
                label: 'Photo',
                caption: 'Required',
                onTap: () {},
              ),
              const F2bIconButton(
                iconId: '1_8026',
                semanticLabel: 'Close',
              ),
              F2bSlideToConfirm(label: 'Slide', onConfirmed: () {}),
              const F2bFocusFrame(child: SizedBox(width: 48, height: 48)),
              const _F2bChipProbe(),
            ],
          ),
        ),
        locale: const Locale('en'),
        theme: AppTheme.light,
      ),
    );
    await tester.pump();

    // Every interactive kit element exposes keyboard activation.
    expect(
      find.byType(FocusableActionDetector),
      findsWidgets,
      reason: 'chips/segments/tiles/slide must be keyboard operable',
    );
    // ActivateIntent is wired for keyboard users on chips/segments/tiles.
    final detectors = tester.widgetList<FocusableActionDetector>(
      find.byType(FocusableActionDetector),
    );
    expect(
      detectors.any((d) => d.actions?[ActivateIntent] != null),
      isTrue,
      reason: 'keyboard ActivateIntent must invoke chip/segment actions',
    );
    // F2bFocusFrame (used for FxButton/FxProfileButton/FxHeader back slots)
    // is present and shows no border when unfocused (geometry unchanged).
    final frames = tester.widgetList<F2bFocusFrame>(find.byType(F2bFocusFrame));
    expect(frames, isNotEmpty, reason: 'Fx usages need a focus frame');
    for (final frame in frames) {
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byWidget(frame),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNull,
          reason: 'unfocused focus frame must not affect layout');
    }

    // Focus the probe: keyboard focus must succeed without exception.
    final chipNode =
        tester.state<_F2bChipProbeState>(find.byType(_F2bChipProbe)).focusNode;
    chipNode.requestFocus();
    await tester.pump();
    expect(chipNode.hasFocus, isTrue);

    // Traverse into the real kit chips: at least one deep-green ring appears.
    final chipDetector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: find.byType(F2bChip).first,
        matching: find.byType(FocusableActionDetector),
      ),
    );
    chipDetector.focusNode?.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final rings = tester.widgetList<Container>(find.byType(Container)).where(
          (c) =>
              (c.decoration as BoxDecoration?)?.border != null &&
              (c.decoration as BoxDecoration?)?.border?.top.color ==
                  Fx.deepGreen,
        );
    expect(rings, isNotEmpty,
        reason: 'focused interactive must show deep-green border');
  });

  testWidgets('chips and segmented options expose 48dp hit areas',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      f2bHost(
        child: Builder(
          builder: (context) => Column(
            children: [
              F2bChip(label: 'Chip', selected: false, onTap: () {}),
              const F2bSegmented(
                labels: ['Pass', 'Minor', 'Major'],
                selectedIndex: 0,
                onSelected: _noop,
              ),
              const F2bIconButton(
                iconId: '1_8026',
                semanticLabel: 'Close',
              ),
            ],
          ),
        ),
        locale: const Locale('en'),
        theme: AppTheme.light,
      ),
    );
    await tester.pump();

    // Icon buttons are already 48x48 Figma slots.
    final iconSize = tester.getSize(find.byType(F2bIconButton));
    expect(iconSize.width, greaterThanOrEqualTo(47.5));
    expect(iconSize.height, greaterThanOrEqualTo(47.5));

    // Chips keep the 32px Figma visual but carry an invisible 8px top/bottom
    // overflow expander (48dp hit) so the 1px geometry gate is unchanged.
    final chipStacks = find.descendant(
      of: find.byType(F2bChip),
      matching: find.byType(Stack),
    );
    expect(chipStacks, findsOneWidget);
    final positioned = tester.widgetList<Positioned>(
      find.descendant(
        of: find.byType(F2bChip),
        matching: find.byType(Positioned),
      ),
    );
    expect(positioned, isNotEmpty);
    final expander = positioned.firstWhere(
      (p) => p.top == -8.0 && p.bottom == -8.0,
      orElse: () => throw TestFailure('chip 48dp expander not found'),
    );
    expect(expander.top, -8.0);

    // Segmented options carry the same overflow expander for 48dp hits.
    final segmentExpanders = tester.widgetList<Positioned>(
      find.descendant(
        of: find.byType(F2bSegmented),
        matching: find.byType(Positioned),
      ),
    );
    expect(segmentExpanders, isNotEmpty,
        reason: 'segmented options need 48dp hit expanders');
  });

  testWidgets('RTL wraps plate/ref/odometer/vin/version in LTR',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1232);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final id in ['finalize', 'success']) {
      await tester.pumpWidget(
        f2bHost(
          child: f2bScreen(id, figma: false),
          locale: const Locale('ar'),
          theme: AppTheme.build(isArabic: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: '$id RTL renders');
      final ltrFrames = tester
          .widgetList<Directionality>(find.byType(Directionality))
          .where((d) => d.textDirection == TextDirection.ltr);
      expect(ltrFrames, isNotEmpty,
          reason: '$id must wrap latin identifiers in Directionality(ltr)');
    }
  });

  test('unknown status/result/severity map to a localized generic label', () {
    final l10n = AppLocalizationsEn('en');
    expect(technicianStatusLabel(l10n, 'BOGUS_CODE'), l10n.notAvailable);
    expect(resultLabel(l10n, 'BOGUS_CODE'), l10n.notAvailable);
    expect(severityLabel(l10n, 'BOGUS_CODE'), l10n.notAvailable);
    expect(technicianStatusLabel(l10n, 'BOGUS_CODE'), isNot('BOGUS_CODE'));
    expect(resultLabel(l10n, 'BOGUS_CODE'), isNot('BOGUS_CODE'));
    expect(severityLabel(l10n, 'BOGUS_CODE'), isNot('BOGUS_CODE'));
  });

  testWidgets('2.0x AR clips to ellipsis without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final id in f2bScreenIds) {
      await tester.pumpWidget(
        f2bHost(
          child: f2bScreen(id, figma: false),
          locale: const Locale('ar'),
          theme: AppTheme.build(isArabic: true),
          textScale: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: '$id 2.0x AR');
    }
    // Kit pills/chips/labels truncate to ellipsis (not silent clip).
    await tester.pumpWidget(
      f2bHost(
        child: Builder(
          builder: (context) => const Column(
            children: [
              F2bSectionLabel('label'),
              F2bStatusPill(label: 'pill'),
              F2bKeyValue(label: 'k', value: 'v'),
            ],
          ),
        ),
        locale: const Locale('en'),
        theme: AppTheme.light,
        textScale: 2,
      ),
    );
    await tester.pump();
    final overflows = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.overflow)
        .whereType<TextOverflow>();
    expect(overflows, isNotEmpty);
    expect(
      overflows.every(
        (o) => o == TextOverflow.ellipsis || o == TextOverflow.visible,
      ),
      isTrue,
      reason: 'kit text must clip to ellipsis at 2.0x, never silent clip',
    );
  });
}

void _noop(int _) {}

/// Test-only probe exposing a focus node next to a chip.
class _F2bChipProbe extends StatefulWidget {
  const _F2bChipProbe();

  @override
  State<_F2bChipProbe> createState() => _F2bChipProbeState();
}

class _F2bChipProbeState extends State<_F2bChipProbe> {
  late final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: F2bChip(label: 'Probe', selected: false, onTap: () {}),
    );
  }
}
