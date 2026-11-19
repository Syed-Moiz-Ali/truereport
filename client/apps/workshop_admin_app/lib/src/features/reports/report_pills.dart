import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The pill language already used by the templates and jobs modules
/// (`TemplatePillChip` / `JobStatusPill`): full radius, dot + label, height
/// 28 for status. This is the report module's only pill, so a status can never
/// pick up a third shape.
class ReportStatusPill extends StatelessWidget {
  const ReportStatusPill({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final WorkshopStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final (Color foreground, Color background) = switch (tone) {
      WorkshopStatusTone.neutral => (ws.ink, ws.canvas),
      WorkshopStatusTone.accent => (ws.accent, ws.accentSoft),
      WorkshopStatusTone.success => (ws.success, ws.successSoft),
      WorkshopStatusTone.warning => (ws.warning, ws.warningSoft),
      WorkshopStatusTone.danger => (ws.danger, ws.dangerSoft),
    };
    const pillHeight = 28.0;
    const radius = pillHeight / 2;
    return Semantics(
      container: true,
      label: label,
      child: Container(
        height: pillHeight,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.spacing.md,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: foreground.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 13, color: foreground)
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: foreground,
                  shape: BoxShape.circle,
                ),
              ),
            SizedBox(width: context.spacing.micro),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ws.meta.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uppercase section marker: the certificate's editorial voice.
class ReportEyebrow extends StatelessWidget {
  const ReportEyebrow({required this.label, this.color, super.key});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Text(
      label.toUpperCase(),
      style: ws.eyebrow.copyWith(color: color ?? ws.muted, letterSpacing: 1.1),
    );
  }
}
