import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A publish failure (including `422 CONSENT_REQUIRED`) is shown inline, with
/// the copy already mapped by `jobErrorCopy`.
class PublishErrorBanner extends StatelessWidget {
  const PublishErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsetsDirectional.all(spacing.md),
        decoration: BoxDecoration(
          color: ws.dangerSoft,
          borderRadius: BorderRadius.circular(ws.cardRadius),
          border: Border.all(color: ws.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 18, color: ws.danger),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(message, style: ws.body.copyWith(color: ws.ink)),
            ),
          ],
        ),
      ),
    );
  }
}
