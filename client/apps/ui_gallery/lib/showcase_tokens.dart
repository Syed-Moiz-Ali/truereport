import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:ui_gallery/support/gallery_widgets.dart';

class TokenSwatchesShowcase extends StatelessWidget {
  const TokenSwatchesShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Light-only (C0 Workstream B): dark panels removed.
        const _TokenPanel(strategy: AppColorStrategy.emeraldFill),
        SizedBox(height: context.spacing.md),
        const _TokenPanel(strategy: AppColorStrategy.deepGreenFill),
      ],
    );
  }
}

class _TokenPanel extends StatelessWidget {
  const _TokenPanel({required this.strategy});

  final AppColorStrategy strategy;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.build(colorStrategy: strategy);
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final colors = context.colors;
          final brand = context.brand;
          final semantic = <_SwatchItem>[
            _SwatchItem('surface', colors.surface),
            _SwatchItem('surfaceLowest', colors.surfaceContainerLowest),
            _SwatchItem('surfaceLow', colors.surfaceContainerLow),
            _SwatchItem('surfaceContainer', colors.surfaceContainer),
            _SwatchItem('surfaceHigh', colors.surfaceContainerHigh),
            _SwatchItem('surfaceHighest', colors.surfaceContainerHighest),
            _SwatchItem('onSurface', colors.onSurface),
            _SwatchItem('onSurfaceVariant', colors.onSurfaceVariant),
            _SwatchItem('outline', colors.outline),
            _SwatchItem('outlineVariant', colors.outlineVariant),
            _SwatchItem('secondary', colors.secondary),
            _SwatchItem('onSecondary', colors.onSecondary),
            _SwatchItem('secondaryContainer', colors.secondaryContainer),
            _SwatchItem('onSecondaryContainer', colors.onSecondaryContainer),
            _SwatchItem('error', colors.error),
            _SwatchItem('onError', colors.onError),
            _SwatchItem('errorContainer', colors.errorContainer),
            _SwatchItem('onErrorContainer', colors.onErrorContainer),
            _SwatchItem('focus', colors.focus),
            _SwatchItem('overlay', colors.overlay),
            _SwatchItem('scrim', colors.scrim),
            _SwatchItem('inverseSurface', colors.inverseSurface),
            _SwatchItem('onInverseSurface', colors.onInverseSurface),
          ];
          final brandColors = <_SwatchItem>[
            _SwatchItem('brand.fill', brand.fill, foreground: brand.onFill),
            _SwatchItem('brand.onFill', brand.onFill, foreground: brand.fill),
            _SwatchItem('brand.ink', brand.ink),
            _SwatchItem(
              'brand.container',
              brand.container,
              foreground: brand.onContainer,
            ),
            _SwatchItem(
              'brand.onContainer',
              brand.onContainer,
              foreground: brand.container,
            ),
          ];
          final tones = context.statusColors;
          final status = <_SwatchItem>[
            for (final tone in StatusTone.values)
              _SwatchItem(
                'status.${tone.name}',
                tones.forTone(tone).background,
                foreground: tones.forTone(tone).foreground,
              ),
          ];
          final severityPalette = context.severityColors;
          final severity = <_SwatchItem>[
            for (final value in AppSeverity.values)
              _SwatchItem(
                'severity.${value.name}',
                severityPalette.forSeverity(value).background,
                foreground: severityPalette.forSeverity(value).foreground,
              ),
          ];
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: context.spacing.sm,
                  runSpacing: context.spacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'light / ${strategy.name}',
                      style: context.texts.titleLarge,
                    ),
                    StatusChip(
                      label: colorHex(brand.fill),
                      tone: StatusTone.neutral,
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.md),
                _SwatchGroup(title: 'Semantic colours', colors: semantic),
                SizedBox(height: context.spacing.md),
                _SwatchGroup(title: 'Brand colours', colors: brandColors),
                SizedBox(height: context.spacing.md),
                _SwatchGroup(title: 'Status pairs', colors: status),
                SizedBox(height: context.spacing.md),
                _SwatchGroup(title: 'Severity pairs', colors: severity),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SwatchGroup extends StatelessWidget {
  const _SwatchGroup({required this.title, required this.colors});

  final String title;
  final List<_SwatchItem> colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.texts.labelLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: [
            for (final entry in colors)
              TokenSwatch(
                name: entry.name,
                color: entry.color,
                foreground: entry.foreground,
              ),
          ],
        ),
      ],
    );
  }
}

class _SwatchItem {
  const _SwatchItem(this.name, this.color, {this.foreground});

  final String name;
  final Color color;
  final Color? foreground;
}

class TypographyShowcase extends StatelessWidget {
  const TypographyShowcase({super.key});

  static const String _englishSample =
      'The quick brown fox inspects 13 vehicles.';
  static const String _arabicSample = 'الثعلب البني السريع يفحص ١٣ مركبة.';

  @override
  Widget build(BuildContext context) {
    final sample = context.isArabic ? _arabicSample : _englishSample;
    final entries = <_TypeEntry>[
      _TypeEntry('display', context.texts.displayLarge),
      _TypeEntry('headlineXl', context.texts.headlineLarge),
      _TypeEntry('headlineLg', context.texts.headlineMedium),
      _TypeEntry('headlineMd', context.texts.headlineSmall),
      _TypeEntry('titleLg', context.texts.titleLarge),
      _TypeEntry('bodyLg', context.texts.bodyLarge),
      _TypeEntry('bodyMd', context.texts.bodyMedium),
      _TypeEntry('bodySm', context.texts.bodySmall),
      _TypeEntry('labelLg', context.texts.labelLarge),
      _TypeEntry('labelMd', context.texts.labelMedium),
      _TypeEntry('labelSm', context.texts.labelSmall),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries) ...[
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(entry.name, style: context.texts.labelLarge),
              Text(
                typeSpec(entry.style),
                style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          Text(sample, style: entry.style),
          Divider(height: context.spacing.xl),
        ],
      ],
    );
  }
}

class _TypeEntry {
  const _TypeEntry(this.name, this.style);

  final String name;
  final TextStyle? style;
}

class LayoutTokensShowcase extends StatelessWidget {
  const LayoutTokensShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final spacingEntries = <_Metric>[
      _Metric('xxs', context.spacing.xxs),
      _Metric('xs', context.spacing.xs),
      _Metric('sm', context.spacing.sm),
      _Metric('md', context.spacing.md),
      _Metric('lg', context.spacing.lg),
      _Metric('gutter', context.spacing.gutter),
      _Metric('xl', context.spacing.xl),
      _Metric('xxl', context.spacing.xxl),
      _Metric('xxxl', context.spacing.xxxl),
      _Metric('huge', context.spacing.huge),
      _Metric('massive', context.spacing.massive),
    ];
    final radiiEntries = <_Metric>[
      _Metric('sm', context.radii.sm),
      _Metric('md', context.radii.md),
      _Metric('lg', context.radii.lg),
      _Metric('xl', context.radii.xl),
      _Metric('card', context.radii.card),
      _Metric('cardLarge', context.radii.cardLarge),
      _Metric('pill', context.radii.pill),
    ];
    final shadowEntries = <_ShadowEntry>[
      _ShadowEntry('card', context.shadows.card),
      _ShadowEntry('floating', context.shadows.floating),
      _ShadowEntry('button', context.shadows.button),
      _ShadowEntry('focus', [context.shadows.focus]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Spacing', style: context.texts.titleMedium),
        SizedBox(height: context.spacing.sm),
        for (final metric in spacingEntries) _SpacingRow(metric: metric),
        SizedBox(height: context.spacing.lg),
        Text('Radii', style: context.texts.titleMedium),
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.md,
          runSpacing: context.spacing.md,
          children: [
            for (final metric in radiiEntries) _RadiusTile(metric: metric),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        Text('Shadows', style: context.texts.titleMedium),
        SizedBox(height: context.spacing.sm),
        for (final entry in shadowEntries) _ShadowTile(entry: entry),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.name, this.value);

  final String name;
  final double value;
}

class _ShadowEntry {
  const _ShadowEntry(this.name, this.shadows);

  final String name;
  final List<BoxShadow> shadows;
}

class _SpacingRow extends StatelessWidget {
  const _SpacingRow({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: context.spacing.massive,
            child: Text(metric.name, style: context.texts.labelSmall),
          ),
          SizedBox(
            width: context.spacing.xxl,
            child: Text(
              metric.value.toStringAsFixed(0),
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: metric.value * 3,
            height: context.spacing.sm,
            decoration: BoxDecoration(
              color: context.brand.fill,
              borderRadius: BorderRadius.circular(context.radii.sm),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadiusTile extends StatelessWidget {
  const _RadiusTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: context.spacing.massive + context.spacing.xxl,
          height: context.spacing.huge,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(metric.value),
            border: Border.all(
              color: context.colors.outlineVariant,
              width: context.sizing.borderWidth,
            ),
          ),
        ),
        SizedBox(height: context.spacing.xxs),
        Text(
          '${metric.name} ${metric.value.toStringAsFixed(0)}',
          style: context.texts.labelSmall,
        ),
      ],
    );
  }
}

class _ShadowTile extends StatelessWidget {
  const _ShadowTile({required this.entry});

  final _ShadowEntry entry;

  @override
  Widget build(BuildContext context) {
    final spec = entry.shadows.map(shadowSpec).join('  |  ');
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(entry.name, style: context.texts.labelLarge),
          SizedBox(height: context.spacing.xxs),
          Text(
            spec.isEmpty ? 'none' : spec,
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Container(
            height: context.spacing.xxl,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(context.radii.lg),
              boxShadow: entry.shadows,
            ),
          ),
        ],
      ),
    );
  }
}

class ArabicFontComparison extends StatelessWidget {
  const ArabicFontComparison({super.key});

  @override
  Widget build(BuildContext context) {
    // Light-only (C0 Workstream B).
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        const noto = _ArabicFontPanel(
          font: AppArabicFont.notoSansArabic,
          name: 'Noto Sans Arabic',
        );
        const ibm = _ArabicFontPanel(
          font: AppArabicFont.ibmPlexSansArabic,
          name: 'IBM Plex Sans Arabic',
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: noto),
              SizedBox(width: context.spacing.lg),
              const Expanded(child: ibm),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            noto,
            SizedBox(height: context.spacing.lg),
            ibm,
          ],
        );
      },
    );
  }
}

class _ArabicFontPanel extends StatelessWidget {
  const _ArabicFontPanel({required this.font, required this.name});

  final AppArabicFont font;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.build(arabicFont: font, isArabic: true);
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: context.texts.labelLarge),
              SizedBox(height: context.spacing.sm),
              Text('الفحص الفني للمركبة', style: context.texts.headlineMedium),
              SizedBox(height: context.spacing.xs),
              Text(
                'تم فحص المركبة ولا توجد ملاحظات على نظام الفرامل.',
                style: context.texts.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
