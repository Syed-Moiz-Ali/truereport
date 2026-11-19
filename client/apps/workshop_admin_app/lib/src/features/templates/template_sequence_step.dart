import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/templates/template_selected_item.dart';

/// Step 2, left pane — the ordered inspection route.
///
/// Numbered nodes on one connecting surface. Ordering is managed with
/// explicit move controls (keyboard reachable, no drag-only affordance) plus
/// remove; the saved payload is still `sortOrder` per entry.
class TemplateSequenceStep extends StatelessWidget {
  const TemplateSequenceStep({
    required this.items,
    required this.enabled,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    super.key,
  });

  final List<TemplateSelectedItem> items;
  final bool enabled;
  final void Function(int index) onMoveUp;
  final void Function(int index) onMoveDown;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 6),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                l10n.builderSequenceTitle,
                style: ws.cardTitle.copyWith(color: ws.ink),
              ),
              const Spacer(),
              Text(
                l10n.templateItemsCount(items.length),
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(Icons.route_outlined, size: 22, color: ws.muted),
                  const SizedBox(height: 10),
                  Text(l10n.noItems, style: ws.body.copyWith(color: ws.ink)),
                  const SizedBox(height: 4),
                  Text(l10n.addItems, style: ws.meta.copyWith(color: ws.muted)),
                ],
              ),
            )
          else
            for (var i = 0; i < items.length; i++)
              _node(context, ws, i, items[i]),
        ],
      ),
    );
  }

  Widget _node(
    BuildContext context,
    WorkshopTokens ws,
    int index,
    TemplateSelectedItem item,
  ) {
    final l10n = AppLocalizations.of(context);
    final first = index == 0;
    final last = index == items.length - 1;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: first
            ? null
            : BorderDirectional(top: BorderSide(color: ws.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: first ? ws.accent : ws.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: ws.meta.copyWith(
                color: first ? ws.onAccent : ws.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.labelEn,
                  maxLines: 2,
                  style: ws.body.copyWith(color: ws.ink, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.stableCode} · ${item.categoryLabelEn} · v${item.versionNo}',
                  style: ws.meta.copyWith(color: ws.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (enabled) ...[
            _icon(
              context,
              icon: Icons.arrow_upward,
              tooltip: l10n.moveUp,
              onPressed: first ? null : () => onMoveUp(index),
            ),
            _icon(
              context,
              icon: Icons.arrow_downward,
              tooltip: l10n.moveDown,
              onPressed: last ? null : () => onMoveDown(index),
            ),
            _icon(
              context,
              icon: Icons.close,
              tooltip: l10n.remove,
              onPressed: () => onRemove(index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _icon(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final ws = context.ws;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkResponse(
          onTap: onPressed,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: onPressed == null ? ws.border : ws.muted,
            ),
          ),
        ),
      ),
    );
  }
}
