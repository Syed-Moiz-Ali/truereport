import 'package:design_system/src/components/workshop_admin.dart';
import 'package:design_system/src/tokens.dart';
import 'package:design_system/src/workshop_tokens.dart';
import 'package:flutter/material.dart';

/// Workshop Admin component kit (Phase 1 of the UI redesign).
///
/// Every primitive here is token-driven through [WorkshopTokens] (`context.ws`)
/// and keeps the workshop look: square-ish 10 px controls, 14 px cards, one
/// green accent, hairline borders and no decorative shadows. Screens compose
/// these instead of styling Material widgets directly.
///
/// Usage order for a page: [WorkshopPageHeader], then [WorkshopToolbar] 16 px
/// below it, then content 24 px below the toolbar (the gaps live at call
/// sites, not inside the widgets).

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

enum WorkshopButtonVariant { primary, secondary, ghost, danger }

/// 46 px high workshop action. Primary = solid green, secondary = white with a
/// hairline border, ghost = borderless, danger = rose outline (never a solid
/// red block; destructive confirmation lives in a dialog).
class WorkshopButton extends StatefulWidget {
  const WorkshopButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = WorkshopButtonVariant.primary,
    this.isLoading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WorkshopButtonVariant variant;
  final bool isLoading;
  final bool expand;

  @override
  State<WorkshopButton> createState() => _WorkshopButtonState();
}

class _WorkshopButtonState extends State<WorkshopButton> {
  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final radius = BorderRadius.circular(context.radii.pill);
    final duration = context.motionDuration(const Duration(milliseconds: 140));

    late final Color background;
    late final Color foreground;
    late final Color borderColor;
    if (!enabled) {
      background = ws.canvas;
      foreground = ws.muted;
      borderColor = ws.border;
    } else {
      switch (widget.variant) {
        case WorkshopButtonVariant.primary:
          background = _hovered || _pressed ? ws.accentHover : ws.accent;
          foreground = ws.onAccent;
          borderColor = Colors.transparent;
        case WorkshopButtonVariant.secondary:
          background = _hovered || _pressed ? ws.canvas : ws.surface;
          foreground = ws.ink;
          borderColor = ws.border;
        case WorkshopButtonVariant.ghost:
          background = _hovered || _pressed
              ? ws.accentSoft
              : Colors.transparent;
          foreground = ws.ink;
          borderColor = Colors.transparent;
        case WorkshopButtonVariant.danger:
          background = _hovered || _pressed ? ws.dangerSoft : ws.surface;
          foreground = ws.danger;
          borderColor = ws.danger;
      }
    }

    final labelStyle = ws.bodyStrong.copyWith(color: foreground);
    final child = widget.isLoading
        ? SizedBox.square(
            dimension: spacing.lg,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: foreground),
                SizedBox(width: spacing.sm),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ),
            ],
          );

    final surface = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: ws.touchTarget,
        minWidth: ws.touchTarget,
      ),
      child: SizedBox(
        height: context.sizing.buttonHeight,
        width: widget.expand ? double.infinity : null,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing.lg),
          child: Center(widthFactor: widget.expand ? null : 1, child: child),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: AnimatedContainer(
        duration: duration,
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          boxShadow: _focused
              ? <BoxShadow>[
                  BoxShadow(
                    color: ws.focus.withValues(alpha: 0.35),
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: borderColor),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? widget.onPressed : null,
            onFocusChange: (value) => setState(() => _focused = value),
            onHover: (value) => setState(() => _hovered = value),
            onHighlightChanged: (value) => setState(() => _pressed = value),
            borderRadius: radius,
            canRequestFocus: enabled,
            child: ExcludeSemantics(child: surface),
          ),
        ),
      ),
    );
  }
}

/// 44 Ã— 44 icon action with a visible focus ring.
class WorkshopIconButton extends StatefulWidget {
  const WorkshopIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tooltip,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool selected;

  @override
  State<WorkshopIconButton> createState() => _WorkshopIconButtonState();
}

class _WorkshopIconButtonState extends State<WorkshopIconButton> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(context.radii.pill);
    final background = widget.selected
        ? ws.accentSoft
        : _hovered && enabled
        ? ws.canvas
        : Colors.transparent;
    final foreground = widget.selected
        ? ws.accent
        : enabled
        ? ws.ink
        : ws.muted;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: Tooltip(
        message: widget.tooltip ?? widget.semanticLabel,
        excludeFromSemantics: true,
        child: AnimatedContainer(
          duration: context.motionDuration(const Duration(milliseconds: 140)),
          curve: context.motion.enterCurve,
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            boxShadow: _focused
                ? <BoxShadow>[
                    BoxShadow(
                      color: ws.focus.withValues(alpha: 0.35),
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onPressed,
              onFocusChange: (value) => setState(() => _focused = value),
              onHover: (value) => setState(() => _hovered = value),
              borderRadius: radius,
              canRequestFocus: enabled,
              child: SizedBox.square(
                dimension: ws.touchTarget,
                child: Icon(widget.icon, size: 20, color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards and headers
// ---------------------------------------------------------------------------

/// White, hairline-bordered, shadow-free workshop surface.
class WorkshopCard extends StatelessWidget {
  const WorkshopCard({
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final radius = BorderRadius.circular(ws.cardRadius);
    final content = Padding(
      padding: padding ?? EdgeInsetsDirectional.all(ws.cardPadding),
      child: child,
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ws.surface,
          borderRadius: radius,
          border: Border.all(color: ws.border),
        ),
        child: onTap == null
            ? content
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  child: content,
                ),
              ),
      ),
    );
  }
}

/// 19 px section title with an optional muted subtitle and a trailing action.
class WorkshopSectionHeader extends StatelessWidget {
  const WorkshopSectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: ws.sectionTitle),
        if (subtitle != null) ...[
          SizedBox(height: context.spacing.xs),
          Text(subtitle!, style: ws.meta.copyWith(color: ws.muted)),
        ],
      ],
    );
    return Semantics(
      container: true,
      header: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final stack =
              action != null &&
              (constraints.maxWidth < 320 || textScale > 1.35);
          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                heading,
                SizedBox(height: context.spacing.xs),
                action!,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              if (action != null) ...[
                SizedBox(width: context.spacing.md),
                action!,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Responsive page heading: title plus actions on one row from 680 px, stacked
/// on phones with the primary action still visible (full width when needed).
/// No search slot here â€” pair with [WorkshopToolbar] for filters.
class WorkshopPageHeader extends StatelessWidget {
  const WorkshopPageHeader({
    required this.title,
    this.subtitle,
    this.primaryAction,
    this.secondaryActions = const [],
    this.eyebrow,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? primaryAction;
  final List<Widget> secondaryActions;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!, style: ws.eyebrow.copyWith(color: ws.muted)),
          SizedBox(height: spacing.xs),
        ],
        Semantics(header: true, child: Text(title, style: ws.pageTitle)),
        if (subtitle != null) ...[
          SizedBox(height: spacing.xs),
          Text(subtitle!, style: ws.body.copyWith(color: ws.muted)),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              heading,
              if (primaryAction != null) ...[
                SizedBox(height: spacing.lg),
                SizedBox(width: double.infinity, child: primaryAction),
              ],
              if (secondaryActions.isNotEmpty) ...[
                SizedBox(height: spacing.sm),
                Wrap(
                  spacing: spacing.sm,
                  runSpacing: spacing.sm,
                  children: secondaryActions,
                ),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            if (secondaryActions.isNotEmpty || primaryAction != null) ...[
              SizedBox(width: spacing.lg),
              Wrap(
                spacing: spacing.sm,
                runSpacing: spacing.sm,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [...secondaryActions, ?primaryAction],
              ),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

/// Compact 44 px search field (max 360 wide) with a hairline border and focus
/// ring. Never stretches full page width.
class WorkshopSearchField extends StatefulWidget {
  const WorkshopSearchField({
    required this.controller,
    required this.hint,
    required this.semanticLabel,
    this.onChanged,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final String semanticLabel;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<WorkshopSearchField> createState() => _WorkshopSearchFieldState();
}

class _WorkshopSearchFieldState extends State<WorkshopSearchField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (mounted) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(context.radii.xl);
    return Semantics(
      textField: true,
      label: widget.semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AnimatedContainer(
          duration: context.motionDuration(const Duration(milliseconds: 140)),
          curve: context.motion.enterCurve,
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: radius,
            boxShadow: _focused
                ? <BoxShadow>[
                    BoxShadow(
                      color: ws.focus.withValues(alpha: 0.3),
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: _focused ? ws.accent : ws.border),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: context.sizing.inputHeight),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              enabled: widget.enabled,
              textAlignVertical: TextAlignVertical.center,
              style: ws.body.copyWith(color: ws.ink),
              cursorColor: ws.accent,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.sm,
                  vertical: spacing.sm,
                ),
                hintText: widget.hint,
                hintStyle: ws.body.copyWith(color: ws.muted),
                prefixIconConstraints: BoxConstraints(
                  minWidth: ws.touchTarget,
                  minHeight: ws.touchTarget,
                ),
                prefixIcon: Icon(Icons.search, size: 18, color: ws.muted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 56 px workshop text field with a persistent label above the control.
///
/// The optional [key] is attached to the inner [TextFormField] so existing
/// tests can read `TextFormField` state straight from the key (the outer
/// widget stays keyless by design).
class WorkshopTextField extends StatefulWidget {
  // The constructor key is forwarded to the inner TextFormField on purpose
  // (see the class doc); the outer widget intentionally stays keyless.
  // ignore: use_key_in_widget_constructors
  const WorkshopTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autofillHints,
    Key? key,
  }) : _fieldKey = key;

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final Iterable<String>? autofillHints;

  final Key? _fieldKey;

  @override
  State<WorkshopTextField> createState() => _WorkshopTextFieldState();
}

class _WorkshopTextFieldState extends State<WorkshopTextField> {
  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(context.radii.xl);
    final idle = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: ws.border),
    );
    final focused = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: ws.accent, width: 1.6),
    );
    final invalid = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: ws.danger, width: 1.2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: ws.meta.copyWith(color: ws.ink, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: spacing.xs),
        TextFormField(
          key: widget._fieldKey,
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          autofocus: widget.autofocus,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          enabled: widget.enabled,
          autofillHints: widget.autofillHints,
          textAlignVertical: TextAlignVertical.center,
          style: ws.body.copyWith(color: ws.ink, fontSize: 15),
          cursorColor: ws.accent,
          // The decoration draws the border, so the validation message lands
          // under the field instead of inside a hand-drawn box.
          decoration: InputDecoration(
            isDense: false,
            filled: true,
            fillColor: widget.enabled ? ws.surface : ws.canvas,
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: idle,
            enabledBorder: idle,
            disabledBorder: idle,
            focusedBorder: focused,
            errorBorder: invalid,
            focusedErrorBorder: focused,
            hintText: widget.hint,
            hintStyle: ws.body.copyWith(color: ws.muted),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: widget.suffixIcon,
                  ),
            errorStyle: ws.meta.copyWith(color: ws.danger),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

/// 32 px pill filter chip (44 px tap target) that renders the count inside the
/// label, e.g. `All (3)`.
class WorkshopFilterChip extends StatefulWidget {
  const WorkshopFilterChip({
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<WorkshopFilterChip> createState() => _WorkshopFilterChipState();
}

class _WorkshopFilterChipState extends State<WorkshopFilterChip> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final radius = BorderRadius.circular(context.radii.pill);
    final text = widget.count == null
        ? widget.label
        : '${widget.label} (${widget.count})';
    return Semantics(
      button: true,
      selected: widget.selected,
      label: text,
      child: AnimatedContainer(
        duration: context.motionDuration(const Duration(milliseconds: 120)),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _focused
              ? <BoxShadow>[
                  BoxShadow(
                    color: ws.focus.withValues(alpha: 0.35),
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            child: SizedBox(
              height: ws.touchTarget,
              child: Center(
                widthFactor: 1,
                child: Ink(
                  decoration: BoxDecoration(
                    color: widget.selected ? ws.accentSoft : ws.surface,
                    borderRadius: radius,
                    border: Border.all(
                      color: widget.selected ? ws.accent : ws.border,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 32),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          text,
                          maxLines: 1,
                          style: ws.bodyStrong.copyWith(color: ws.ink),
                        ),
                      ),
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

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

enum WorkshopStatusTone { neutral, accent, success, warning, danger }

/// Small status pill with dot/icon + text. Status is never colour-only.
class WorkshopStatusBadge extends StatelessWidget {
  const WorkshopStatusBadge({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final WorkshopStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final (Color foreground, Color background) = switch (tone) {
      WorkshopStatusTone.neutral => (ws.ink, ws.canvas),
      WorkshopStatusTone.accent => (ws.accent, ws.accentSoft),
      WorkshopStatusTone.success => (ws.success, ws.successSoft),
      WorkshopStatusTone.warning => (ws.warning, ws.warningSoft),
      WorkshopStatusTone.danger => (ws.danger, ws.dangerSoft),
    };
    return Semantics(
      container: true,
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(context.radii.pill),
          border: Border.all(color: foreground.withValues(alpha: 0.28)),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: context.spacing.xs,
          runSpacing: context.spacing.xxs,
          children: [
            if (icon != null)
              Icon(icon, size: 13, color: foreground)
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: foreground,
                ),
              ),
            Text(
              label,
              softWrap: true,
              style: ws.meta.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Initials disc. Never truncates.
class WorkshopAvatar extends StatelessWidget {
  const WorkshopAvatar({
    required this.initials,
    required this.semanticLabel,
    this.size = 36,
    this.onTap,
    super.key,
  });

  final String initials;
  final String semanticLabel;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: ws.accentSoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        maxLines: 1,
        style: ws.bodyStrong.copyWith(color: ws.accent, fontSize: size * 0.36),
      ),
    );
    return Semantics(
      container: true,
      image: onTap == null,
      button: onTap != null,
      label: semanticLabel,
      child: onTap == null
          ? ExcludeSemantics(child: disc)
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: ExcludeSemantics(child: disc),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metrics
// ---------------------------------------------------------------------------

/// One metric inside a [WorkshopMetricStrip].
///
/// Reuses the workshop metric descriptor (label + value) so the strip renders
/// a single coherent surface instead of stacked cards.
class WorkshopMetricStrip extends StatelessWidget {
  const WorkshopMetricStrip({required this.items, super.key});

  final List<WorkshopMetric> items;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final cells = <Widget>[
          for (final item in items)
            Expanded(
              child: _MetricCell(key: item.key, metric: item),
            ),
        ];
        final Widget content;
        if (wide) {
          content = IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _withVerticalSeparators(context, cells),
            ),
          );
        } else {
          final rows = <Widget>[];
          for (var i = 0; i < cells.length; i += 2) {
            final pair = cells.skip(i).take(2).toList(growable: false);
            if (rows.isNotEmpty) {
              rows.add(const WorkshopDivider());
            }
            rows.add(
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _withVerticalSeparators(context, pair),
                ),
              ),
            );
          }
          content = Column(mainAxisSize: MainAxisSize.min, children: rows);
        }
        return Container(
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: BorderRadius.circular(ws.cardRadius),
            border: Border.all(color: ws.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        );
      },
    );
  }

  List<Widget> _withVerticalSeparators(
    BuildContext context,
    List<Widget> cells,
  ) {
    final out = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      if (i > 0) {
        out.add(Container(width: 1, color: context.ws.border));
      }
      out.add(cells[i]);
    }
    return out;
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric, super.key});

  final WorkshopMetric metric;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Semantics(
      container: true,
      label: '${metric.value}, ${metric.label}',
      child: Padding(
        padding: EdgeInsetsDirectional.all(ws.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(metric.value, style: ws.sectionTitle),
            SizedBox(height: context.spacing.xs),
            Text(metric.label, style: ws.meta.copyWith(color: ws.muted)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account menu
// ---------------------------------------------------------------------------

/// Avatar trigger + account menu (full name, email, settings, language, sign
/// out). PopupMenuButton supplies Escape/arrow-key behaviour.
class WorkshopAccountMenu extends StatefulWidget {
  const WorkshopAccountMenu({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.onSettings,
    required this.onSignOut,
    required this.onToggleLanguage,
    required this.languageLabel,
    required this.settingsLabel,
    required this.signOutLabel,
    this.compact = false,
    super.key,
  });

  final String initials;
  final String displayName;
  final String email;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final VoidCallback onToggleLanguage;
  final String languageLabel;
  final bool compact;
  final String settingsLabel;
  final String signOutLabel;

  @override
  State<WorkshopAccountMenu> createState() => _WorkshopAccountMenuState();
}

class _WorkshopAccountMenuState extends State<WorkshopAccountMenu> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(context.radii.pill);

    final trigger = widget.compact
        ? WorkshopAvatar(
            initials: widget.initials,
            semanticLabel: widget.displayName,
            size: 36,
          )
        : Row(
            children: [
              WorkshopAvatar(
                initials: widget.initials,
                semanticLabel: widget.displayName,
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.displayName, style: ws.bodyStrong),
                    if (widget.email.isNotEmpty)
                      Text(
                        widget.email,
                        style: ws.meta.copyWith(color: ws.muted),
                      ),
                  ],
                ),
              ),
            ],
          );

    return Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: AnimatedContainer(
        duration: context.motionDuration(const Duration(milliseconds: 140)),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _focused
              ? <BoxShadow>[
                  BoxShadow(
                    color: ws.focus.withValues(alpha: 0.35),
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: PopupMenuButton<int>(
          tooltip: widget.displayName,
          position: PopupMenuPosition.under,
          constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
          color: ws.surface,
          onSelected: (value) {
            if (value == 1) {
              widget.onSettings();
            } else if (value == 2) {
              widget.onToggleLanguage();
            } else if (value == 3) {
              widget.onSignOut();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              enabled: false,
              child: Semantics(
                header: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.displayName, style: ws.bodyStrong),
                    if (widget.email.isNotEmpty)
                      Text(
                        widget.email,
                        style: ws.meta.copyWith(color: ws.muted),
                      ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<int>(
              value: 1,
              child: _AccountMenuRow(
                icon: Icons.settings_outlined,
                label: widget.settingsLabel,
              ),
            ),
            PopupMenuItem<int>(
              value: 2,
              child: _AccountMenuRow(
                icon: Icons.language,
                label: widget.languageLabel,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<int>(
              value: 3,
              child: _AccountMenuRow(
                icon: Icons.logout,
                label: widget.signOutLabel,
                tone: ws.danger,
              ),
            ),
          ],
          child: Semantics(
            button: true,
            label: widget.displayName,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: ws.touchTarget),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.xs,
                  vertical: spacing.xs,
                ),
                child: ExcludeSemantics(child: trigger),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountMenuRow extends StatelessWidget {
  const _AccountMenuRow({required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final color = tone ?? ws.ink;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: Text(label, style: ws.body.copyWith(color: color)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

/// Compact empty state (no oversized illustration).
class WorkshopEmptyState extends StatelessWidget {
  const WorkshopEmptyState({
    required this.title,
    this.body,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  final String title;
  final String? body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsetsDirectional.all(ws.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: ws.muted),
              SizedBox(height: spacing.sm),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: ws.bodyStrong,
                ),
              ),
              if (body != null) ...[
                SizedBox(height: spacing.xs),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ],
              if (action != null) ...[SizedBox(height: spacing.md), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bounded inline error with human copy and a retry action.
class WorkshopErrorState extends StatelessWidget {
  const WorkshopErrorState({
    required this.title,
    required this.body,
    required this.retryLabel,
    required this.onRetry,
    super.key,
  });

  final String title;
  final String body;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: EdgeInsetsDirectional.all(ws.cardPadding),
        decoration: BoxDecoration(
          color: ws.dangerSoft,
          borderRadius: BorderRadius.circular(ws.cardRadius),
          border: Border.all(color: ws.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: ws.danger),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: ws.bodyStrong.copyWith(color: ws.danger),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.xs),
            Text(body, style: ws.body.copyWith(color: ws.ink)),
            SizedBox(height: spacing.md),
            WorkshopButton(
              label: retryLabel,
              onPressed: onRetry,
              variant: WorkshopButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton blocks for loading states (never a spinner-only page).
class WorkshopSkeleton extends StatefulWidget {
  const WorkshopSkeleton({this.lines = 3, this.card = false, super.key});

  final int lines;
  final bool card;

  @override
  State<WorkshopSkeleton> createState() => _WorkshopSkeletonState();
}

class _WorkshopSkeletonState extends State<WorkshopSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = context.motion.slow * 3;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.55;
    } else if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final bars = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.lines,
        (index) => Padding(
          padding: EdgeInsetsDirectional.only(bottom: spacing.sm),
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: index.isEven ? 1 : 0.7,
            child: Container(
              height: spacing.md,
              decoration: BoxDecoration(
                color: ws.canvas,
                borderRadius: BorderRadius.circular(ws.chipRadius),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 0.9).animate(
          CurvedAnimation(
            parent: _controller,
            curve: context.motion.enterCurve,
          ),
        ),
        child: widget.card
            ? WorkshopCard(child: bars)
            : Padding(
                padding: EdgeInsetsDirectional.all(spacing.xs),
                child: bars,
              ),
      ),
    );
  }
}

/// Small muted note (help text, non-actionable hints).
class WorkshopInlineNote extends StatelessWidget {
  const WorkshopInlineNote({
    required this.text,
    this.icon = Icons.info_outline,
    super.key,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: ws.canvas,
        borderRadius: BorderRadius.circular(ws.chipRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: ws.muted),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Text(text, style: ws.meta.copyWith(color: ws.muted)),
          ),
        ],
      ),
    );
  }
}

/// 1 px hairline divider.
class WorkshopDivider extends StatelessWidget {
  const WorkshopDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.ws.border);
  }
}

// ---------------------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------------------

/// Page scroll container: responsive gutter, 1120 px content column and
/// always-scrollable physics so a [RefreshIndicator] can wrap it.
class WorkshopPageScroll extends StatelessWidget {
  const WorkshopPageScroll({
    required this.children,
    this.controller,
    this.padding,
    this.alwaysScrollable = true,
    super.key,
  });

  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool alwaysScrollable;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return SingleChildScrollView(
      controller: controller,
      physics: alwaysScrollable ? const AlwaysScrollableScrollPhysics() : null,
      padding: padding ?? ws.pagePaddingOf(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// One filter row: compact search (max 360) + wrapping filters. On phones the
/// search stacks above the filters; filters never scroll off horizontally.
class WorkshopToolbar extends StatelessWidget {
  const WorkshopToolbar({
    this.search,
    this.filters = const [],
    this.trailing,
    this.wrap = true,
    super.key,
  });

  final Widget? search;
  final List<Widget> filters;
  final Widget? trailing;

  /// When true (default) search and filters share one row from 680 px and
  /// stack below it. When false the toolbar always uses the stacked layout
  /// (useful inside narrow panels). Filters are always a [Wrap], never a
  /// clipped horizontal bar.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final searchBox = search == null
        ? null
        : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: search,
          );
    final filterWrap = filters.isEmpty
        ? null
        : Wrap(
            spacing: spacing.md,
            runSpacing: spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: filters,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        if (!wide || !wrap) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ?searchBox,
              if (searchBox != null && (filterWrap != null || trailing != null))
                SizedBox(height: spacing.md),
              ?filterWrap,
              if (filterWrap != null && trailing != null)
                SizedBox(height: spacing.md),
              ?trailing,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ?searchBox,
            if (searchBox != null && filterWrap != null)
              SizedBox(width: spacing.md),
            if (filterWrap != null) Expanded(child: filterWrap),
            if (trailing != null) ...[SizedBox(width: spacing.md), trailing!],
          ],
        );
      },
    );
  }
}
