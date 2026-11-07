import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.titleDirection,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  /// Explicit direction for identifier-like titles (references, VINs).
  final TextDirection? titleDirection;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textDirection: titleDirection,
            style: context.texts.headlineSmall,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: context.spacing.xs),
          Text(
            subtitle!,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackAction =
              action != null &&
              (constraints.maxWidth < context.sizing.targetMin * 7 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.2);
          if (action == null) {
            return heading;
          }
          if (stackAction) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                SizedBox(height: context.spacing.sm),
                action!,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              SizedBox(width: context.spacing.md),
              action!,
            ],
          );
        },
      ),
    );
  }
}

class AppListTile extends StatefulWidget {
  const AppListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.enabled = true,
    this.titleDirection,
    this.subtitleDirection,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final bool enabled;

  /// Explicit directions for identifier-like content (references, VINs,
  /// plates, phone numbers). Names stay ambient.
  final TextDirection? titleDirection;
  final TextDirection? subtitleDirection;

  @override
  State<AppListTile> createState() => _AppListTileState();
}

class _AppListTileState extends State<AppListTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = widget.enabled ? widget.onTap : null;
    final radius = BorderRadius.circular(context.radii.lg);
    final content = Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            SizedBox(width: context.spacing.md),
          ],
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    textDirection: widget.titleDirection,
                    style: context.texts.titleMedium,
                  ),
                  if (widget.subtitle != null) ...[
                    SizedBox(height: context.spacing.xs),
                    Text(
                      widget.subtitle!,
                      textDirection: widget.subtitleDirection,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            SizedBox(width: context.spacing.md),
            Flexible(
              fit: FlexFit.loose,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: widget.trailing!,
              ),
            ),
          ],
        ],
      ),
    );
    return Semantics(
      container: true,
      button: effectiveOnTap != null,
      enabled: effectiveOnTap != null ? widget.enabled : null,
      label: widget.semanticLabel,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _focused ? [context.shadows.focus] : null,
        ),
        child: InkWell(
          onTap: effectiveOnTap,
          onLongPress: widget.enabled ? widget.onLongPress : null,
          canRequestFocus: effectiveOnTap != null,
          onFocusChange: (value) => setState(() => _focused = value),
          borderRadius: radius,
          focusColor: context.colors.primary.withValues(alpha: 0.1),
          hoverColor: context.colors.primary.withValues(alpha: 0.08),
          highlightColor: context.colors.primary.withValues(alpha: 0.12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: context.sizing.targetMin),
            child: content,
          ),
        ),
      ),
    );
  }
}
