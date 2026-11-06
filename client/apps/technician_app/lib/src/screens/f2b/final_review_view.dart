import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';

/// Figma screen 13. The blocked state of the review route: real server blocking
/// items, a real coverage count and a disabled continue action.
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
    return Scaffold(
      backgroundColor: Fx.white,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 72, 20, 40),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.reviewAndFinalize.toUpperCase(),
                        maxLines: 1,
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
                    F2bStatusPill(
                      label: '${review.blocking.length} ${l10n.missingItems}',
                      background: const Color(0xFFFFDAD6),
                      foreground: const Color(0xFF79000E),
                      dot: const Color(0xFFB91A24),
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w600,
                        0.44,
                        color: const Color(0xFF79000E),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.reviewAndFinalize,
                style: Fx.display26.copyWith(color: Fx.ink),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.finalizeIrreversible,
                style: Fx.body14.copyWith(color: Fx.muted),
              ),
              const SizedBox(height: 24),
              if (review.blocking.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0x4DFFDAD7),
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
                            color: Color(0xFFB91A24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${review.blocking.length} ${l10n.missingItems}',
                              style: Fx.title16.copyWith(color: Fx.ink),
                            ),
                            const SizedBox(height: 4),
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
              const SizedBox(height: 32),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x99F4F3F8),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: F2bKeyValue(
                        label: l10n.completedItems,
                        value: '${review.completed} / ${review.total}',
                      ),
                    ),
                    Text(
                      '${review.total == 0 ? 0 : ((review.completed / review.total) * 100).round()}%',
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w700,
                        0.44,
                        color: Fx.deepGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FxButton(
                label: l10n.reviewAndFinalize,
                onPressed: _canContinue ? onContinue : null,
                icon: FxIcon(
                  id: '1_8463',
                  size: 13.33,
                  color: _canContinue ? Fx.white : const Color(0xFFC7C5D3),
                ),
                trailingIcon: false,
              ),
              const SizedBox(height: 12),
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
            child: FxHeader(
              title: job.templateName.isEmpty
                  ? l10n.checklist
                  : job.templateName,
              showBack: onBack != null,
              titleInset: 4,
              actions: [
                FxProfileButton(
                  initials: 'TR',
                  iconId: '1_8478',
                  onPressed: onProfile,
                  semanticLabel: l10n.technicianProfileTitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
    return FxCard(
      radius: 32,
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      semanticLabel: '${issue.label ?? issue.code}. ${issue.detail ?? ''}',
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
                '$index',
                textDirection: TextDirection.ltr,
                style: Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.ink),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        issue.label ?? issue.code,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: Fx.title16.copyWith(color: Fx.ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    F2bStatusPill(
                      label: l10n.missingItems,
                      background: const Color(0xFFFFDAD6),
                      foreground: const Color(0xFFB91A24),
                      style: Fx.caption.copyWith(
                        color: const Color(0xFFB91A24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  issue.detail ?? issue.code,
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: Fx.body13.copyWith(color: Fx.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDAD6),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: FxIcon(
                id: '1_8406',
                size: 18.33,
                color: Color(0xFFB91A24),
              ),
            ),
          ),
          const FxIcon(id: '1_8408', size: 7, color: Color(0xFFC7C5D3)),
        ],
      ),
    );
  }
}
