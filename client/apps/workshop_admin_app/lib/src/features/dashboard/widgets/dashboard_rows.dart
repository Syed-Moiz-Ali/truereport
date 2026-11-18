import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Group heading for the dashboard's three action groups (direction B).
///
/// A single square swatch carries the colour, the title carries the meaning and
/// the meta carries the server count. No card, no container — the page's groups
/// sit directly on the canvas.
class DashboardGroupHeader extends StatelessWidget {
  const DashboardGroupHeader({
    required this.swatch,
    required this.title,
    required this.meta,
    super.key,
  });

  final Color swatch;
  final String title;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final swatchBox = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: swatch,
        borderRadius: BorderRadius.circular(1),
      ),
    );
    final titleText = Text(title, maxLines: 2, style: ws.sectionTitle);
    final metaText = meta == null
        ? null
        : Text(meta!, style: ws.meta.copyWith(color: ws.muted));

    return Semantics(
      header: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dense =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.4;
          if (dense) {
            // Narrow column, or large text: the count drops under the title
            // instead of squeezing it into a two-line fragment.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    swatchBox,
                    SizedBox(width: spacing.sm),
                    Flexible(child: titleText),
                  ],
                ),
                if (metaText != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: spacing.md),
                    child: metaText,
                  ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              swatchBox,
              SizedBox(width: spacing.sm),
              Flexible(child: titleText),
              if (metaText != null) ...[
                SizedBox(width: spacing.sm),
                Flexible(child: metaText),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// One job line inside a group: title + status pill, one meta line, an optional
/// verb. A rule separates rows; there is no card.
///
/// The verb is a text action, not a filled button: the page has exactly one
/// filled button ("New job") and the row verbs must not compete with it.
class DashboardJobRow extends StatelessWidget {
  const DashboardJobRow({
    required this.title,
    required this.meta,
    required this.statusLabel,
    required this.statusTone,
    required this.onTap,
    this.verbLabel,
    this.onVerb,
    this.verbInline = true,
    this.rowKey,
    super.key,
  });

  final String title;
  final String meta;
  final String statusLabel;
  final WorkshopStatusTone statusTone;
  final VoidCallback onTap;
  final String? verbLabel;
  final VoidCallback? onVerb;
  final bool verbInline;
  final Key? rowKey;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;

    // Wrap, not Row: at 2x text scale a long vehicle name and a status pill do
    // not both fit on one line in the narrow column, and a Row would overflow.
    // The pill drops to its own line instead.
    final titleLine = Wrap(
      spacing: spacing.sm,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ws.bodyStrong,
        ),
        WorkshopStatusBadge(label: statusLabel, tone: statusTone),
      ],
    );

    // The meta is a data line (reference · customer · technician · schedule).
    // A fixed LTR base keeps its runs in logical order in Arabic too; the
    // Arabic name inside still shapes right-to-left.
    final metaLine = Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        meta,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        style: ws.meta.copyWith(color: ws.muted),
      ),
    );

    final verb = (verbLabel == null || onVerb == null)
        ? null
        : _RowVerb(label: verbLabel!, onTap: onVerb!);

    return Material(
      key: rowKey,
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        canRequestFocus: true,
        hoverColor: ws.canvas,
        focusColor: ws.accentSoft,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: spacing.md),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: ws.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleLine,
                    const SizedBox(height: 3),
                    metaLine,
                    // On phone the verb gets its own line: the meta line keeps
                    // the reference, customer and schedule instead of being
                    // truncated to make room for an action.
                    if (verb != null && !verbInline) ...[
                      SizedBox(height: spacing.xs),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: verb,
                      ),
                    ],
                  ],
                ),
              ),
              if (verb != null && verbInline) ...[
                SizedBox(width: spacing.md),
                verb,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RowVerb extends StatelessWidget {
  const _RowVerb({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: true,
          borderRadius: BorderRadius.circular(ws.chipRadius),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: ws.touchTarget),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: ws.meta.copyWith(
                      color: ws.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: spacing.xxs),
                  Icon(Icons.arrow_forward, size: 14, color: ws.accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet empty line for a group that has nothing in it.
class DashboardGroupEmpty extends StatelessWidget {
  const DashboardGroupEmpty({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.md),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 15, color: ws.muted),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(text, style: ws.meta.copyWith(color: ws.muted)),
          ),
        ],
      ),
    );
  }
}
