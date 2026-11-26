import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Photo-lightbox palette. The markup editor is a dark room by design: the
/// photo must be the only bright thing on screen. Kept here so no screen
/// hardcodes a hex value.
abstract final class FieldworkDark {
  static const Color canvas = Color(0xFF0B0F14);
  static const Color bar = Color(0xFF11161D);
  static const Color elevated = Color(0x1FFFFFFF);
  static const Color stroke = Color(0x29FFFFFF);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xB3FFFFFF);
  static const Color textDisabled = Color(0x40FFFFFF);
  static const Color fill = Color(0x29FFFFFF);
  static const Color fillStrong = Color(0x3DFFFFFF);
}

/// Geometry for the Fieldwork language.
///
/// One radius family per screen: controls 14, cards 16, status pills 999,
/// dialogs 20, sheets 24. Values that already exist as design-system tokens
/// are aliased, the rest live here once so nothing in a screen hardcodes a
/// number.
abstract final class FieldworkMetrics {
  /// Primary action height (thumb zone, gloves).
  static const double primaryHeight = 56;

  /// Secondary/compact action height.
  static const double secondaryHeight = 48;

  /// Icon-only control target. Never below the 44 px accessibility floor.
  static const double iconTarget = 48;

  static const double controlRadius = 14;
  static const double cardRadius = 16;
  static const double chipRadius = 999;
  static const double dialogRadius = 20;
  static const double sheetRadius = 24;

  /// Readable measure for the focus column and the item screen.
  static const double focusMaxWidth = 760;

  /// Run-sheet rail at the 1440 layout.
  static const double runSheetWidth = 248;

  /// Above this width the run sheet sits beside the focus card.
  static const double railBreakpoint = 1020;

  /// Below this inner width the result choices stack full-width. A phone
  /// pushes a 2-up grid under ~104 px per tile, where served labels truncate.
  static const double stackedResultsBreakpoint = 360;
}

/// Body text in the module, built from the theme so the real family, fallbacks
/// and colour resolution stay in one place.
TextStyle fieldworkText(
  BuildContext context,
  double size, {
  FontWeight weight = FontWeight.w500,
  double? height,
  double tracking = 0,
  Color? color,
}) {
  return context.texts.bodyMedium!.copyWith(
    fontSize: size,
    height: height == null ? null : height / size,
    fontWeight: weight,
    letterSpacing: tracking,
    color: color ?? context.colors.onSurface,
  );
}

/// Numbers that must line up in columns read as numbers.
TextStyle fieldworkNumber(
  BuildContext context,
  double size, {
  FontWeight weight = FontWeight.w800,
  double? height,
  double tracking = 0,
  Color? color,
}) {
  return fieldworkText(
    context,
    size,
    weight: weight,
    height: height,
    tracking: tracking,
    color: color,
  ).copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]);
}

/// Section eyebrow: small, spaced, uppercase supplied by the served copy.
TextStyle fieldworkEyebrow(BuildContext context, {Color? color}) =>
    fieldworkText(
      context,
      11.5,
      weight: FontWeight.w700,
      height: 14,
      tracking: 0.8,
      color: color ?? context.colors.onSurfaceVariant,
    );

/// The single card surface of the module (radius 16, hairline border).
class FieldworkCard extends StatelessWidget {
  const FieldworkCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? context.colors.surfaceLowest,
          borderRadius: BorderRadius.circular(FieldworkMetrics.cardRadius),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FieldworkMetrics.cardRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The hero band of the focus card: a tinted plate, never a second card.
class FieldworkTint extends StatelessWidget {
  const FieldworkTint({
    required this.child,
    this.padding = const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 20),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.brand.container,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Status pill: dot/icon plus label, never colour alone. Radius 999, 28 high.
class FieldworkPill extends StatelessWidget {
  const FieldworkPill({
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Semantics(
      label: label,
      child: Container(
        height: dense ? 24 : 28,
        padding: EdgeInsetsDirectional.symmetric(horizontal: dense ? 8 : 10),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(FieldworkMetrics.chipRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: dense ? 12 : 13, color: pair.foreground),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: fieldworkText(
                  context,
                  dense ? 11.5 : 12,
                  weight: FontWeight.w700,
                  height: dense ? 14 : 16,
                  color: pair.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A thin progress track with the same fill everywhere in the module.
class FieldworkBar extends StatelessWidget {
  const FieldworkBar({
    required this.value,
    this.height = 6,
    this.color,
    this.trackColor,
    this.semanticLabel,
    super.key,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color:
                    trackColor ??
                    context.colors.outlineVariant.withValues(alpha: 0.55),
              ),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: value.clamp(0.0, 1.0),
                child: ColoredBox(color: color ?? context.brand.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One item in the run sheet's tick strip.
class FieldworkTick {
  const FieldworkTick({
    required this.label,
    required this.categoryCode,
    this.answered = false,
    this.current = false,
    this.safety = false,
  });

  final String label;
  final String categoryCode;
  final bool answered;
  final bool current;
  final bool safety;
}

/// The run sheet as ticks: position without a table. Every tick is a tap target
/// (44 px) that jumps to the item's category.
class FieldworkTicks extends StatelessWidget {
  const FieldworkTicks({
    required this.ticks,
    required this.semanticLabel,
    required this.onTap,
    this.height = 22,
    super.key,
  });

  final List<FieldworkTick> ticks;
  final String semanticLabel;
  final ValueChanged<FieldworkTick> onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < ticks.length; index++) ...[
            Expanded(
              child: Semantics(
                button: true,
                label: ticks[index].label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(ticks[index]),
                  child: SizedBox(
                    height: 44,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: context.motionDuration(context.motion.fast),
                          height: ticks[index].answered || ticks[index].current
                              ? height
                              : height * 0.45,
                          decoration: BoxDecoration(
                            color: ticks[index].answered
                                ? context.brand.ink
                                : ticks[index].current
                                ? context.colors.onSurfaceVariant
                                : context.colors.outlineVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ticks[index].safety
                                ? context.statusColors.danger.foreground
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (index != ticks.length - 1) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }
}

/// Row/tile interaction surface: hover tint, press scale and a keyboard focus
/// ring. Used for run-sheet stations and up-next rows.
class FieldworkPress extends StatefulWidget {
  const FieldworkPress({
    required this.child,
    required this.onTap,
    this.radius = FieldworkMetrics.controlRadius,
    this.semanticLabel,
    this.selected = false,
    super.key,
  });

  final Widget child;

  /// Null makes the row presentational: no tap, no button semantics.
  final VoidCallback? onTap;
  final double radius;
  final String? semanticLabel;
  final bool selected;

  @override
  State<FieldworkPress> createState() => _FieldworkPressState();
}

class _FieldworkPressState extends State<FieldworkPress> {
  bool _hover = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    return Semantics(
      button: onTap != null,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: onTap != null,
        mouseCursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hover = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap?.call();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: onTap == null
                ? null
                : (_) => setState(() => _pressed = true),
            onTapCancel: onTap == null
                ? null
                : () => setState(() => _pressed = false),
            onTapUp: onTap == null
                ? null
                : (_) => setState(() => _pressed = false),
            onTap: onTap,
            child: AnimatedScale(
              scale: _pressed ? context.motion.pressScale : 1,
              duration: context.motionDuration(context.motion.fast),
              curve: context.motion.enterCurve,
              child: AnimatedContainer(
                duration: context.motionDuration(context.motion.fast),
                decoration: BoxDecoration(
                  color: _hover
                      ? context.colors.surfaceContainerLow
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: _focused
                      ? Border.all(color: context.colors.focus, width: 2)
                      : null,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum FieldworkButtonVariant { primary, tonal, ghost, danger, text }

/// The module's action control: radius 14, 56 primary / 48 secondary, ink
/// primary, inline loading, keyboard focus ring, press scale.
///
/// The design-system `AppButton` is pill-only; the approved Fieldwork house
/// style is 14 with the ink primary, so this primitive mirrors its behaviour
/// while using the same tokens.
class FieldworkButton extends StatefulWidget {
  const FieldworkButton({
    required this.label,
    required this.onPressed,
    this.variant = FieldworkButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.height = FieldworkMetrics.primaryHeight,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final FieldworkButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final double height;
  final String? semanticLabel;

  @override
  State<FieldworkButton> createState() => _FieldworkButtonState();
}

class _FieldworkButtonState extends State<FieldworkButton> {
  bool _hover = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final (
      Color background,
      Color foreground,
      BorderSide? border,
    ) = switch (widget.variant) {
      FieldworkButtonVariant.primary => (
        enabled ? brand.ink : colors.surfaceContainerHighest,
        enabled ? colors.surfaceLowest : colors.onSurfaceVariant,
        null,
      ),
      FieldworkButtonVariant.tonal => (
        brand.container,
        brand.onContainer,
        null,
      ),
      FieldworkButtonVariant.ghost => (
        colors.surfaceLowest,
        enabled ? colors.onSurface : colors.onSurfaceVariant,
        BorderSide(color: colors.outlineVariant),
      ),
      FieldworkButtonVariant.danger => (
        enabled ? colors.error : colors.surfaceContainerHighest,
        enabled ? colors.onError : colors.onSurfaceVariant,
        null,
      ),
      FieldworkButtonVariant.text => (
        Colors.transparent,
        enabled ? brand.ink : colors.onSurfaceVariant,
        null,
      ),
    };
    final hovered = _hover && enabled;
    final effectiveBackground = hovered
        ? (widget.variant == FieldworkButtonVariant.primary
              ? Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.14),
                  background,
                )
              : widget.variant == FieldworkButtonVariant.tonal
              ? Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.05),
                  background,
                )
              : background)
        : background;

    final content = widget.isLoading
        ? SizedBox.square(
            dimension: context.sizing.iconMd,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: foreground),
                SizedBox(width: context.spacing.sm),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelLarge?.copyWith(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: FocusableActionDetector(
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (value) => setState(() => _hover = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (enabled) {
                widget.onPressed!();
              }
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTap: enabled ? widget.onPressed : null,
            child: AnimatedScale(
              scale: _pressed ? context.motion.pressScale : 1,
              duration: context.motionDuration(context.motion.fast),
              curve: context.motion.enterCurve,
              child: AnimatedContainer(
                duration: context.motionDuration(context.motion.fast),
                curve: context.motion.enterCurve,
                height: widget.height,
                width: widget.expand ? double.infinity : null,
                constraints: BoxConstraints(minWidth: widget.expand ? 0 : 88),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: context.spacing.lg,
                ),
                decoration: BoxDecoration(
                  color: effectiveBackground,
                  borderRadius: BorderRadius.circular(
                    FieldworkMetrics.controlRadius,
                  ),
                  border: _focused
                      ? Border.all(color: colors.focus, width: 2)
                      : border == null
                      ? null
                      : Border.fromBorderSide(border),
                  boxShadow: <BoxShadow>[
                    if (widget.variant == FieldworkButtonVariant.primary &&
                        enabled)
                      ...context.shadows.buttonSubtle,
                  ],
                ),
                alignment: Alignment.center,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact icon action with a tooltip and a semantic label.
class FieldworkIconButton extends StatefulWidget {
  const FieldworkIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.dark = false,
    this.selected = false,
    this.size = FieldworkMetrics.iconTarget,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final bool dark;
  final bool selected;
  final double size;

  @override
  State<FieldworkIconButton> createState() => _FieldworkIconButtonState();
}

class _FieldworkIconButtonState extends State<FieldworkIconButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final colors = context.colors;
    final foreground = widget.dark
        ? Colors.white
        : enabled
        ? colors.onSurface
        : colors.onSurfaceVariant;
    final background = widget.selected
        ? (widget.dark
              ? Colors.white.withValues(alpha: 0.16)
              : context.brand.container)
        : (widget.dark ? Colors.transparent : colors.surfaceLowest);
    final border = widget.dark
        ? Border.all(color: Colors.white.withValues(alpha: 0.16))
        : Border.all(color: colors.outlineVariant);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: Tooltip(
        message: widget.semanticLabel,
        excludeFromSemantics: true,
        child: FocusableActionDetector(
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                if (enabled) {
                  widget.onPressed!();
                }
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? widget.onPressed : null,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(
                  FieldworkMetrics.controlRadius,
                ),
                border: _focused
                    ? Border.all(color: colors.focus, width: 2)
                    : border,
              ),
              child: Icon(
                widget.icon,
                size: 21,
                color: enabled
                    ? foreground
                    : foreground.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title inside the focus card.
class FieldworkSectionHeader extends StatelessWidget {
  const FieldworkSectionHeader({
    required this.title,
    this.meta,
    this.trailing,
    this.titleSuffix,
    super.key,
  });

  final String title;
  final String? meta;
  final Widget? trailing;
  final Widget? titleSuffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            title,
            style: fieldworkText(
              context,
              15,
              weight: FontWeight.w800,
              height: 20,
              tracking: -0.2,
            ),
          ),
        ),
        if (titleSuffix != null) ...[const SizedBox(width: 8), titleSuffix!],
        if (meta != null) ...[
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              meta!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: fieldworkText(
                context,
                12,
                height: 16,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

/// Inline, scoped message. `liveRegion` so a screen reader announces it.
class FieldworkNote extends StatelessWidget {
  const FieldworkNote({
    required this.message,
    this.tone = StatusTone.neutral,
    this.icon,
    this.action,
    super.key,
  });

  final String message;
  final StatusTone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(FieldworkMetrics.controlRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 1),
              child: Icon(
                icon ?? Icons.info_outline_rounded,
                size: 15,
                color: pair.foreground,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: fieldworkText(
                  context,
                  12.5,
                  weight: FontWeight.w600,
                  height: 18,
                  color: pair.foreground,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action!],
          ],
        ),
      ),
    );
  }
}

/// Hairline used between zones of the focus card.
class FieldworkDivider extends StatelessWidget {
  const FieldworkDivider({this.indent = 0, super.key});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: indent,
      color: context.colors.outlineVariant,
    );
  }
}

/// The oversized item number of the hero, rear-of-card watermark.
class FieldworkGhostNumber extends StatelessWidget {
  const FieldworkGhostNumber({required this.number, this.color, super.key});

  final String number;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        number,
        textDirection: TextDirection.ltr,
        style: fieldworkNumber(
          context,
          46,
          height: 42,
          tracking: -2,
          color: color ?? context.brand.onContainer.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

/// The hero band shared by the hub's focus card and the item screen.
class FieldworkHero extends StatelessWidget {
  const FieldworkHero({
    required this.eyebrow,
    required this.label,
    required this.numberLabel,
    this.eyebrowNumber,
    this.instruction,
    this.spec,
    this.safety = false,
    this.safetyLabel = '',
    this.trailing,
    super.key,
  });

  final String eyebrow;

  /// An LTR-isolated "5 / 30" prefix, so RTL cannot reorder it.
  final String? eyebrowNumber;
  final String label;
  final String numberLabel;
  final String? instruction;
  final String? spec;
  final bool safety;
  final String safetyLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final onContainer = context.brand.onContainer;
    final instructionText = (instruction ?? '').trim();
    final specText = (spec ?? '').trim();
    final eyebrowStyle = fieldworkText(
      context,
      11.5,
      weight: FontWeight.w700,
      height: 15,
      tracking: 0.7,
      color: onContainer.withValues(alpha: 0.75),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (eyebrowNumber != null)
                    Text(
                      eyebrowNumber!,
                      textDirection: TextDirection.ltr,
                      style: eyebrowStyle,
                    ),
                  Text(eyebrow, style: eyebrowStyle),
                  if (safety)
                    FieldworkPill(
                      label: safetyLabel,
                      tone: StatusTone.danger,
                      icon: Icons.health_and_safety_outlined,
                      dense: true,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: fieldworkText(
                  context,
                  27,
                  weight: FontWeight.w800,
                  height: 31,
                  tracking: -0.7,
                  color: onContainer,
                ),
              ),
              if (instructionText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  instructionText,
                  style: fieldworkText(
                    context,
                    13.5,
                    height: 20,
                    color: onContainer.withValues(alpha: 0.85),
                  ),
                ),
              ],
              if (specText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.straighten_rounded,
                      size: 15,
                      color: onContainer.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        specText,
                        style: fieldworkText(
                          context,
                          12,
                          weight: FontWeight.w700,
                          height: 16,
                          color: onContainer.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        trailing ?? FieldworkGhostNumber(number: numberLabel),
      ],
    );
  }
}

/// Small progress ring for the mobile dock.
class FieldworkRing extends StatelessWidget {
  const FieldworkRing({
    required this.value,
    required this.center,
    required this.sub,
    this.size = 48,
    this.stroke = 4,
    this.semanticLabel,
    super.key,
  });

  final double value;
  final String center;
  final String sub;
  final double size;
  final double stroke;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _FieldworkRingPainter(
                value: value,
                track: context.colors.outlineVariant,
                arc: context.brand.ink,
                stroke: stroke,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: stroke + 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                // One LTR run, so RTL cannot reorder "15" and "/30".
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: center,
                        style: fieldworkNumber(context, 13, height: 16),
                      ),
                      TextSpan(
                        text: sub,
                        style: fieldworkText(
                          context,
                          10,
                          weight: FontWeight.w700,
                          height: 13,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldworkRingPainter extends CustomPainter {
  const _FieldworkRingPainter({
    required this.value,
    required this.track,
    required this.arc,
    required this.stroke,
  });

  final double value;
  final Color track;
  final Color arc;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arcPaint = Paint()
      ..color = arc
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    if (value <= 0) {
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963267948966,
      6.283185307179586 * value.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FieldworkRingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.track != track ||
      oldDelegate.arc != arc ||
      oldDelegate.stroke != stroke;
}
