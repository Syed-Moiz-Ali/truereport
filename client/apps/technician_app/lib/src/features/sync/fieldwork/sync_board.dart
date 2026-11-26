import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../inspection/fieldwork/fieldwork_ui.dart';

/// The sync outbox in the Fieldwork language: a measured top bar, a tinted
/// outbox summary, the conflicts that need a decision, one surface per job and
/// a pinned action.
///
/// Presentation only: the page resolves every string, counts the operations and
/// owns replay, refresh and routing. The preview harness mounts this same
/// widget with sample data.

/// Title, context line and connection state for the top bar.
class SyncHeaderData {
  const SyncHeaderData({
    required this.title,
    this.subtitle = '',
    this.stateLabel = '',
    this.stateTone = StatusTone.neutral,
    this.stateIcon = Icons.cloud_done_outlined,
  });

  final String title;

  /// Context line under the title; empty hides it.
  final String subtitle;
  final String stateLabel;
  final StatusTone stateTone;
  final IconData stateIcon;
}

/// The outbox at a glance: how many changes, how old the oldest one is and how
/// many conflicts are waiting.
class SyncSummaryData {
  const SyncSummaryData({
    required this.eyebrow,
    required this.count,
    required this.countLabel,
    required this.hint,
    this.oldestLabel,
    this.conflictLabel,
  });

  final String eyebrow;
  final int count;

  /// Already composed, e.g. "7 changes on this phone".
  final String countLabel;

  /// Localized clock/date of the oldest change; null when the outbox is empty.
  final String? oldestLabel;

  /// Already composed conflict count; null when there are no conflicts.
  final String? conflictLabel;

  /// "Saved safely..." — the same promise in the hero and the footer.
  final String hint;
}

class SyncConflictData {
  const SyncConflictData({
    required this.id,
    required this.itemCode,
    required this.jobLabel,
    required this.revisionLabel,
    required this.stateLabel,
    required this.semanticLabel,
  });

  final String id;
  final String itemCode;
  final String jobLabel;

  /// "1 → 2" — isolated LTR, never reordered by RTL.
  final String revisionLabel;
  final String stateLabel;
  final String semanticLabel;
}

class SyncConflictsData {
  const SyncConflictsData({
    required this.title,
    required this.hint,
    required this.items,
  });

  /// "2 items changed on the server".
  final String title;
  final String hint;
  final List<SyncConflictData> items;
}

class SyncOperationData {
  const SyncOperationData({
    required this.icon,
    required this.title,
    required this.itemCode,
    required this.timeLabel,
    required this.stateLabel,
    required this.stateTone,
    required this.semanticLabel,
    this.errorLabel,
    this.attemptsLabel,
  });

  final IconData icon;
  final String title;
  final String itemCode;
  final String timeLabel;
  final String stateLabel;
  final StatusTone stateTone;
  final String semanticLabel;

  /// Resolved "Last error: ..." line; null hides it.
  final String? errorLabel;

  /// Resolved attempt count; null hides it.
  final String? attemptsLabel;
}

class SyncGroupData {
  const SyncGroupData({
    required this.jobLabel,
    required this.metaLabel,
    required this.operations,
  });

  /// "Job #job-1001".
  final String jobLabel;

  /// "3 waiting to sync".
  final String metaLabel;
  final List<SyncOperationData> operations;
}

class SyncEmptyData {
  const SyncEmptyData({required this.title, required this.body});

  final String title;
  final String body;
}

class SyncErrorData {
  const SyncErrorData({
    required this.title,
    required this.body,
    required this.retryLabel,
  });

  final String title;
  final String body;
  final String retryLabel;
}

class SyncFooterData {
  const SyncFooterData({
    required this.hint,
    required this.actionLabel,
    required this.savedLabel,
  });

  final String hint;
  final String actionLabel;
  final String savedLabel;
}

/// The whole sync screen. The page owns providers and replay; this widget owns
/// the layout and every visual state.
class SyncBoard extends StatelessWidget {
  const SyncBoard({
    required this.header,
    required this.summary,
    required this.empty,
    required this.footer,
    required this.loading,
    required this.replaying,
    required this.canSync,
    required this.onBack,
    required this.onSync,
    required this.onOpenConflict,
    required this.onRetry,
    required this.onRefresh,
    this.conflicts,
    this.groups = const <SyncGroupData>[],
    this.error,
    this.offlineLabel,
    super.key,
  });

  final SyncHeaderData header;
  final SyncSummaryData summary;
  final SyncConflictsData? conflicts;
  final List<SyncGroupData> groups;
  final SyncEmptyData empty;
  final SyncFooterData footer;
  final SyncErrorData? error;
  final String? offlineLabel;

  final bool loading;
  final bool replaying;
  final bool canSync;

  final VoidCallback onBack;
  final VoidCallback onSync;
  final ValueChanged<String> onOpenConflict;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final hPad = screen >= 600 ? 24.0 : 16.0;
    // The single primary lives in the hero from 1000 up and in the pinned
    // footer below that, so the outbox never carries two competing CTAs.
    final heroAction = screen >= 1000;
    final isClear =
        !loading &&
        error == null &&
        summary.count == 0 &&
        (conflicts == null || conflicts!.items.isEmpty);
    return Column(
      children: [
        SyncTopBar(header: header, onBack: onBack),
        if (offlineLabel != null)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(hPad, 12, hPad, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FieldworkMetrics.focusMaxWidth,
                ),
                child: FieldworkNote(
                  message: offlineLabel!,
                  tone: StatusTone.warning,
                  icon: Icons.cloud_off_rounded,
                ),
              ),
            ),
          ),
        Expanded(
          child: _body(
            context,
            hPad: hPad,
            heroAction: heroAction,
            isClear: isClear,
          ),
        ),
        SyncFooter(
          data: footer,
          empty: isClear,
          showAction: !heroAction && summary.count > 0,
          showHint: offlineLabel == null,
          canSync: canSync,
          replaying: replaying,
          onSync: onSync,
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context, {
    required double hPad,
    required bool heroAction,
    required bool isClear,
  }) {
    if (loading) {
      return _scroll(
        context,
        hPad: hPad,
        center: false,
        child: const SyncSkeleton(),
      );
    }
    final errorData = error;
    if (errorData != null) {
      return _scroll(
        context,
        hPad: hPad,
        center: true,
        child: _SyncStatePanel(
          icon: Icons.error_outline_rounded,
          tone: StatusTone.danger,
          title: errorData.title,
          body: errorData.body,
          action: FieldworkButton(
            label: errorData.retryLabel,
            icon: Icons.refresh_rounded,
            height: FieldworkMetrics.secondaryHeight,
            onPressed: onRetry,
          ),
        ),
      );
    }
    if (isClear) {
      return _scroll(
        context,
        hPad: hPad,
        center: true,
        child: SyncAllClear(data: empty, hint: footer.hint),
      );
    }
    return _scroll(
      context,
      hPad: hPad,
      center: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SyncSummaryHero(
            data: summary,
            showAction: heroAction,
            replaying: replaying,
            canSync: canSync,
            actionLabel: footer.actionLabel,
            onSync: onSync,
          ),
          if (conflicts != null && conflicts!.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            SyncConflictsCard(data: conflicts!, onOpen: onOpenConflict),
          ],
          for (final group in groups) ...[
            const SizedBox(height: 12),
            SyncOutboxGroup(data: group),
          ],
        ],
      ),
    );
  }

  /// One scroll for every state, so pull-to-refresh works even when the screen
  /// is empty and the composition can be optically centred.
  Widget _scroll(
    BuildContext context, {
    required double hPad,
    required bool center,
    required Widget child,
  }) {
    return RefreshIndicator(
      color: context.brand.ink,
      backgroundColor: context.colors.surface,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsetsDirectional.fromSTEB(hPad, 16, hPad, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FieldworkMetrics.focusMaxWidth,
                ),
                child: center
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 40).clamp(
                            0,
                            double.infinity,
                          ),
                        ),
                        child: Center(child: child),
                      )
                    : child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Back, title, the serving context and the connection pill.
class SyncTopBar extends StatelessWidget {
  const SyncTopBar({
    required this.header,
    required this.onBack,
    this.trailing,
    super.key,
  });

  final SyncHeaderData header;
  final VoidCallback onBack;

  /// Overrides the connection pill (the conflict screen puts a counter here).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest,
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(wide ? 16 : 10, 9, 14, 9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FieldworkMetrics.focusMaxWidth,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FieldworkIconButton(
                icon: rtl
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_back_rounded,
                semanticLabel: MaterialLocalizations.of(context)
                    .backButtonTooltip,
                onPressed: onBack,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      header.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fieldworkText(
                        context,
                        20,
                        weight: FontWeight.w800,
                        height: 25,
                        tracking: -0.4,
                      ),
                    ),
                    if (header.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        header.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: fieldworkText(
                          context,
                          12,
                          weight: FontWeight.w600,
                          height: 16,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  (header.stateLabel.trim().isEmpty
                      ? const SizedBox.shrink()
                      : FieldworkPill(
                          label: header.stateLabel,
                          tone: header.stateTone,
                          icon: header.stateIcon,
                          dense: true,
                        )),
            ],
          ),
        ),
      ),
    );
  }
}

/// The outbox at a glance, in the module's tinted hero.
class SyncSummaryHero extends StatelessWidget {
  const SyncSummaryHero({
    required this.data,
    required this.showAction,
    required this.replaying,
    required this.canSync,
    required this.actionLabel,
    required this.onSync,
    super.key,
  });

  final SyncSummaryData data;
  final bool showAction;
  final bool replaying;
  final bool canSync;
  final String actionLabel;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final onContainer = context.brand.onContainer;
    return FieldworkCard(
      child: FieldworkTint(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.eyebrow,
                    style: fieldworkEyebrow(
                      context,
                      color: onContainer.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: data.countLabel,
                    child: ExcludeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${data.count}',
                            textDirection: TextDirection.ltr,
                            style: fieldworkNumber(
                              context,
                              40,
                              height: 42,
                              tracking: -1.2,
                              color: onContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              data.countLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: fieldworkText(
                                context,
                                13,
                                weight: FontWeight.w600,
                                height: 18,
                                color: onContainer.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (data.oldestLabel != null)
                        _SyncMeta(
                          icon: Icons.schedule_rounded,
                          label: data.oldestLabel!,
                          color: onContainer.withValues(alpha: 0.8),
                        ),
                      if (data.conflictLabel != null)
                        FieldworkPill(
                          label: data.conflictLabel!,
                          tone: StatusTone.danger,
                          icon: Icons.sync_problem_rounded,
                          dense: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (showAction && data.count > 0) ...[
              const SizedBox(width: 16),
              FieldworkButton(
                label: actionLabel,
                icon: Icons.sync_rounded,
                height: FieldworkMetrics.secondaryHeight,
                isLoading: replaying,
                onPressed: canSync ? onSync : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SyncMeta extends StatelessWidget {
  const _SyncMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: fieldworkNumber(
            context,
            12,
            weight: FontWeight.w600,
            height: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Conflicts are decisions, not rows to scan: the highest-priority block.
class SyncConflictsCard extends StatelessWidget {
  const SyncConflictsCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final SyncConflictsData data;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final danger = context.statusColors.danger;
    return FieldworkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: danger.background,
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 1),
                  child: Icon(
                    Icons.sync_problem_rounded,
                    size: 18,
                    color: danger.foreground,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.title,
                        maxLines: 2,
                        style: fieldworkText(
                          context,
                          13,
                          weight: FontWeight.w800,
                          height: 17,
                          color: danger.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.hint,
                        maxLines: 2,
                        style: fieldworkText(
                          context,
                          11.5,
                          weight: FontWeight.w500,
                          height: 15,
                          color: danger.foreground.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < data.items.length; index++) ...[
            if (index > 0) const FieldworkDivider(),
            _ConflictLine(
              conflict: data.items[index],
              onTap: () => onOpen(data.items[index].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConflictLine extends StatelessWidget {
  const _ConflictLine({required this.conflict, required this.onTap});

  final SyncConflictData conflict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final danger = context.statusColors.danger;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return FieldworkPress(
      onTap: onTap,
      radius: 0,
      semanticLabel: conflict.semanticLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 12, 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: danger.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.priority_high_rounded,
                  size: 18,
                  color: danger.foreground,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conflict.itemCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fieldworkText(
                        context,
                        14,
                        weight: FontWeight.w700,
                        height: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            conflict.jobLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: fieldworkText(
                              context,
                              11.5,
                              weight: FontWeight.w600,
                              height: 15,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          conflict.revisionLabel,
                          textDirection: TextDirection.ltr,
                          style: fieldworkNumber(
                            context,
                            11,
                            weight: FontWeight.w600,
                            height: 15,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FieldworkPill(
                label: conflict.stateLabel,
                tone: StatusTone.danger,
                dense: true,
              ),
              const SizedBox(width: 2),
              Icon(
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 18,
                color: danger.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One surface per job: a header, then hairline operation rows.
class SyncOutboxGroup extends StatelessWidget {
  const SyncOutboxGroup({required this.data, super.key});

  final SyncGroupData data;

  @override
  Widget build(BuildContext context) {
    return FieldworkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: context.colors.surfaceContainerLow,
            padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    data.jobLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fieldworkText(
                      context,
                      13,
                      weight: FontWeight.w800,
                      height: 17,
                      tracking: -0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  data.metaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fieldworkText(
                    context,
                    11.5,
                    weight: FontWeight.w600,
                    height: 15,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < data.operations.length; index++) ...[
            if (index > 0) const FieldworkDivider(indent: 14),
            _OperationLine(operation: data.operations[index]),
          ],
        ],
      ),
    );
  }
}

class _OperationLine extends StatelessWidget {
  const _OperationLine({required this.operation});

  final SyncOperationData operation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(operation.stateTone);
    final itemCode = operation.itemCode.trim();
    return Semantics(
      container: true,
      label: operation.semanticLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  operation.icon,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      operation.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: fieldworkText(
                        context,
                        13.5,
                        weight: FontWeight.w700,
                        height: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: pair.foreground,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              operation.stateLabel,
                              style: fieldworkText(
                                context,
                                11.5,
                                weight: FontWeight.w600,
                                height: 15,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (itemCode.isNotEmpty)
                          Text(
                            itemCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: fieldworkNumber(
                              context,
                              11,
                              weight: FontWeight.w600,
                              height: 15,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    if (operation.errorLabel != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        operation.errorLabel!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: fieldworkText(
                          context,
                          11.5,
                          weight: FontWeight.w600,
                          height: 15,
                          color: context.statusColors.danger.foreground,
                        ),
                      ),
                    ],
                    if (operation.attemptsLabel != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        operation.attemptsLabel!,
                        style: fieldworkText(
                          context,
                          11,
                          weight: FontWeight.w500,
                          height: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 46,
                child: Text(
                  operation.timeLabel,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fieldworkNumber(
                    context,
                    11.5,
                    weight: FontWeight.w600,
                    height: 15,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The calm end state: nothing on the phone, everything on the server.
class SyncAllClear extends StatelessWidget {
  const SyncAllClear({required this.data, required this.hint, super.key});

  final SyncEmptyData data;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final success = context.statusColors.success;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: success.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_done_outlined,
              size: 30,
              color: success.foreground,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: fieldworkText(
              context,
              22,
              weight: FontWeight.w800,
              height: 28,
              tracking: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: fieldworkText(
              context,
              13.5,
              weight: FontWeight.w500,
              height: 20,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          FieldworkNote(
            message: hint,
            tone: StatusTone.neutral,
            icon: Icons.lock_outline_rounded,
          ),
        ],
      ),
    );
  }
}

/// Skeleton shaped like the summary and the outbox, never a bare spinner.
class SyncSkeleton extends StatelessWidget {
  const SyncSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldworkCard(
          padding: EdgeInsetsDirectional.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LoadingSkeleton(lines: 1, height: 14),
              SizedBox(height: 14),
              LoadingSkeleton(lines: 1, height: 40),
              SizedBox(height: 14),
              LoadingSkeleton(lines: 1, height: 14),
            ],
          ),
        ),
        SizedBox(height: 12),
        FieldworkCard(
          padding: EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: LoadingSkeleton(lines: 4, height: 44),
        ),
        SizedBox(height: 12),
        FieldworkCard(
          padding: EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: LoadingSkeleton(lines: 3, height: 44),
        ),
      ],
    );
  }
}

class _SyncStatePanel extends StatelessWidget {
  const _SyncStatePanel({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final StatusTone tone;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: pair.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: pair.foreground),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: fieldworkText(
              context,
              18,
              weight: FontWeight.w800,
              height: 24,
              tracking: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: fieldworkText(
              context,
              13,
              height: 19,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Pinned status and the outbox's single action on phones.
class SyncFooter extends StatelessWidget {
  const SyncFooter({
    required this.data,
    required this.empty,
    required this.showAction,
    required this.showHint,
    required this.canSync,
    required this.replaying,
    required this.onSync,
    super.key,
  });

  final SyncFooterData data;
  final bool empty;
  final bool showAction;

  /// False while the offline banner above carries the same promise.
  final bool showHint;
  final bool canSync;
  final bool replaying;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final success = context.statusColors.success;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FieldworkMetrics.focusMaxWidth,
          ),
          child: Row(
            children: [
              Expanded(
                child: empty
                    ? Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: success.foreground,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              data.savedLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: fieldworkText(
                                context,
                                12,
                                weight: FontWeight.w700,
                                height: 16,
                                color: success.foreground,
                              ),
                            ),
                          ),
                        ],
                      )
                    : showHint
                    ? Text(
                        data.hint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: fieldworkText(
                          context,
                          11.5,
                          weight: FontWeight.w500,
                          height: 15,
                          color: context.colors.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (!empty && showAction) ...[
                const SizedBox(width: 12),
                FieldworkButton(
                  label: data.actionLabel,
                  icon: Icons.sync_rounded,
                  height: FieldworkMetrics.secondaryHeight,
                  isLoading: replaying,
                  onPressed: canSync ? onSync : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
