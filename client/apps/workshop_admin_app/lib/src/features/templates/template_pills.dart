import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// Rounded control language for the templates module.
///
/// Buttons and chips are full pills (radius = height / 2). This is a local
/// choice for this module — the shared `WorkshopButton` keeps the 10px
/// control radius — so the divergence is deliberate and contained here.
enum TemplatePillVariant { filled, outline, ghost, danger }

class TemplatePillButton extends StatefulWidget {
  const TemplatePillButton({
    required this.label,
    required this.onPressed,
    this.variant = TemplatePillVariant.filled,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TemplatePillVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  State<TemplatePillButton> createState() => _TemplatePillButtonState();
}

class _TemplatePillButtonState extends State<TemplatePillButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final enabled = widget.onPressed != null && !widget.loading;
    final height = widget.compact ? 34.0 : 42.0;

    final (Color bg, Color fg, Color border) = switch (widget.variant) {
      TemplatePillVariant.filled => (
        !enabled
            ? ws.border
            : _hover
            ? ws.accentHover
            : ws.accent,
        !enabled ? ws.muted : ws.onAccent,
        Colors.transparent,
      ),
      TemplatePillVariant.outline => (
        _hover ? ws.canvas : ws.surface,
        enabled ? ws.ink : ws.muted,
        ws.border,
      ),
      TemplatePillVariant.ghost => (
        _hover ? ws.canvas : Colors.transparent,
        enabled ? ws.muted : ws.muted,
        Colors.transparent,
      ),
      TemplatePillVariant.danger => (
        _hover ? ws.dangerSoft : ws.surface,
        ws.danger,
        ws.danger,
      ),
    };

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: widget.compact ? 15 : 17, color: fg),
        if (widget.loading || widget.icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ws.meta.copyWith(
              color: fg,
              fontSize: widget.compact ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            scale: _pressed ? 0.98 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: height,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: widget.compact ? 14 : 20,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(color: border),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter / category chip. Pill, 32 high, optional trailing count.
class TemplatePillChip extends StatefulWidget {
  const TemplatePillChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  State<TemplatePillChip> createState() => _TemplatePillChipState();
}

class _TemplatePillChipState extends State<TemplatePillChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final selected = widget.selected;
    final bg = selected
        ? ws.accentSoft
        : _hover
        ? ws.canvas
        : ws.surface;
    final fg = selected ? ws.accent : ws.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: widget.count == null
          ? widget.label
          : '${widget.label} (${widget.count})',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 32,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? ws.accent : ws.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: ws.meta.copyWith(
                    color: selected ? ws.accent : ws.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.count != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${widget.count}',
                    style: ws.meta.copyWith(
                      color: fg,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lifecycle badge for DRAFT / PUBLISHED / RETIRED.
class TemplateStatusPill extends StatelessWidget {
  const TemplateStatusPill({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final (Color bg, Color fg, String label) = switch (status) {
      'PUBLISHED' => (ws.successSoft, ws.success, l10n.published),
      'RETIRED' => (ws.canvas, ws.muted, l10n.retired),
      _ => (ws.warningSoft, ws.warning, l10n.draft),
    };
    return Semantics(
      label: label,
      child: Container(
        height: 24,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: ws.eyebrow.copyWith(color: fg, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

/// Round template mark used in the index and the builder header.
class TemplateGlyph extends StatelessWidget {
  const TemplateGlyph({this.size = 40, this.filled = false, super.key});

  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? ws.accent : ws.accentSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.checklist_rounded,
          size: size * 0.48,
          color: filled ? ws.onAccent : ws.accent,
        ),
      ),
    );
  }
}
