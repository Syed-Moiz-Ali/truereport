import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../inspection/fieldwork/fieldwork_item.dart';
import '../../inspection/fieldwork/fieldwork_ui.dart';

/// Job identity for every review screen's top bar. Strings are resolved by the
/// page wrapper; this layer never reads l10n for identity.
class ReviewJobHeader {
  const ReviewJobHeader({
    required this.vehicle,
    required this.plate,
    required this.reference,
    required this.statusLabel,
    required this.statusTone,
    this.progressLabel,
    this.progress,
  });

  final String vehicle;
  final String plate;
  final String reference;

  /// Resolved status copy; null omits the pill (no invented state).
  final String? statusLabel;
  final StatusTone statusTone;

  /// For example "28 of 30 items"; null hides the progress group.
  final String? progressLabel;

  /// 0..1 track under the progress label; null hides the track.
  final double? progress;
}

/// The review top bar: back, vehicle identity, then plate, reference, status and
/// assessed progress. Nothing here truncates identity; the meta line wraps.
class ReviewTopBar extends StatelessWidget {
  const ReviewTopBar({required this.header, required this.onBack, super.key});

  final ReviewJobHeader header;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 2),
                child: FieldworkIconButton(
                  icon: rtl
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                  semanticLabel: MaterialLocalizations.of(context)
                      .backButtonTooltip,
                  onPressed: onBack,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      header.vehicle,
                      maxLines: 2,
                      style: fieldworkText(
                        context,
                        16,
                        weight: FontWeight.w800,
                        height: 20,
                        tracking: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (header.plate.trim().isNotEmpty)
                          _Plate(label: header.plate),
                        if (header.reference.trim().isNotEmpty)
                          Text(
                            header.reference,
                            textDirection: TextDirection.ltr,
                            style: fieldworkNumber(
                              context,
                              11.5,
                              weight: FontWeight.w600,
                              height: 15,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        if (header.statusLabel != null)
                          FieldworkPill(
                            label: header.statusLabel!,
                            tone: header.statusTone,
                            dense: true,
                          ),
                        if (header.progressLabel != null) ...[
                          Text(
                            header.progressLabel!,
                            style: fieldworkNumber(
                              context,
                              11.5,
                              weight: FontWeight.w700,
                              height: 15,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          if (header.progress != null)
                            SizedBox(
                              width: 56,
                              child: FieldworkBar(
                                value: header.progress!,
                                height: 4,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A back-only bar for the loading and error shells, where the job identity is
/// not guaranteed to be loaded.
class ReviewBackBar extends StatelessWidget {
  const ReviewBackBar({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest,
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 14, 9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FieldworkMetrics.focusMaxWidth,
          ),
          child: Row(
            children: [
              FieldworkIconButton(
                icon: rtl
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_back_rounded,
                semanticLabel: MaterialLocalizations.of(context)
                    .backButtonTooltip,
                onPressed: onBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 7,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Text(
        label,
        textDirection: TextDirection.ltr,
        style: fieldworkNumber(
          context,
          11.5,
          weight: FontWeight.w700,
          height: 15,
          tracking: 0.4,
        ),
      ),
    );
  }
}

/// The shared review frame: sticky top bar, one measured column, pinned footer.
class ReviewShell extends StatelessWidget {
  const ReviewShell({
    required this.topBar,
    required this.zones,
    required this.footer,
    this.maxWidth = FieldworkMetrics.focusMaxWidth,
    this.centerContent = false,
    super.key,
  });

  final Widget topBar;
  final List<Widget> zones;
  final Widget footer;
  final double maxWidth;

  /// Success moments and the signing sheet sit in the optical centre of the
  /// content area; gates and receipts stay top-aligned and scroll.
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: centerContent ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (var index = 0; index < zones.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          zones[index],
        ],
      ],
    );
    return Column(
      children: [
        topBar,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = centerContent
                  ? ConstrainedBox(
                      // The 44 is the shell's vertical padding; centring must
                      // not push content past the footer.
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 44).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: Center(child: column),
                    )
                  : column;
              return SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 16, 14, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: content,
                  ),
                ),
              );
            },
          ),
        ),
        footer,
      ],
    );
  }
}

/// Score, grade and safety cap as the dominant number of the gate.
///
/// Renders nothing when the served summary carries none of the three; the page
/// already gates on the same condition.
class ReviewScoreHero extends StatelessWidget {
  const ReviewScoreHero({
    required this.score,
    required this.grade,
    required this.capApplied,
    required this.capReason,
    required this.scoreLabel,
    required this.gradeLabel,
    required this.capLabel,
    required this.capAppliedLabel,
    super.key,
  });

  final int? score;
  final String? grade;
  final bool capApplied;
  final String capReason;
  final String scoreLabel;
  final String gradeLabel;
  final String capLabel;
  final String capAppliedLabel;

  @override
  Widget build(BuildContext context) {
    if (score == null && grade == null && !capApplied) {
      return const SizedBox.shrink();
    }
    final onContainer = context.brand.onContainer;
    final hasNumber = score != null || grade != null;
    final value = score != null ? '$score' : grade;
    final label = score != null
        ? scoreLabel
        : grade != null
        ? gradeLabel
        : capLabel;
    final reason = capReason.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldworkCard(
          child: FieldworkTint(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: fieldworkEyebrow(
                          context,
                          color: onContainer.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasNumber && value != null ? value : capAppliedLabel,
                        textDirection: TextDirection.ltr,
                        style: fieldworkNumber(
                          context,
                          score != null ? 46 : 28,
                          weight: FontWeight.w800,
                          height: score != null ? 48 : 32,
                          tracking: score != null ? -1.4 : -0.4,
                          color: hasNumber
                              ? onContainer
                              : context.statusColors.warning.foreground,
                        ),
                      ),
                      if (capApplied) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              capLabel.toUpperCase(),
                              style: fieldworkEyebrow(
                                context,
                                color: context.statusColors.warning.foreground
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                            FieldworkPill(
                              label: capAppliedLabel,
                              tone: StatusTone.warning,
                              icon: Icons.shield_outlined,
                              dense: true,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (score != null && grade != null) ...[
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gradeLabel.toUpperCase(),
                        textAlign: TextAlign.end,
                        style: fieldworkEyebrow(
                          context,
                          color: onContainer.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        grade!,
                        textDirection: TextDirection.ltr,
                        style: fieldworkNumber(
                          context,
                          26,
                          weight: FontWeight.w800,
                          height: 30,
                          tracking: -0.4,
                          color: onContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (capApplied && reason.isNotEmpty) ...[
          const SizedBox(height: 10),
          FieldworkNote(
            message: reason,
            tone: StatusTone.warning,
            icon: Icons.shield_outlined,
          ),
        ],
      ],
    );
  }
}

/// One row of the gate: a blocker (tappable) or a warning (quiet).
class ReviewGateRowData {
  const ReviewGateRowData({
    required this.icon,
    required this.title,
    this.code,
    this.onTap,
  });

  final IconData icon;
  final String title;

  /// Item code or other reference shown under the title.
  final String? code;
  final VoidCallback? onTap;
}

/// The blockers/warnings surface: rows in one card, hairlines between.
///
/// `quiet` swaps to a tonal background and never shows chevrons, so warnings
/// never read as blockers.
class ReviewGateCard extends StatelessWidget {
  const ReviewGateCard({
    required this.title,
    required this.count,
    required this.rows,
    this.tone = StatusTone.danger,
    this.quiet = false,
    super.key,
  });

  final String title;
  final int count;
  final List<ReviewGateRowData> rows;
  final StatusTone tone;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(tone);
    return FieldworkCard(
      color: quiet ? colors.surfaceContainer : null,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 2,
                    style: fieldworkEyebrow(
                      context,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pair.background,
                    borderRadius: BorderRadius.circular(
                      FieldworkMetrics.chipRadius,
                    ),
                  ),
                  child: Text(
                    '$count',
                    textDirection: TextDirection.ltr,
                    style: fieldworkNumber(
                      context,
                      11.5,
                      weight: FontWeight.w800,
                      height: 15,
                      color: pair.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const FieldworkDivider(),
              _GateRow(row: rows[index], tone: tone, quiet: quiet),
            ],
          ],
        ),
      ),
    );
  }
}

class _GateRow extends StatelessWidget {
  const _GateRow({required this.row, required this.tone, required this.quiet});

  final ReviewGateRowData row;
  final StatusTone tone;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(tone);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final tappable = row.onTap != null && !quiet;
    final code = (row.code ?? '').trim();
    final content = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsetsDirectional.fromSTEB(2, 10, 2, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: pair.background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(row.icon, size: 18, color: pair.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.title,
                  style: fieldworkText(
                    context,
                    13.5,
                    weight: FontWeight.w700,
                    height: 18,
                    tracking: -0.1,
                  ),
                ),
                if (code.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    code,
                    textDirection: TextDirection.ltr,
                    style: fieldworkNumber(
                      context,
                      11.5,
                      weight: FontWeight.w600,
                      height: 15,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 6),
            Icon(
              rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
    if (!tappable) {
      return content;
    }
    return FieldworkPress(
      onTap: row.onTap,
      radius: 0,
      semanticLabel: row.title,
      child: content,
    );
  }
}

/// The calm ready state: one success mark, what happens next, nothing to do
/// inside the card because the footer owns the action.
class ReviewReadyCard extends StatelessWidget {
  const ReviewReadyCard({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const ReviewSuccessMark(size: 64),
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
        ],
      ),
    );
  }
}

/// Score data for [SummaryGateView]; null hides the hero entirely.
class ReviewScoreData {
  const ReviewScoreData({
    required this.score,
    required this.grade,
    required this.capApplied,
    required this.capReason,
    required this.scoreLabel,
    required this.gradeLabel,
    required this.capLabel,
    required this.capAppliedLabel,
  });

  final int? score;
  final String? grade;
  final bool capApplied;
  final String capReason;
  final String scoreLabel;
  final String gradeLabel;
  final String capLabel;
  final String capAppliedLabel;
}

/// The ready state copy for [SummaryGateView]; null keeps the gate closed.
class ReviewReadyData {
  const ReviewReadyData({required this.title, required this.body});

  final String title;
  final String body;
}

/// The whole sign-off gate as one presentational screen: top bar, score hero,
/// blockers, warnings, ready state, conflicts, and the pinned footer.
///
/// The page computes the labels and actions (the gate logic) and hands them in;
/// this widget only lays the screen out.
class SummaryGateView extends StatelessWidget {
  const SummaryGateView({
    required this.header,
    required this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    required this.saving,
    this.secondaryLabel,
    this.onSecondary,
    this.score,
    this.offlineLabel,
    this.error,
    this.blockersTitle,
    this.blockers = const <ReviewGateRowData>[],
    this.warningsTitle,
    this.warnings = const <ReviewGateRowData>[],
    this.ready,
    this.readyChecks = const <ReviewReceiptRow>[],
    this.conflictsPanel,
    super.key,
  });

  final ReviewJobHeader header;
  final VoidCallback onBack;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool saving;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final ReviewScoreData? score;
  final String? offlineLabel;
  final String? error;
  final String? blockersTitle;
  final List<ReviewGateRowData> blockers;
  final String? warningsTitle;
  final List<ReviewGateRowData> warnings;
  final ReviewReadyData? ready;

  /// Known facts that make the ready state true (items assessed, signature
  /// captured, no conflicts). Rendered as a receipt under the ready card.
  final List<ReviewReceiptRow> readyChecks;
  final Widget? conflictsPanel;

  @override
  Widget build(BuildContext context) {
    final scoreData = score;
    final readyData = ready;
    final zones = <Widget>[
      if (offlineLabel != null)
        FieldworkNote(
          message: offlineLabel!,
          tone: StatusTone.warning,
          icon: Icons.cloud_off_rounded,
        ),
      if (scoreData != null)
        ReviewScoreHero(
          score: scoreData.score,
          grade: scoreData.grade,
          capApplied: scoreData.capApplied,
          capReason: scoreData.capReason,
          scoreLabel: scoreData.scoreLabel,
          gradeLabel: scoreData.gradeLabel,
          capLabel: scoreData.capLabel,
          capAppliedLabel: scoreData.capAppliedLabel,
        ),
      if (error != null)
        FieldworkNote(
          message: error!,
          tone: StatusTone.danger,
          icon: Icons.error_outline_rounded,
        ),
      if (readyData != null) ...[
        ReviewReadyCard(title: readyData.title, body: readyData.body),
        if (readyChecks.isNotEmpty) ReviewReceipt(rows: readyChecks),
      ] else if (blockers.isNotEmpty)
        ReviewGateCard(
          title: blockersTitle ?? '',
          count: blockers.length,
          rows: blockers,
        ),
      if (warnings.isNotEmpty)
        ReviewGateCard(
          title: warningsTitle ?? '',
          count: warnings.length,
          tone: StatusTone.warning,
          quiet: true,
          rows: warnings,
        ),
      ?conflictsPanel,
    ];

    return ReviewShell(
      topBar: ReviewTopBar(header: header, onBack: onBack),
      zones: zones,
      centerContent: readyData != null,
      footer: ItemFooter(
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
        saving: saving,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
      ),
    );
  }
}

/// The signed/unsigned screen as one presentational frame.
class SignatureView extends StatelessWidget {
  const SignatureView({
    required this.header,
    required this.onBack,
    required this.readOnly,
    required this.primaryLabel,
    required this.onPrimary,
    required this.saving,
    required this.body,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final ReviewJobHeader header;
  final VoidCallback onBack;
  final bool readOnly;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool saving;

  /// The signing card or the read-only reason card.
  final Widget body;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return ReviewShell(
      topBar: ReviewTopBar(header: header, onBack: onBack),
      zones: [body],
      centerContent: !readOnly,
      footer: ItemFooter(
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
        saving: saving,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
      ),
    );
  }
}

/// The completion mark: one ring, one tick, a short settle when motion is on.
class ReviewSuccessMark extends StatelessWidget {
  const ReviewSuccessMark({this.size = 96, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.success;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.textScalerOf(context).scale(1) > 2;
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: pair.background, shape: BoxShape.circle),
      child: Icon(
        Icons.check_rounded,
        size: size * 0.48,
        color: pair.foreground,
      ),
    );
    if (reduceMotion) {
      return Center(child: mark);
    }
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.94, end: 1),
        duration: context.motionDuration(const Duration(milliseconds: 220)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: mark,
      ),
    );
  }
}

/// One label/value pair of the handover receipt.
class ReviewReceiptRow {
  const ReviewReceiptRow({required this.label, required this.value});

  final String label;
  final String value;
}

/// What was submitted, on one surface with hairline rows.
class ReviewReceipt extends StatelessWidget {
  const ReviewReceipt({required this.rows, super.key});

  final List<ReviewReceiptRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FieldworkCard(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 16, 2),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const FieldworkDivider(),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 136,
                      child: Text(
                        rows[index].label.toUpperCase(),
                        style: fieldworkText(
                          context,
                          10.5,
                          weight: FontWeight.w700,
                          height: 14,
                          tracking: 0.7,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rows[index].value,
                        textAlign: TextAlign.end,
                        style: fieldworkNumber(
                          context,
                          13,
                          weight: FontWeight.w700,
                          height: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
