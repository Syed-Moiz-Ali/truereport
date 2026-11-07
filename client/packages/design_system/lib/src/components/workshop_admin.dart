import 'dart:ui';

import 'package:design_system/src/components/buttons.dart';
import 'package:design_system/src/components/overlays.dart';
import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared Workshop Admin compositions for F3-A screens 1–4
/// (header, user chip, stat/job/option cards, dialog, side sheet)
/// and F3-B screens 5–8 (staff/metric/template/sequence/drop-zone/locked).
///
/// All text is caller-supplied (ARB-only at call sites); no Figma sample
/// copy, people, vehicles, bays, telemetry or review wording lives here.
/// Light-only, tokens-only. Derived narrow layouts reuse the same widgets
/// with tighter constraints (labelled derived at call sites).

/// Floating blurred workshop header (Figma 1184×80, white 90 % + blur).
///
/// Sits above scrolled content; callers supply title, optional search,
/// actions and the signed-in user chip. Never ships user data of its own.
class WorkshopHeader extends StatelessWidget {
  const WorkshopHeader({
    required this.title,
    this.search,
    this.actions = const [],
    this.user,
    this.leading,
    this.semanticLabel,
    super.key,
  });

  final String title;
  final Widget? search;
  final List<Widget> actions;
  final Widget? user;
  final Widget? leading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radii.xl),
        child: BackdropFilter(
          // Approximates the Figma 48 background blur at half strength
          // for raster cost; recorded in deviations.md (F3-A).
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 80),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: context.spacing.xl,
              vertical: context.spacing.sm,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface.withValues(alpha: 0.9),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Narrow (derived) layouts stack the search below the
                // title row; the 1280 Figma row is unchanged (O3/P7).
                if (constraints.maxWidth < AppBreakpoints.phone) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _titleRow(context),
                      if (search != null) ...[
                        SizedBox(height: context.spacing.sm),
                        search!,
                      ],
                    ],
                  );
                }
                final spacing = context.spacing;
                return Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      SizedBox(width: spacing.sm),
                    ],
                    Flexible(
                      flex: 2,
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.headlineSmall,
                        ),
                      ),
                    ),
                    if (search != null) ...[
                      SizedBox(width: spacing.lg),
                      Flexible(flex: 3, child: search!),
                    ],
                    if (actions.isNotEmpty) ...[
                      SizedBox(width: spacing.md),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var index = 0;
                              index < actions.length;
                              index++) ...[
                            if (index > 0) SizedBox(width: spacing.xs),
                            actions[index],
                          ],
                        ],
                      ),
                    ],
                    if (user != null) ...[
                      SizedBox(width: spacing.md),
                      Flexible(child: user!),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _titleRow(BuildContext context) {
    final spacing = context.spacing;
    return Row(
      children: [
        if (leading != null) ...[leading!, SizedBox(width: spacing.sm)],
        Flexible(
          flex: 2,
          child: Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.headlineSmall,
            ),
          ),
        ),
        if (actions.isNotEmpty) ...[
          SizedBox(width: spacing.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) SizedBox(width: spacing.xs),
                actions[index],
              ],
            ],
          ),
        ],
        if (user != null) ...[
          SizedBox(width: spacing.md),
          Flexible(fit: FlexFit.loose, child: user!),
        ],
      ],
    );
  }
}

/// Signed-in user chip: initials disc + display name (+ workshop name).
/// Never shows a role claim (D-F3-3); role stays out of the product.
class WorkshopUserChip extends StatelessWidget {
  const WorkshopUserChip({
    required this.initials,
    required this.displayName,
    this.workshopName,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final String initials;
  final String displayName;
  final String? workshopName;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final sizing = context.sizing;
    return Semantics(
      container: true,
      button: onTap != null,
      label:
          semanticLabel ??
          (workshopName == null
              ? displayName
              : '$displayName, $workshopName'),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: onTap != null,
          borderRadius: BorderRadius.circular(context.radii.pill),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: sizing.targetMin),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: spacing.sm,
                vertical: spacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: sizing.iconLg * 2,
                    height: sizing.iconLg * 2,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.labelLarge,
                        ),
                        if (workshopName != null)
                          Text(
                            workshopName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// KPI / stat card (Figma 346.7×346.7): icon tile + big number + caption +
/// optional progress track + optional status slot. Values are caller data.
class WorkshopStatCard extends StatelessWidget {
  const WorkshopStatCard({
    required this.value,
    required this.caption,
    this.icon,
    this.progress,
    this.status,
    this.semanticLabel,
    this.onTap,
    super.key,
  });

  final String value;
  final String caption;
  final IconData? icon;
  final double? progress;
  final Widget? status;
  final String? semanticLabel;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final sizing = context.sizing;
    final radius = BorderRadius.circular(context.radii.cardLarge);
    final content = Padding(
      padding: EdgeInsetsDirectional.all(spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: sizing.targetMin,
                  height: sizing.targetMin,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(context.radii.lg),
                  ),
                  child: Icon(
                    icon,
                    size: sizing.iconLg,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: spacing.sm),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: context.texts.displaySmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (status != null) ...[
                SizedBox(width: spacing.sm),
                Flexible(child: status!),
              ],
            ],
          ),
          SizedBox(height: spacing.xs),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (progress != null) ...[
            SizedBox(height: spacing.sm),
            _WorkshopTrack(fraction: progress!.clamp(0.0, 1.0)),
          ],
        ],
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel ?? '$value, $caption',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: radius,
          boxShadow: context.shadows.card,
        ),
        child: onTap == null
            ? content
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  canRequestFocus: true,
                  borderRadius: radius,
                  child: content,
                ),
              ),
      ),
    );
  }
}

/// Job article card (Figma 1104×150): neutral thumbnail tile + title/status
/// row + meta lines + assignee + chevron. Thumbnails are neutral icon
/// tiles — never sample photos (locked rule).
class WorkshopJobCard extends StatefulWidget {
  const WorkshopJobCard({
    required this.title,
    required this.reference,
    this.status,
    this.thumbnail,
    this.meta = const [],
    this.assignee,
    this.onTap,
    this.onOpen,
    this.openSemanticLabel,
    this.semanticLabel,
    super.key,
  });

  final String title;
  final String reference;
  final Widget? status;
  final Widget? thumbnail;
  final List<Widget> meta;
  final Widget? assignee;
  final VoidCallback? onTap;
  final VoidCallback? onOpen;
  final String? openSemanticLabel;
  final String? semanticLabel;

  @override
  State<WorkshopJobCard> createState() => _WorkshopJobCardState();
}

class _WorkshopJobCardState extends State<WorkshopJobCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final sizing = context.sizing;
    final radius = BorderRadius.circular(context.radii.card);
    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: radius,
          boxShadow: [
            ...context.shadows.card,
            if (_focused) context.shadows.focus,
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            canRequestFocus: widget.onTap != null,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: sizing.targetMin * 2),
              child: Padding(
                padding: EdgeInsetsDirectional.all(spacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    widget.thumbnail ??
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(
                              context.radii.lg,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.directions_car_outlined,
                            size: sizing.iconLg,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    SizedBox(width: spacing.lg),
                    Expanded(
                      child: widget.semanticLabel == null
                          ? _WorkshopJobCardText(card: widget)
                          : ExcludeSemantics(
                              child: _WorkshopJobCardText(card: widget),
                            ),
                    ),
                    if (widget.onOpen != null) ...[
                      SizedBox(width: spacing.md),
                      AppIconButton(
                        icon: Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back
                            : Icons.arrow_forward,
                        semanticLabel:
                            widget.openSemanticLabel ?? widget.title,
                        onPressed: widget.onOpen,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkshopTrack extends StatelessWidget {
  const _WorkshopTrack({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(context.radii.pill),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: fraction,
        child: Container(
          decoration: BoxDecoration(
            color: context.brand.fill,
            borderRadius: BorderRadius.circular(context.radii.pill),
          ),
        ),
      ),
    );
  }
}

/// Selectable radio/option card (tier cards, technician rows): tint +
/// filled radio + check when selected; selection is never colour-alone.
class WorkshopOptionCard<T> extends StatefulWidget {
  const WorkshopOptionCard({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.caption,
    this.leading,
    this.trailing,
    this.semanticLabel,
    super.key,
  });

  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final String title;
  final String? caption;
  final Widget? leading;
  final Widget? trailing;
  final String? semanticLabel;

  @override
  State<WorkshopOptionCard<T>> createState() => _WorkshopOptionCardState<T>();
}

class _WorkshopOptionCardState<T> extends State<WorkshopOptionCard<T>> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final spacing = context.spacing;
    final sizing = context.sizing;
    final selected = widget.value == widget.groupValue;
    final radius = BorderRadius.circular(context.radii.lg);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: widget.semanticLabel ?? widget.title,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          color: selected ? brand.container : colors.surfaceContainerLow,
          borderRadius: radius,
          boxShadow: _focused ? [context.shadows.focus] : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => widget.onChanged(widget.value),
            canRequestFocus: true,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            child: ExcludeSemantics(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: sizing.targetMin),
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: spacing.md,
                    vertical: spacing.sm,
                  ),
                  child: Row(
                    children: [
                      _WorkshopRadio(selected: selected),
                      SizedBox(width: spacing.md),
                      if (widget.leading != null) ...[
                        widget.leading!,
                        SizedBox(width: spacing.md),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: context.texts.titleMedium,
                            ),
                            if (widget.caption != null) ...[
                              SizedBox(height: spacing.xs),
                              Text(
                                widget.caption!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.trailing != null) ...[
                        SizedBox(width: spacing.md),
                        widget.trailing!,
                      ],
                    ],
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

class _WorkshopJobCardText extends StatelessWidget {
  const _WorkshopJobCardText({required this.card});

  final WorkshopJobCard card;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                card.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleLarge,
              ),
            ),
            if (card.status != null) ...[
              SizedBox(width: spacing.sm),
              Flexible(child: card.status!),
            ],
          ],
        ),
        SizedBox(height: spacing.xs),
        Text(
          card.reference,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
          style: context.texts.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        for (final line in card.meta) ...[
          SizedBox(height: spacing.xs),
          DefaultTextStyle(
            style:
                context.texts.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ) ??
                const TextStyle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: line,
          ),
        ],
        if (card.assignee != null) ...[
          SizedBox(height: spacing.sm),
          card.assignee!,
        ],
      ],
    );
  }
}

class _WorkshopRadio extends StatelessWidget {
  const _WorkshopRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final colors = context.colors;
    final sizing = context.sizing;
    final size = sizing.iconLg;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? brand.fill : Colors.transparent,
        border: Border.all(
          color: selected ? brand.fill : colors.surfaceContainerHighest,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Icon(Icons.check, size: sizing.iconMd, color: brand.onFill)
          : null,
    );
  }
}

/// Centred workshop dialog (Figma 512 wide): title, subtitle, close,
/// content, actions. Focus is trapped by the modal route; Esc closes;
/// focus returns to the invoker via [WorkshopDialog.show].
class WorkshopDialog extends StatelessWidget {
  const WorkshopDialog({
    required this.title,
    required this.closeSemanticLabel,
    this.subtitle,
    this.content,
    this.actions = const [],
    this.autofocusClose = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? content;
  final List<Widget> actions;
  final String closeSemanticLabel;
  final bool autofocusClose;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String closeSemanticLabel,
    String? subtitle,
    Widget? content,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
  }) async {
    final previouslyFocused = FocusManager.instance.primaryFocus;
    try {
      return await showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierColor: context.colors.scrim,
        builder: (dialogContext) => Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  Navigator.of(dialogContext).pop();
                  return null;
                },
              ),
            },
            child: Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: dialogContext.spacing.lg,
                vertical: dialogContext.spacing.xl,
              ),
              backgroundColor: dialogContext.colors.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  dialogContext.radii.cardLarge,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: WorkshopDialog(
                  title: title,
                  subtitle: subtitle,
                  content: content,
                  actions: actions,
                  closeSemanticLabel: closeSemanticLabel,
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      previouslyFocused?.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Semantics(
      container: true,
      namesRoute: true,
      label: title,
      child: Padding(
        padding: EdgeInsetsDirectional.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: context.texts.headlineSmall,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: spacing.xs),
                        Text(
                          subtitle!,
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: spacing.sm),
                Focus(
                  autofocus: autofocusClose,
                  child: AppIconButton(
                    icon: Icons.close,
                    semanticLabel: closeSemanticLabel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            if (content != null) ...[
              SizedBox(height: spacing.lg),
              Flexible(child: SingleChildScrollView(child: content!)),
            ],
            if (actions.isNotEmpty) ...[
              SizedBox(height: spacing.lg),
              Wrap(
                spacing: spacing.sm,
                runSpacing: spacing.sm,
                alignment: WrapAlignment.end,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Right-hand workshop drawer (Figma 420 wide, fixed footer); below
/// [AppBreakpoints.phone] it falls back to the bottom sheet (O3 derived).
class WorkshopSideSheet extends StatelessWidget {
  const WorkshopSideSheet({
    required this.title,
    required this.closeSemanticLabel,
    this.subtitle,
    this.body,
    this.footer,
    super.key,
  });

  final String title;
  final String closeSemanticLabel;
  final String? subtitle;
  final Widget? body;
  final Widget? footer;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String closeSemanticLabel,
    String? subtitle,
    Widget? body,
    Widget? footer,
    bool barrierDismissible = true,
  }) async {
    if (MediaQuery.sizeOf(context).width < AppBreakpoints.phone) {
      return showAppBottomSheet<T>(
        context,
        child: WorkshopSideSheet(
          title: title,
          subtitle: subtitle,
          body: body,
          footer: footer,
          closeSemanticLabel: closeSemanticLabel,
        ),
      );
    }
    final previouslyFocused = FocusManager.instance.primaryFocus;
    try {
      return await showGeneralDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierLabel: closeSemanticLabel,
        barrierColor: context.colors.scrim,
        transitionDuration:
            context.motionDuration(context.motion.fast),
        pageBuilder: (sheetContext, _, _) => Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  Navigator.of(sheetContext).pop();
                  return null;
                },
              ),
            },
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SizedBox(
                width: 420,
                height: double.infinity,
                child: Material(
                  color: sheetContext.colors.surfaceContainerLowest,
                  borderRadius: BorderRadiusDirectional.horizontal(
                    start: Radius.circular(sheetContext.radii.cardLarge),
                  ).resolve(Directionality.of(sheetContext)),
                  child: SafeArea(
                    child: WorkshopSideSheet(
                      title: title,
                      subtitle: subtitle,
                      body: body,
                      footer: footer,
                      closeSemanticLabel: closeSemanticLabel,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        transitionBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: context.motion.enterCurve,
          );
          final offset = Tween<Offset>(
            begin: Directionality.of(context) == TextDirection.rtl
                ? const Offset(-1, 0)
                : const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved);
          return SlideTransition(position: offset, child: child);
        },
      );
    } finally {
      previouslyFocused?.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Semantics(
      container: true,
      namesRoute: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              spacing.xl,
              spacing.xl,
              spacing.xl,
              spacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: context.texts.headlineSmall,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: spacing.xs),
                        Text(
                          subtitle!,
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: spacing.sm),
                AppIconButton(
                  icon: Icons.close,
                  semanticLabel: closeSemanticLabel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          if (body != null)
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.xl,
                ),
                child: body!,
              ),
            ),
          if (footer != null) ...[
            Padding(
              padding: EdgeInsetsDirectional.all(spacing.xl),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Staff card (screen 5): 56 px avatar tile with status dot, name + role,
/// skill/tag row, trailing action slot (password reset menu etc.).
///
/// Status is display-only: Workshop Admin has no disable/reactivate
/// endpoint (platform-only), so no toggle is rendered; the dot mirrors
/// `StaffMember.status` (ACTIVE = success tone, else neutral).
class WorkshopStaffCard extends StatefulWidget {
  const WorkshopStaffCard({
    required this.displayName,
    required this.statusActive,
    this.roleLabel,
    this.detail,
    this.avatar,
    this.tags = const [],
    this.trailing,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final String displayName;
  final bool statusActive;
  final String? roleLabel;

  /// Optional second line (e.g. a masked email). Always laid out LTR:
  /// identifiers and masked addresses must not mirror in RTL locales.
  final Widget? detail;
  final Widget? avatar;
  final List<Widget> tags;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<WorkshopStaffCard> createState() => _WorkshopStaffCardState();
}

class _WorkshopStaffCardState extends State<WorkshopStaffCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final sizing = context.sizing;
    final radius = BorderRadius.circular(context.radii.card);
    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.semanticLabel ?? widget.displayName,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: radius,
          boxShadow: [
            ...context.shadows.card,
            if (_focused) context.shadows.focus,
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            canRequestFocus: widget.onTap != null,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: sizing.targetMin * 2),
              child: Padding(
                padding: EdgeInsetsDirectional.all(spacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: sizing.targetMin + spacing.sm,
                          height: sizing.targetMin + spacing.sm,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(
                              context.radii.lg,
                            ),
                          ),
                          alignment: Alignment.center,
                          child:
                              widget.avatar ??
                              Text(
                                _initial(widget.displayName),
                                style: context.texts.titleMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                        ),
                        PositionedDirectional(
                          end: -2,
                          bottom: -2,
                          child: Container(
                            width: sizing.iconMd,
                            height: sizing.iconMd,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.statusActive
                                  ? context.statusColors
                                        .forTone(StatusTone.success)
                                        .foreground
                                  : colors.onSurfaceVariant.withValues(
                                      alpha: 0.4,
                                    ),
                              border: Border.all(
                                color: colors.surfaceContainerLowest,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (widget.roleLabel != null) ...[
                          SizedBox(height: spacing.xs),
                          Text(
                            widget.roleLabel!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (widget.detail != null) ...[
                          SizedBox(height: spacing.xs),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: DefaultTextStyle(
                              style:
                                  context.texts.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ) ??
                                  const TextStyle(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: widget.detail!,
                            ),
                          ),
                        ],
                          if (widget.tags.isNotEmpty) ...[
                            SizedBox(height: context.spacing.sm),
                            Wrap(
                              spacing: context.spacing.xs,
                              runSpacing: context.spacing.xs,
                              children: widget.tags,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      SizedBox(width: spacing.sm),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _initial(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

/// Compact metric pod (screens 5/7 KPI cards, screen 8 pods): icon tile +
/// value + label + optional progress track. Values are caller data only.
class WorkshopMetric extends StatelessWidget {
  const WorkshopMetric({
    required this.value,
    required this.label,
    this.icon,
    this.progress,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final String value;
  final String label;
  final IconData? icon;
  final double? progress;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final sizing = context.sizing;
    final radius = BorderRadius.circular(context.radii.card);
    final content = Padding(
      padding: EdgeInsetsDirectional.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: sizing.targetMin,
                  height: sizing.targetMin,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(context.radii.lg),
                  ),
                  child: Icon(
                    icon,
                    size: sizing.iconLg,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: spacing.sm),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: context.texts.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (progress != null) ...[
            SizedBox(height: spacing.sm),
            _WorkshopTrack(fraction: progress!.clamp(0.0, 1.0)),
          ],
        ],
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel ?? '$value, $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: radius,
          boxShadow: context.shadows.card,
        ),
        child: onTap == null
            ? content
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  canRequestFocus: true,
                  borderRadius: radius,
                  child: content,
                ),
              ),
      ),
    );
  }
}

/// Template grid card (screen 7): icon tile + status, title + version,
/// description, requirement pill, footer row (updated + Edit action slot).
class WorkshopTemplateCard extends StatefulWidget {
  const WorkshopTemplateCard({
    required this.title,
    required this.versionLabel,
    this.description,
    this.requirement,
    this.footer,
    this.status,
    this.icon,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final String title;
  final String versionLabel;
  final String? description;
  final Widget? requirement;
  final Widget? footer;
  final Widget? status;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<WorkshopTemplateCard> createState() => _WorkshopTemplateCardState();
}

class _WorkshopTemplateCardState extends State<WorkshopTemplateCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final sizing = context.sizing;
    final radius = BorderRadius.circular(context.radii.cardLarge);
    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.semanticLabel ?? '${widget.title}, ${widget.versionLabel}',
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: radius,
          boxShadow: [
            ...context.shadows.card,
            if (_focused) context.shadows.focus,
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            canRequestFocus: widget.onTap != null,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsetsDirectional.all(spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: sizing.targetMin,
                        height: sizing.targetMin,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                            context.radii.lg,
                          ),
                        ),
                        child: Icon(
                          widget.icon ?? Icons.dashboard_customize_outlined,
                          size: sizing.iconLg,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (widget.status != null) Flexible(child: widget.status!),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    widget.versionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: context.texts.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (widget.description != null) ...[
                    SizedBox(height: spacing.xs),
                    Text(
                      widget.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall,
                    ),
                  ],
                  if (widget.requirement != null) ...[
                    SizedBox(height: spacing.sm),
                    widget.requirement!,
                  ],
                  if (widget.footer != null) ...[
                    SizedBox(height: spacing.sm),
                    widget.footer!,
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

/// Sequence card (screen 8 builder): numeral + title + chips + locked-rule
/// note + trailing control cluster (move/delete/drag provided by caller).
///
/// Reordering itself is screen-owned: wrap rows in a `ReorderableListView`
/// (existing Flutter widget) with `ReorderableDragStartListener` on the
/// handle slot so every drag handle works against the ordered save API.
class WorkshopSequenceCard extends StatefulWidget {
  const WorkshopSequenceCard({
    required this.indexLabel,
    required this.title,
    this.chips = const [],
    this.ruleNote,
    this.controls,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final String indexLabel;
  final String title;
  final List<Widget> chips;
  final Widget? ruleNote;
  final Widget? controls;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<WorkshopSequenceCard> createState() => _WorkshopSequenceCardState();
}

class _WorkshopSequenceCardState extends State<WorkshopSequenceCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(context.radii.lg);
    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.semanticLabel ?? '${widget.indexLabel}, ${widget.title}',
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: radius,
          boxShadow: _focused ? [context.shadows.focus] : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            canRequestFocus: widget.onTap != null,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsetsDirectional.all(spacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      widget.indexLabel,
                      textDirection: TextDirection.ltr,
                      style: context.texts.headlineSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  SizedBox(width: spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.chips.isNotEmpty) ...[
                          SizedBox(height: spacing.xs),
                          Wrap(
                            spacing: spacing.xs,
                            runSpacing: spacing.xs,
                            children: widget.chips,
                          ),
                        ],
                        if (widget.ruleNote != null) ...[
                          SizedBox(height: spacing.xs),
                          DefaultTextStyle(
                            style:
                                context.texts.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ) ??
                                const TextStyle(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            child: widget.ruleNote!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.controls != null) ...[
                    SizedBox(width: spacing.sm),
                    widget.controls!,
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

/// Locked-rule pill: read-only indicator of what the platform locks
/// (`noteRequirement` / `evidenceRequirement` · lockedByPlatform).
class WorkshopLockedPill extends StatelessWidget {
  const WorkshopLockedPill({required this.label, this.semanticLabel, super.key});

  final String label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(StatusTone.neutral);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticLabel ?? label,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.spacing.sm,
          vertical: context.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(context.radii.pill),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: context.spacing.xs,
          children: [
            Icon(
              Icons.lock_outline,
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

/// Dashed drop-zone visual (screen 8): tap-to-add is wired by the screen
/// (existing tap flow); the zone itself never claims backend DnD.
class WorkshopDropZone extends StatefulWidget {
  const WorkshopDropZone({
    required this.label,
    this.hint,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<WorkshopDropZone> createState() => _WorkshopDropZoneState();
}

class _WorkshopDropZoneState extends State<WorkshopDropZone> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(context.radii.lg);
    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.semanticLabel ?? widget.label,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _focused ? [context.shadows.focus] : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            canRequestFocus: widget.onTap != null,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            child: CustomPaint(
              painter: _DashedBorder(
                color: colors.outlineVariant,
                radius: radius,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 96),
                child: Padding(
                  padding: EdgeInsetsDirectional.all(spacing.lg),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: context.sizing.iconLg,
                          color: colors.onSurfaceVariant,
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: context.texts.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (widget.hint != null) ...[
                          SizedBox(height: context.spacing.xs),
                          Text(
                            widget.hint!,
                            textAlign: TextAlign.center,
                            style: context.texts.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
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

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});

  final Color color;
  final BorderRadius radius;

  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
