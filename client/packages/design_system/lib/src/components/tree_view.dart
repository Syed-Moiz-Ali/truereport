import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Immutable node for [AppTreeView]. Nodes are compared by identity.
@immutable
class AppTreeNode<T> {
  const AppTreeNode({
    required this.data,
    required this.label,
    this.children = const [],
    this.icon,
    this.semanticLabel,
    this.enabled = true,
  });

  final T data;
  final String label;
  final List<AppTreeNode<T>> children;
  final IconData? icon;
  final String? semanticLabel;
  final bool enabled;
}

/// Expandable, keyboard-navigable tree. Drag/drop is intentionally not
/// supported in F1.
class AppTreeView<T> extends StatefulWidget {
  const AppTreeView({
    required this.roots,
    this.selected,
    this.onSelected,
    this.initiallyExpanded,
    this.onExpandedChanged,
    this.showSearch = false,
    this.searchLabel,
    this.searchHint,
    this.searchSemanticLabel,
    this.onSearchChanged,
    this.semanticsLabel,
    this.empty,
    this.expandSemanticLabel,
    this.collapseSemanticLabel,
    super.key,
  });

  final List<AppTreeNode<T>> roots;
  final T? selected;
  final ValueChanged<T>? onSelected;
  final Set<T>? initiallyExpanded;
  final void Function(T node, bool expanded)? onExpandedChanged;
  final bool showSearch;
  final String? searchLabel;
  final String? searchHint;
  final String? searchSemanticLabel;
  final ValueChanged<String>? onSearchChanged;
  final String? semanticsLabel;
  final Widget? empty;
  final String? expandSemanticLabel;
  final String? collapseSemanticLabel;

  @override
  State<AppTreeView<T>> createState() => _AppTreeViewState<T>();
}

class _AppTreeViewState<T> extends State<AppTreeView<T>> {
  late final TextEditingController _searchController;
  late final FocusNode _treeFocusNode;
  late final FocusNode _searchFocusNode;
  final Set<AppTreeNode<T>> _expanded = <AppTreeNode<T>>{};
  T? _internalSelected;
  int _focusedIndex = 0;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _treeFocusNode = FocusNode(debugLabel: 'AppTreeView');
    _searchFocusNode = FocusNode(debugLabel: 'AppTreeView.search');
    _internalSelected = widget.selected;
    final initiallyExpanded = widget.initiallyExpanded;
    if (initiallyExpanded != null) {
      void visit(AppTreeNode<T> node) {
        if (initiallyExpanded.contains(node.data)) {
          _expanded.add(node);
        }
        for (final child in node.children) {
          visit(child);
        }
      }

      for (final root in widget.roots) {
        visit(root);
      }
    }
  }

  @override
  void didUpdateWidget(covariant AppTreeView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      _internalSelected = widget.selected;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _treeFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isSelected(AppTreeNode<T> node) {
    final selected = widget.selected ?? _internalSelected;
    return selected != null && node.data == selected;
  }

  List<_VisibleNode<T>> _collectVisible() {
    final query = _searchController.text.trim().toLowerCase();
    final result = <_VisibleNode<T>>[];

    bool subtreeMatches(AppTreeNode<T> node) {
      if (query.isEmpty) {
        return true;
      }
      if (node.label.toLowerCase().contains(query)) {
        return true;
      }
      return node.children.any(subtreeMatches);
    }

    void visit(AppTreeNode<T> node, int depth, int parentIndex) {
      final selfMatches =
          query.isEmpty || node.label.toLowerCase().contains(query);
      final childMatches =
          query.isNotEmpty && node.children.any(subtreeMatches);
      if (query.isNotEmpty && !selfMatches && !childMatches) {
        return;
      }
      final index = result.length;
      final expanded = query.isNotEmpty
          ? childMatches
          : _expanded.contains(node);
      result.add(
        _VisibleNode<T>(
          node: node,
          depth: depth,
          parentIndex: parentIndex,
          expanded: expanded,
          hasChildren: node.children.isNotEmpty,
        ),
      );
      if (expanded && node.children.isNotEmpty) {
        for (final child in node.children) {
          visit(child, depth + 1, index);
        }
      }
    }

    for (final root in widget.roots) {
      visit(root, 0, -1);
    }
    return result;
  }

  void _setExpanded(AppTreeNode<T> node, bool expanded) {
    setState(() {
      if (expanded) {
        _expanded.add(node);
      } else {
        _expanded.remove(node);
      }
    });
    widget.onExpandedChanged?.call(node.data, expanded);
  }

  void _select(AppTreeNode<T> node) {
    if (!node.enabled) {
      return;
    }
    setState(() => _internalSelected = node.data);
    widget.onSelected?.call(node.data);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_searchFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }
    final visible = _collectVisible();
    if (visible.isEmpty) {
      return KeyEventResult.ignored;
    }
    final current = _focusedIndex.clamp(0, visible.length - 1);
    final target = visible[current];
    final key = event.logicalKey;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final forwardKey = isRtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final backwardKey = isRtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _focusedIndex = (current + 1).clamp(0, visible.length - 1);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(
        () => _focusedIndex = (current - 1).clamp(0, visible.length - 1),
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      setState(() => _focusedIndex = 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      setState(() => _focusedIndex = visible.length - 1);
      return KeyEventResult.handled;
    }
    if (key == forwardKey) {
      if (target.hasChildren) {
        if (!target.expanded) {
          _setExpanded(target.node, true);
        } else if (current + 1 < visible.length &&
            visible[current + 1].parentIndex == current) {
          setState(() => _focusedIndex = current + 1);
        }
      }
      return KeyEventResult.handled;
    }
    if (key == backwardKey) {
      if (target.hasChildren && target.expanded) {
        _setExpanded(target.node, false);
      } else if (target.parentIndex >= 0) {
        setState(() => _focusedIndex = target.parentIndex);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _select(target.node);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onSearchChanged(String value) {
    setState(() {});
    widget.onSearchChanged?.call(value);
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final visible = _collectVisible();
    final focusedIndex = visible.isEmpty
        ? 0
        : _focusedIndex.clamp(0, visible.length - 1);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Focus(
      focusNode: _treeFocusNode,
      onKeyEvent: _handleKey,
      onFocusChange: (value) => setState(() => _hasFocus = value),
      child: Semantics(
        container: true,
        label: widget.semanticsLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showSearch) _buildSearch(context),
            if (visible.isEmpty)
              widget.empty ?? const SizedBox.shrink()
            else
              ListView.builder(
                primary: false,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: visible.length,
                itemBuilder: (context, index) => _buildRow(
                  context,
                  visible[index],
                  index,
                  _hasFocus && index == focusedIndex,
                  isRtl,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
      child: Semantics(
        textField: true,
        label: widget.searchSemanticLabel ?? widget.searchLabel,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            labelText: widget.searchLabel,
            hintText: widget.searchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    onPressed: _clearSearch,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    _VisibleNode<T> entry,
    int index,
    bool focused,
    bool isRtl,
  ) {
    final node = entry.node;
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final sizing = context.sizing;
    final selected = _isSelected(node);
    final foreground = !node.enabled
        ? colors.onSurfaceVariant.withValues(alpha: 0.38)
        : selected
        ? colors.onSecondaryContainer
        : colors.onSurface;
    final background = selected ? colors.secondaryContainer : null;
    final radius = BorderRadius.circular(radii.md);

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      expanded: entry.hasChildren ? entry.expanded : null,
      enabled: node.enabled,
      label: node.semanticLabel ?? node.label,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          boxShadow: focused ? [context.shadows.focus] : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              _treeFocusNode.requestFocus();
              setState(() => _focusedIndex = index);
              _select(node);
            },
            canRequestFocus: false,
            borderRadius: radius,
            hoverColor: colors.focus.withValues(alpha: 0.04),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: sizing.targetMin),
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: entry.depth * spacing.lg + spacing.xs,
                  end: spacing.sm,
                ),
                child: Row(
                  children: [
                    if (entry.hasChildren)
                      _ExpandButton(
                        expanded: entry.expanded,
                        isRtl: isRtl,
                        label: entry.expanded
                            ? widget.collapseSemanticLabel ?? node.label
                            : widget.expandSemanticLabel ?? node.label,
                        onTap: () {
                          _treeFocusNode.requestFocus();
                          setState(() => _focusedIndex = index);
                          _setExpanded(node, !entry.expanded);
                        },
                      )
                    else
                      SizedBox.square(dimension: sizing.targetMin),
                    if (node.icon != null) ...[
                      Icon(node.icon, size: sizing.iconMd, color: foreground),
                      SizedBox(width: spacing.sm),
                    ],
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          node.label,
                          style: context.texts.bodyMedium?.copyWith(
                            color: foreground,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
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
    );
  }
}

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({
    required this.expanded,
    required this.isRtl,
    required this.label,
    required this.onTap,
  });

  final bool expanded;
  final bool isRtl;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sizing = context.sizing;
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.radii.md),
          child: SizedBox.square(
            dimension: sizing.targetMin,
            child: Center(
              child: AnimatedRotation(
                turns: expanded ? 0 : (isRtl ? -0.25 : 0.25),
                duration: context.motionDuration(context.motion.fast),
                curve: context.motion.enterCurve,
                child: Icon(
                  Icons.expand_more,
                  size: sizing.iconMd,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisibleNode<T> {
  const _VisibleNode({
    required this.node,
    required this.depth,
    required this.parentIndex,
    required this.expanded,
    required this.hasChildren,
  });

  final AppTreeNode<T> node;
  final int depth;
  final int parentIndex;
  final bool expanded;
  final bool hasChildren;
}
