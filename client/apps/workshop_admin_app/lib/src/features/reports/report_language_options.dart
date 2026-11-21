import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/models.dart';

/// One delivery-language choice: the wire code and its registry label.
class ReportLanguageOption {
  const ReportLanguageOption({required this.code, required this.label});

  final String code;
  final String label;
}

/// Display label for a language code, or null when the code is blank.
///
/// [registry] is the LIVE language registry. A code resolves to its
/// `nativeName`; a code the registry does not carry falls back to the
/// upper-case code. A blank code has no label, so callers choose their own
/// missing-value copy.
String? resolvedLanguageLabel(
  Iterable<WorkshopLanguage>? registry,
  String code,
) {
  final normalized = code.trim();
  if (normalized.isEmpty) return null;
  if (registry != null) {
    for (final language in registry) {
      if (language.code == normalized) {
        final nativeName = language.nativeName.trim();
        if (nativeName.isNotEmpty) return nativeName;
        break;
      }
    }
  }
  return normalized.toUpperCase();
}

/// Display label for a delivery language code; a blank code renders an em dash.
String reportLanguageLabel(Iterable<WorkshopLanguage>? registry, String code) =>
    resolvedLanguageLabel(registry, code) ?? '—';

/// Delivery language choices built from the LIVE registry.
///
/// [registry] is the provider's filtered list. When it is unavailable (null or
/// empty) the current UI manifest is the best remaining evidence, and `en` is
/// the final fallback. The job language is only kept when the registry lists it
/// as live; a retired/dead code must not become selectable again.
List<ReportLanguageOption> reportLanguageOptions(
  List<WorkshopLanguage>? registry, {
  required String preferred,
  UiMessageManifest? manifest,
}) {
  final options = <ReportLanguageOption>[];
  final seen = <String>{};

  void add(String code, String label) {
    final normalized = code.trim();
    if (normalized.isEmpty || !seen.add(normalized)) return;
    options.add(ReportLanguageOption(code: normalized, label: label));
  }

  final live = <WorkshopLanguage>[
    for (final language in registry ?? const <WorkshopLanguage>[])
      if (language.active && language.isLive && language.code.trim().isNotEmpty)
        language,
  ];
  if (live.isNotEmpty) {
    for (final language in live) {
      add(language.code, reportLanguageLabel(live, language.code));
    }
    return List<ReportLanguageOption>.unmodifiable(options);
  }

  final languages = manifest?.languages ?? const <UiMessageLanguage>[];
  for (final language in languages) {
    final code = language.code.trim();
    if (code.isEmpty) continue;
    final nativeName = language.nativeName.trim();
    add(code, nativeName.isNotEmpty ? nativeName : code.toUpperCase());
  }

  if (options.isEmpty) add('en', 'EN');
  return List<ReportLanguageOption>.unmodifiable(options);
}

/// The code that starts selected in the send sheet.
///
/// The job language wins only when the registry-backed options carry it;
/// otherwise English, and finally whatever the source advertises first.
String reportDeliveryLanguage(
  List<ReportLanguageOption> options, {
  required String preferred,
}) {
  final jobLanguage = preferred.trim();
  if (jobLanguage.isNotEmpty &&
      options.any((option) => option.code == jobLanguage)) {
    return jobLanguage;
  }
  if (options.any((option) => option.code == 'en')) return 'en';
  return options.isEmpty ? 'en' : options.first.code;
}
