import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../jobs_queue_style.dart';

/// One headed section of the queue: a small tracked label, the count, an
/// optional collapse affordance and one rounded surface holding the rows.
///
/// Sections with no rows render nothing, so an empty bucket never leaves a
/// stray heading on the screen.
class QueueSection extends StatelessWidget {
  const QueueSection({
    required this.title,
    required this.rows,
    this.collapsed = false,
    this.onToggle,
    this.footer,
    super.key,
  });

  final String title;
  final List<Widget> rows;
  final bool collapsed;
  final VoidCallback? onToggle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty && footer == null) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;

    final header = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 4, 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Row(
          children: [
            Flexible(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: queueEyebrow(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 7,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(QueueMetrics.radiusChip),
              ),
              child: Text(
                '${rows.length}',
                textDirection: TextDirection.ltr,
                style: queueText(
                  context,
                  11,
                  weight: FontWeight.w700,
                  height: 14,
                  tabular: true,
                ),
              ),
            ),
            if (onToggle != null) ...[
              const Spacer(),
              Icon(
                collapsed
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );

    final body = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index += 1) ...[
            rows[index],
            if (index != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: colors.outlineVariant,
                indent: 14,
                endIndent: 14,
              ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onToggle == null)
          header
        else
          Semantics(
            button: true,
            expanded: !collapsed,
            child: FocusableActionDetector(
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    onToggle!();
                    return null;
                  },
                ),
              },
              mouseCursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: header,
              ),
            ),
          ),
        if (!collapsed && rows.isNotEmpty) body,
        ?footer,
      ],
    );
  }
}
