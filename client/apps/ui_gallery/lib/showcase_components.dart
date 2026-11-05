import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:ui_gallery/support/gallery_widgets.dart';

class ButtonsShowcase extends StatelessWidget {
  const ButtonsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.md,
      children: [
        GalleryTile(
          label: 'Primary',
          child: AppButton(label: 'Primary', onPressed: () {}),
        ),
        GalleryTile(
          label: 'Secondary (tonal)',
          child: AppButton(
            label: 'Secondary',
            onPressed: () {},
            variant: AppButtonVariant.tonal,
          ),
        ),
        GalleryTile(
          label: 'Text',
          child: AppButton(
            label: 'Text',
            onPressed: () {},
            variant: AppButtonVariant.text,
          ),
        ),
        GalleryTile(
          label: 'Destructive',
          child: AppButton(
            label: 'Delete',
            onPressed: () {},
            variant: AppButtonVariant.destructive,
          ),
        ),
        GalleryTile(
          label: 'Loading',
          child: AppButton(label: 'Saving', onPressed: () {}, isLoading: true),
        ),
        const GalleryTile(
          label: 'Disabled',
          child: AppButton(label: 'Disabled', onPressed: null),
        ),
        GalleryTile(
          label: 'Pressed',
          child: Transform.scale(
            scale: context.motion.pressScale,
            child: AppButton(label: 'Pressed', onPressed: () {}),
          ),
        ),
        GalleryTile(
          label: 'Focus ring',
          child: Container(
            padding: EdgeInsetsDirectional.all(context.spacing.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.radii.lg),
              boxShadow: [context.shadows.focus],
            ),
            child: AppButton(label: 'Focused', onPressed: () {}),
          ),
        ),
        GalleryTile(
          label: 'With icon',
          child: AppButton(
            label: 'Continue',
            icon: Icons.arrow_forward,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class IconButtonsShowcase extends StatelessWidget {
  const IconButtonsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.md,
      children: [
        GalleryTile(
          label: 'Default',
          child: AppIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit',
            semanticLabel: 'Edit',
            onPressed: () {},
          ),
        ),
        const GalleryTile(
          label: 'Disabled',
          child: AppIconButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete',
            semanticLabel: 'Delete',
            onPressed: null,
          ),
        ),
      ],
    );
  }
}

class SvgIconsShowcase extends StatelessWidget {
  const SvgIconsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.md,
      children: [
        for (final icon in AppIconName.values)
          GalleryTile(
            label: icon.name,
            child: AppIcon(
              icon,
              size: context.sizing.iconXl,
              color: context.brand.ink,
              semanticLabel: icon.name,
            ),
          ),
      ],
    );
  }
}

class CardsShowcase extends StatelessWidget {
  const CardsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.md,
      children: [
        GalleryTile(
          label: 'Large card',
          width: 320,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inspection summary', style: context.texts.titleLarge),
                SizedBox(height: context.spacing.xs),
                Text(
                  'Coverage and findings for the current job.',
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        GalleryTile(
          label: 'Tonal card',
          width: 320,
          child: AppTonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Offline ready', style: context.texts.titleMedium),
                SizedBox(height: context.spacing.xs),
                Text(
                  'Changes are saved on this device.',
                  style: context.texts.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const GalleryTile(
          label: 'Stat card',
          width: 320,
          child: AppStatCard(
            label: 'Coverage',
            value: '62%',
            caption: '12 of 19 items',
          ),
        ),
      ],
    );
  }
}

class InputsShowcase extends StatefulWidget {
  const InputsShowcase({super.key});

  @override
  State<InputsShowcase> createState() => _InputsShowcaseState();
}

class _InputsShowcaseState extends State<InputsShowcase> {
  final _defaultController = TextEditingController(text: 'TR-2026-001');
  final _disabledController = TextEditingController(text: 'Locked value');
  final _noteController = TextEditingController();
  final _errorController = TextEditingController();
  final _errorSearchController = TextEditingController();

  @override
  void dispose() {
    _defaultController.dispose();
    _disabledController.dispose();
    _noteController.dispose();
    _errorController.dispose();
    _errorSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.md,
      children: [
        GalleryTile(
          label: 'Default',
          width: 320,
          child: AppTextField(
            controller: _defaultController,
            label: 'Job number',
            hint: 'TR-2026-001',
            helperText: 'Visible while editing',
          ),
        ),
        const GalleryTile(
          label: 'Focus',
          width: 320,
          child: _AutoFocusField(label: 'Email', hint: 'name@example.com'),
        ),
        GalleryTile(
          label: 'Error',
          width: 320,
          child: AppTextField(
            controller: _errorController,
            label: 'Email',
            hint: 'name@example.com',
            errorText: l10n.invalidEmail,
          ),
        ),
        GalleryTile(
          label: 'Disabled',
          width: 320,
          child: AppTextField(
            controller: _disabledController,
            label: 'Disabled',
            enabled: false,
          ),
        ),
        GalleryTile(
          label: 'Multiline',
          width: 320,
          child: AppTextField(
            controller: _noteController,
            label: 'Note',
            hint: 'Add a finding note',
            maxLines: 3,
          ),
        ),
        GalleryTile(
          label: 'Required error',
          width: 320,
          child: AppTextField(
            controller: _errorSearchController,
            label: 'Search',
            errorText: l10n.requiredField,
          ),
        ),
      ],
    );
  }
}

class _AutoFocusField extends StatefulWidget {
  const _AutoFocusField({required this.label, required this.hint});

  final String label;
  final String hint;

  @override
  State<_AutoFocusField> createState() => _AutoFocusFieldState();
}

class _AutoFocusFieldState extends State<_AutoFocusField> {
  final _controller = TextEditingController(text: 'focused@example.com');
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Uri.base.queryParameters['autofocus'] != '0') {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      focusNode: _focusNode,
      label: widget.label,
      hint: widget.hint,
    );
  }
}
