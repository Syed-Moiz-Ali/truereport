import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

import '../../../admin_providers.dart';
import 'settings_geometry.dart';
import 'settings_primitives.dart';

/// The only live preference on this screen: the interface language.
///
/// Large options, each showing the language in its own script and its locale
/// code. The list comes straight from the shared backend manifest and the tap
/// applies the language immediately; there is no save button, no confirmation
/// dialog and no app-local language list.
class SettingsLanguageSurface extends ConsumerWidget {
  const SettingsLanguageSurface({
    this.client = adminUiMessageClient,
    super.key,
  });

  final String client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final selection = ref.watch(languageSelectionProvider(client));
    final languages =
        selection.manifest?.languages ?? const <UiMessageLanguage>[];

    // One language means nothing to choose: stay out of the way.
    if (languages.length < 2) return const SizedBox.shrink();

    return SettingsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t(WorkshopAdminKeys.settingsLanguage), style: ws.sectionTitle),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final options = <Widget>[
                for (final language in languages)
                  SettingsLanguageOption(
                    key: Key('settings-language-${language.code}'),
                    label: language.displayName,
                    code: language.code.toUpperCase(),
                    selected: selection.activeLanguage == language.code,
                    onTap: () => ref
                        .read(languageSelectionProvider(client).notifier)
                        .useLanguage(language.code),
                  ),
              ];
              if (constraints.maxWidth < 280) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      options[i],
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final option in options)
                    SizedBox(width: 200, child: option),
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
