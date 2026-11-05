import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

@immutable
class AdminNavItem {
  const AdminNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
    this.semanticLabel,
    this.badge,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Widget? badge;
  final bool enabled;
}

enum AdminSidebarVariant { expanded, rail }

/// Persistent admin sidebar. Callers supply the brand, items and optional
/// footer; no route names or user data live in the design system.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    required this.brand,
    required this.items,
    this.variant = AdminSidebarVariant.expanded,
    this.brandSemanticLabel,
    this.semanticsLabel,
    this.footer,
    super.key,
  });

  final Widget brand;
  final List<AdminNavItem> items;
  final AdminSidebarVariant variant;
  final String? brandSemanticLabel;
  final String? semanticsLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.colors;
    final expanded = variant == AdminSidebarVariant.expanded;
    final width = expanded
        ? spacing.huge * 5 + spacing.lg
        : spacing.huge + spacing.xl;
    final horizontalPadding = expanded ? spacing.md : spacing.xs;

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(color: colors.surfaceLowest),
        child: SafeArea(
          top: false,
          child: Semantics(
            container: true,
            label: semanticsLabel,
            child: ListView(
              primary: false,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: horizontalPadding,
                vertical: spacing.xl,
              ),
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(bottom: spacing.xl),
                  child: Semantics(
                    label: brandSemanticLabel,
                    child: expanded
                        ? Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: brand,
                          )
                        : Center(child: brand),
                  ),
                ),
                for (final item in items)
                  Padding(
                    padding: EdgeInsetsDirectional.only(bottom: spacing.xs),
                    child: expanded
                        ? _AdminSidebarTile(item: item)
                        : _AdminRailTile(item: item),
                  ),
                if (footer != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: spacing.xl),
                    child: expanded ? footer! : Center(child: footer!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSidebarTile extends StatefulWidget {
  const _AdminSidebarTile({required this.item});

  final AdminNavItem item;

  @override
  State<_AdminSidebarTile> createState() => _AdminSidebarTileState();
}

class _AdminSidebarTileState extends State<_AdminSidebarTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final spacing = context.spacing;
    final colors = context.colors;
    final brand = context.brand;
    final sizing = context.sizing;
    final radius = BorderRadius.circular(context.radii.lg);
    final foreground = item.selected
        ? brand.onContainer
        : colors.onSurfaceVariant;

    return Semantics(
      container: true,
      button: true,
      selected: item.selected,
      enabled: item.enabled,
      onTap: item.enabled ? item.onTap : null,
      label: item.semanticLabel ?? item.label,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: context.motionDuration(context.motion.fast),
          curve: context.motion.enterCurve,
          decoration: BoxDecoration(
            color: item.selected ? brand.container : null,
            borderRadius: radius,
            boxShadow: _focused ? [context.shadows.focus] : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: item.enabled ? item.onTap : null,
              canRequestFocus: item.enabled,
              onFocusChange: (value) => setState(() => _focused = value),
              borderRadius: radius,
              focusColor: colors.focus.withValues(alpha: 0.1),
              hoverColor: colors.focus.withValues(alpha: 0.06),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: sizing.targetMin),
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: spacing.sm,
                    vertical: spacing.xs,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: context.motionDuration(context.motion.fast),
                        curve: context.motion.enterCurve,
                        width: spacing.xs,
                        height: spacing.xl,
                        decoration: BoxDecoration(
                          color: item.selected ? brand.ink : null,
                          borderRadius: BorderRadius.circular(
                            context.radii.pill,
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Icon(item.icon, size: sizing.iconMd, color: foreground),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: Text(
                          item.label,
                          style: context.texts.labelLarge?.copyWith(
                            color: item.enabled
                                ? foreground
                                : colors.onSurfaceVariant.withValues(
                                    alpha: 0.38,
                                  ),
                            fontWeight: item.selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (item.badge != null) ...[
                        SizedBox(width: spacing.sm),
                        item.badge!,
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

class _AdminRailTile extends StatefulWidget {
  const _AdminRailTile({required this.item});

  final AdminNavItem item;

  @override
  State<_AdminRailTile> createState() => _AdminRailTileState();
}

class _AdminRailTileState extends State<_AdminRailTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = context.colors;
    final brand = context.brand;
    final sizing = context.sizing;
    final radius = BorderRadius.circular(context.radii.lg);
    final foreground = item.selected ? brand.ink : colors.onSurfaceVariant;

    return Tooltip(
      message: item.label,
      child: Semantics(
        container: true,
        button: true,
        selected: item.selected,
        enabled: item.enabled,
        onTap: item.enabled ? item.onTap : null,
        label: item.semanticLabel ?? item.label,
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: context.motionDuration(context.motion.fast),
            curve: context.motion.enterCurve,
            decoration: BoxDecoration(
              color: item.selected ? brand.container : null,
              borderRadius: radius,
              boxShadow: _focused ? [context.shadows.focus] : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: item.enabled ? item.onTap : null,
                canRequestFocus: item.enabled,
                onFocusChange: (value) => setState(() => _focused = value),
                borderRadius: radius,
                focusColor: colors.focus.withValues(alpha: 0.1),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: sizing.targetMin,
                    minHeight: sizing.targetMin,
                  ),
                  child: SizedBox(
                    height: sizing.targetMin,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: sizing.iconLg,
                          color: item.enabled
                              ? foreground
                              : colors.onSurfaceVariant.withValues(alpha: 0.38),
                        ),
                        if (item.selected)
                          Positioned(
                            top: context.spacing.xs,
                            child: Container(
                              width: context.spacing.xs,
                              height: context.spacing.xs,
                              decoration: BoxDecoration(
                                color: brand.ink,
                                shape: BoxShape.circle,
                              ),
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
      ),
    );
  }
}

/// 64 dp admin top bar with slots for search, actions and the signed-in user.
/// The bar never supplies its own user data or account-security wording.
class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminTopBar({
    required this.title,
    this.search,
    this.actions = const [],
    this.user,
    this.leading,
    this.height = 64,
    this.semanticsLabel,
    super.key,
  });

  final String title;
  final Widget? search;
  final List<Widget> actions;
  final Widget? user;
  final Widget? leading;
  final double height;
  final String? semanticsLabel;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.colors;

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.xl,
          vertical: spacing.sm,
        ),
        decoration: BoxDecoration(color: colors.surface),
        child: Row(
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
                  style: context.texts.titleLarge,
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
                  for (var index = 0; index < actions.length; index++) ...[
                    if (index > 0) SizedBox(width: spacing.xs),
                    actions[index],
                  ],
                ],
              ),
            ],
            if (user != null) ...[SizedBox(width: spacing.md), user!],
          ],
        ),
      ),
    );
  }
}

/// Responsive admin shell.
///
/// >= 900 dp: 256 dp expanded sidebar.
/// 600-899 dp: collapsed rail.
/// < 600 dp: bottom navigation fallback.
class AdminShell extends StatelessWidget {
  const AdminShell({
    required this.title,
    required this.brand,
    required this.items,
    required this.child,
    this.topBarSearch,
    this.topBarActions = const [],
    this.topBarUser,
    this.topBarLeading,
    this.sidebarFooter,
    this.brandSemanticLabel,
    this.sidebarSemanticsLabel,
    this.navigationSemanticsLabel,
    this.contentPadding,
    super.key,
  });

  final String title;
  final Widget brand;
  final List<AdminNavItem> items;
  final Widget child;
  final Widget? topBarSearch;
  final List<Widget> topBarActions;
  final Widget? topBarUser;
  final Widget? topBarLeading;
  final Widget? sidebarFooter;
  final String? brandSemanticLabel;
  final String? sidebarSemanticsLabel;
  final String? navigationSemanticsLabel;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final expanded = width >= AppBreakpoints.tablet;
        final rail = !expanded && width >= AppBreakpoints.phone;
        final bottom = !expanded && !rail;
        final sidebar = expanded
            ? AdminSidebar(
                brand: brand,
                items: items,
                variant: AdminSidebarVariant.expanded,
                brandSemanticLabel: brandSemanticLabel,
                semanticsLabel: sidebarSemanticsLabel,
                footer: sidebarFooter,
              )
            : rail
            ? AdminSidebar(
                brand: brand,
                items: items,
                variant: AdminSidebarVariant.rail,
                brandSemanticLabel: brandSemanticLabel,
                semanticsLabel: sidebarSemanticsLabel,
                footer: sidebarFooter,
              )
            : null;

        return Scaffold(
          appBar: AdminTopBar(
            title: title,
            search: topBarSearch,
            actions: topBarActions,
            user: topBarUser,
            leading: topBarLeading,
          ),
          bottomNavigationBar: bottom && items.isNotEmpty
              ? _AdminBottomBar(
                  items: items,
                  semanticsLabel: navigationSemanticsLabel,
                )
              : null,
          body: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?sidebar,
                Expanded(
                  child: Padding(
                    padding:
                        contentPadding ??
                        EdgeInsetsDirectional.all(context.spacing.xl),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminBottomBar extends StatelessWidget {
  const _AdminBottomBar({required this.items, required this.semanticsLabel});

  final List<AdminNavItem> items;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizing = context.sizing;
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Container(
        decoration: BoxDecoration(color: colors.surfaceLowest),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: sizing.navDockHeight),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(child: _AdminBottomTile(item: item)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminBottomTile extends StatefulWidget {
  const _AdminBottomTile({required this.item});

  final AdminNavItem item;

  @override
  State<_AdminBottomTile> createState() => _AdminBottomTileState();
}

class _AdminBottomTileState extends State<_AdminBottomTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = context.colors;
    final brand = context.brand;
    final sizing = context.sizing;
    final foreground = item.selected ? brand.ink : colors.onSurfaceVariant;
    final radius = BorderRadius.circular(context.radii.lg);

    return Semantics(
      container: true,
      button: true,
      selected: item.selected,
      enabled: item.enabled,
      onTap: item.enabled ? item.onTap : null,
      label: item.semanticLabel ?? item.label,
      child: ExcludeSemantics(
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
              onTap: item.enabled ? item.onTap : null,
              canRequestFocus: item.enabled,
              onFocusChange: (value) => setState(() => _focused = value),
              borderRadius: radius,
              focusColor: colors.focus.withValues(alpha: 0.1),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: sizing.targetMin),
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: context.spacing.xs,
                    vertical: context.spacing.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: sizing.iconLg,
                        color: item.enabled
                            ? foreground
                            : colors.onSurfaceVariant.withValues(alpha: 0.38),
                      ),
                      SizedBox(height: context.spacing.xs),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: context.texts.labelSmall?.copyWith(
                          color: item.enabled
                              ? foreground
                              : colors.onSurfaceVariant.withValues(alpha: 0.38),
                          fontWeight: item.selected
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
