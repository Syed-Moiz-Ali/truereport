import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'settings_geometry.dart';

/// Shared atoms for the settings screen.
///
/// Everything is token-driven (`context.ws`): no colour, radius or type value
/// is inlined at the call site. Geometry that deliberately differs from the
/// workshop kit default lives in [SettingsGeometry] and is documented there.

/// A 16 px surface with a hairline border and no shadow.
class SettingsSurface extends StatelessWidget {
  const SettingsSurface({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(SettingsGeometry.surfaceRadius),
        border: Border.all(color: ws.border),
      ),
      child: child,
    );
  }
}

enum SettingsPillTone { neutral, accent, onInk }

/// 28 px status pill. Never colour alone: every pill carries a label and,
/// where the meaning matters, an icon.
class SettingsPill extends StatelessWidget {
  const SettingsPill({
    required this.label,
    this.tone = SettingsPillTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final SettingsPillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final (background, foreground, border) = switch (tone) {
      SettingsPillTone.neutral => (ws.canvas, ws.muted, ws.border),
      SettingsPillTone.accent => (ws.accentSoft, ws.accent, Colors.transparent),
      SettingsPillTone.onInk => (
        ws.surface.withValues(alpha: 0.1),
        ws.surface.withValues(alpha: 0.92),
        ws.surface.withValues(alpha: 0.18),
      ),
    };
    return Container(
      height: SettingsGeometry.pillHeight,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SettingsGeometry.pillRadius),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ws.meta.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 48 px destructive action: outline by default, tinted on hover, never a
/// solid red block. Label always visible; icon is decorative.
class SettingsActionButton extends StatefulWidget {
  const SettingsActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  State<SettingsActionButton> createState() => _SettingsActionButtonState();
}

class _SettingsActionButtonState extends State<SettingsActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final enabled = widget.onPressed != null;
    final foreground = enabled ? ws.danger : ws.muted;
    final border = enabled ? (_focused ? ws.focus : ws.danger) : ws.border;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = enabled),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: context.motionDuration(SettingsGeometry.press),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(
                SettingsGeometry.controlRadius,
              ),
              onFocusChange: (value) => setState(() => _focused = value),
              onHighlightChanged: (value) => setState(() => _pressed = value),
              child: AnimatedContainer(
                duration: context.motionDuration(SettingsGeometry.settle),
                curve: Curves.easeOutCubic,
                height: SettingsGeometry.controlHeight,
                width: widget.expand ? double.infinity : null,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: _hovered ? ws.dangerSoft : ws.surface,
                  borderRadius: BorderRadius.circular(
                    SettingsGeometry.controlRadius,
                  ),
                  border: Border.all(color: border, width: _focused ? 2 : 1),
                ),
                child: Row(
                  mainAxisSize: widget.expand
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: foreground),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: ws.bodyStrong.copyWith(color: foreground),
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

/// Rounded-square seal used for the workshop. Shape is shared with
/// [SettingsAvatar] so both monograms read as one family.
class SettingsSeal extends StatelessWidget {
  const SettingsSeal({
    required this.icon,
    this.size = 52,
    this.onInk = false,
    super.key,
  });

  final IconData icon;
  final double size;
  final bool onInk;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onInk ? ws.surface.withValues(alpha: 0.09) : ws.accentSoft,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: onInk
              ? ws.surface.withValues(alpha: 0.16)
              : ws.accent.withValues(alpha: 0.18),
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.42,
        color: onInk ? ws.surface : ws.accent,
      ),
    );
  }
}

/// Initials monogram. Identity is never truncated — the initials are the
/// short form, the full name always sits beside it.
class SettingsAvatar extends StatelessWidget {
  const SettingsAvatar({
    required this.initials,
    this.semanticLabel,
    this.size = 40,
    this.onInk = false,
    super.key,
  });

  final String initials;

  /// When null the avatar is decorative: the full name is always rendered
  /// beside it, so announcing the initials would repeat the identity.
  final String? semanticLabel;
  final double size;
  final bool onInk;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final background = onInk
        ? ws.surface.withValues(alpha: 0.1)
        : ws.accentSoft;
    final foreground = onInk ? ws.surface : ws.accent;
    final visual = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: onInk
              ? ws.surface.withValues(alpha: 0.16)
              : ws.accent.withValues(alpha: 0.18),
        ),
      ),
      child: ExcludeSemantics(
        child: Text(
          initials,
          style: ws.bodyStrong.copyWith(
            fontSize: size * 0.34,
            color: foreground,
            height: 1,
          ),
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) {
      return ExcludeSemantics(child: visual);
    }
    return Semantics(label: label, excludeSemantics: true, child: visual);
  }
}

/// First letters of the first two words. Empty input yields an empty string so
/// callers can omit the avatar rather than draw a blank tile.
String settingsInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return (parts.first.characters.first + parts[1].characters.first)
      .toUpperCase();
}
