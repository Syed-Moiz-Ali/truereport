import 'dart:ui' as ui;

import 'package:design_system/src/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Exact values transcribed from the technician Figma nodes for F2-A.1.
///
/// These are deliberately Figma-exact, not the accessible product token scale.
/// The owner requirement for F2-A.1 is a 100% identical render; accessibility is
/// added invisibly (semantic labels and hit areas) rather than by restyling.
abstract final class Fx {
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A1B1F);
  static const inkStrong = Color(0xFF1B1B25);
  static const muted = Color(0xFF5E5D69);
  static const outline = Color(0xFF6C7A71);
  static const secondaryInk = Color(0xFF3C4A42);
  static const darkInk = Color(0xFF00422B);
  static const container = Color(0xFFF4F3F8);
  static const container99 = Color(0x99F4F3F8);
  static const surfaceHigh = Color(0xFFEEEDF3);
  static const surfaceHighest = Color(0xFFE9E7ED);
  static const divider = Color(0xFFEEEDF3);
  static const emerald = Color(0xFF10B981);
  static const emeraldPressed = Color(0xFF059669);
  static const deepGreen = Color(0xFF006C49);
  static const selectedTint = Color(0xFF6FFBBE);
  static const warningRed = Color(0xFFFF7A73);
  static const dangerRed = Color(0xFFB91A24);
  static const sage = Color(0xFFBBCABF);
  static const error = Color(0xFFA3231F);
  static const glow = Color(0x4D6FFBBE);
  static const pillRadius = 999.0;
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceLow, surfaceHighest],
  );
  static const heroOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [transparent, black66],
  );
  static const baseline = Color(0xFFE3E1EF);
  static const tintEmerald = Color(0x1A10B981);
  static const tintMint = Color(0x4D6FFBBE);
  static const tintLilac = Color(0x66E1DEEC);
  static const iconGrey = Color(0xFF62616D);
  static const barStrong = Color(0x665E5D69);
  static const barMedium = Color(0x4D5E5D69);
  static const barWeak = Color(0x335E5D69);
  static const mint33 = Color(0x336FFBBE);
  static const whiteE5 = Color(0xE5FFFFFF);
  static const whiteCC = Color(0xCCFFFFFF);
  static const white90 = Color(0xE6FFFFFF);
  static const black66 = Color(0x66000000);
  static const transparent = Color(0x00000000);
  static const surfaceLow = Color(0xFFF7F6FB);

  static const String fontFamily = TrFonts.latin;
  static const List<String> fontFallback = <String>[
    TrFonts.arabicDefault,
    TrFonts.arabicAlternative,
    TrFonts.cyrillicFallback,
    TrFonts.cjkFallback,
  ];

  static TextStyle text(
    double size,
    double lineHeight,
    FontWeight weight,
    double tracking, {
    Color color = ink,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: tracking,
      color: color,
    );
  }

  static TextStyle get caption =>
      text(11, 14, FontWeight.w600, 0.44, color: muted);
  static TextStyle get captionWide => text(11, 14, FontWeight.w700, 0.55);
  static TextStyle get captionMedium =>
      text(11, 14, FontWeight.w500, 0.44, color: muted);
  static TextStyle get body13 => text(13, 18, FontWeight.w400, 0);
  static TextStyle get body13Medium => text(13, 18, FontWeight.w500, 0);
  static TextStyle get label12 => text(12, 16, FontWeight.w600, 0.24);
  static TextStyle get label12Wide => text(12, 16, FontWeight.w600, 0.3);
  static TextStyle get label12Bold => text(12, 16, FontWeight.w700, 0.24);
  static TextStyle get label14 => text(14, 18, FontWeight.w700, -0.14);
  static TextStyle get body14 => text(14, 20, FontWeight.w500, -0.07);
  static TextStyle get title16 => text(16, 22, FontWeight.w700, -0.16);
  static TextStyle get title16W600 => text(16, 24, FontWeight.w600, -0.16);
  static TextStyle get heading18 => text(18, 24, FontWeight.w700, -0.27);
  static TextStyle get heading22 => text(22, 28, FontWeight.w700, -0.55);
  static TextStyle get display26 => text(26, 32, FontWeight.w800, -0.65);
  static TextStyle get display22 => text(22, 30.25, FontWeight.w800, -0.55);
  static TextStyle get display18 => text(18, 24, FontWeight.w800, -0.27);
  static TextStyle get display16 => text(16, 20, FontWeight.w800, -0.16);
  static TextStyle get stat16 => text(16, 22, FontWeight.w700, -0.16);
  static TextStyle get welcome16 => text(16, 24, FontWeight.w500, -0.4);

  static const cardRadius = 32.0;
  static const fieldRadius = 16.0;
  static const tileRadius = 16.0;

  static const cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0B000000), blurRadius: 40, offset: Offset(0, 14)),
  ];

  static const smallShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const ctaShadow = <BoxShadow>[
    BoxShadow(color: Color(0x4D10B981), blurRadius: 25, offset: Offset(0, 10)),
  ];

  static const pillShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const switchThumbShadow = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const softShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const panelShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D000000), blurRadius: 32, offset: Offset(0, 12)),
  ];

  static const navShadow = <BoxShadow>[
    BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 50, offset: Offset(0, 18)),
  ];

  static const headerShadow = <BoxShadow>[
    BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 1)),
  ];

  static const upShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, -10)),
  ];
}

/// Test-only synchronous cache for the exported SVGs. Widget tests run under
/// fake async, where rootBundle image loading does not complete; the capture
/// and golden setup registers the files from disk so the harness renders them.
abstract final class FxSvgCache {
  static final Map<String, String> _cache = <String, String>{};

  static void register(String id, String svg) {
    _cache[id] = svg;
  }

  static String? get(String id) => _cache[id];
}

/// Renders the exported Figma SVG for a node id. Falls back to [fallback] only
/// when the export did not include that vector, so no shape is invented.
class FxIcon extends StatelessWidget {
  const FxIcon({
    required this.id,
    required this.size,
    this.color,
    this.fallback,
    super.key,
  });

  final String id;
  final double size;
  final Color? color;
  final IconData? fallback;

  @override
  Widget build(BuildContext context) {
    final cached = FxSvgCache.get(id);
    final icon = cached != null
        ? SvgPicture.string(
            cached,
            width: size,
            height: size,
            fit: BoxFit.contain,
            colorFilter: color == null
                ? null
                : ColorFilter.mode(color!, BlendMode.srcIn),
          )
        : SvgPicture.asset(
            'assets/icons/figma/Icon-$id.svg',
            package: 'design_system',
            width: size,
            height: size,
            fit: BoxFit.contain,
            colorFilter: color == null
                ? null
                : ColorFilter.mode(color!, BlendMode.srcIn),
            placeholderBuilder: (_) => fallback == null
                ? SizedBox.square(dimension: size)
                : Icon(fallback, size: size, color: color),
          );
    return SizedBox.square(dimension: size, child: icon);
  }
}

class FxCard extends StatelessWidget {
  const FxCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = Fx.cardRadius,
    this.color = Fx.white,
    this.shadows = Fx.cardShadow,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final List<BoxShadow> shadows;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
      ),
      child: child,
    );
    if (onTap == null) {
      return semanticLabel == null
          ? card
          : Semantics(label: semanticLabel, child: card);
    }
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: card,
        ),
      ),
    );
  }
}

enum FxButtonTone { primary, tonal, text, white }

class FxButton extends StatelessWidget {
  const FxButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = FxButtonTone.primary,
    this.expand = true,
    this.height = 56,
    this.trailingIcon = true,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final FxButtonTone tone;
  final bool expand;
  final double height;
  final bool trailingIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, shadows, border) = switch (tone) {
      FxButtonTone.primary => (Fx.emerald, Fx.white, Fx.ctaShadow, null),
      FxButtonTone.tonal => (Fx.container, Fx.ink, Fx.pillShadow, null),
      FxButtonTone.white => (Fx.white, Fx.ink, Fx.pillShadow, null),
      FxButtonTone.text => (
        Colors.transparent,
        Fx.ink,
        const <BoxShadow>[],
        null,
      ),
    };
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !trailingIcon) ...[icon!, const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Fx.label14.copyWith(color: foreground),
          ),
        ),
        if (icon != null && trailingIcon) ...[const SizedBox(width: 8), icon!],
      ],
    );
    final button = Container(
      height: height,
      width: expand ? double.infinity : null,
      padding: tone == FxButtonTone.text
          ? const EdgeInsets.symmetric(horizontal: 12)
          : null,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        boxShadow: shadows,
        border: border == null ? null : Border.all(color: border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Center(child: content),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel ?? label,
      child: button,
    );
  }
}

/// White shadowed field card with the icon and placeholder inside, exactly as
/// drawn. The visible label is not drawn; [semanticLabel] supplies the name to
/// assistive technology and the whole 48 px card is the hit area.
class FxField extends StatelessWidget {
  const FxField({
    required this.controller,
    required this.semanticLabel,
    required this.iconId,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
    this.focusNode,
    this.autofillHints,
    this.inputFormatters,
    this.height = 48,
    this.ltr = false,
    this.fieldKey,
    super.key,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final String iconId;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final double height;
  final bool ltr;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      textField: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Fx.white,
          borderRadius: BorderRadius.circular(Fx.fieldRadius),
          boxShadow: Fx.pillShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            FxIcon(id: iconId, size: 17, color: Fx.outline),
            const SizedBox(width: 12),
            Expanded(
              child: ExcludeSemantics(
                child: TextField(
                  key: fieldKey,
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  autofillHints: autofillHints,
                  inputFormatters: inputFormatters,
                  textDirection: ltr ? TextDirection.ltr : null,
                  style: Fx.body14.copyWith(color: Fx.ink),
                  cursorColor: Fx.emerald,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: Fx.body14.copyWith(color: Fx.outline),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            if (suffix != null) ...[const SizedBox(width: 8), suffix!],
          ],
        ),
      ),
    );
  }
}

/// Form-aware version of [FxField] that keeps Flutter validation working while
/// drawing the exact Figma field card.
class FxTextField extends StatelessWidget {
  const FxTextField({
    required this.controller,
    required this.semanticLabel,
    required this.iconId,
    required this.hint,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffix,
    this.focusNode,
    this.autofillHints,
    this.inputFormatters,
    this.height = 48,
    this.ltr = false,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final String iconId;
  final String hint;
  final FormFieldValidator<String>? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final double height;
  final bool ltr;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      textField: true,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        decoration: BoxDecoration(
          color: Fx.white,
          borderRadius: BorderRadius.circular(Fx.fieldRadius),
          boxShadow: Fx.pillShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FxIcon(id: iconId, size: 17, color: Fx.outline),
            const SizedBox(width: 12),
            Expanded(
              child: ExcludeSemantics(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onFieldSubmitted: onFieldSubmitted,
                  autofillHints: autofillHints,
                  inputFormatters: inputFormatters,
                  validator: validator,

                  textDirection: ltr ? TextDirection.ltr : null,
                  style: Fx.body14.copyWith(color: Fx.ink),
                  cursorColor: Fx.emerald,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorStyle: Fx.caption.copyWith(
                      color: const Color(0xFFA3231F),
                    ),
                    hintText: hint,
                    hintStyle: Fx.body14.copyWith(color: Fx.outline),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: false,
                  ),
                ),
              ),
            ),
            if (suffix != null) ...[const SizedBox(width: 8), suffix!],
          ],
        ),
      ),
    );
  }
}

class FxLanguageSwitch extends StatelessWidget {
  const FxLanguageSwitch({
    required this.isArabic,
    required this.onChanged,
    this.englishLabel = 'English',
    this.arabicLabel = 'عربي',
    this.englishKey,
    this.arabicKey,
    this.switchKey,
    super.key,
  });

  final bool isArabic;
  final ValueChanged<bool> onChanged;
  final String englishLabel;
  final String arabicLabel;
  final Key? englishKey;
  final Key? arabicKey;
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: switchKey,
      height: 32,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(999),
        boxShadow: Fx.pillShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
            key: englishKey,
            label: englishLabel,
            selected: !isArabic,
            width: 70.84,
            onTap: () => onChanged(false),
            semanticLabel: 'English',
          ),
          _segment(
            key: arabicKey,
            label: arabicLabel,
            selected: isArabic,
            width: 49.58,
            onTap: () => onChanged(true),
            semanticLabel: 'العربية',
          ),
        ],
      ),
    );
  }

  Widget _segment({
    Key? key,
    required String label,
    required bool selected,
    required double width,
    required VoidCallback onTap,
    required String semanticLabel,
  }) {
    return Semantics(
      key: key,
      button: true,
      selected: selected,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: width,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Fx.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected ? Fx.pillShadow : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Fx.label12.copyWith(color: selected ? Fx.ink : Fx.muted),
          ),
        ),
      ),
    );
  }
}

class FxHeader extends StatelessWidget implements PreferredSizeWidget {
  const FxHeader({
    required this.title,
    this.showBack = false,
    this.actions = const <Widget>[],
    this.leading,
    this.titleStyle,
    this.horizontalPadding = 16,
    this.titleInset = 0,
    this.headerKey,
    super.key,
  });

  final String title;
  final bool showBack;
  final List<Widget> actions;
  final Widget? leading;
  final TextStyle? titleStyle;
  final double horizontalPadding;
  final double titleInset;
  final Key? headerKey;

  static const double height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: headerKey,
      height: height,
      decoration: const BoxDecoration(
        color: Fx.whiteCC,
        boxShadow: Fx.headerShadow,
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                if (showBack || leading != null) ...[
                  leading ??
                      Semantics(
                        button: true,
                        label: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        child: InkResponse(
                          onTap: () => Navigator.of(context).maybePop(),
                          radius: 24,
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: 20,
                                color: Fx.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: titleInset),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (titleStyle ?? Fx.heading18).copyWith(
                          color: Fx.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FxProfileButton extends StatelessWidget {
  const FxProfileButton({
    required this.initials,
    required this.onPressed,
    this.size = 32,
    this.image,
    this.iconId,
    this.semanticLabel,
    super.key,
  });

  final String initials;
  final VoidCallback? onPressed;
  final double size;
  final ui.Image? image;
  final String? iconId;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? 'Profile',
      child: InkResponse(
        onTap: onPressed,
        radius: size,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Fx.deepGreen,
            shape: BoxShape.circle,
          ),
          child: image != null
              ? ClipOval(
                  child: RawImage(image: image, fit: BoxFit.cover),
                )
              : iconId != null
              ? FxIcon(id: iconId!, size: 12, color: Fx.white)
              : Text(
                  initials,
                  textDirection: TextDirection.ltr,
                  style: Fx.label12.copyWith(
                    color: Fx.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class FxAvatar extends StatelessWidget {
  const FxAvatar({
    required this.initials,
    this.size = 44,
    this.textStyle,
    this.glow = false,
    this.glowInset = 12,
    this.image,
    this.semanticLabel,
    super.key,
  });

  final String initials;
  final double size;
  final TextStyle? textStyle;
  final bool glow;
  final double glowInset;
  final ui.Image? image;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Fx.emerald,
        shape: BoxShape.circle,
      ),
      child: image == null
          ? Text(
              initials,
              textDirection: TextDirection.ltr,
              style: (textStyle ?? Fx.label14).copyWith(color: Fx.white),
            )
          : ClipOval(
              child: RawImage(image: image, fit: BoxFit.cover),
            ),
    );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: glow
            ? Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Fx.emerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2610B981),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: size - glowInset,
                    height: size - glowInset,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Fx.emerald,
                      shape: BoxShape.circle,
                    ),
                    child: image == null
                        ? Text(
                            initials,
                            textDirection: TextDirection.ltr,
                            style: (textStyle ?? Fx.label14).copyWith(
                              color: Fx.white,
                            ),
                          )
                        : ClipOval(
                            child: RawImage(image: image, fit: BoxFit.cover),
                          ),
                  ),
                ),
              )
            : circle,
      ),
    );
  }
}

class FxDockItem {
  const FxDockItem({
    required this.label,
    required this.iconId,
    required this.semanticLabel,
  });

  final String label;
  final String iconId;
  final String semanticLabel;
}

class FxDock extends StatelessWidget {
  const FxDock({
    required this.items,
    required this.selectedIndex,
    this.onSelected,
    this.slotWidth = 44,
    this.gap = 39.5,
    this.dockKey,
    super.key,
  });

  final List<FxDockItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final double slotWidth;
  final double gap;
  final Key? dockKey;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(SizedBox(width: gap));
      }
      final selected = i == selectedIndex;
      children.add(
        Semantics(
          button: true,
          selected: selected,
          label: items[i].semanticLabel,
          child: InkResponse(
            onTap: onSelected == null ? null : () => onSelected!(i),
            radius: slotWidth / 2,
            child: SizedBox(
              width: slotWidth,
              height: 44,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FxIcon(
                      id: items[i].iconId,
                      size: 20,
                      color: selected ? Fx.ink : Fx.muted,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Fx.caption.copyWith(
                        color: selected ? Fx.ink : Fx.muted,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        key: dockKey ?? const Key('f2a1-dock-container'),
        height: 64,
        decoration: BoxDecoration(
          color: Fx.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(999),
          boxShadow: Fx.navShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small label pill with exact Figma type and fill.
class FxPill extends StatelessWidget {
  const FxPill({
    required this.label,
    this.background = Fx.container,
    this.foreground = Fx.ink,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    this.height = 18,
    this.style,
    this.leading,
    this.gap = 6,
    super.key,
  });

  final String label;
  final Color background;
  final Color foreground;
  final EdgeInsetsGeometry padding;
  final double height;
  final TextStyle? style;
  final Widget? leading;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: gap)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (style ?? Fx.caption).copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class FxDot extends StatelessWidget {
  const FxDot({this.size = 8, this.color = Fx.emerald, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Exact coverage ring from the Figma hub: 176 px, 13.2 px stroke.
class FxCoverageRing extends StatelessWidget {
  const FxCoverageRing({
    required this.done,
    required this.total,
    this.size = 176,
    this.strokeWidth = 13.2,
    this.semanticLabel,
    this.label,
    super.key,
  });

  final int done;
  final int total;
  final double size;
  final double strokeWidth;
  final String? semanticLabel;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: '$done / $total',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              child: CustomPaint(
                size: Size.square(size),
                painter: _FxRingPainter(
                  fraction: fraction,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$done',
                      textDirection: TextDirection.ltr,
                      style: Fx.display26.copyWith(color: Fx.ink, height: 1),
                    ),
                    Text(
                      '/$total',
                      textDirection: TextDirection.ltr,
                      style: Fx.body14.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
                if (label != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: Fx.text(
                      11,
                      14,
                      FontWeight.w700,
                      0.55,
                      color: Fx.muted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FxRingPainter extends CustomPainter {
  const _FxRingPainter({required this.fraction, required this.strokeWidth});

  final double fraction;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track = Paint()
      ..color = Fx.surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final arc = Paint()
      ..color = Fx.emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963267948966,
      6.283185307179586 * fraction,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _FxRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Small round icon tile used across the Figma screens (40 or 48 circle).
class FxIconTile extends StatelessWidget {
  const FxIconTile({
    required this.iconId,
    this.size = 40,
    this.iconSize = 18,
    this.background = Fx.container,
    this.color = Fx.ink,
    this.circle = true,
    this.radius = 12,
    super.key,
  });

  final String iconId;
  final double size;
  final double iconSize;
  final Color background;
  final Color color;
  final bool circle;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
      child: FxIcon(id: iconId, size: iconSize, color: color),
    );
  }
}

class FxSectionLabel extends StatelessWidget {
  const FxSectionLabel({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Fx.label14.copyWith(color: Fx.muted, letterSpacing: 0.7),
    );
  }
}

String fxInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  String firstLetter(String value) {
    final runes = value.runes;
    return runes.isEmpty ? '' : String.fromCharCode(runes.first);
  }

  final first = firstLetter(parts.first);
  final last = parts.length == 1 ? '' : firstLetter(parts.last);
  return (first + last).toUpperCase();
}
