import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_states.dart';
import '../../platform_theme.dart';

/// Human taxonomy row (Direction A, lifecycle pass).
///
/// What an admin needs, nothing they don't: the human name, the lifecycle
/// state, the code, and the pipeline position. Tone, order counters,
/// visibility lists and version counters stay in the edit dialog where they
/// belong. Same test contract as the retired cards: identical keys
/// (`reference-record-<code>`, `reference-state-<code>`, publish / retire /
/// edit / move), identical chip copy, identical enablement.
class ReferenceRecordRow extends StatelessWidget {
  const ReferenceRecordRow({
    super.key,
    required this.code,
    required this.labelKey,
    required this.label,
    required this.selectable,
    required this.isDraft,
    required this.position,
    required this.total,
    required this.strings,
    required this.busy,
    required this.onEdit,
    required this.onPublish,
    required this.onRetire,
    this.onMoveUp,
    this.onMoveDown,
  });

  final String code;
  final String labelKey;
  final String? label;
  final bool selectable;
  final bool isDraft;
  final int position;
  final int total;
  final UiMessageStrings strings;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onRetire;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final reorderable = onMoveUp != null || onMoveDown != null;
    final reorder = reorderable
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                key: Key('reference-move-up-$code'),
                tooltip: strings.tKey(CommonKeys.buttonMoveUp),
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                onPressed: busy ? null : onMoveUp,
              ),
              IconButton(
                key: Key('reference-move-down-$code'),
                tooltip: strings.tKey(CommonKeys.buttonMoveDown),
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                onPressed: busy ? null : onMoveDown,
              ),
            ],
          )
        : const SizedBox.shrink();
    final title = label ?? code;
    final positionText = strings.tArgsKey(
      PlatformAdminKeys.referencePositionLabel,
      <String, Object?>{'index': '$position', 'total': '$total'},
    );
    final content = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: PtTheme.font(
                    15,
                    lineHeight: 21,
                    weight: FontWeight.w700,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              PlatformStatusChip(
                key: Key('reference-state-$code'),
                status: isDraft ? 'DRAFT' : 'PUBLISHED',
                label: strings.tKey(
                  isDraft
                      ? PlatformAdminKeys.referenceDraftBadge
                      : PlatformAdminKeys.referencePublishedBadge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: label == null ? labelKey : code,
                  style: PtTheme.font(
                    12,
                    lineHeight: 17,
                    weight: FontWeight.w700,
                    color: PtTheme.muted,
                  ),
                ),
                TextSpan(
                  text: ' · $positionText',
                  style: PtTheme.font(
                    12,
                    lineHeight: 17,
                    weight: FontWeight.w400,
                    color: PtTheme.muted,
                  ),
                ),
                if (!selectable)
                  TextSpan(
                    text:
                        ' · ${strings.tKey(PlatformAdminKeys.referenceNotSelectableLabel)}',
                    style: PtTheme.font(
                      12,
                      lineHeight: 17,
                      weight: FontWeight.w600,
                      color: PtTheme.gold,
                    ),
                  ),
              ],
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        PlatformGhostButton(
          key: Key('reference-edit-$code'),
          label: strings.tKey(CommonKeys.buttonEdit),
          icon: Icons.edit_outlined,
          onPressed: busy ? null : onEdit,
        ),
        if (isDraft)
          PlatformSecondaryButton(
            key: Key('reference-publish-$code'),
            label: strings.tKey(PlatformAdminKeys.referencePublish),
            icon: Icons.publish_rounded,
            onPressed: busy ? null : onPublish,
          )
        else
          PlatformSecondaryButton(
            key: Key('reference-retire-$code'),
            label: strings.tKey(PlatformAdminKeys.referenceRetire),
            icon: Icons.archive_outlined,
            destructive: true,
            onPressed: busy ? null : onRetire,
          ),
      ],
    );
    return Container(
      key: Key('reference-record-$code'),
      color: isDraft ? const Color(0xFFFFFBEB) : Colors.transparent,
      padding: const EdgeInsetsDirectional.fromSTEB(6, 12, 14, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    reorder,
                    const SizedBox(width: 4),
                    content,
                  ],
                ),
                const SizedBox(height: 10),
                actions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              reorder,
              const SizedBox(width: 4),
              content,
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

/// Read-only dropdown value row. Same contract as the retired card:
/// identical key (`reference-value-<code>`), human name first, then the
/// code, the display position, and a flag only when the value cannot be
/// chosen in forms. No actions.
class ReferenceValueRow extends StatelessWidget {
  const ReferenceValueRow({
    super.key,
    required this.code,
    required this.labelKey,
    required this.label,
    required this.selectable,
    required this.parentCode,
    required this.position,
    required this.total,
    required this.strings,
  });

  final String code;
  final String labelKey;
  final String? label;
  final bool selectable;
  final String? parentCode;
  final int position;
  final int total;
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    final title = label ?? code;
    final positionText = strings.tArgsKey(
      PlatformAdminKeys.referencePositionLabel,
      <String, Object?>{'index': '$position', 'total': '$total'},
    );
    return Container(
      key: Key('reference-value-$code'),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: PtTheme.font(15, lineHeight: 21, weight: FontWeight.w700),
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: label == null ? labelKey : code,
                  style: PtTheme.font(
                    12,
                    lineHeight: 17,
                    weight: FontWeight.w700,
                    color: PtTheme.muted,
                  ),
                ),
                if (parentCode != null && parentCode!.isNotEmpty)
                  TextSpan(
                    text:
                        ' ${strings.tArgsKey(PlatformAdminKeys.referenceValueParentLabel, <String, Object?>{'parent': parentCode})}',
                    style: PtTheme.font(
                      12,
                      lineHeight: 17,
                      weight: FontWeight.w400,
                      color: PtTheme.muted,
                    ),
                  ),
                TextSpan(
                  text: ' · $positionText',
                  style: PtTheme.font(
                    12,
                    lineHeight: 17,
                    weight: FontWeight.w400,
                    color: PtTheme.muted,
                  ),
                ),
                if (!selectable)
                  TextSpan(
                    text:
                        ' · ${strings.tKey(PlatformAdminKeys.referenceNotSelectableLabel)}',
                    style: PtTheme.font(
                      12,
                      lineHeight: 17,
                      weight: FontWeight.w600,
                      color: PtTheme.gold,
                    ),
                  ),
              ],
            ),
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

/// Draft-aware record list with the exact state contract of the retired
/// `_RecordsView`: error + retry, skeleton while either read is pending
/// (both must resolve before the list paints, otherwise every row would
/// flash as a draft), empty view, then the new compact rows.
///
/// Lifecycle clarity: rows group by state — drafts first, then published —
/// each run headed by its own catalog label with a count. The grouping is
/// a stable sort, so order inside a state never changes; moves operate on
/// display positions and the backend still receives one explicit order.
class ReferenceRecordList extends StatelessWidget {
  const ReferenceRecordList({
    super.key,
    required this.strings,
    required this.admin,
    required this.published,
    required this.onRetry,
    required this.row,
  });

  final UiMessageStrings strings;
  final AsyncValue<List<ReferenceRecord>> admin;
  final AsyncValue<List<ReferenceRecord>> published;
  final VoidCallback onRetry;
  final Widget Function(
    List<ReferenceRecord> records,
    Set<String> drafts,
    int index,
    ReferenceRecord record,
  )
  row;

  @override
  Widget build(BuildContext context) {
    if (admin.hasError || published.hasError) {
      return PlatformErrorView(
        message: strings.tKey(PlatformAdminKeys.taxonomyError),
        retryLabel: strings.tKey(PlatformAdminKeys.taxonomyRetry),
        onRetry: onRetry,
      );
    }
    if (!admin.hasValue || !published.hasValue) {
      return const PlatformSkeletonList(rows: 4);
    }
    final records = admin.requireValue;
    final drafts = draftCodes(records, published.requireValue);
    if (records.isEmpty) {
      return PlatformEmptyView(
        title: strings.tKey(PlatformAdminKeys.taxonomyEmpty),
      );
    }
    final ordered = <ReferenceRecord>[
      for (final record in records)
        if (drafts.contains(record.code)) record,
      for (final record in records)
        if (!drafts.contains(record.code)) record,
    ];
    final draftItems = ordered.where((r) => drafts.contains(r.code));
    final publishedItems = ordered.where((r) => !drafts.contains(r.code));
    var position = 0;
    Widget section(String title, Iterable<ReferenceRecord> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GroupHeader(title: title),
          for (final record in items) ...<Widget>[
            if (position > 0) const Divider(height: 1, color: PtTheme.border),
            Builder(
              builder: (context) {
                final index = position++;
                return row(ordered, drafts, index, record);
              },
            ),
          ],
        ],
      );
    }

    return LedgerSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (draftItems.isNotEmpty)
            section(
              strings.tArgsKey(
                PlatformAdminKeys.referenceDraftGroupTitle,
                <String, Object?>{'count': '${draftItems.length}'},
              ),
              draftItems,
            ),
          if (publishedItems.isNotEmpty)
            section(
              strings.tArgsKey(
                PlatformAdminKeys.referencePublishedGroupTitle,
                <String, Object?>{'count': '${publishedItems.length}'},
              ),
              publishedItems,
            ),
        ],
      ),
    );
  }
}

/// Lifecycle group header: state name plus count, never a bare number.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 8),
      child: Text(
        title,
        style: PtTheme.font(
          10.5,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: PtTheme.muted,
        ),
      ),
    );
  }
}

/// Single-read list with the exact state contract of the retired `_ListView`.
class ReferenceValueList<T> extends StatelessWidget {
  const ReferenceValueList({
    super.key,
    required this.strings,
    required this.async,
    required this.onRetry,
    required this.row,
  });

  final UiMessageStrings strings;
  final AsyncValue<List<T>> async;
  final VoidCallback onRetry;
  final Widget Function(int index, T value) row;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const PlatformSkeletonList(rows: 4),
      error: (error, _) => PlatformErrorView(
        message: strings.tKey(PlatformAdminKeys.taxonomyError),
        retryLabel: strings.tKey(PlatformAdminKeys.taxonomyRetry),
        onRetry: onRetry,
      ),
      data: (items) {
        if (items.isEmpty) {
          return PlatformEmptyView(
            title: strings.tKey(PlatformAdminKeys.taxonomyEmpty),
          );
        }
        return LedgerSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < items.length; i++) ...<Widget>[
                if (i > 0) const Divider(height: 1, color: PtTheme.border),
                row(i, items[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// One bordered surface for a ledger; rows carry hairline dividers.
class LedgerSurface extends StatelessWidget {
  const LedgerSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }
}
