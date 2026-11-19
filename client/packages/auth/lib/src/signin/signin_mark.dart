import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The brand lockup: the TR tile, the wordmark and the portal label.
///
/// Extracted from the page so the ink surface and the phone band share one
/// definition. The tile is typographic because no logo asset exists; inventing
/// one was rejected at Gate 0.
class SigninMark extends StatelessWidget {
  const SigninMark({
    super.key,
    required this.onAccent,
    required this.portalLabel,
    this.appName = 'TrueReport',
    this.showPortalLabel = true,
  });

  /// `true` on the ink surface, `false` on the paper canvas.
  final bool onAccent;

  /// "Workshop Admin", "Technician", "Platform Admin", …
  final String portalLabel;
  final String appName;

  /// Hidden at >= 1.5x text in the phone band, where the label is the first
  /// thing to truncate and the wordmark already carries the identity.
  final bool showPortalLabel;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final foreground = onAccent ? ws.onAccent : ws.ink;
    final secondary = onAccent ? ws.onAccent.withValues(alpha: 0.72) : ws.muted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: onAccent ? ws.surface : ws.accent,
            borderRadius: BorderRadius.circular(ws.chipRadius),
          ),
          child: Text(
            'TR',
            style: ws.meta.copyWith(
              color: onAccent ? ws.accent : ws.onAccent,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        SizedBox(width: spacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  appName,
                  maxLines: 1,
                  style: ws.sectionTitle.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ),
              if (showPortalLabel)
                Text(
                  portalLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.meta.copyWith(color: secondary, height: 1.2),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
