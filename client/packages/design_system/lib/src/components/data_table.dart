import 'dart:math' as math;

import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

typedef AppDataCellBuilder<T> = Widget Function(
  BuildContext context,
  T row,
  int rowIndex,
);

/// Column definition for [AppDataTable]. No column chooser exists in F1.
@immutable
class AppDataColumn<T> {
  const AppDataColumn({
    required this.label,
    required this.cellBuilder,
    this.width,
    this.numeric = false,
    this.semanticLabel,
  });

  final String label;
  final AppDataCellBuilder<T> cellBuilder;
  final double? width;
  final bool numeric;
  final String? semanticLabel;
}

/// Row action shown in the trailing actions cell of [AppDataTable].
@immutable
class AppDataRowAction<T> {
  const AppDataRowAction({
    required this.label,
    required this.onSelected,
    this.icon = Icons.more_horiz,
    this.semanticLabel,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final ValueChanged<T> onSelected;
  final IconData icon;
  final String? semanticLabel;
  final bool destructive;
  final bool enabled;
}

/// Web-oriented data table with a sticky header, sortable columns, row actions,
/// horizontal scrolling and a card fallback below [cardBreakpoint].
///
/// The sticky header is used when the table receives a bounded height (for
/// example inside an `Expanded`). In an unbounded parent the header scrolls with
/// the rows so the widget stays safe to embed in long forms.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    this.onSort,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.rowActions = const [],
    this.actionsLabel,
    this.onRowTap,
    this.rowSemanticLabelBuilder,
    this.empty,
    this.cardBreakpoint = AppBreakpoints.phone,
    this.semanticLabel,
    this.stickyHeader = true,
    super.key,
  });

  final List<AppDataColumn<T>> columns;
  final List<T> rows;
  final void Function(int columnIndex, bool ascending)? onSort;
  final int? sortColumnIndex;
  final bool sortAscending;
  final List<AppDataRowAction<T>> rowActions;
  final String? actionsLabel;
  final ValueChanged<T>? onRowTap;
  final String Function(T row, int rowIndex)? rowSemanticLabelBuilder;
  final Widget? empty;
  final double cardBreakpoint;
  final String? semanticLabel;
  final bool stickyHeader;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < cardBreakpoint) {
          return _buildCards(context);
        }
        if (rows.isEmpty) {
          return empty ?? const SizedBox.shrink();
        }

        final actionWidth = rowActions.isEmpty ? 0.0 : context.sizing.targetMin;
        final widths = _resolveWidths(
          context,
          math.max(0, constraints.maxWidth - actionWidth),
        );
        final tableWidth = math.max(
          widths.fold<double>(0, (total, value) => total + value) + actionWidth,
          constraints.maxWidth,
        );
        final header = _buildHeader(context, widths, actionWidth);
        final body = constraints.maxHeight.isFinite && stickyHeader
            ? _buildStickyBody(
                context,
                widths,
                actionWidth,
                constraints.maxHeight,
              )
            : _buildPlainBody(
                context,
                widths,
                actionWidth,
                header,
                scrollable: constraints.maxHeight.isFinite,
              );

        return Semantics(
          container: true,
          label: semanticLabel,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              height: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : null,
              child: body,
            ),
          ),
        );
      },
    );
  }

  List<double> _resolveWidths(BuildContext context, double available) {
    final explicitTotal = columns
        .where((column) => column.width != null)
        .fold<double>(0, (total, column) => total + column.width!);
    final flexibleCount = columns
        .where((column) => column.width == null)
        .length;
    final fallback = flexibleCount == 0
        ? 0.0
        : math.max(
            (available - explicitTotal) / flexibleCount,
            context.sizing.targetMin * 2,
          );
    return [for (final column in columns) column.width ?? fallback];
  }

  Widget _buildStickyBody(
    BuildContext context,
    List<double> widths,
    double actionWidth,
    double height,
  ) {
    final headerExtent = math.max(
      context.sizing.targetMin,
      MediaQuery.textScalerOf(context).scale(context.sizing.targetMin) +
          context.spacing.md * 2,
    );
    final header = _buildHeader(context, widths, actionWidth);
    return CustomScrollView(
      primary: false,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _TableHeaderDelegate(header: header, extent: headerExtent),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildRow(context, widths, actionWidth, index),
            childCount: rows.length,
          ),
        ),
      ],
    );
  }

  Widget _buildPlainBody(
    BuildContext context,
    List<double> widths,
    double actionWidth,
    Widget header, {
    required bool scrollable,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        for (var index = 0; index < rows.length; index++)
          _buildRow(context, widths, actionWidth, index),
      ],
    );
    if (!scrollable) {
      return content;
    }
    return SingleChildScrollView(primary: false, child: content);
  }

  Widget _buildHeader(
    BuildContext context,
    List<double> widths,
    double actionWidth,
  ) {
    final colors = context.colors;
    final sizing = context.sizing;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: colors.surfaceContainer,
            width: sizing.dividerWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          for (var index = 0; index < columns.length; index++)
            SizedBox(
              width: widths[index],
              child: _buildHeaderCell(context, index),
            ),
          if (actionWidth > 0) SizedBox(width: actionWidth),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, int index) {
    final column = columns[index];
    final colors = context.colors;
    final spacing = context.spacing;
    final sizing = context.sizing;
    final sorted = sortColumnIndex == index;
    final canSort = onSort != null;
    return Semantics(
      header: true,
      button: canSort,
      onTap: canSort
          ? () => onSort!(index, sorted ? !sortAscending : true)
          : null,
      label: column.semanticLabel ?? column.label,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: canSort
                ? () {
                    final ascending = sorted ? !sortAscending : true;
                    onSort!(index, ascending);
                  }
                : null,
            canRequestFocus: canSort,
            focusColor: colors.focus.withValues(alpha: 0.08),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: sizing.targetMin),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.md,
                  vertical: spacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: column.numeric
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        column.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: column.numeric
                            ? TextAlign.end
                            : TextAlign.start,
                        style: context.texts.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (sorted) ...[
                      SizedBox(width: spacing.xs),
                      Icon(
                        sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: sizing.iconSm,
                        color: colors.onSurfaceVariant,
                        semanticLabel: null,
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

  Widget _buildRow(
    BuildContext context,
    List<double> widths,
    double actionWidth,
    int index,
  ) {
    final row = rows[index];
    final colors = context.colors;
    final spacing = context.spacing;
    final sizing = context.sizing;
    final isLast = index == rows.length - 1;
    final label = rowSemanticLabelBuilder?.call(row, index);

    return _DataRowShell(
      onTap: onRowTap == null ? null : () => onRowTap!(row),
      semanticLabel: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: colors.surfaceContainer,
                    width: sizing.dividerWidth,
                  ),
                ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: sizing.targetMin),
          child: Row(
            children: [
              for (
                var columnIndex = 0;
                columnIndex < columns.length;
                columnIndex++
              )
                SizedBox(
                  width: widths[columnIndex],
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: spacing.md,
                      vertical: spacing.sm,
                    ),
                    child: Align(
                      alignment: columns[columnIndex].numeric
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: columns[columnIndex].cellBuilder(
                        context,
                        row,
                        index,
                      ),
                    ),
                  ),
                ),
              if (actionWidth > 0)
                SizedBox(
                  width: actionWidth,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _buildActions(context, row),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, T row) {
    final colors = context.colors;
    if (rowActions.isEmpty) {
      return const SizedBox.shrink();
    }
    if (rowActions.length == 1) {
      final action = rowActions.first;
      return IconButton(
        onPressed: action.enabled ? () => action.onSelected(row) : null,
        tooltip: action.semanticLabel ?? action.label,
        icon: Icon(
          action.icon,
          color: action.destructive ? colors.error : colors.onSurfaceVariant,
        ),
      );
    }
    return PopupMenuButton<int>(
      tooltip:
          actionsLabel ?? MaterialLocalizations.of(context).showMenuTooltip,
      icon: Icon(Icons.more_horiz, color: colors.onSurfaceVariant),
      onSelected: (index) {
        final action = rowActions[index];
        if (action.enabled) {
          action.onSelected(row);
        }
      },
      itemBuilder: (context) => [
        for (var index = 0; index < rowActions.length; index++)
          PopupMenuItem<int>(
            value: index,
            enabled: rowActions[index].enabled,
            child: Row(
              children: [
                Icon(
                  rowActions[index].icon,
                  color: rowActions[index].destructive
                      ? colors.error
                      : colors.onSurfaceVariant,
                ),
                SizedBox(width: context.spacing.sm),
                Flexible(child: Text(rowActions[index].label)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCards(BuildContext context) {
    if (rows.isEmpty) {
      return empty ?? const SizedBox.shrink();
    }
    final spacing = context.spacing;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < rows.length; index++)
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: spacing.md),
              child: _buildCard(context, index),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, int index) {
    final row = rows[index];
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final sizing = context.sizing;
    final radius = BorderRadius.circular(radii.xl);
    final label = rowSemanticLabelBuilder?.call(row, index);

    return Semantics(
      container: true,
      button: onRowTap != null,
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: radius,
          border: Border.all(
            color: colors.surfaceContainer,
            width: sizing.dividerWidth,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onRowTap == null ? null : () => onRowTap!(row),
            canRequestFocus: onRowTap != null,
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsetsDirectional.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final column in columns)
                    Padding(
                      padding: EdgeInsetsDirectional.only(bottom: spacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            column.label,
                            style: context.texts.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: spacing.xs),
                          Align(
                            alignment: column.numeric
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            child: column.cellBuilder(context, row, index),
                          ),
                        ],
                      ),
                    ),
                  if (rowActions.isNotEmpty)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _buildActions(context, row),
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

class _DataRowShell extends StatefulWidget {
  const _DataRowShell({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<_DataRowShell> createState() => _DataRowShellState();
}

class _DataRowShellState extends State<_DataRowShell> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          boxShadow: _focused ? [context.shadows.focus] : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            canRequestFocus: widget.onTap != null,
            onFocusChange: (value) => setState(() => _focused = value),
            focusColor: context.colors.focus.withValues(alpha: 0.08),
            hoverColor: context.colors.focus.withValues(alpha: 0.04),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _TableHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TableHeaderDelegate({required this.header, required this.extent});

  final Widget header;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: header);
  }

  @override
  bool shouldRebuild(covariant _TableHeaderDelegate oldDelegate) {
    return oldDelegate.header != header || oldDelegate.extent != extent;
  }
}
