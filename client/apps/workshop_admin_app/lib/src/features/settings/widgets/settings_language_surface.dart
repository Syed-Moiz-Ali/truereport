import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'settings_geometry.dart';
import 'settings_primitives.dart';

/// The only live preference on this screen: the interface language.
///
/// Two large options, each showing the language in its own script and its
/// locale code. Selection applies immediately through [onChanged]; there is no
/// save button and no confirmation dialog.
class SettingsLanguageSurface extends StatelessWidget {
  const SettingsLanguageSurface({
    required this.isArabic,
    required this.onChanged,
    super.key,
  });

  final bool isArabic;

  /// Called with `true` when Arabic is chosen, `false` for English.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final english = const Locale('en').languageCode.toUpperCase();
    final arabic = const Locale('ar').languageCode.toUpperCase();

    return SettingsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.settingsLanguage, style: ws.sectionTitle),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final options = <Widget>[
                SettingsLanguageOption(
                  key: const Key('settings-language-en'),
                  label: l10n.languageEnglish,
                  code: english,
                  selected: !isArabic,
                  onTap: () => onChanged(false),
                ),
                SettingsLanguageOption(
                  key: const Key('settings-language-ar'),
                  label: l10n.languageArabic,
                  code: arabic,
                  selected: isArabic,
                  onTap: () => onChanged(true),
                ),
              ];
              if (constraints.maxWidth < 280) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [options[0], const SizedBox(height: 8), options[1]],
                );
              }
              return Row(
                children: [
                  Expanded(child: options[0]),
                  const SizedBox(width: 12),
                  Expanded(child: options[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SettingsLanguageOption extends StatefulWidget {
  const SettingsLanguageOption({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<SettingsLanguageOption> createState() => _SettingsLanguageOptionState();
}

class _SettingsLanguageOptionState extends State<SettingsLanguageOption> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final radius = BorderRadius.circular(SettingsGeometry.controlRadius);
    final borderColor = _focused
        ? ws.focus
        : widget.selected
        ? ws.accent
        : ws.border;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            onHover: (value) => setState(() => _hovered = value),
            onFocusChange: (value) => setState(() => _focused = value),
            child: AnimatedContainer(
              duration: context.motionDuration(SettingsGeometry.settle),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(
                minHeight: 76,
                minWidth: SettingsGeometry.controlHeight,
              ),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: widget.selected
                    ? ws.accentSoft
                    : _hovered
                    ? ws.canvas
                    : ws.surface,
                borderRadius: radius,
                border: Border.all(
                  color: borderColor,
                  width: _focused ? 2 : (widget.selected ? 1.5 : 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.selected
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 18,
                    color: widget.selected ? ws.accent : ws.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: ws.cardTitle.copyWith(
                            fontSize: 17,
                            color: widget.selected ? ws.accent : ws.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.code,
                          style: ws.eyebrow.copyWith(color: ws.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
