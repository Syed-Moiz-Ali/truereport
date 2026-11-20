import 'package:flutter/material.dart';

import '../platform_theme.dart';

/// Primary filled button (deep green). Always maximum one primary per action area.
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
      weight: FontWeight.w600,
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
                    Icon(icon, size: 16, color: PtTheme.white),
                    const SizedBox(width: 6),
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
        disabledBackgroundColor: PtTheme.muted.withValues(alpha: 0.25),
        disabledForegroundColor: PtTheme.white.withValues(alpha: 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(44, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: child,
    );
  }
}

/// Secondary outlined button with subtle border and clear states.
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
    final color = destructive ? PtTheme.rose : PtTheme.ink;
    final borderColor = destructive
        ? PtTheme.rose.withValues(alpha: 0.35)
        : PtTheme.border;

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor, width: 1),
        backgroundColor: PtTheme.white,
        foregroundColor: color,
        disabledForegroundColor: PtTheme.muted.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(44, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : (icon == null
                ? Text(
                    label,
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w500,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: PtTheme.font(
                            13,
                            lineHeight: 18,
                            weight: FontWeight.w500,
                            color: color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )),
    );
  }
}

/// Ghost / text button for tertiary actions without visual clutter.
class PlatformGhostButton extends StatelessWidget {
  const PlatformGhostButton({
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
    final color = destructive ? PtTheme.rose : PtTheme.muted;

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(44, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : (icon == null
                ? Text(
                    label,
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w500,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: PtTheme.font(
                            13,
                            lineHeight: 18,
                            weight: FontWeight.w500,
                            color: color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )),
    );
  }
}

/// Destructive filled button for critical actions (e.g. deletion, retiring).
class PlatformDestructiveButton extends StatelessWidget {
  const PlatformDestructiveButton({
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
      weight: FontWeight.w600,
      color: PtTheme.white,
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: PtTheme.rose,
        foregroundColor: PtTheme.white,
        disabledBackgroundColor: PtTheme.rose.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(44, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: isLoading
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
                      Icon(icon, size: 16, color: PtTheme.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: labelStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )),
    );
  }
}
