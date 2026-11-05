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
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(child: body),
    );
  }
}

class AppSliverScaffold extends StatelessWidget {
  const AppSliverScaffold({
    required this.slivers,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
    super.key,
  });

  final List<Widget> slivers;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: CustomScrollView(slivers: slivers),
    );
  }
}

@immutable
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.onTap,
    this.semanticLabel,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool enabled;
}

class AppBottomNavDock extends StatelessWidget {
  const AppBottomNavDock({
    required this.items,
    required this.selectedIndex,
    this.onSelected,
    this.semanticLabel,
    super.key,
  }) : assert(items.length <= 4);

  final List<AppBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final visibleItems = items.length > 4 ? items.sublist(0, 4) : items;
    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }
    final dock = Container(
      constraints: BoxConstraints(minHeight: context.sizing.navDockHeight),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: spacing.xs,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(context.radii.pill),
        boxShadow: context.shadows.floating,
      ),
      child: Row(
        children: [
          for (var index = 0; index < visibleItems.length; index++)
            _NavDockItem(
              item: visibleItems[index],
              selected: index == selectedIndex,
              onSelected: onSelected,
              index: index,
            ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: spacing.xl,
        end: spacing.xl,
        bottom: spacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: Semantics(container: true, label: semanticLabel, child: dock),
      ),
    );
  }
}

class _NavDockItem extends StatefulWidget {
  const _NavDockItem({
    required this.item,
    required this.selected,
    required this.onSelected,
    required this.index,
  });

  final AppBottomNavItem item;
  final bool selected;
  final ValueChanged<int>? onSelected;
  final int index;

  @override
  State<_NavDockItem> createState() => _NavDockItemState();
}

class _NavDockItemState extends State<_NavDockItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.colors;
    final item = widget.item;
    final enabled = item.enabled;
    final onTap = !enabled
        ? null
        : item.onTap ??
              (widget.onSelected == null
                  ? null
                  : () => widget.onSelected!(widget.index));
    final color = !enabled
        ? colors.onSurfaceVariant.withValues(alpha: 0.38)
        : widget.selected
        ? colors.onSurface
        : colors.onSurfaceVariant;
    final label = item.semanticLabel ?? item.label;
    final radius = BorderRadius.circular(context.radii.pill);
    return Expanded(
      child: Semantics(
        container: true,
        button: true,
        selected: widget.selected,
        enabled: enabled && onTap != null,
        onTap: onTap,
        label: label,
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: context.motionDuration(context.motion.fast),
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: _focused ? [context.shadows.focus] : null,
            ),
            child: InkWell(
              onTap: onTap,
              canRequestFocus: onTap != null,
              onFocusChange: (value) => setState(() => _focused = value),
              borderRadius: radius,
              focusColor: colors.primary.withValues(alpha: 0.1),
              hoverColor: colors.primary.withValues(alpha: 0.08),
              highlightColor: colors.primary.withValues(alpha: 0.12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: context.sizing.targetMin,
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: spacing.xs,
                    vertical: spacing.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: widget.selected ? 1 : 0,
                        duration: context.motionDuration(context.motion.fast),
                        child: Container(
                          width: spacing.xs,
                          height: spacing.xs,
                          decoration: BoxDecoration(
                            color: context.brand.ink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                      Icon(
                        widget.selected
                            ? item.selectedIcon ?? item.icon
                            : item.icon,
                        size: context.sizing.iconLg,
                        color: color,
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: context.texts.labelSmall?.copyWith(
                          color: color,
                          fontWeight: widget.selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
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
