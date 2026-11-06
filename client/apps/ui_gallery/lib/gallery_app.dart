import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:ui_gallery/fixture_guard.dart';
import 'package:ui_gallery/showcase_chrome.dart';
import 'package:ui_gallery/showcase_components.dart';
import 'package:ui_gallery/showcase_fidelity.dart';
import 'package:ui_gallery/showcase_selection.dart';
import 'package:ui_gallery/showcase_tokens.dart';
import 'package:ui_gallery/support/gallery_widgets.dart';

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  static const List<double> _widths = <double>[390, 600, 900, 1280];

  Locale _locale = const Locale('en');
  Brightness _brightness = Brightness.light;
  double _textScale = 1;
  AppColorStrategy _strategy = AppColorStrategy.emeraldFill;
  AppArabicFont _arabicFont = AppArabicFont.notoSansArabic;
  int _widthIndex = 0;

  @override
  void initState() {
    super.initState();
    final query = Uri.base.queryParameters;
    if (query['lang'] == 'ar') {
      _locale = const Locale('ar');
    }
    if (query['theme'] == 'dark') {
      _brightness = Brightness.dark;
    }
    final scale = double.tryParse(query['scale'] ?? '');
    if (scale == 1 || scale == 1.5 || scale == 2) {
      _textScale = scale!;
    }
    if (query['strategy'] == 'deepGreen') {
      _strategy = AppColorStrategy.deepGreenFill;
    }
    if (query['font'] == 'ibm') {
      _arabicFont = AppArabicFont.ibmPlexSansArabic;
    }
    final width = int.tryParse(query['width'] ?? '');
    if (width != null) {
      final index = _widths.indexOf(width.toDouble());
      if (index >= 0) {
        _widthIndex = index;
      }
    }
  }

  bool get _isArabic => _locale.languageCode == 'ar';

  ThemeData get _theme => AppTheme.build(
    brightness: _brightness,
    colorStrategy: _strategy,
    arabicFont: _arabicFont,
    isArabic: _isArabic,
  );

  void _selectLocale(bool arabic) {
    setState(() => _locale = Locale(arabic ? 'ar' : 'en'));
  }

  void _selectBrightness(Brightness brightness) {
    setState(() => _brightness = brightness);
  }

  void _selectTextScale(double scale) {
    setState(() => _textScale = scale);
  }

  void _selectStrategy(AppColorStrategy strategy) {
    setState(() => _strategy = strategy);
  }

  void _selectArabicFont(AppArabicFont font) {
    setState(() => _arabicFont = font);
  }

  void _selectWidth(int index) {
    setState(() => _widthIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrueReport UI Gallery',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      themeMode: ThemeMode.light,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        return Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(_textScale)),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: _GalleryBody(state: this),
    );
  }
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody({required this.state});

  final _GalleryAppState state;

  @override
  Widget build(BuildContext context) {
    final width = _GalleryAppState._widths[state._widthIndex];
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            ),
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.noScaling),
              child: SingleChildScrollView(
                child: _GalleryControls(state: state),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.all(context.spacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(context.radii.xl),
                      border: Border.all(
                        color: context.colors.outlineVariant,
                        width: context.sizing.borderWidth,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.all(context.spacing.lg),
                      child: _GallerySections(state: state),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryControls extends StatelessWidget {
  const _GalleryControls({required this.state});

  final _GalleryAppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return Container(
      width: double.infinity,
      color: context.colors.surfaceContainerLow,
      padding: EdgeInsetsDirectional.all(spacing.md),
      child: Column(
        spacing: spacing.md,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ControlGroup(
            label: 'Locale',
            children: [
              _Choice(
                label: l10n.languageEnglish,
                selected: !state._isArabic,
                onSelected: () => state._selectLocale(false),
              ),
              _Choice(
                label: l10n.languageArabic,
                selected: state._isArabic,
                onSelected: () => state._selectLocale(true),
              ),
            ],
          ),
          _ControlGroup(
            label: 'Theme',
            children: [
              _Choice(
                label: 'Light',
                selected: state._brightness == Brightness.light,
                onSelected: () => state._selectBrightness(Brightness.light),
              ),
              _Choice(
                label: 'Dark',
                selected: state._brightness == Brightness.dark,
                onSelected: () => state._selectBrightness(Brightness.dark),
              ),
            ],
          ),
          _ControlGroup(
            label: 'Text scale',
            children: [
              for (final scale in const <double>[1, 1.5, 2])
                _Choice(
                  label: '${scale}x',
                  selected: state._textScale == scale,
                  onSelected: () => state._selectTextScale(scale),
                ),
            ],
          ),
          _ControlGroup(
            label: 'A2 strategy',
            children: [
              _Choice(
                label: 'Emerald fill',
                selected: state._strategy == AppColorStrategy.emeraldFill,
                onSelected: () =>
                    state._selectStrategy(AppColorStrategy.emeraldFill),
              ),
              _Choice(
                label: 'Deep green fill',
                selected: state._strategy == AppColorStrategy.deepGreenFill,
                onSelected: () =>
                    state._selectStrategy(AppColorStrategy.deepGreenFill),
              ),
            ],
          ),
          _ControlGroup(
            label: 'Arabic font',
            children: [
              _Choice(
                label: 'Noto Sans Arabic',
                selected: state._arabicFont == AppArabicFont.notoSansArabic,
                onSelected: () =>
                    state._selectArabicFont(AppArabicFont.notoSansArabic),
              ),
              _Choice(
                label: 'IBM Plex Sans Arabic',
                selected: state._arabicFont == AppArabicFont.ibmPlexSansArabic,
                onSelected: () =>
                    state._selectArabicFont(AppArabicFont.ibmPlexSansArabic),
              ),
            ],
          ),
          _ControlGroup(
            label: 'Viewport width',
            children: [
              for (
                var index = 0;
                index < _GalleryAppState._widths.length;
                index++
              )
                _Choice(
                  label: _GalleryAppState._widths[index].toStringAsFixed(0),
                  selected: state._widthIndex == index,
                  onSelected: () => state._selectWidth(index),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.spacing.xxs),
        Wrap(spacing: context.spacing.xs, children: children),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _GallerySections extends StatelessWidget {
  const _GallerySections({required this.state});

  final _GalleryAppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.appTitle,
          style: context.texts.headlineLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'F1 token and component gallery',
          style: context.texts.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.spacing.xxl),
        GallerySection(
          title: 'A2 brand comparison',
          subtitle:
              'The same samples rendered with emeraldFill and deepGreenFill.',
          child: _A2Comparison(state: state),
        ),
        if (FixtureGuard.enabled) ...[
          const GallerySection(
            title: 'Figma-exact variants (test-only)',
            subtitle:
                'Figma node bounding boxes, Figma copy, measured by the harness.',
            child: FidelityShowcase(),
          ),
          const GallerySection(
            title: 'Primary button options (A2 re-opened)',
            subtitle:
                'Four options on the real Figma button in EN and AR at 1.0x and 2.0x.',
            child: PrimaryButtonOptionsShowcase(),
          ),
        ],
        const GallerySection(
          title: 'Token swatches',
          subtitle: 'Every semantic colour in light, dark, emeraldFill and deepGreenFill.',
          child: TokenSwatchesShowcase(),
        ),
        const GallerySection(
          title: 'Typography',
          subtitle: 'All type styles in the active locale and text scale.',
          child: TypographyShowcase(),
        ),
        const GallerySection(
          title: 'Arabic font candidates',
          subtitle: 'Noto Sans Arabic and IBM Plex Sans Arabic side by side.',
          child: ArabicFontComparison(),
        ),
        const GallerySection(
          title: 'Spacing, radii and shadows',
          subtitle: 'Values read from the active theme extensions.',
          child: LayoutTokensShowcase(),
        ),
        const GallerySection(title: 'Buttons', child: ButtonsShowcase()),
        const GallerySection(
          title: 'Icon buttons',
          child: IconButtonsShowcase(),
        ),
        const GallerySection(title: 'SVG icon set', child: SvgIconsShowcase()),
        const GallerySection(title: 'Cards', child: CardsShowcase()),
        const GallerySection(title: 'Inputs', child: InputsShowcase()),
        const GallerySection(
          title: 'Chips, status and severity',
          child: ChipsShowcase(),
        ),
        const GallerySection(
          title: 'Segmented control and language switch',
          child: SegmentedShowcase(),
        ),
        const GallerySection(
          title: 'Inspection result selector',
          subtitle: 'All six results, selected and unselected.',
          child: ResultSelectorShowcase(),
        ),
        const GallerySection(
          title: 'Progress and coverage',
          child: ProgressShowcase(),
        ),
        const GallerySection(
          title: 'Navigation',
          subtitle: 'Bottom dock.',
          child: NavigationShowcase(),
        ),
        if (FixtureGuard.enabled)
          const GallerySection(
            title: 'Technician dock decision (P7)',
            subtitle:
                'Product 3-item dock and the Figma 4-item layout, shown for owner review only.',
            child: TechnicianDockComparison(),
          ),
        const GallerySection(
          title: 'Admin chrome',
          subtitle: 'Sidebar, top bar and AdminShell.',
          child: AdminChromeShowcase(),
        ),
        const GallerySection(title: 'States', child: StatesShowcase()),
        const GallerySection(
          title: 'Overlays',
          subtitle: 'Dialog and bottom sheet triggered by buttons.',
          child: OverlaysShowcase(),
        ),
        const GallerySection(title: 'Data table', child: DataTableShowcase()),
        const GallerySection(title: 'Tree view', child: TreeViewShowcase()),
      ],
    );
  }
}

class _A2Comparison extends StatelessWidget {
  const _A2Comparison({required this.state});

  final _GalleryAppState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final emerald = _StrategyPanel(
          state: state,
          strategy: AppColorStrategy.emeraldFill,
        );
        final deepGreen = _StrategyPanel(
          state: state,
          strategy: AppColorStrategy.deepGreenFill,
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: emerald),
              SizedBox(width: context.spacing.lg),
              Expanded(child: deepGreen),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            emerald,
            SizedBox(height: context.spacing.lg),
            deepGreen,
          ],
        );
      },
    );
  }
}

class _StrategyPanel extends StatelessWidget {
  const _StrategyPanel({required this.state, required this.strategy});

  final _GalleryAppState state;
  final AppColorStrategy strategy;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.build(
      brightness: state._brightness,
      colorStrategy: strategy,
      arabicFont: state._arabicFont,
      isArabic: state._isArabic,
    );
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final brand = context.brand;
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(strategy.name, style: context.texts.titleLarge),
                SizedBox(height: context.spacing.sm),
                Wrap(
                  spacing: context.spacing.sm,
                  runSpacing: context.spacing.sm,
                  children: [
                    TokenSwatch(
                      name: 'brand.fill',
                      color: brand.fill,
                      foreground: brand.onFill,
                    ),
                    TokenSwatch(name: 'brand.ink', color: brand.ink),
                    TokenSwatch(
                      name: 'brand.container',
                      color: brand.container,
                      foreground: brand.onContainer,
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.md),
                Wrap(
                  spacing: context.spacing.sm,
                  runSpacing: context.spacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppButton(label: 'Primary action', onPressed: () {}),
                    AppButton(
                      label: 'Tonal action',
                      onPressed: () {},
                      variant: AppButtonVariant.tonal,
                    ),
                    const StatusChip(
                      label: 'Success',
                      tone: StatusTone.success,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

