import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

String colorHex(Color color) {
  final value = color.toARGB32();
  return '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

String shadowSpec(BoxShadow shadow) {
  final dx = shadow.offset.dx.toStringAsFixed(0);
  final dy = shadow.offset.dy.toStringAsFixed(0);
  final blur = shadow.blurRadius.toStringAsFixed(0);
  final spread = shadow.spreadRadius.toStringAsFixed(0);
  return '$dx $dy $blur $spread ${colorHex(shadow.color)}';
}

String typeSpec(TextStyle? style) {
  final size = style?.fontSize;
  final height = style?.height;
  final weight = style?.fontWeight?.value;
  final tracking = style?.letterSpacing;
  final sizeText = size == null ? '?' : size.toStringAsFixed(0);
  final heightText = height == null ? '?' : height.toStringAsFixed(2);
  final weightText = weight == null ? '?' : weight.toStringAsFixed(0);
  final trackingText = tracking == null ? '?' : tracking.toStringAsFixed(1);
  return '$sizeText/$heightText  w$weightText  ls $trackingText';
}

class GallerySection extends StatelessWidget {
  const GallerySection({
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          SizedBox(height: context.spacing.md),
          child,
        ],
      ),
    );
  }
}

class GalleryTile extends StatelessWidget {
  const GalleryTile({
    required this.label,
    required this.child,
    this.width,
    super.key,
  });

  final String label;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          child,
        ],
      ),
    );
  }
}

class TokenSwatch extends StatelessWidget {
  const TokenSwatch({
    required this.name,
    required this.color,
    this.foreground,
    super.key,
  });

  final String name;
  final Color color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final swatchWidth = context.spacing.massive + context.spacing.sm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: swatchWidth,
          height: context.spacing.huge,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(context.radii.md),
            border: Border.all(
              color: context.colors.outlineVariant,
              width: context.sizing.borderWidth,
            ),
          ),
          child: foreground == null
              ? null
              : Text(
                  'Aa',
                  style: context.texts.labelLarge?.copyWith(color: foreground),
                ),
        ),
        SizedBox(height: context.spacing.xxs),
        SizedBox(
          width: swatchWidth,
          child: Text(name, style: context.texts.labelSmall),
        ),
        Text(
          colorHex(color),
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
