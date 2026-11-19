// THROWAWAY preview kit. Deleted after direction approval.
import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

abstract final class IRadii {
  static const double control = 999;
  static const double card = 16;
  static const double sheet = 24;
}

TextStyle iText(
  BuildContext context,
  double size, {
  FontWeight weight = FontWeight.w400,
  double height = 1.45,
  Color? color,
  double tracking = 0,
  bool tabular = false,
}) {
  return context.texts.bodyMedium!.copyWith(
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    letterSpacing: tracking,
    color: color ?? context.colors.onSurface,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}

TextStyle iEyebrow(BuildContext context, {Color? color}) => iText(
  context,
  11,
  weight: FontWeight.w700,
  height: 14,
  tracking: 0.9,
  color: color ?? context.colors.onSurfaceVariant,
);

TextStyle iMeta(BuildContext context, {Color? color}) =>
    iText(context, 12.5, height: 18, color: color);

TextStyle iBody(BuildContext context, {Color? color}) =>
    iText(context, 14.5, height: 22, color: color);

TextStyle iTitle(BuildContext context) =>
    iText(context, 24, weight: FontWeight.w700, height: 30, tracking: -0.5);

String iT(BuildContext context, String en, String ar) =>
    Directionality.of(context) == TextDirection.rtl ? ar : en;

class IButton extends StatelessWidget {
  const IButton({
    required this.label,
    this.variant = IButtonVariant.primary,
    this.icon,
    this.expand = false,
    this.onTap,
    super.key,
  });

  final String label;
  final IButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final colors = context.colors;
    final (bg, fg, border) = switch (variant) {
      IButtonVariant.primary => (brand.ink, Colors.white, null),
      IButtonVariant.soft => (colors.surfaceContainer, colors.onSurface, null),
      IButtonVariant.ghost => (
        Colors.transparent,
        colors.onSurface,
        colors.outlineVariant,
      ),
      IButtonVariant.onDark => (Colors.white, brand.ink, null),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(IRadii.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(IRadii.control),
        onTap: onTap ?? () {},
        child: Container(
          height: 48,
          constraints: const BoxConstraints(minWidth: 48),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IRadii.control),
            border: border == null ? null : Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: iText(
                  context,
                  14.5,
                  weight: FontWeight.w700,
                  height: 18,
                  color: fg,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum IButtonVariant { primary, soft, ghost, onDark }

class IChip extends StatelessWidget {
  const IChip({
    required this.label,
    this.selected = false,
    this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final StatusTone? tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final pair = tone == null ? null : context.statusColors.forTone(tone!);
    return Container(
      height: 30,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? brand.container : pair?.background ?? colors.surface,
        borderRadius: BorderRadius.circular(IRadii.control),
        border: Border.all(
          color: selected
              ? brand.ink.withValues(alpha: 0.28)
              : colors.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: selected
                  ? brand.onContainer
                  : pair?.foreground ?? colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: iText(
              context,
              12.5,
              weight: FontWeight.w600,
              height: 16,
              color: selected
                  ? brand.onContainer
                  : pair?.foreground ?? colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class IPlate extends StatelessWidget {
  const IPlate(this.value, {this.onDark = false, super.key});

  final String value;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : context.colors.onSurface;
    final border = onDark
        ? Colors.white.withValues(alpha: 0.38)
        : context.colors.outline;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : context.brand.ink,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: iText(
              context,
              13,
              weight: FontWeight.w700,
              height: 17,
              tracking: 0.7,
              tabular: true,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class IProgress extends StatelessWidget {
  const IProgress({
    required this.value,
    required this.total,
    this.onDark = false,
    this.height = 6,
    super.key,
  });

  final int value;
  final int total;
  final bool onDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    final track = onDark
        ? Colors.white.withValues(alpha: 0.24)
        : context.colors.surfaceContainerHighest;
    final fill = onDark ? Colors.white : context.brand.ink;
    return ClipRRect(
      borderRadius: BorderRadius.circular(IRadii.control),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: track)),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  width: constraints.maxWidth * fraction,
                  color: fill,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IRing extends StatelessWidget {
  const IRing({
    required this.value,
    required this.total,
    this.size = 74,
    this.onDark = false,
    super.key,
  });

  final int value;
  final int total;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: fraction,
          track: onDark
              ? Colors.white.withValues(alpha: 0.2)
              : context.colors.surfaceContainerHighest,
          fill: onDark ? Colors.white : context.brand.ink,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: iText(
                  context,
                  size * 0.28,
                  weight: FontWeight.w700,
                  height: size * 0.32,
                  tabular: true,
                  color: onDark ? Colors.white : context.colors.onSurface,
                ),
              ),
              Text(
                'of $total',
                style: iText(
                  context,
                  size * 0.14,
                  height: size * 0.18,
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.track,
    required this.fill,
  });

  final double fraction;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08;
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.fill != fill;
}

class IResultSelector extends StatelessWidget {
  const IResultSelector({required this.selected, super.key});

  final String selected;

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        'ok',
        iT(context, 'No issue', 'سليم'),
        Icons.check_rounded,
        StatusTone.success,
      ),
      (
        'watch',
        iT(context, 'Attention', 'انتباه'),
        Icons.priority_high_rounded,
        StatusTone.warning,
      ),
      (
        'defect',
        iT(context, 'Defect', 'عيب'),
        Icons.close_rounded,
        StatusTone.danger,
      ),
    ];
    return Row(
      children: [
        for (final option in options) ...[
          Expanded(
            child: _ResultTile(
              id: option.$1,
              label: option.$2,
              icon: option.$3,
              tone: option.$4,
              selected: selected == option.$1,
            ),
          ),
          if (option != options.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.id,
    required this.label,
    required this.icon,
    required this.tone,
    required this.selected,
  });

  final String id;
  final String label;
  final IconData icon;
  final StatusTone tone;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    final colors = context.colors;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: selected ? pair.background : colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? pair.foreground : colors.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: selected ? pair.foreground : colors.onSurfaceVariant,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            style: iText(
              context,
              11.5,
              weight: FontWeight.w700,
              height: 14,
              color: selected ? pair.foreground : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class IEvidenceGrid extends StatelessWidget {
  const IEvidenceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget tile(IconData icon, {bool add = false}) => Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: add ? colors.surface : context.brand.container,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: add ? colors.outlineVariant : Colors.transparent,
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: add ? colors.onSurfaceVariant : context.brand.ink,
      ),
    );
    return Row(
      children: [
        tile(Icons.photo_rounded),
        const SizedBox(width: 8),
        tile(Icons.photo_rounded),
        const SizedBox(width: 8),
        tile(Icons.add_rounded, add: true),
      ],
    );
  }
}

class PreviewShell extends StatelessWidget {
  const PreviewShell({
    required this.direction,
    required this.signature,
    required this.children,
    super.key,
  });

  final String direction;
  final String signature;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      direction,
                      style: iText(
                        context,
                        17,
                        weight: FontWeight.w700,
                        height: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        signature,
                        style: iMeta(
                          context,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StyleTile extends StatelessWidget {
  const StyleTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final status = context.statusColors;
    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(IRadii.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final type = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(iT(context, 'Inspection', 'الفحص'), style: iTitle(context)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '18',
                    style: iText(
                      context,
                      40,
                      weight: FontWeight.w700,
                      height: 42,
                      tracking: -1,
                      tabular: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 4),
                    child: Text(
                      iT(context, ' of 30 items', ' من 30 عنصراً'),
                      style: iMeta(context, color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const IPlate('D-48213'),
              const SizedBox(height: 8),
              Text(
                iT(
                  context,
                  'Front brake pads · minimum 3 mm',
                  'فحمات الفرامل · 3 مم كحد أدنى',
                ),
                style: iMeta(context, color: colors.onSurfaceVariant),
              ),
            ],
          );
          final palette = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Swatch(colors.onSurface, 'ink'),
              _Swatch(brand.ink, 'pine'),
              _Swatch(brand.container, 'mint'),
              _Swatch(colors.surfaceContainerLow, 'canvas'),
              _Swatch(colors.outlineVariant, 'line'),
              _Swatch(status.success.background, 'ok'),
              _Swatch(status.warning.background, 'wait'),
              _Swatch(status.danger.background, 'defect'),
            ],
          );
          final controls = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IButton(
                label: iT(context, 'Save & next', 'حفظ والتالي'),
                icon: Icons.arrow_forward_rounded,
              ),
              IChip(
                label: iT(context, 'Defect', 'عيب'),
                tone: StatusTone.danger,
              ),
              IChip(
                label: iT(context, 'Safety critical', 'حرج للسلامة'),
                tone: StatusTone.danger,
                icon: Icons.health_and_safety_outlined,
              ),
              IChip(
                label: iT(context, 'Brakes 0/4', 'الفرامل 0/4'),
                selected: true,
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (narrow) ...[
                type,
                const SizedBox(height: 16),
                palette,
                const SizedBox(height: 16),
                controls,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: type),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          palette,
                          const SizedBox(height: 18),
                          const IResultSelector(selected: 'defect'),
                          const SizedBox(height: 14),
                          controls,
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.colors.outlineVariant),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: iText(
            context,
            9.5,
            height: 12,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
