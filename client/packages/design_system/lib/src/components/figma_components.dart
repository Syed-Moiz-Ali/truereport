import 'package:design_system/src/components/icons.dart';
import 'package:design_system/src/figma_spec.dart';
import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

/// Figma-exact primary button.
///
/// The structure is the Figma `Button` frame: 342 x 56, pill radius,
/// horizontal gap 8, a 14/18 w700 label and the 10.67 px arrow. Option [1] is
/// the unnamed Figma default; the other options are the owner's pending
/// primary-colour choices and are shown only in the gallery.
class FigmaPrimaryButton extends StatefulWidget {
  const FigmaPrimaryButton({
    required this.label,
    required this.onPressed,
    this.spec = FigmaPrimaryButtonSpec.figmaExact,
    this.icon = true,
    this.width = FigmaGeometry.buttonWidth,
    this.showSubtleShadow = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final FigmaPrimaryButtonSpec spec;
  final bool icon;
  final double width;
  final bool showSubtleShadow;

  @override
  State<FigmaPrimaryButton> createState() => _FigmaPrimaryButtonState();
}

class _FigmaPrimaryButtonState extends State<FigmaPrimaryButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final shadows = <BoxShadow>[
      if (widget.showSubtleShadow) ...FigmaShadows.buttonSubtle,
      if (_focused) context.shadows.focus,
    ];
    final radius = BorderRadius.circular(FigmaGeometry.pillRadius);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        width: widget.width,
        height: FigmaGeometry.buttonHeight,
        decoration: BoxDecoration(
          color: enabled
              ? widget.spec.fill
              : context.colors.surfaceContainerHighest,
          borderRadius: radius,
          boxShadow: shadows,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onPressed,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: widget.spec.textStyle.copyWith(
                        color: enabled
                            ? widget.spec.label
                            : context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (widget.icon) ...[
                    const SizedBox(width: FigmaGeometry.buttonGap),
                    AppIcon(
                      AppIconName.arrowForward,
                      size: FigmaGeometry.buttonIcon,
                      color: enabled
                          ? widget.spec.label
                          : context.colors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma delivery-status pill: container fill, 8 px emerald dot, 12/16 w600.
class FigmaStatusPill extends StatelessWidget {
  const FigmaStatusPill({
    required this.label,
    this.dotColor = FigmaColors.emerald,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final Color dotColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel ?? label,
      child: Container(
        height: FigmaGeometry.statusPillHeight,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: FigmaColors.container,
          borderRadius: BorderRadius.circular(FigmaGeometry.pillRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: FigmaGeometry.statusPillDot,
              height: FigmaGeometry.statusPillDot,
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(FigmaGeometry.pillRadius),
              ),
            ),
            const SizedBox(width: FigmaGeometry.statusPillDotGap),
            Text(
              label,
              style: FigmaType.labelMd.copyWith(color: FigmaColors.inkStrong),
            ),
          ],
        ),
      ),
    );
  }
}

class FigmaDeliveryItem {
  const FigmaDeliveryItem({
    required this.icon,
    required this.label,
    required this.status,
    this.dotColor = FigmaColors.emerald,
    this.iconWidth = FigmaGeometry.statusIcon,
    this.iconHeight = FigmaGeometry.statusIcon,
  });

  final AppIconName icon;
  final String label;
  final String status;
  final Color dotColor;
  final double iconWidth;
  final double iconHeight;
}

/// Figma `Delivery Status Card`: 350 x 145, radius 32, padding 20, gap 16,
/// two 36 px rows and a 1 px `#EEEDF3` divider. No border.
class FigmaDeliveryStatusCard extends StatelessWidget {
  const FigmaDeliveryStatusCard({
    required this.items,
    this.width = FigmaGeometry.cardWidth,
    this.semanticLabel,
    super.key,
  }) : assert(items.length == 2, 'The Figma card has exactly two rows');

  final List<FigmaDeliveryItem> items;
  final double width;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: FigmaColors.surface,
          borderRadius: BorderRadius.circular(FigmaGeometry.cardRadius),
          boxShadow: FigmaShadows.card,
        ),
        padding: const EdgeInsets.all(FigmaGeometry.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(items[0]),
            const SizedBox(height: FigmaGeometry.cardGap),
            Container(height: 1, color: FigmaColors.divider),
            const SizedBox(height: FigmaGeometry.cardGap),
            _row(items[1]),
          ],
        ),
      ),
    );
  }

  Widget _row(FigmaDeliveryItem item) {
    return SizedBox(
      height: FigmaGeometry.statusIconCircle,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: FigmaGeometry.statusIconCircle,
                  height: FigmaGeometry.statusIconCircle,
                  decoration: const BoxDecoration(
                    color: FigmaColors.container,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(
                    item.icon,
                    size: item.iconWidth,
                    height: item.iconHeight,
                    color: FigmaColors.muted,
                  ),
                ),
                const SizedBox(width: FigmaGeometry.statusIconTextGap),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigmaType.titleLg.copyWith(
                      color: FigmaColors.inkStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FigmaStatusPill(label: item.status, dotColor: item.dotColor),
        ],
      ),
    );
  }
}

class FigmaResultOption<T> {
  const FigmaResultOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Figma three-way pill toggle (`Severity Pill-Shaped Toggle Group`).
///
/// 350 px wide, 11/14 uppercase label, 52 px pill, 6 px padding and gap, three
/// 40 px options. [exact] keeps the 40 px Figma option height; product variants
/// pass `false` to meet the 48 dp target rule.
class FigmaThreeWaySelector<T> extends StatelessWidget {
  const FigmaThreeWaySelector({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.width = FigmaGeometry.selectorWidth,
    this.exact = true,
    this.semanticLabel,
    super.key,
  }) : assert(options.length == 3, 'The primary toggle has three options');

  final String label;
  final List<FigmaResultOption<T>> options;
  final T? selected;
  final ValueChanged<T>? onChanged;
  final double width;
  final bool exact;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final optionHeight = exact ? FigmaGeometry.selectorOptionHeight : 48.0;
    final pillHeight = optionHeight + FigmaGeometry.selectorPillPadding * 2;
    return Semantics(
      container: true,
      label: semanticLabel ?? label,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: FigmaGeometry.selectorLabelHeight,
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FigmaType.captionWide.copyWith(
                  color: FigmaColors.muted,
                ),
              ),
            ),
            const SizedBox(height: FigmaGeometry.selectorLabelGap),
            Container(
              height: pillHeight,
              padding: const EdgeInsets.all(
                FigmaGeometry.selectorPillPadding,
              ),
              decoration: BoxDecoration(
                color: FigmaColors.container,
                borderRadius: BorderRadius.circular(FigmaGeometry.pillRadius),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(width: FigmaGeometry.selectorPillGap),
                    Expanded(
                      child: _Option<T>(
                        option: options[i],
                        selected: selected == options[i].value,
                        height: optionHeight,
                        onTap: onChanged == null
                            ? null
                            : () => onChanged!(options[i].value),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option<T> extends StatefulWidget {
  const _Option({
    required this.option,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  final FigmaResultOption<T> option;
  final bool selected;
  final double height;
  final VoidCallback? onTap;

  @override
  State<_Option<T>> createState() => _OptionState<T>();
}

class _OptionState<T> extends State<_Option<T>> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final radius = BorderRadius.circular(FigmaGeometry.pillRadius);
    final foreground = selected ? FigmaColors.ink : FigmaColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      enabled: widget.onTap != null,
      label: widget.option.label,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        height: widget.height,
        decoration: BoxDecoration(
          color: selected ? FigmaColors.selected : Colors.transparent,
          borderRadius: radius,
          boxShadow: <BoxShadow>[
            if (selected) ...FigmaShadows.selectedOption,
            if (_focused) context.shadows.focus,
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  widget.option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: (selected ? FigmaType.labelBold : FigmaType.labelMd)
                      .copyWith(color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary result chips for the three results the Figma toggle does not
/// draw. Same visual language, wrapped below the primary toggle.
class FigmaSecondaryResultChips<T> extends StatelessWidget {
  const FigmaSecondaryResultChips({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final List<FigmaResultOption<T>> options;
  final T? selected;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Wrap(
        spacing: FigmaGeometry.selectorPillGap,
        runSpacing: FigmaGeometry.selectorPillGap,
        children: [
          for (final option in options)
            _SecondaryChip<T>(
              option: option,
              selected: selected == option.value,
              onTap: onChanged == null ? null : () => onChanged!(option.value),
            ),
        ],
      ),
    );
  }
}

class _SecondaryChip<T> extends StatelessWidget {
  const _SecondaryChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final FigmaResultOption<T> option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FigmaGeometry.pillRadius);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: option.label,
      child: Material(
        color: selected ? FigmaColors.selected : FigmaColors.container,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: ExcludeSemantics(
                  child: Text(
                    option.label,
                    style:
                        (selected ? FigmaType.labelBold : FigmaType.labelMd)
                            .copyWith(
                              color: selected
                                  ? FigmaColors.ink
                                  : FigmaColors.muted,
                            ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
