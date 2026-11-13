import 'package:flutter/material.dart';

import '../platform_theme.dart';

/// Primary filled pill button (deep green). Always first in an action row.
class PlatformPrimaryButton extends StatelessWidget {
  const PlatformPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final labelStyle = PtTheme.font(
      13,
      lineHeight: 18,
      weight: FontWeight.w700,
      color: PtTheme.white,
    );
    final child = isLoading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: PtTheme.white,
            ),
          )
        : (icon == null
              ? Text(
                  label,
                  style: labelStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: PtTheme.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        style: labelStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ));
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: PtTheme.deepGreen,
        foregroundColor: PtTheme.white,
        disabledBackgroundColor: PtTheme.muted.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        elevation: 0,
      ),
      child: child,
    );
  }
}

/// Secondary outlined pill button.
class PlatformSecondaryButton extends StatelessWidget {
  const PlatformSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? PtTheme.rose : PtTheme.deepGreen;
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: destructive
              ? PtTheme.rose.withValues(alpha: 0.45)
              : PtTheme.border,
          width: 1.4,
        ),
        backgroundColor: PtTheme.white,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : icon == null
          ? Text(
              label,
              style: PtTheme.font(
                13,
                lineHeight: 18,
                weight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w700,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}
