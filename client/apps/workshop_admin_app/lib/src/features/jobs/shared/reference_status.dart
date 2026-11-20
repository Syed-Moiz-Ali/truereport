import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

/// Finds a reference record by code without depending on `collection`.
///
/// Comparison ignores case, spaces, hyphens and underscores so a UI value such
/// as `DEPOT HUB` still finds `DEPOT_HUB`.
ReferenceRecord? referenceRecordFor(
  Iterable<ReferenceRecord>? records,
  String code,
) {
  if (records == null || code.trim().isEmpty) return null;
  final target = _normalizeReferenceCode(code);
  for (final record in records) {
    if (_normalizeReferenceCode(record.code) == target) return record;
  }
  return null;
}

String _normalizeReferenceCode(String raw) =>
    raw.trim().replaceAll(RegExp(r'[\s-]+'), '_').toUpperCase();

/// Humanizes a code that has no served label. Never invents a display label.
String humanizeReferenceCode(String raw) {
  final cleaned = raw.trim().replaceAll(RegExp(r'[\s_-]+'), ' ');
  if (cleaned.isEmpty) return '';
  return cleaned
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

/// Canonical consent-domain code for a boolean consent flag.
String consentStatusCode(bool granted) => granted ? 'GRANTED' : 'NOT_GRANTED';

/// Served label for a code, falling back to the humanized code only.
String referenceStatusText(Iterable<ReferenceRecord>? records, String code) {
  if (code.trim().isEmpty) return '';
  return referenceLabelFor(referenceRecordFor(records, code)) ??
      humanizeReferenceCode(code);
}

/// Served tone for a code; neutral when the taxonomy has no record.
WorkshopStatusTone referenceStatusTone(
  Iterable<ReferenceRecord>? records,
  String code,
) {
  final record = referenceRecordFor(records, code);
  return workshopToneFromToken(record?.tone ?? '');
}

/// Resolves a backend `labelKey` through the existing l10n bundle.
///
/// Returns null when the key is not in the bundle yet, so the caller can use a
/// migration fallback instead of rendering an empty label.
String? referenceLabelFor(ReferenceRecord? record) {
  if (record == null || record.labelKey.isEmpty) return null;
  final text = remoteEnglish(record.labelKey);
  return text.isEmpty ? null : text;
}

/// Maps a backend tone token to the workshop badge tone.
WorkshopStatusTone workshopToneFromToken(String token) {
  return switch (token.toLowerCase()) {
    'success' || 'positive' => WorkshopStatusTone.success,
    'warning' || 'caution' => WorkshopStatusTone.warning,
    'danger' ||
    'error' ||
    'negative' ||
    'critical' => WorkshopStatusTone.danger,
    'accent' || 'info' || 'primary' => WorkshopStatusTone.accent,
    _ => WorkshopStatusTone.neutral,
  };
}

/// Foreground/background pair for the compact queue pill.
(Color, Color) workshopPillColors(WorkshopStatusTone tone, WorkshopTokens ws) {
  return switch (tone) {
    WorkshopStatusTone.success => (ws.success, ws.successSoft),
    WorkshopStatusTone.warning => (ws.warning, ws.warningSoft),
    WorkshopStatusTone.danger => (ws.danger, ws.dangerSoft),
    WorkshopStatusTone.accent => (ws.accent, ws.accentSoft),
    WorkshopStatusTone.neutral => (ws.ink, ws.canvas),
  };
}
