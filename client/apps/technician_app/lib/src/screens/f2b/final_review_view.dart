import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2b/f2b_intl.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';
import 'package:technician_app/src/ui_helpers.dart';

/// Figma screen 13. The blocked state of the review route: real server blocking
/// items, a real completed/total count with a computed coverage percentage
/// explicitly labelled as coverage (never a score or pass-rate), and a disabled
/// continue action until the gate passes.
class FinalReviewView extends StatelessWidget {
  const FinalReviewView({
    required this.job,
    required this.review,
    required this.onOpenIssue,
    required this.onContinue,
    this.onBack,
    this.onProfile,
    this.busy = false,
    super.key,
  });

  final TechnicianJob job;
  final ReviewResult review;
  final ValueChanged<ReviewIssue> onOpenIssue;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final bool busy;

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
          ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(_M.gutter, 72, _M.gutter, _M.blockMid),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: _M.padLarge),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.reviewAndFinalize.toUpperCase(),
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
                    F2bStatusPill(
                      label:
                          '${formatCountLocalized(review.blocking.length, localeName)} ${l10n.missingItems}',
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
              Semantics(
                header: true,
                child: Text(
                  l10n.reviewAndFinalize,
                  style: Fx.display26.copyWith(color: Fx.ink),
                ),
              ),
              const SizedBox(height: _M.gapXSmall),
              Text(
                l10n.finalizeIrreversible,
                style: Fx.body14.copyWith(color: Fx.muted),
              ),
              const SizedBox(height: _M.padLarge),
              if (review.blocking.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(_M.gutter),
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
                      const SizedBox(width: _M.padMid),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${formatCountLocalized(review.blocking.length, localeName)} ${l10n.missingItems}',
                              style: Fx.title16.copyWith(color: Fx.ink),
                            ),
                            const SizedBox(height: _M.gapXSmall),
                            Text(
                              l10n.finalizeIrreversible,
                              style: Fx.body13.copyWith(color: Fx.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: _M.gapLarge),
              F2bSectionLabel(l10n.missingItems),
              const SizedBox(height: 14),
              for (var index = 0; index < review.blocking.length; index++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 14),
                  child: _IssueRow(
                    index: index + 1,
                    issue: review.blocking[index],
                    onTap: () => onOpenIssue(review.blocking[index]),
                  ),
                ),
              const SizedBox(height: 18),
              Semantics(
                label: l10n.technicianCoverageSemantics(
                  review.completed,
                  review.total,
                ),
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(_M.padMid),
                    decoration: BoxDecoration(
                      color: Fx.container99,
                      borderRadius: BorderRadius.circular(Fx.cardRadius),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Fx.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: FxIcon(
                              id: '1_8452',
                              size: 16.5,
                              color: Fx.emerald,
                            ),
                          ),
                        ),
                        const SizedBox(width: _M.gapMid),
                        Expanded(
                          child: F2bKeyValue(
                            label: l10n.completedItems,
                            value: formatCountPairLocalized(
                              review.completed,
                              review.total,
                              localeName,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.coverage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w600,
                                0.55,
                                color: Fx.muted,
                              ),
                            ),
                            const SizedBox(height: _M.tick),
                            Text(
                              formatPercentLocalized(percent, localeName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              textDirection: TextDirection.ltr,
                              style: Fx.text(
                                16,
                                22,
                                FontWeight.w700,
                                -0.16,
                                color: Fx.inkStrong,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _M.gapLarge),
              F2bFocusFrame(
                child: FxButton(
                  label: l10n.reviewAndFinalize,
                  onPressed: _canContinue ? onContinue : null,
                  icon: FxIcon(
                    id: '1_8463',
                    size: 13.33,
                    color: _canContinue ? Fx.white : F2b.greyLavender,
                  ),
                  trailingIcon: false,
                ),
              ),
              const SizedBox(height: _M.gapMid),
              Text(
                l10n.finalizeIrreversible,
                textAlign: TextAlign.center,
                style: Fx.body13.copyWith(color: Fx.muted),
              ),
            ],
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            // Focus frame at header level gives the FxHeader back button a
            // visible deep-green ring on keyboard focus; unfocused it is
            // borderless so the 1.0x geometry is unchanged.
            child: F2bFocusFrame(
              borderRadius: BorderRadius.zero,
              child: FxHeader(
                title: job.templateName.isEmpty
                    ? l10n.checklist
                    : job.templateName,
                showBack: onBack != null,
                titleInset: 4,
                actions: [
                // 48 dp invisible hit area; the visible disc stays Figma-exact.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: F2bFocusFrame(
                      borderRadius: BorderRadius.circular(Fx.pillRadius),
                      child: FxProfileButton(
                        initials: _initials(job.assignedTechnicianName),
                        iconId: '1_8478',
                        onPressed: onProfile,
                        semanticLabel: l10n.technicianProfileTitle,
                      ),
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

  String _initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'TR';
    final first = String.fromCharCode(parts.first.runes.first).toUpperCase();
    if (parts.length == 1) return first;
    final last = String.fromCharCode(parts.last.runes.first).toUpperCase();
    return '$first$last';
  }
}

/// Maps a server blocking code to a localized requirement label so a raw
/// unlocalized status code is never shown.
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

/// The server sends a result code (localized here via the shared helpers) or,
/// for evidence, an English "Required evidence: …, verified: …" sentence. Both
/// raw forms are replaced with ARB copy; nothing invented, nothing unlocalized.
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

class _IssueRow extends StatelessWidget {
  const _IssueRow({
    required this.index,
    required this.issue,
    required this.onTap,
  });

  final int index;
  final ReviewIssue issue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final title = _issueTitle(l10n, issue);
    final detail = _issueDetail(l10n, issue);
    return FxCard(
      radius: 32,
      padding: const EdgeInsets.all(_M.gutter),
      onTap: onTap,
      semanticLabel: '$title. $detail',
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                formatCountLocalized(index, localeName),
                textDirection: TextDirection.ltr,
                style: Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.ink),
              ),
            ),
          ),
          const SizedBox(width: _M.padMid),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 1.0x-exact: pill keeps its intrinsic width when it fits
                    // (cap is above the 1.0x intrinsic), and only scales down
                    // via scaleDown when text-scaling would overflow.
                    final maxPillWidth = constraints.maxWidth * 0.6;
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Fx.title16.copyWith(color: Fx.ink),
                          ),
                        ),
                        const SizedBox(width: _M.gapSmall),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxPillWidth,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment:
                                AlignmentDirectional.centerEnd,
                            child: F2bStatusPill(
                              label: l10n.missingItems,
                              background: F2b.rosePale,
                              foreground: Fx.dangerRed,
                              style: Fx.caption.copyWith(
                                color: Fx.dangerRed,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: _M.tick),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.body13.copyWith(color: Fx.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: _M.gapSmall),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: F2b.rosePale,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: FxIcon(
                id: '1_8406',
                size: 18.33,
                color: Fx.dangerRed,
              ),
            ),
          ),
          const FxIcon(id: '1_8408', size: 7, color: F2b.greyLavender),
        ],
      ),
    );
  }
}

/// Figma-exact spacing for this screen (F2-A `_M` pattern).
abstract final class _M {
  static const double tick = 2;
  static const double gapXSmall = 4;
  static const double gapSmall = 8;
  static const double gapMid = 12;
  static const double padMid = 16;
  static const double gutter = 20;
  static const double padLarge = 24;
  static const double gapLarge = 32;
  static const double blockMid = 40;
}
