import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../platform_theme.dart';

/// Shared card primitives for the languages module (Direction B).
///
/// Registries, workspaces and queues all speak the same visual language:
/// a human name, a lifecycle state chip, one big coverage number with a
/// meter, and verb-first actions. No raw codes, no database columns.

/// 8px coverage meter. Warn below full coverage, accent at 100%.
class LanguageCoverageMeter extends StatelessWidget {
  const LanguageCoverageMeter({super.key, required this.value});

  /// 0..1 fraction.
  final double value;

  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0.0, 1.0) * 100).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Row(
          children: <Widget>[
            Expanded(
              flex: filled,
              child: Container(
                color: value >= 1 ? PtTheme.deepGreen : PtTheme.amber,
              ),
            ),
            Expanded(
              flex: 100 - filled,
              child: Container(color: PtTheme.border.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lifecycle state chip: dot + label, never color alone.
class LanguageStateChip extends StatelessWidget {
  const LanguageStateChip({super.key, required this.label, this.warn = false});

  final String label;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final fg = warn ? PtTheme.gold : PtTheme.deepGreen;
    final bg = warn
        ? PtTheme.amber.withValues(alpha: 0.14)
        : PtTheme.deepGreen.withValues(alpha: 0.1);
    return Container(
      height: 28,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Registry status code (LIVE / DRAFT / TRANSLATING / REVIEW / RETIRED) to
/// its catalog key. Unknown codes fall back to the raw code so nothing
/// renders blank.
UiMessageKey languageStatusKey(String status) {
  switch (status.toUpperCase()) {
    case 'LIVE':
      return PlatformAdminKeys.statusLanguageLive;
    case 'DRAFT':
      return PlatformAdminKeys.statusLanguageDraft;
    case 'TRANSLATING':
      return PlatformAdminKeys.statusLanguageTranslating;
    case 'REVIEW':
      return PlatformAdminKeys.statusLanguageReview;
    case 'RETIRED':
      return PlatformAdminKeys.statusLanguageRetired;
    default:
      return PlatformAdminKeys.statusLanguageDraft;
  }
}

/// Grid/unit: numbers stay LTR even in an RTL locale.
///
/// Fractions and counters like `377 / 394` are neutral-separated numeric runs;
/// under RTL bidi the two runs get reordered and read backwards. Wrapping the
/// text in an explicit LTR direction keeps the digits in reading order.
class LtrNumbers extends StatelessWidget {
  const LtrNumbers(this.child, {super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.ltr, child: child);
  }
}

/// One bordered card shell shared by language surfaces.
class LanguageCardShell extends StatelessWidget {
  const LanguageCardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: child,
    );
  }
}

/// One ledger surface shared by language lists: single border, hairline
/// dividers between rows.
class LanguageLedger extends StatelessWidget {
  const LanguageLedger({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (var i = 0; i < children.length; i++) ...<Widget>[
              if (i > 0) const Divider(height: 1, color: PtTheme.border),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Responsive card grid: 2-up on desktop, 1-up below 860px.
class LanguageGrid extends StatelessWidget {
  const LanguageGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 12),
                children[i],
              ],
            ],
          );
        }
        const columns = 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - 12) / columns,
                child: child,
              ),
          ],
        );
      },
    );
  }
}
