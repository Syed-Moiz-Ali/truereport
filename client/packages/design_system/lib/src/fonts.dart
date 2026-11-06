/// Font families registered by this package's `pubspec.yaml`.
///
/// Flutter registers fonts declared by a package under the
/// `packages/<package>/` family prefix, so Flutter styles must reference the
/// prefixed names. The unprefixed token names in [TrFontFamilies] remain the
/// source of truth for non-Flutter outputs such as the generated CSS.
abstract final class TrFonts {
  static const String _prefix = 'packages/design_system/';

  static const String latin = '${_prefix}Plus Jakarta Sans';
  static const String arabicDefault = '${_prefix}Noto Sans Arabic';
  static const String arabicAlternative = '${_prefix}IBM Plex Sans Arabic';
  static const String cyrillicFallback = '${_prefix}Noto Sans';
  static const String cjkFallback = '${_prefix}Noto Sans SC';
}
