import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticLabel ?? label,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.spacing.md,
          vertical: context.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(context.radii.pill),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: context.spacing.xs,
          runSpacing: context.spacing.xs,
          children: [
            Icon(
              icon ?? _iconForTone(tone),
              size: context.sizing.iconMd,
              color: pair.foreground,
            ),
            Text(
              label,
              style: context.texts.labelMedium?.copyWith(
                color: pair.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({
    required this.label,
    this.severity = StatusTone.warning,
    this.appSeverity,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final StatusTone severity;
  final AppSeverity? appSeverity;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final level = appSeverity;
    final tone = level == null ? severity : _toneForSeverity(level);
    final icon = level == null ? _iconForTone(tone) : _iconForSeverity(level);
    return StatusChip(
      label: label,
      tone: tone,
      icon: icon,
      semanticLabel: semanticLabel,
    );
  }
}

class AppSelectableText extends StatelessWidget {
  const AppSelectableText({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppFilterChip(
      label: label,
      selected: selected,
      icon: icon,
      semanticLabel: semanticLabel,
      onSelected: onTap == null ? null : (_) => onTap!(),
    );
  }
}

class AppFilterChip extends StatefulWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    this.onSelected,
    this.onRemoved,
    this.removeSemanticLabel,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onRemoved;
  final String? removeSemanticLabel;
  final IconData? icon;
  final String? semanticLabel;

  @override
  State<AppFilterChip> createState() => _AppFilterChipState();
}

class _AppFilterChipState extends State<AppFilterChip> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final colors = context.colors;
    final radii = context.radii;
    final sizing = context.sizing;
    final selected = widget.selected;
    final foreground = selected ? brand.onContainer : colors.onSurfaceVariant;
    final background = selected ? brand.container : colors.surfaceContainer;
    final radius = BorderRadius.circular(radii.pill);

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: sizing.iconMd, color: foreground),
          SizedBox(width: context.spacing.xs),
        ],
        if (selected) ...[
          Icon(Icons.check, size: sizing.iconSm, color: foreground),
          SizedBox(width: context.spacing.xs),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: context.texts.labelLarge?.copyWith(color: foreground),
          ),
        ),
        if (widget.onRemoved != null) ...[
          SizedBox(width: context.spacing.xs),
          Semantics(
            button: true,
            label:
                widget.removeSemanticLabel ??
                MaterialLocalizations.of(context).deleteButtonTooltip,
            child: InkWell(
              onTap: widget.onRemoved,
              borderRadius: BorderRadius.circular(radii.pill),
              child: SizedBox.square(
                dimension: sizing.targetMin,
                child: Icon(
                  Icons.close,
                  size: sizing.iconSm,
                  color: foreground,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return Semantics(
      button: widget.onSelected != null,
      selected: selected,
      container: true,
      label: widget.semanticLabel ?? widget.label,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _focused ? [context.shadows.focus] : null,
        ),
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onSelected == null
                ? null
                : () => widget.onSelected!(!selected),
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: sizing.targetMin),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: context.spacing.md,
                  vertical: context.spacing.xs,
                ),
                child: label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.radii.pill);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        padding: EdgeInsetsDirectional.all(context.spacing.xs),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: radius,
        ),
        child: Row(
          children: [
            for (var index = 0; index < segments.length; index++) ...[
              if (index > 0) SizedBox(width: context.spacing.xs),
              Expanded(
                child: _SegmentButton<T>(
                  segment: segments[index],
                  selected: segments[index].value == selected,
                  onSelected: onChanged,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentButton<T> extends StatefulWidget {
  const _SegmentButton({
    required this.segment,
    required this.selected,
    required this.onSelected,
  });

  final AppSegment<T> segment;
  final bool selected;
  final ValueChanged<T> onSelected;

  @override
  State<_SegmentButton<T>> createState() => _SegmentButtonState<T>();
}

class _SegmentButtonState<T> extends State<_SegmentButton<T>> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final colors = context.colors;
    final foreground = widget.selected ? brand.onFill : colors.onSurfaceVariant;

    return Semantics(
      selected: widget.selected,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.radii.pill),
          boxShadow: _focused ? [context.shadows.focus] : null,
        ),
        child: TextButton(
          onPressed: () => widget.onSelected(widget.segment.value),
          onFocusChange: (value) => setState(() => _focused = value),
          style: TextButton.styleFrom(
            backgroundColor: widget.selected ? brand.fill : null,
            foregroundColor: foreground,
            minimumSize: Size(
              context.sizing.targetMin,
              context.sizing.targetMin,
            ),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: context.spacing.md,
              vertical: context.spacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.radii.pill),
            ),
            textStyle: context.texts.labelLarge,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.segment.icon != null) ...[
                Icon(
                  widget.segment.icon,
                  size: context.sizing.iconMd,
                  color: foreground,
                ),
                SizedBox(width: context.spacing.xs),
              ],
              if (widget.selected) ...[
                Icon(
                  Icons.check,
                  size: context.sizing.iconSm,
                  color: foreground,
                ),
                SizedBox(width: context.spacing.xs),
              ],
              Flexible(
                child: Text(
                  widget.segment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelLarge?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppLanguageSwitch extends StatelessWidget {
  const AppLanguageSwitch({
    required this.englishLabel,
    required this.arabicLabel,
    required this.isArabic,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final String englishLabel;
  final String arabicLabel;
  final bool isArabic;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedControl<bool>(
      selected: isArabic,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      segments: [
        AppSegment<bool>(value: false, label: englishLabel),
        AppSegment<bool>(value: true, label: arabicLabel),
      ],
    );
  }
}

IconData _iconForTone(StatusTone tone) => switch (tone) {
  StatusTone.neutral => Icons.circle_outlined,
  StatusTone.info => Icons.info_outline,
  StatusTone.success => Icons.check_circle_outline,
  StatusTone.warning => Icons.warning_amber_rounded,
  StatusTone.danger => Icons.error_outline,
  StatusTone.critical => Icons.dangerous_outlined,
};

StatusTone _toneForSeverity(AppSeverity severity) => switch (severity) {
  AppSeverity.minor => StatusTone.neutral,
  AppSeverity.moderate => StatusTone.warning,
  AppSeverity.major => StatusTone.danger,
  AppSeverity.safetyCritical => StatusTone.critical,
};

IconData _iconForSeverity(AppSeverity severity) => switch (severity) {
  AppSeverity.minor => Icons.circle_outlined,
  AppSeverity.moderate => Icons.warning_amber_rounded,
  AppSeverity.major => Icons.error_outline,
  AppSeverity.safetyCritical => Icons.dangerous_outlined,
};
