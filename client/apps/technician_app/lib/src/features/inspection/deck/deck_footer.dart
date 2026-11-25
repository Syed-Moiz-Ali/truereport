import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import 'deck_header.dart';

/// One persistent primary action, derived from real progress, plus the single
/// secondary entry to the summary.
///
/// The label is decided by the deck, not here: `Finish job` only when every
/// item in every section is assessed, otherwise `Continue · {next item}` or
/// `Check {next item}`.
class DeckFooter extends StatelessWidget {
  const DeckFooter({
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.onSummary,
    this.nextItem,
    super.key,
  });

  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final VoidCallback onSummary;

  /// Name of the item the primary action will open. Shown above the buttons so
  /// a long checklist sentence never truncates the verb on a 390 px screen.
  final String? nextItem;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 12),
      child: DeckCapped(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (nextItem != null && nextItem!.isNotEmpty) ...[
              Text(
                '${t(TechnicianKeys.technicianNextUp)} · $nextItem',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: deckText(
                  context,
                  11.5,
                  weight: FontWeight.w600,
                  height: 15,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                _FooterSecondary(
                  label: t(TechnicianKeys.technicianDeckSummaryAction),
                  onPressed: onSummary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FooterPrimary(
                    label: primaryLabel,
                    icon: primaryIcon,
                    onPressed: onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterPrimary extends StatefulWidget {
  const _FooterPrimary({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_FooterPrimary> createState() => _FooterPrimaryState();
}

class _FooterPrimaryState extends State<_FooterPrimary> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: SizedBox(
          height: 48,
          child: Material(
            color: context.brand.ink,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onPressed,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: _focused
                      ? Border.all(color: context.colors.focus, width: 2)
                      : null,
                ),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.label,
                        key: const Key('inspection-next-action'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: deckText(
                          context,
                          14,
                          weight: FontWeight.w700,
                          height: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(widget.icon, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterSecondary extends StatefulWidget {
  const _FooterSecondary({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_FooterSecondary> createState() => _FooterSecondaryState();
}

class _FooterSecondaryState extends State<_FooterSecondary> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: SizedBox(
          height: 48,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onPressed,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _focused ? colors.focus : colors.outlineVariant,
                    width: _focused ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 17,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: deckText(
                        context,
                        13.5,
                        weight: FontWeight.w600,
                        height: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
