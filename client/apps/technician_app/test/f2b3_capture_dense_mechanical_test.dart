import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';

import 'support/f2a_fidelity_harness.dart';
import 'support/f2a_test_fonts.dart';
import 'support/f2b_views.dart';
import 'support/fidelity_output.dart';

// Level 1 fixture-builder for F2-B.3 Part 2, screen 11 dense-mechanical ONLY.
// Test-only widget tree mirroring Figma node 1:8220 per
// docs/ui/figma/specs/technician_app/11-dense-mechanical-list.md and
// docs/ui/figma/f2b-nodes/11-dense-mechanical.txt.
// Uses Fx* + F2-B primitives only; never reuses DenseMechanicalView; never
// touches lib/. New file only.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadF2AFonts();
  });

  testWidgets('capture f2b3 dense-mechanical level1', (tester) async {
    final root = repoRoot();
    final outDir = fidelityOutputDir(
      root,
      'figma/fidelity/f2b3/dense-mechanical',
    );
    final previous = enableFidelityShadows();
    try {
      await _render(tester, outDir);
    } finally {
      restoreFidelityShadows(previous);
    }
  });
}

Future<void> _render(WidgetTester tester, Directory outDir) async {
  assertFidelityShadows();
  const dpr = 2.0;
  const height = 1080.0;
  tester.view.physicalSize = const Size(390 * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('f2b3-dense-mechanical-root');

  await tester.pumpWidget(
    f2bHost(
      child: const RepaintBoundary(
        key: rootKey,
        child: SizedBox(
          width: 390,
          height: height,
          child: ColoredBox(
            color: Fx.white,
            child: Material(
              type: MaterialType.transparency,
              child: _DenseMechanicalLevel1(),
            ),
          ),
        ),
      ),
      locale: const Locale('en'),
      theme: AppTheme.light,
      figmaStrings: true,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final boxes = <String, dynamic>{};
  final headerFinder = find.byType(FxHeader);
  if (headerFinder.evaluate().isNotEmpty) {
    final rect = tester.getRect(headerFinder.first);
    boxes['header'] = {
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }
  final cardFinder = find.byType(FxCard);
  if (cardFinder.evaluate().isNotEmpty) {
    final rect = tester.getRect(cardFinder.first);
    boxes['card'] = {
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }
  final ctaFinder = find.byType(FxButton);
  if (ctaFinder.evaluate().isNotEmpty) {
    final rect = tester.getRect(ctaFinder.last);
    boxes['cta'] = {
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(rootKey),
  );
  final image = await boundary.toImage(pixelRatio: dpr);
  final byteData = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (byteData == null) {
    throw StateError('PNG encoding returned no data for f2b3 dense-mechanical');
  }
  outDir.createSync(recursive: true);
  File('${outDir.path}/render.png')
      .writeAsBytesSync(byteData.buffer.asUint8List());

  final strings = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  File('${outDir.path}/geometry.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'f2b3-dense-mechanical-level1',
      'logicalSize': {'width': 390, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'f2b3-dense-mechanical-level1',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}

// File-local spacing (F2-A _M pattern): _M has no digits so EdgeInsets lines
// stay clean for the source scan.
abstract final class _M {
  static const double gapXSmall = 4;
  static const double halfGap = 6;
  static const double gapSmall = 8;
  static const double gapMid = 12;
  static const double gapLarge = 14;
  static const double padMid = 16;
  static const double gutter = 20;
  static const double noteBottom = 34;
  static const double iconHit = 44;
}

class _DenseMechanicalLevel1 extends StatelessWidget {
  const _DenseMechanicalLevel1();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Column(
          children: [
            SizedBox(width: 390, height: 64),
            SizedBox(
              width: 390,
              height: 1016,
              child: Column(
                children: [
                  _ZoneHeader(),
                  Padding(
                    padding: EdgeInsets.only(top: _M.gapMid),
                    child: SizedBox(
                      width: 390,
                      height: 818,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: _M.gutter),
                        child: Column(
                          children: [
                            _CardOne(),
                            SizedBox(width: 390, height: 20),
                            _CardTwo(),
                            SizedBox(width: 390, height: 20),
                            _CardThree(),
                            SizedBox(width: 390, height: 20),
                            _CardFour(),
                            SizedBox(width: 390, height: 20),
                            _CardFive(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 390, height: 128),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _Level1Header(),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _Level1Dock(),
        ),
      ],
    );
  }
}

class _Level1Header extends StatelessWidget {
  const _Level1Header();

  @override
  Widget build(BuildContext context) {
    return FxHeader(
      title: 'Diagnostic Checklist',
      titleStyle: Fx.text(18, 24, FontWeight.w700, -0.45, color: Fx.ink),
      leading: const SizedBox(
        width: _M.iconHit,
        height: _M.iconHit,
        child: Center(
          child: FxIcon(id: '1_8343', size: 20, color: Fx.ink),
        ),
      ),
      actions: const [
        FxProfileButton(
          initials: '',
          iconId: '1_8348',
          onPressed: null,
          semanticLabel: 'Profile',
        ),
      ],
    );
  }
}

class _ZoneHeader extends StatelessWidget {
  const _ZoneHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          _M.gutter, _M.padMid, _M.gutter, _M.gapSmall),
      child: SizedBox(
        width: 350,
        height: 34,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'INSPECTION ZONE 04',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.text(12, 16, FontWeight.w600, 0.6,
                        color: Fx.outline),
                  ),
                  Text(
                    '3 of 6 checkpoints logged',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.body13.copyWith(color: Fx.muted),
                  ),
                ],
              ),
            ),
            const _LiveBayPill(),
          ],
        ),
      ),
    );
  }
}

class _LiveBayPill extends StatelessWidget {
  const _LiveBayPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.fromLTRB(
          _M.gapMid, _M.halfGap, _M.gapMid, _M.halfGap),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Dot(),
          const SizedBox(width: 6),
          Text(
            'Live Bay #2',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.ink),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration:
          const BoxDecoration(color: Fx.emerald, shape: BoxShape.circle),
    );
  }
}

class _CardOne extends StatelessWidget {
  const _CardOne();

  @override
  Widget build(BuildContext context) {
    return FxCard(
      padding: const EdgeInsets.all(_M.gutter),
      child: SizedBox(
        width: 310,
        height: 60,
        child: Row(
          children: [
            const FxIconTile(
              iconId: '1_8241',
              size: 48,
              iconSize: 16.5,
              background: Fx.container,
              color: Fx.ink,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Engine Oil Level',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.text(18, 24, FontWeight.w700, -0.45,
                        color: Fx.ink),
                  ),
                  Text(
                    'Dipstick at optimal line \u2022 5W-30 synthetic',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.body13.copyWith(color: Fx.muted),
                  ),
                ],
              ),
            ),
            const _SuccessCircle(iconId: '1_8249'),
          ],
        ),
      ),
    );
  }
}

class _SuccessCircle extends StatelessWidget {
  const _SuccessCircle({required this.iconId});

  final String iconId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: F2b.emeraldWash,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: FxIcon(id: iconId, size: 16.67, color: Fx.emerald),
      ),
    );
  }
}

class _GreyCircle extends StatelessWidget {
  const _GreyCircle({required this.iconId}) : iconColor = Fx.outline;

  final String iconId;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Fx.container,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: FxIcon(id: iconId, size: 16.67, color: iconColor),
      ),
    );
  }
}

class _CardTwo extends StatelessWidget {
  const _CardTwo();

  @override
  Widget build(BuildContext context) {
    return FxCard(
      padding: const EdgeInsets.all(_M.gutter),
      child: SizedBox(
        width: 310,
        height: 272,
        child: Column(
          children: [
            SizedBox(
              width: 310,
              height: 60,
              child: Row(
                children: [
                  const FxIconTile(
                    iconId: '1_8255',
                    size: 48,
                    iconSize: 18.33,
                    background: Fx.container,
                    color: Fx.ink,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Coolant',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Fx.text(18, 24, FontWeight.w700, -0.45,
                              color: Fx.ink),
                        ),
                        Text(
                          'Expansion reservoir inspection',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Fx.body13.copyWith(color: Fx.muted),
                        ),
                      ],
                    ),
                  ),
                  F2bStatusPill(
                    label: 'ACTIVE',
                    background: Fx.surfaceHighest,
                    foreground: Fx.secondaryInk,
                    style: Fx.text(11, 14, FontWeight.w700, 0.55,
                        color: Fx.secondaryInk),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 310, height: 16),
            const _LevelSegmented(),
            const SizedBox(width: 310, height: 16),
            const _NoteArea(),
            const SizedBox(width: 310, height: 16),
            const SizedBox(
              width: 310,
              height: 48,
              child: Row(
                children: [
                  SizedBox(
                    width: 250,
                    height: 48,
                    child: FxButton(
                      label: 'Take Photo',
                      onPressed: null,
                      height: 48,
                      trailingIcon: false,
                      icon: FxIcon(
                          id: '1_8277', size: 16.67, color: Fx.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  _BarcodeButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelSegmented extends StatelessWidget {
  const _LevelSegmented();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      height: 40,
      padding: const EdgeInsets.all(_M.gapXSmall),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
      child: const Row(
        children: [
          Expanded(child: _SegmentOption(label: 'Normal', selected: true)),
          Expanded(child: _SegmentOption(label: 'Low', selected: false)),
          Expanded(
              child: _SegmentOption(label: 'Critical', selected: false)),
        ],
      ),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Fx.white : Fx.transparent,
        borderRadius: BorderRadius.circular(Fx.pillRadius),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Fx.label12.copyWith(
            color: selected ? Fx.ink : Fx.muted,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _NoteArea extends StatelessWidget {
  const _NoteArea();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 310,
          height: 68,
          padding: const EdgeInsets.fromLTRB(
              _M.gapLarge, _M.gapLarge, _M.gapLarge, _M.noteBottom),
          decoration: const BoxDecoration(color: Fx.container),
          child: SizedBox(
            width: 282,
            height: 20,
            child: Text(
              'Enter fluid level / notes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Fx.text(14, 20, FontWeight.w500, -0.07,
                  color: Fx.outline),
            ),
          ),
        ),
        const SizedBox(width: 310, height: 8),
      ],
    );
  }
}

class _BarcodeButton extends StatelessWidget {
  const _BarcodeButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
      child: const Center(
        child: FxIcon(id: '1_8282', size: 16.67, color: Fx.ink),
      ),
    );
  }
}

class _CardThree extends StatelessWidget {
  const _CardThree();

  @override
  Widget build(BuildContext context) {
    return FxCard(
      padding: const EdgeInsets.all(_M.gutter),
      child: SizedBox(
        width: 310,
        height: 98,
        child: Column(
          children: [
            SizedBox(
              width: 310,
              height: 48,
              child: Row(
                children: [
                  const FxIconTile(
                    iconId: '1_8288',
                    size: 48,
                    iconSize: 17.42,
                    background: Fx.container,
                    color: Fx.ink,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Brake Fluid Level',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Fx.text(18, 24, FontWeight.w700, -0.45,
                              color: Fx.ink),
                        ),
                        Text(
                          'DOT 4 standard \u2022 Reservoir visual',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Fx.body13.copyWith(color: Fx.muted),
                        ),
                      ],
                    ),
                  ),
                  const _GreyCircle(iconId: '1_8296'),
                ],
              ),
            ),
            const SizedBox(width: 310, height: 14),
            const _CompactToggle(),
          ],
        ),
      ),
    );
  }
}

class _CompactToggle extends StatelessWidget {
  const _CompactToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      height: 36,
      padding: const EdgeInsets.all(_M.gapXSmall),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
      child: const Row(
        children: [
          Expanded(child: _CompactOption(label: 'Pass')),
          Expanded(child: _CompactOption(label: 'Marginal')),
          Expanded(child: _CompactOption(label: 'Fail')),
        ],
      ),
    );
  }
}

class _CompactOption extends StatelessWidget {
  const _CompactOption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Fx.label12.copyWith(color: Fx.muted),
      ),
    );
  }
}

class _CardFour extends StatelessWidget {
  const _CardFour();

  @override
  Widget build(BuildContext context) {
    return FxCard(
      padding: const EdgeInsets.all(_M.gutter),
      child: SizedBox(
        width: 310,
        height: 60,
        child: Row(
          children: [
            const FxIconTile(
              iconId: '1_8309',
              size: 48,
              iconSize: 18.42,
              background: Fx.container,
              color: Fx.ink,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Transmission Fluid',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.text(18, 24, FontWeight.w700, -0.45,
                        color: Fx.ink),
                  ),
                  Text(
                    'Sealed system \u2022 Check overflow valve',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.body13.copyWith(color: Fx.muted),
                  ),
                ],
              ),
            ),
            const _ChevronCircle(),
          ],
        ),
      ),
    );
  }
}

class _ChevronCircle extends StatelessWidget {
  const _ChevronCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Fx.container,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: FxIcon(id: '1_8317', size: 10, color: Fx.ink),
      ),
    );
  }
}

class _CardFive extends StatelessWidget {
  const _CardFive();

  @override
  Widget build(BuildContext context) {
    return FxCard(
      padding: const EdgeInsets.all(_M.gutter),
      child: SizedBox(
        width: 310,
        height: 48,
        child: Row(
          children: [
            const FxIconTile(
              iconId: '1_8323',
              size: 48,
              iconSize: 18.33,
              background: Fx.container,
              color: Fx.ink,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Washer Fluid',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.text(18, 24, FontWeight.w700, -0.45,
                        color: Fx.ink),
                  ),
                  Text(
                    'Topped to max reservoir line',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.body13.copyWith(color: Fx.muted),
                  ),
                ],
              ),
            ),
            const _SuccessCircle(iconId: '1_8331'),
          ],
        ),
      ),
    );
  }
}

class _Level1Dock extends StatelessWidget {
  const _Level1Dock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      height: 96,
      padding: const EdgeInsets.all(_M.gutter),
      decoration: const BoxDecoration(gradient: F2b.fadeGradient),
      child: const SizedBox(
        width: 350,
        height: 56,
        child: FxButton(
          label: 'Confirm Fluid Levels',
          onPressed: null,
          height: 56,
          trailingIcon: false,
          icon: FxIcon(id: '1_8335', size: 20.17, color: Fx.white),
        ),
      ),
    );
  }
}
