import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2b/f2b_intl.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';
import 'package:technician_app/src/ui_helpers.dart';

/// Figma screen 13: Final Review (Missing Items).
///
/// Displays blocked items requiring mandatory resolution before client sign-off.
/// In Figma mode ([isFigma] = true), matches Figma screen 13 pixel-perfect (SSIM >= 0.98).
/// In product mode, binds to real [ReviewResult] items, localized strings,
/// and computed coverage metrics.
class FinalReviewView extends StatelessWidget {
  const FinalReviewView({
    required this.job,
    required this.review,
    required this.onOpenIssue,
    required this.onContinue,
    this.onBack,
    this.onProfile,
    this.busy = false,
    this.isFigma = false,
    super.key,
  });

  final TechnicianJob job;
  final ReviewResult review;
  final ValueChanged<ReviewIssue> onOpenIssue;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final bool busy;
  final bool isFigma;

  bool get _canContinue => review.ready && review.blocking.isEmpty && !busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final percent = review.total == 0
        ? 0
        : ((review.completed / review.total) * 100).round();

    return Scaffold(
      backgroundColor: Fx.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 64),
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 40),
              children: [
                _buildOverviewCard(context, l10n, localeName),
                _buildAttentionBanner(l10n, localeName),
                _buildMissingItemsStack(context, l10n, localeName),
                _buildMetadataCard(l10n, localeName, percent),
                _buildBottomAction(l10n),
              ],
            ),
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: F2bFocusFrame(
              borderRadius: BorderRadius.zero,
              child: _buildHeader(context, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final title = isFigma
        ? 'Diagnostic Checklist'
        : (job.templateName.isEmpty ? l10n.checklist : job.templateName);

    return Container(
      key: const ValueKey('header'),
      width: 390,
      height: 64,
      decoration: const BoxDecoration(
        color: Fx.whiteCC,
        boxShadow: Fx.headerShadow,
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isFigma)
                  SizedBox(
                    width: 223.53,
                    height: 44,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: FxIcon(
                              id: '1_8473',
                              size: 20,
                              color: Fx.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              title,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: Fx.text(
                                18,
                                24,
                                FontWeight.w700,
                                -0.45,
                                color: Fx.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Semantics(
                          button: true,
                          label: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          child: InkResponse(
                            onTap: onBack,
                            radius: 24,
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: FxIcon(
                                  id: '1_8473',
                                  size: 20,
                                  color: Fx.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 4),
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Fx.text(
                                18,
                                24,
                                FontWeight.w700,
                                -0.45,
                                color: Fx.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: F2bFocusFrame(
                      borderRadius: BorderRadius.circular(Fx.pillRadius),
                      child: InkResponse(
                        onTap: onProfile,
                        radius: 16,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Fx.deepGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: FxIcon(
                              id: '1_8478',
                              size: 12,
                              color: Fx.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    AppLocalizations l10n,
    String localeName,
  ) {
    final issueCount = review.blocking.length;
    final pillText = isFigma
        ? '3 Action Items'
        : '${formatCountLocalized(issueCount, localeName)} ${l10n.missingItems}';

    return Container(
      key: const ValueKey('overview'),
      constraints: const BoxConstraints(minHeight: 138),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isFigma)
                  SizedBox(
                    width: 165.38,
                    height: 16,
                    child: Text(
                      'STEP 4 OF 4 \u2022 VALIDATION',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: Fx.text(
                        12,
                        16,
                        FontWeight.w600,
                        0.6,
                        color: Fx.muted,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      'STEP 4 OF 4 \u2022 VALIDATION',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.text(
                        12,
                        16,
                        FontWeight.w600,
                        0.6,
                        color: Fx.muted,
                      ),
                    ),
                  ),
                const Spacer(),
                F2bStatusPill(
                  label: pillText,
                  background: F2b.rosePale,
                  foreground: F2b.redMaroon,
                  dot: Fx.dangerRed,
                  style: Fx.text(
                    11,
                    14,
                    FontWeight.w600,
                    0.44,
                    color: F2b.redMaroon,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: Text(
              isFigma ? 'Review Findings' : l10n.reviewAndFinalize,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Fx.display26.copyWith(
                color: Fx.ink,
                letterSpacing: -0.65,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFigma
                ? 'Resolve outstanding compliance requirements\nbefore submitting the digital work order.'
                : l10n.finalizeIrreversible,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Fx.body14.copyWith(
              color: Fx.muted,
              letterSpacing: -0.07,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAttentionBanner(AppLocalizations l10n, String localeName) {
    final count = review.blocking.length;
    final title = isFigma
        ? '3 Mandatory Photos Missing'
        : '${formatCountLocalized(count, localeName)} ${l10n.missingItems}';

    return Container(
      constraints: const BoxConstraints(minHeight: 184),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const ValueKey('banner'),
            constraints: const BoxConstraints(minHeight: 160),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: F2b.roseWash,
              borderRadius: BorderRadius.circular(Fx.cardRadius),
              boxShadow: Fx.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    shape: BoxShape.circle,
                    boxShadow: Fx.pillShadow,
                  ),
                  child: const Center(
                    child: FxIcon(
                      id: '1_8367',
                      size: 22,
                      color: Fx.dangerRed,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Fx.title16.copyWith(
                          color: Fx.ink,
                          letterSpacing: -0.16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFigma
                            ? 'Customer sign-off & quality assurance\nmandate verified optical documentation\nfor critical fluid and wear sections.'
                            : l10n.finalizeIrreversible,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Fx.text(
                          13,
                          18,
                          FontWeight.w400,
                          0,
                          color: Fx.iconGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 56,
                              height: 24,
                              child: Stack(
                                children: [
                                  _badge('1', 0),
                                  _badge('2', 16),
                                  _badge('3', 32),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 11.17,
                                ),
                                child: Text(
                                  isFigma
                                      ? 'Tap any item below to capture\ninstantly'
                                      : l10n.photoRequired,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Fx.text(
                                    11,
                                    14,
                                    FontWeight.w600,
                                    0.44,
                                    color: Fx.muted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _badge(String numeral, double left) {
    return PositionedDirectional(
      start: left,
      top: 0,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: F2b.rosePale,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            numeral,
            textDirection: TextDirection.ltr,
            style: Fx.text(
              11,
              16.5,
              FontWeight.w700,
              0,
              color: F2b.redMaroon,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingItemsStack(
    BuildContext context,
    AppLocalizations l10n,
    String localeName,
  ) {
    final items = isFigma ? _figmaItems() : _productItems(l10n);

    return Container(
      constraints: const BoxConstraints(minHeight: 354),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const ValueKey('items-stack'),
            constraints: const BoxConstraints(minHeight: 322),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 4),
                  child: Text(
                    isFigma
                        ? 'MANDATORY RESOLUTION ITEMS'
                        : l10n.missingItems.toUpperCase(),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: Fx.text(
                      12,
                      16,
                      FontWeight.w600,
                      0.6,
                      color: Fx.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _buildMissingItemCard(items[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMissingItemCard(_ReviewCardData data) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.circular(Fx.cardRadius),
        boxShadow: Fx.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isFigma)
            SizedBox(
              width: data.leftWidth,
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Fx.container,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FxIcon(
                        id: data.iconId,
                        size: data.iconSize,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: data.leftWidth - 64,
                    height: 42,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: data.titleRowWidth,
                          height: 22,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: data.titleWidth,
                                height: 22,
                                child: Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    end: data.titleRightPad,
                                  ),
                                  child: Text(
                                    data.title,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                    style: Fx.title16.copyWith(color: Fx.ink),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: data.chipWidth,
                                height: 18,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  8,
                                  2,
                                  8,
                                  2,
                                ),
                                decoration: BoxDecoration(
                                  color: data.chipBg,
                                  borderRadius:
                                      BorderRadius.circular(Fx.pillRadius),
                                ),
                                child: Text(
                                  data.chipLabel,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                  style: Fx.text(
                                    11,
                                    14,
                                    FontWeight.w600,
                                    0.44,
                                    color: data.chipTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: data.detailWidth,
                          height: 18,
                          child: Text(
                            data.detail,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: Fx.text(
                              13,
                              18,
                              FontWeight.w400,
                              0,
                              color: Fx.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Fx.container,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FxIcon(
                        id: data.iconId,
                        size: data.iconSize,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                data.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Fx.title16.copyWith(color: Fx.ink),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 18,
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                8,
                                2,
                                8,
                                2,
                              ),
                              decoration: BoxDecoration(
                                color: data.chipBg,
                                borderRadius:
                                    BorderRadius.circular(Fx.pillRadius),
                              ),
                              child: Text(
                                data.chipLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Fx.text(
                                  11,
                                  14,
                                  FontWeight.w600,
                                  0.44,
                                  color: data.chipTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Fx.text(
                            13,
                            18,
                            FontWeight.w400,
                            0,
                            color: Fx.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          InkResponse(
            onTap: data.onTap,
            radius: 20,
            child: SizedBox(
              width: 50.17,
              height: 36,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: F2b.rosePale,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FxIcon(
                        id: data.actionIconId,
                        size: data.actionIconSize,
                        color: Fx.dangerRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 6.17,
                    height: 10,
                    child: Center(
                      child: FxIcon(
                        id: data.chevronId,
                        size: 10,
                        color: F2b.greyLavender,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(
    AppLocalizations l10n,
    String localeName,
    int percent,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const ValueKey('metadata-card'),
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Fx.container99,
              borderRadius: BorderRadius.circular(Fx.cardRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 25.83,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Fx.white,
                          borderRadius: BorderRadius.circular(Fx.pillRadius),
                        ),
                        child: const Center(
                          child: FxIcon(
                            id: '1_8452',
                            size: 16.5,
                            color: Fx.emerald,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFigma
                                  ? '28 Verified Data Points'
                                  : '${formatCountLocalized(review.completed, localeName)} ${l10n.completedItems}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Fx.text(
                                12,
                                16,
                                FontWeight.w600,
                                0.24,
                                color: Fx.ink,
                              ),
                            ),
                            Text(
                              isFigma
                                  ? 'Powertrain, OBD-II & exterior\nscans passed'
                                  : '${formatCountPairLocalized(review.completed, review.total, localeName)} ${l10n.coverage}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Fx.text(
                                13,
                                18,
                                FontWeight.w400,
                                0,
                                color: Fx.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10.75),
                  child: Text(
                    isFigma
                        ? '91%\nComplete'
                        : '${formatPercentLocalized(percent, localeName)}\n${l10n.coverage}',
                    maxLines: 2,
                    textAlign: TextAlign.end,
                    style: Fx.text(
                      11,
                      14,
                      FontWeight.w700,
                      0.44,
                      color: Fx.deepGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBottomAction(AppLocalizations l10n) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Opacity(
            opacity: _canContinue ? 1.0 : 0.8,
            child: F2bFocusFrame(
              borderRadius: BorderRadius.circular(Fx.pillRadius),
              child: Container(
                key: const ValueKey('continue'),
                height: 56,
                decoration: BoxDecoration(
                  color: _canContinue ? Fx.emerald : Colors.transparent,
                  borderRadius: BorderRadius.circular(Fx.pillRadius),
                ),
                child: InkWell(
                  onTap: _canContinue ? onContinue : null,
                  borderRadius: BorderRadius.circular(Fx.pillRadius),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 13.33,
                          height: 17.5,
                          child: Center(
                            child: FxIcon(
                              id: '1_8463',
                              size: 17.5,
                              color: _canContinue
                                  ? Fx.white
                                  : F2b.greyLavender,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFigma
                              ? 'Resolve to Continue'
                              : l10n.reviewAndFinalize,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          textAlign: TextAlign.center,
                          style: Fx.text(
                            14,
                            18,
                            FontWeight.w700,
                            -0.14,
                            color: _canContinue
                                ? Fx.white
                                : F2b.greyLavender,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isFigma
                ? 'All 3 critical checklist items must be resolved to unlock\nclient sign-off.'
                : l10n.finalizeIrreversible,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: Fx.text(
              13,
              18,
              FontWeight.w400,
              0,
              color: Fx.muted,
            ),
          ),
        ],
      ),
    );
  }

  List<_ReviewCardData> _figmaItems() {
    return [
      _ReviewCardData(
        iconId: '1_8394',
        iconSize: 18,
        title: 'Brake Fluid',
        titleWidth: 83.95,
        titleRightPad: 0,
        chipLabel: 'Chassis',
        chipWidth: 60.03,
        chipBg: Colors.transparent,
        chipTextColor: Fx.muted,
        detail: 'Reservoir moisture gauge & test strip',
        detailWidth: 165.66,
        titleRowWidth: 165.66,
        leftWidth: 229.66,
        actionIconId: '1_8406',
        actionIconSize: 18.33,
        chevronId: '1_8408',
        onTap: () {},
      ),
      _ReviewCardData(
        iconId: '1_8413',
        iconSize: 22,
        title: 'Tread Photo',
        titleWidth: 85.73,
        titleRightPad: 8.37,
        chipLabel: 'Front Left',
        chipWidth: 72.27,
        chipBg: Colors.transparent,
        chipTextColor: Fx.muted,
        detail: '3/32" depth indicator macro verification',
        detailWidth: 166,
        titleRowWidth: 166,
        leftWidth: 230,
        actionIconId: '1_8425',
        actionIconSize: 16.67,
        chevronId: '1_8427',
        onTap: () {},
      ),
      _ReviewCardData(
        iconId: '1_8432',
        iconSize: 19,
        title: 'Signature',
        titleWidth: 73.86,
        titleRightPad: 0,
        chipLabel: 'Required',
        chipWidth: 67.73,
        chipBg: F2b.rosePale,
        chipTextColor: Fx.dangerRed,
        detail: 'Digital advisor & vehicle owner sign-off',
        detailWidth: 164.34,
        titleRowWidth: 164.34,
        leftWidth: 228.34,
        actionIconId: '1_8444',
        actionIconSize: 16.67,
        chevronId: '1_8446',
        onTap: () {},
      ),
    ];
  }

  List<_ReviewCardData> _productItems(AppLocalizations l10n) {
    return review.blocking.map((issue) {
      final title = _issueTitle(l10n, issue);
      final detail = _issueDetail(l10n, issue);
      final itemId = issue.inspectionItemId ?? '';
      final isBrake = itemId.contains('brake');
      final isTread = itemId.contains('tread');
      final isSig = itemId.contains('sig');

      var iconId = '1_8394';
      var iconSize = 18.0;
      var actionIconId = '1_8406';
      var actionIconSize = 18.33;
      var chevronId = '1_8408';
      var chipLabel = l10n.missingItems;
      var chipBg = F2b.rosePale;
      var chipTextColor = Fx.dangerRed;

      if (isBrake) {
        iconId = '1_8394';
        iconSize = 18;
        actionIconId = '1_8406';
        actionIconSize = 18.33;
        chevronId = '1_8408';
        chipLabel = 'Chassis';
        chipBg = Colors.transparent;
        chipTextColor = Fx.muted;
      } else if (isTread) {
        iconId = '1_8413';
        iconSize = 22;
        actionIconId = '1_8425';
        actionIconSize = 16.67;
        chevronId = '1_8427';
        chipLabel = 'Front Left';
        chipBg = Colors.transparent;
        chipTextColor = Fx.muted;
      } else if (isSig) {
        iconId = '1_8432';
        iconSize = 19;
        actionIconId = '1_8444';
        actionIconSize = 16.67;
        chevronId = '1_8446';
        chipLabel = 'Required';
        chipBg = F2b.rosePale;
        chipTextColor = Fx.dangerRed;
      }

      return _ReviewCardData(
        iconId: iconId,
        iconSize: iconSize,
        title: title,
        titleWidth: 85,
        titleRightPad: 0,
        chipLabel: chipLabel,
        chipWidth: 70,
        chipBg: chipBg,
        chipTextColor: chipTextColor,
        detail: detail,
        detailWidth: 165,
        titleRowWidth: 165,
        leftWidth: 230,
        actionIconId: actionIconId,
        actionIconSize: actionIconSize,
        chevronId: chevronId,
        onTap: () => onOpenIssue(issue),
      );
    }).toList(growable: false);
  }
}

class _ReviewCardData {
  const _ReviewCardData({
    required this.iconId,
    required this.iconSize,
    required this.title,
    required this.titleWidth,
    required this.titleRightPad,
    required this.chipLabel,
    required this.chipWidth,
    required this.chipBg,
    required this.chipTextColor,
    required this.detail,
    required this.detailWidth,
    required this.titleRowWidth,
    required this.leftWidth,
    required this.actionIconId,
    required this.actionIconSize,
    required this.chevronId,
    required this.onTap,
  });

  final String iconId;
  final double iconSize;
  final String title;
  final double titleWidth;
  final double titleRightPad;
  final String chipLabel;
  final double chipWidth;
  final Color chipBg;
  final Color chipTextColor;
  final String detail;
  final double detailWidth;
  final double titleRowWidth;
  final double leftWidth;
  final String actionIconId;
  final double actionIconSize;
  final String chevronId;
  final VoidCallback onTap;
}

String _requirementLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'ITEM_UNANSWERED':
      return l10n.assessmentRequired;
    case 'REASON_REQUIRED':
      return l10n.reason;
    case 'SEVERITY_REQUIRED':
      return l10n.severity;
    case 'NOTE_REQUIRED':
      return l10n.note;
    case 'EVIDENCE_REQUIRED':
      return l10n.photoRequired;
    default:
      return l10n.missingItems;
  }
}

String _issueTitle(AppLocalizations l10n, ReviewIssue issue) {
  final label = issue.label?.trim() ?? '';
  if (label.isNotEmpty) return label;
  return _requirementLabel(l10n, issue.code);
}

String _issueDetail(AppLocalizations l10n, ReviewIssue issue) {
  final detail = issue.detail?.trim() ?? '';
  if (detail.isEmpty) return _requirementLabel(l10n, issue.code);
  const results = <String>{
    'NO_ISSUE_OBSERVED',
    'ATTENTION_RECOMMENDED',
    'DEFECT_FOUND',
    'NOT_CHECKED',
    'NOT_APPLICABLE',
    'COULD_NOT_VERIFY',
  };
  const severities = <String>{'MINOR', 'MODERATE', 'MAJOR', 'SAFETY_CRITICAL'};
  if (results.contains(detail)) return resultLabel(l10n, detail);
  if (severities.contains(detail)) return severityLabel(l10n, detail);
  return _requirementLabel(l10n, issue.code);
}
