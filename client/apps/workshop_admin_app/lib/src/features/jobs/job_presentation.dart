import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

export 'shared/job_fact.dart';
export 'shared/job_fact_grid.dart';
export 'shared/job_status_badge.dart';

/// Breakpoint at which a job list becomes a table instead of stacked cards.
/// Shared by the board and any tabular job surface.
const double jobWideRowMinWidth = 820;

/// Small icon + text row; the text wraps instead of being clipped unless the
/// caller pins it (identifiers such as job references never wrap).
class JobMetaLine extends StatelessWidget {
  const JobMetaLine({
    required this.icon,
    required this.text,
    this.textDirection,
    this.maxLines = 2,
    this.softWrap = true,
    super.key,
  });

  final IconData icon;
  final String text;
  final TextDirection? textDirection;
  final int maxLines;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(top: spacing.xxs),
          child: Icon(icon, size: 14, color: ws.muted),
        ),
        SizedBox(width: spacing.xs),
        Flexible(
          child: Text(
            text,
            textDirection: textDirection,
            maxLines: maxLines,
            softWrap: softWrap,
            style: ws.meta.copyWith(color: ws.muted),
          ),
        ),
      ],
    );
  }
}

/// 60 px page top bar for job sub-pages: back, title and trailing actions.
///
/// Grows with the title (two lines) instead of truncating at large text
/// scales, and keeps a 44 px back target with a semantic label.
class JobPageTopBar extends StatelessWidget {
  const JobPageTopBar({
    required this.title,
    this.breadcrumbs,
    this.onBack,
    this.actions = const [],
    super.key,
  });

  final String title;
  final List<String>? breadcrumbs;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      constraints: BoxConstraints(minHeight: ws.topBarHeight),
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
        vertical: spacing.xs,
      ),
      child: Row(
        children: [
          WorkshopIconButton(
            icon: rtl ? Icons.arrow_forward : Icons.arrow_back,
            semanticLabel: l10n.commonBack,
            onPressed:
                onBack ??
                () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                },
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: breadcrumbs != null && breadcrumbs!.isNotEmpty
                ? Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: spacing.xs,
                    children: [
                      for (int i = 0; i < breadcrumbs!.length; i++) ...[
                        if (i > 0)
                          Text('/', style: ws.meta.copyWith(color: ws.muted)),
                        Text(
                          breadcrumbs![i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: i == breadcrumbs!.length - 1
                              ? ws.cardTitle.copyWith(color: ws.ink)
                              : ws.meta.copyWith(
                                  color: ws.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                        ),
                      ],
                    ],
                  )
                : Text(
                    title,
                    maxLines: 2,
                    style: ws.cardTitle.copyWith(color: ws.ink),
                  ),
          ),
          for (final action in actions) ...[
            SizedBox(width: spacing.xs),
            action,
          ],
        ],
      ),
    );
  }
}
