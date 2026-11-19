import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';

/// Document bar for a job sub-page: back, the job reference, its lifecycle pill.
///
/// Same geometry as the job record page, so moving between the record and a
/// decision page does not shift the eye. The reference is always LTR because it
/// is a Latin identifier, never translated.
class JobPageBar extends StatelessWidget {
  const JobPageBar({required this.reference, this.status, super.key});

  final String reference;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: ws.topBarHeight,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
      ),
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
          child: Row(
            children: [
              WorkshopIconButton(
                icon: rtl ? Icons.arrow_forward : Icons.arrow_back,
                semanticLabel: l10n.commonBack,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    reference,
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ws.bodyStrong.copyWith(color: ws.ink),
                  ),
                ),
              ),
              if (status != null) ...[
                SizedBox(width: spacing.sm),
                JobStatusPill(status: status!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Section bar for a job-owned page that has no job reference in context:
/// back, the page title, and an optional trailing pill (count, status).
///
/// Same 60 px geometry as [JobPageBar] so moving between the record, the public
/// link, notifications and the archive never shifts the eye. The title is
/// translated copy, so it follows the ambient direction instead of being pinned
/// LTR like a reference.
class JobTitleBar extends StatelessWidget {
  const JobTitleBar({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: ws.topBarHeight,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
      ),
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
          child: Row(
            children: [
              WorkshopIconButton(
                icon: rtl ? Icons.arrow_forward : Icons.arrow_back,
                semanticLabel: l10n.commonBack,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ws.bodyStrong.copyWith(color: ws.ink),
                  ),
                ),
              ),
              if (trailing != null) ...[SizedBox(width: spacing.sm), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Page identity: what this page is, whose job it is, one meta line.
///
/// The name wraps instead of truncating: identity is never ellipsized.
class JobIdentityBlock extends StatelessWidget {
  const JobIdentityBlock({
    required this.eyebrow,
    required this.title,
    this.meta = const <String>[],
    super.key,
  });

  final String eyebrow;
  final String title;
  final List<String> meta;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final metaStyle = ws.meta.copyWith(color: ws.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: ws.eyebrow.copyWith(color: ws.muted),
        ),
        SizedBox(height: spacing.xs),
        Text(
          title,
          style: ws.pageTitle.copyWith(color: ws.ink, letterSpacing: -0.7),
        ),
        if (meta.isNotEmpty) ...[
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.md,
            runSpacing: spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // The separator leads each later item, so a wrapped line can never
              // end on a dangling dot.
              Text(meta.first, style: metaStyle),
              for (final item in meta.skip(1))
                Text('·\u00A0$item', style: metaStyle),
            ],
          ),
        ],
      ],
    );
  }
}

/// Page body grid: 5/4 columns from 900 px, one stack below it.
class JobSplitColumns extends StatelessWidget {
  const JobSplitColumns({
    required this.leading,
    required this.trailing,
    super.key,
  });

  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final gap = context.spacing.lg;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              SizedBox(height: gap),
              trailing,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: leading),
            SizedBox(width: gap),
            Expanded(flex: 4, child: trailing),
          ],
        );
      },
    );
  }
}
