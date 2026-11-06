import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

List<TextStyle?> _allTextStyles(TextTheme theme) => <TextStyle?>[
  theme.displayLarge,
  theme.displayMedium,
  theme.displaySmall,
  theme.headlineLarge,
  theme.headlineMedium,
  theme.headlineSmall,
  theme.titleLarge,
  theme.titleMedium,
  theme.titleSmall,
  theme.bodyLarge,
  theme.bodyMedium,
  theme.bodySmall,
  theme.labelLarge,
  theme.labelMedium,
  theme.labelSmall,
];

void main() {
  group('theme extensions', () {
    for (final strategy in AppColorStrategy.values) {
      for (final brightness in Brightness.values) {
        for (final arabicFont in AppArabicFont.values) {
          for (final isArabic in const <bool>[false, true]) {
            final name =
                '${strategy.name} ${brightness.name} '
                '${arabicFont.name} arabic=$isArabic';
            test('$name exposes every theme extension', () {
              final theme = AppTheme.build(
                brightness: brightness,
                colorStrategy: strategy,
                arabicFont: arabicFont,
                isArabic: isArabic,
              );

              expect(theme.brightness, brightness);
              expect(theme.extension<AppSpacingTokens>(), isNotNull);
              expect(theme.extension<AppRadiiTokens>(), isNotNull);
              expect(theme.extension<AppShadowTokens>(), isNotNull);
              expect(theme.extension<AppSizingTokens>(), isNotNull);
              expect(theme.extension<AppMotionTokens>(), isNotNull);
              expect(theme.extension<AppStatusColors>(), isNotNull);
              expect(theme.extension<AppSeverityColors>(), isNotNull);
              final brand = theme.extension<AppBrandColors>();
              expect(brand, isNotNull);
              expect(brand!.strategy, strategy);
            });
          }
        }
      }
    }

    test('light, dark and deep-green helpers expose the same extensions', () {
      for (final theme in <ThemeData>[
        AppTheme.light,
        AppTheme.dark,
        AppTheme.lightDeepGreen,
        AppTheme.darkDeepGreen,
      ]) {
        expect(theme.extension<AppSpacingTokens>(), isNotNull);
        expect(theme.extension<AppRadiiTokens>(), isNotNull);
        expect(theme.extension<AppShadowTokens>(), isNotNull);
        expect(theme.extension<AppSizingTokens>(), isNotNull);
        expect(theme.extension<AppMotionTokens>(), isNotNull);
        expect(theme.extension<AppStatusColors>(), isNotNull);
        expect(theme.extension<AppSeverityColors>(), isNotNull);
        expect(theme.extension<AppBrandColors>(), isNotNull);
      }
    });
  });

  group('spacing, radii and sizing', () {
    test('spacing tokens match the F1 contract', () {
      final spacing = AppTheme.light.extension<AppSpacingTokens>()!;
      expect(spacing.xxs, 2);
      expect(spacing.xs, 4);
      expect(spacing.micro, 6);
      expect(spacing.sm, 8);
      expect(spacing.md, 12);
      expect(spacing.lg, 16);
      expect(spacing.gutter, 20);
      expect(spacing.xl, 24);
      expect(spacing.xxl, 32);
      expect(spacing.xxxl, 40);
      expect(spacing.huge, 48);
      expect(spacing.massive, 64);
    });

    test('radii tokens match the F1 contract', () {
      final radii = AppTheme.light.extension<AppRadiiTokens>()!;
      expect(radii.sm, 4);
      expect(radii.md, 8);
      expect(radii.lg, 12);
      expect(radii.xl, 16);
      expect(radii.card, 24);
      expect(radii.cardLarge, 32);
      expect(radii.sheet, 48);
      expect(radii.pill, 999);
    });

    test('sizing tokens match the F1 contract', () {
      final sizing = AppTheme.light.extension<AppSizingTokens>()!;
      expect(sizing.targetMin, 48);
      expect(sizing.buttonHeight, 56);
      expect(sizing.technicianPrimaryHeight, 56);
      expect(sizing.inputHeight, 56);
      expect(sizing.navDockHeight, 64);
      expect(sizing.cardPadding, 24);
      expect(sizing.iconSm, 16);
      expect(sizing.iconMd, 20);
      expect(sizing.iconLg, 24);
      expect(sizing.iconXl, 32);
      expect(sizing.focusRingWidth, 2);
      expect(sizing.focusRingOffset, 2);
      expect(sizing.borderWidth, 1.5);
      expect(sizing.dividerWidth, 1);
      expect(sizing.maxContentWidth, 1280);
    });

    test('motion tokens match the F1 contract', () {
      final motion = AppTheme.light.extension<AppMotionTokens>()!;
      expect(motion.fast, const Duration(milliseconds: 120));
      expect(motion.normal, const Duration(milliseconds: 220));
      expect(motion.slow, const Duration(milliseconds: 320));
      expect(motion.pressScale, 0.98);
      expect(motion.enterCurve, Curves.easeOutCubic);
      expect(motion.exitCurve, Curves.easeInCubic);
    });
  });

  group('typography', () {
    test('no text style is below 12 px and body sizes are 14/16', () {
      for (final theme in <ThemeData>[
        AppTheme.light,
        AppTheme.dark,
        AppTheme.build(isArabic: true),
        AppTheme.build(brightness: Brightness.dark, isArabic: true),
      ]) {
        for (final style in _allTextStyles(theme.textTheme)) {
          expect(style, isNotNull);
          expect(style!.fontSize, greaterThanOrEqualTo(12));
        }
        expect(theme.textTheme.bodyMedium!.fontSize, 14);
        expect(theme.textTheme.bodyLarge!.fontSize, 16);
        expect(theme.textTheme.labelMedium!.fontSize, 12);
        expect(theme.textTheme.labelSmall!.fontSize, 12);
      }
    });

    test('Arabic type scale uses zero tracking and 1.55 body height', () {
      final theme = AppTheme.build(isArabic: true);
      for (final style in _allTextStyles(theme.textTheme)) {
        expect(style!.letterSpacing, 0);
      }
      for (final style in <TextStyle>[
        theme.textTheme.bodyLarge!,
        theme.textTheme.bodyMedium!,
        theme.textTheme.bodySmall!,
      ]) {
        expect(style.height, closeTo(1.55, 0.001));
      }
    });

    test('Arabic font choice is reflected in the fallback stack', () {
      for (final font in AppArabicFont.values) {
        final theme = AppTheme.build(arabicFont: font);
        final expected = font == AppArabicFont.notoSansArabic
            ? TrFonts.arabicDefault
            : TrFonts.arabicAlternative;
        final fallback = theme.textTheme.bodyLarge!.fontFamilyFallback;
        expect(fallback, contains(expected));
      }
    });
  });

  group('WCAG contrast from actual colour values', () {
    test('A2 default brand.onFill on brand.fill passes 4.5:1', () {
      final brand = AppTheme.build().extension<AppBrandColors>()!;
      expect(
        _contrastRatio(brand.onFill, brand.fill),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('A2 alternative white on #006C49 passes 4.5:1', () {
      final brand = AppTheme.build(
        colorStrategy: AppColorStrategy.deepGreenFill,
      ).extension<AppBrandColors>()!;
      expect(
        _contrastRatio(brand.onFill, brand.fill),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF006C49)),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('every brand onFill/fill pair passes 4.5:1', () {
      for (final strategy in AppColorStrategy.values) {
        for (final brightness in Brightness.values) {
          final brand = AppTheme.build(
            brightness: brightness,
            colorStrategy: strategy,
          ).extension<AppBrandColors>()!;
          expect(
            _contrastRatio(brand.onFill, brand.fill),
            greaterThanOrEqualTo(4.5),
            reason: '${strategy.name} ${brightness.name}',
          );
        }
      }
    });

    test('#10B981 on white is below 4.5:1 and must not be text', () {
      expect(
        _contrastRatio(const Color(0xFF10B981), const Color(0xFFFFFFFF)),
        lessThan(4.5),
      );
    });

    test('every status foreground/background pair passes 4.5:1', () {
      for (final brightness in Brightness.values) {
        final status = AppTheme.build(brightness: brightness)
            .extension<AppStatusColors>()!;
        for (final tone in StatusTone.values) {
          final pair = status.forTone(tone);
          expect(
            _contrastRatio(pair.foreground, pair.background),
            greaterThanOrEqualTo(4.5),
            reason: '${brightness.name} ${tone.name}',
          );
        }
      }
    });

    test('every severity foreground/background pair passes 4.5:1', () {
      for (final brightness in Brightness.values) {
        final severity = AppTheme.build(brightness: brightness)
            .extension<AppSeverityColors>()!;
        for (final level in AppSeverity.values) {
          final pair = severity.forSeverity(level);
          expect(
            _contrastRatio(pair.foreground, pair.background),
            greaterThanOrEqualTo(4.5),
            reason: '${brightness.name} ${level.name}',
          );
        }
      }
    });

    test('focus ring is at least 3:1 against the surface', () {
      for (final brightness in Brightness.values) {
        final theme = AppTheme.build(brightness: brightness);
        final shadows = theme.extension<AppShadowTokens>()!;
        expect(
          _contrastRatio(theme.colorScheme.focus, theme.colorScheme.surface),
          greaterThanOrEqualTo(3),
          reason: '${brightness.name} focus colour',
        );
        expect(
          _contrastRatio(shadows.focus.color, theme.colorScheme.surface),
          greaterThanOrEqualTo(3),
          reason: '${brightness.name} focus ring shadow',
        );
      }
    });
  });
}
