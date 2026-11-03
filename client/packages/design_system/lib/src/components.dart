import 'package:design_system/src/reduce_motion.dart';
import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.backgroundColor,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      body: SafeArea(child: body),
    );
  }
}

enum AppButtonVariant { primary, tonal, text }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final effective = isLoading ? null : onPressed;
    final child = isLoading
        ? SizedBox.square(
            dimension: spacing.xl,
            child: CircularProgressIndicator(
              strokeWidth: spacing.xs / 2,
              color: variant == AppButtonVariant.primary
                  ? context.colors.onPrimary
                  : context.colors.onSecondaryContainer,
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: spacing.xl),
                SizedBox(width: spacing.sm),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    return Semantics(
      button: true,
      enabled: effective != null,
      label: label,
      child: switch (variant) {
        AppButtonVariant.primary => FilledButton(
          onPressed: effective,
          child: child,
        ),
        AppButtonVariant.tonal => FilledButton.tonal(
          onPressed: effective,
          child: child,
        ),
        AppButtonVariant.text => TextButton(onPressed: effective, child: child),
      },
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.textDirection,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.textInputAction,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textDirection: textDirection,
        autofillHints: autofillHints,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        onChanged: onChanged,
        enabled: enabled,
        readOnly: readOnly,
        maxLines: maxLines,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? EdgeInsetsDirectional.all(context.spacing.lg),
        child: child,
      ),
    );
  }
}

class AppSelectableText extends StatelessWidget {
  const AppSelectableText({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final spacing = context.spacing;
    final radius = context.radii;
    final duration = context.motionDuration(context.motion.fast);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: spacing.huge),
          child: AnimatedContainer(
            duration: duration,
            curve: context.motion.enterCurve,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.secondaryContainer
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(radius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: spacing.lg,
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: spacing.xs),
                ],
                AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: context.motion.enterCurve,
                  style: context.texts.labelLarge!.copyWith(
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Semantics(
      label: label,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
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
          children: [
            if (icon != null)
              Icon(icon, size: context.spacing.lg, color: pair.foreground),
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
    super.key,
  });

  final String label;
  final StatusTone severity;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: label,
      tone: severity,
      icon: Icons.warning_amber_rounded,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
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
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.texts.headlineSmall),
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
            ),
          ),
          if (action != null) ...[SizedBox(width: context.spacing.md), action!],
        ],
      ),
    );
  }
}

class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radii.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.spacing.huge),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: context.spacing.md,
              vertical: context.spacing.sm,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: context.spacing.md),
                ],
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.texts.titleMedium),
                      if (subtitle != null) ...[
                        SizedBox(height: context.spacing.xs),
                        Text(
                          subtitle!,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: context.spacing.md),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: trailing!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.body,
    this.action,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String title;
  final String body;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: context.spacing.xxl,
            color: context.colors.secondary,
          ),
          SizedBox(height: context.spacing.md),
          Text(title, style: context.texts.titleMedium),
          SizedBox(height: context.spacing.xs),
          Text(
            body,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            SizedBox(height: context.spacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    required this.body,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  final String title;
  final String body;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: context.spacing.xxl,
            color: context.colors.error,
          ),
          SizedBox(height: context.spacing.md),
          Text(title, style: context.texts.titleMedium),
          SizedBox(height: context.spacing.xs),
          Text(
            body,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (onRetry != null && retryLabel != null) ...[
            SizedBox(height: context.spacing.lg),
            AppButton(
              label: retryLabel!,
              onPressed: onRetry,
              variant: AppButtonVariant.tonal,
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({this.lines = 3, this.height, super.key});

  final int lines;
  final double? height;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ReduceMotion.enabled(context)) {
      _controller.stop();
      _controller.value = 0.55;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radius = context.radii;
    return Semantics(
      label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 0.8).animate(
          CurvedAnimation(
            parent: _controller,
            curve: context.motion.enterCurve,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            widget.lines,
            (index) => Container(
              height: widget.height ?? spacing.md,
              margin: EdgeInsetsDirectional.only(bottom: spacing.sm),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(radius.sm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.warning;
    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        width: double.infinity,
        padding: EdgeInsetsDirectional.all(context.spacing.md),
        decoration: BoxDecoration(
          color: pair.background,
          border: BorderDirectional(
            bottom: BorderSide(color: pair.foreground.withValues(alpha: 0.25)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off,
              size: context.spacing.lg,
              color: pair.foreground,
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.texts.bodySmall?.copyWith(
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

class FadeInCard extends StatelessWidget {
  const FadeInCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = context.motionDuration(context.motion.normal);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: context.motion.enterCurve,
      builder: (context, value, animatedChild) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, context.spacing.sm * (1 - value)),
          child: animatedChild,
        ),
      ),
      child: child,
    );
  }
}

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton(
          label:
              cancelLabel ??
              MaterialLocalizations.of(context).cancelButtonLabel,
          onPressed: () => Navigator.of(context).pop(false),
          variant: AppButtonVariant.text,
        ),
        AppButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          variant: AppButtonVariant.primary,
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.spacing.lg,
        end: context.spacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + context.spacing.lg,
      ),
      child: child,
    ),
  );
}

class AppSliverScaffold extends StatelessWidget {
  const AppSliverScaffold({
    required this.slivers,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    super.key,
  });

  final List<Widget> slivers;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(slivers: slivers),
    );
  }
}
