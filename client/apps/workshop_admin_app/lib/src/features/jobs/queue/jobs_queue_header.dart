import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// Queue heading: an eyebrow over a rule, the title, one primary action.
/// The archive is a secondary route, never a dock destination.
class JobsQueueHeader extends StatelessWidget {
  const JobsQueueHeader({
    required this.onCreate,
    required this.onOpenArchive,
    super.key,
  });

  final VoidCallback onCreate;
  final VoidCallback onOpenArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final create = WorkshopButton(
      key: const Key('jobs-new'),
      label: l10n.newJob,
      icon: Icons.add,
      onPressed: onCreate,
    );
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 2,
              decoration: BoxDecoration(
                color: ws.accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            SizedBox(width: spacing.sm),
            Text(
              l10n.jobsQueueEyebrow.toUpperCase(),
              style: ws.eyebrow.copyWith(color: ws.muted),
            ),
          ],
        ),
        SizedBox(height: spacing.sm),
        Semantics(
          header: true,
          child: Text(l10n.queueTitle, style: ws.pageTitle),
        ),
        SizedBox(height: spacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            l10n.jobsQueueSubtitle,
            style: ws.body.copyWith(color: ws.muted),
          ),
        ),
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
              SizedBox(height: spacing.lg),
              Row(
                children: [
                  Expanded(child: create),
                  SizedBox(width: spacing.sm),
                  _ArchiveMenu(onOpenArchive: onOpenArchive),
                ],
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            SizedBox(width: spacing.lg),
            WorkshopButton(
              key: const Key('jobs-queue-more'),
              label: l10n.jobsArchiveOpen,
              icon: Icons.inventory_2_outlined,
              variant: WorkshopButtonVariant.secondary,
              onPressed: onOpenArchive,
            ),
            SizedBox(width: spacing.sm),
            create,
          ],
        );
      },
    );
  }
}

/// Search plus the one active filter, above the content. Never a wall of chips.
class JobsQueueToolbar extends StatelessWidget {
  const JobsQueueToolbar({
    required this.searchController,
    required this.onSearchChanged,
    required this.filtersActive,
    required this.activeFilterLabel,
    required this.onClearFilters,
    super.key,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool filtersActive;
  final String? activeFilterLabel;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final filter = filtersActive && activeFilterLabel != null
        ? _ActiveFilter(
            label: activeFilterLabel!,
            clearLabel: l10n.jobsClearFilters,
            onClear: onClearFilters,
          )
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final field = QueueSearchField(
          key: const Key('jobs-search'),
          controller: searchController,
          hint: l10n.jobSearch,
          semanticLabel: l10n.jobSearch,
          onChanged: onSearchChanged,
          maxWidth: constraints.maxWidth >= 680 ? 380 : null,
        );
        if (constraints.maxWidth < 680) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              field,
              if (filter != null) ...[
                SizedBox(height: spacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: filter,
                ),
              ],
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: field,
              ),
            ),
            if (filter != null) ...[SizedBox(width: spacing.md), filter],
            const Spacer(),
            Text(l10n.jobsSortNote, style: ws.meta.copyWith(color: ws.muted)),
          ],
        );
      },
    );
  }
}

/// 52 px search with a 14 px radius, an inset focus ring and a clear action.
class QueueSearchField extends StatefulWidget {
  const QueueSearchField({
    required this.controller,
    required this.hint,
    required this.semanticLabel,
    this.onChanged,
    this.maxWidth,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final String semanticLabel;
  final ValueChanged<String>? onChanged;
  final double? maxWidth;

  @override
  State<QueueSearchField> createState() => _QueueSearchFieldState();
}

class _QueueSearchFieldState extends State<QueueSearchField> {
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
    final radius = BorderRadius.circular(ws.controlRadius);
    return Semantics(
      textField: true,
      label: widget.semanticLabel,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth ?? double.infinity,
          minHeight: 52,
        ),
        child: AnimatedContainer(
          duration: context.motionDuration(const Duration(milliseconds: 140)),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: radius,
            border: Border.all(color: ws.border),
            boxShadow: _focused
                ? <BoxShadow>[
                    BoxShadow(
                      color: ws.focus.withValues(alpha: 0.18),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          foregroundDecoration: _focused
              ? BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: ws.focus, width: 2),
                )
              : null,
          child: Row(
            children: [
              SizedBox(width: spacing.md),
              Icon(Icons.search, size: 18, color: ws.muted),
              SizedBox(width: spacing.sm),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: ws.accent,
                  style: ws.body.copyWith(color: ws.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: ws.body.copyWith(color: ws.muted),
                    contentPadding: EdgeInsetsDirectional.symmetric(
                      vertical: spacing.md,
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) {
                    return SizedBox(width: spacing.md);
                  }
                  return Padding(
                    padding: EdgeInsetsDirectional.only(end: spacing.xs),
                    child: Semantics(
                      button: true,
                      label: MaterialLocalizations.of(context)
                          .deleteButtonTooltip,
                      child: InkWell(
                        onTap: () {
                          widget.controller.clear();
                          widget.onChanged?.call('');
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox.square(
                          dimension: 40,
                          child: Icon(Icons.close, size: 16, color: ws.muted),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFilter extends StatelessWidget {
  const _ActiveFilter({
    required this.label,
    required this.clearLabel,
    required this.onClear,
  });

  final String label;
  final String clearLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      height: 40,
      padding: EdgeInsetsDirectional.only(start: spacing.md, end: spacing.xxs),
      decoration: BoxDecoration(
        color: ws.accentSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ws.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: ws.bodyStrong.copyWith(color: ws.accent)),
          SizedBox(width: spacing.xxs),
          Semantics(
            button: true,
            label: clearLabel,
            child: InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(999),
              child: SizedBox.square(
                dimension: 32,
                child: Icon(Icons.close, size: 15, color: ws.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveMenu extends StatelessWidget {
  const _ArchiveMenu({required this.onOpenArchive});

  final VoidCallback onOpenArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return PopupMenuButton<String>(
      key: const Key('jobs-queue-more'),
      tooltip: l10n.jobsArchiveTitle,
      position: PopupMenuPosition.under,
      color: ws.surface,
      onSelected: (_) => onOpenArchive(),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          key: const Key('jobs-archive-open'),
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 18, color: ws.ink),
              SizedBox(width: context.spacing.sm),
              Text(
                l10n.jobsArchiveOpen,
                style: ws.body.copyWith(color: ws.ink),
              ),
            ],
          ),
        ),
      ],
      child: Semantics(
        button: true,
        label: l10n.jobsArchiveOpen,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: BorderRadius.circular(ws.controlRadius),
            border: Border.all(color: ws.border),
          ),
          child: Icon(Icons.more_horiz, size: 20, color: ws.ink),
        ),
      ),
    );
  }
}
