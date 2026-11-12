import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:uuid/uuid.dart';

/// Stable category icon mapping. The server sends an `iconCode`; widgets must
/// never infer an icon from a category label.
IconData categoryIconFor(String? iconCode) {
  final code = (iconCode ?? '').trim().toUpperCase();
  return switch (code) {
    'EXTERIOR' || 'BODY' => Icons.directions_car_outlined,
    'INTERIOR' || 'CABIN' => Icons.chair_outlined,
    'ENGINE' || 'ENGINE_BAY' => Icons.settings_outlined,
    'MECHANICAL' => Icons.build_outlined,
    'ELECTRICAL' || 'BATTERY' => Icons.bolt_outlined,
    'BRAKES' || 'BRAKE' => Icons.disc_full_outlined,
    'TIRES' || 'TYRES' || 'WHEELS' => Icons.trip_origin_outlined,
    'SUSPENSION' => Icons.compress_outlined,
    'TRANSMISSION' => Icons.settings_input_component_outlined,
    'FLUIDS' || 'FLUID' => Icons.water_drop_outlined,
    'COOLING' || 'AC' || 'HVAC' => Icons.ac_unit_outlined,
    'OBD' || 'DIAGNOSTICS' => Icons.computer_outlined,
    'LIGHTING' || 'LIGHTS' => Icons.lightbulb_outline,
    'SAFETY' => Icons.health_and_safety_outlined,
    'EQUIPMENT' => Icons.handyman_outlined,
    _ => Icons.checklist_rounded,
  };
}

String evidenceTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'PHOTO' => l10n.technicianPhoto,
  'VIDEO' => l10n.technicianVideo,
  'DOCUMENT' => l10n.technicianDocument,
  _ => type,
};

class EvidenceRequirement {
  const EvidenceRequirement({
    required this.minPhotos,
    required this.minVideos,
    required this.requiresDocument,
    required this.minNotesChars,
  });

  final int minPhotos;
  final int minVideos;
  final bool requiresDocument;
  final int minNotesChars;

  static EvidenceRequirement forResult(ChecklistItem item, String? resultCode) {
    var photos = resultCode == 'DEFECT_FOUND' ? 2 : 1;
    var videos = 1;
    var document = false;
    var notes = 0;
    EvidenceRule? match;
    for (final rule in item.evidenceRules) {
      if (rule.resultCode == resultCode) {
        match = rule;
        break;
      }
    }
    if (match != null) {
      photos = match.minPhotos;
      videos = match.minVideos;
      notes = match.minNotesChars;
      document = match.requiredEvidenceType == 'DOCUMENT';
    } else {
      for (final rule in item.evidenceRules) {
        notes = notes > rule.minNotesChars ? notes : rule.minNotesChars;
      }
    }
    return EvidenceRequirement(
      minPhotos: photos,
      minVideos: videos,
      requiresDocument: document,
      minNotesChars: notes,
    );
  }
}

int resultSeverityRank(String? resultCode) => switch (resultCode) {
  'DEFECT_FOUND' => 4,
  'ATTENTION_RECOMMENDED' => 3,
  'COULD_NOT_VERIFY' => 2,
  'NO_ISSUE_OBSERVED' => 1,
  'NOT_APPLICABLE' => 0,
  _ => 0,
};

MeasurementBand? worstBandForValues(
  ChecklistItem item,
  Iterable<double> values,
) {
  MeasurementBand? worst;
  for (final value in values) {
    final band = item.bandForValue(value);
    if (band == null) {
      continue;
    }
    if (worst == null ||
        resultSeverityRank(band.resultCode) > resultSeverityRank(worst.resultCode)) {
      worst = band;
    }
  }
  return worst;
}

ScoreBand? scoreBandForResult(ChecklistItem item, String? resultCode) {
  for (final band in item.scoreBands) {
    if (band.resultCode == resultCode) {
      return band;
    }
  }
  return null;
}

bool isNetworkFailure(Object failure) {
  if (failure is AppFailure) {
    if (failure.messageKey == 'error.network' || failure.code == 'NETWORK') {
      return true;
    }
    return failure.statusCode == null;
  }
  final name = failure.runtimeType.toString().toLowerCase();
  return name.contains('socket') || name.contains('clientexception');
}

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

Future<({int width, int height})?> decodeImageSize(List<int> bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = (width: image.width, height: image.height);
    image.dispose();
    codec.dispose();
    return size;
  } on Object {
    return null;
  }
}

String mimeForPath(String? path, {String fallback = 'application/octet-stream'}) {
  final lower = (path ?? '').toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.heic')) {
    return 'image/heic';
  }
  if (lower.endsWith('.heif')) {
    return 'image/heif';
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.mp4')) {
    return 'video/mp4';
  }
  if (lower.endsWith('.webm')) {
    return 'video/webm';
  }
  if (lower.endsWith('.mov')) {
    return 'video/quicktime';
  }
  if (lower.endsWith('.pdf')) {
    return 'application/pdf';
  }
  return fallback;
}

String prettyPayload(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) {
    return '';
  }
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
  } on Object {
    return text;
  }
}

Map<String, ApiFieldError> fieldErrorsByCode(Object failure) {
  final errors = ApiFieldError.fromFailure(failure);
  return {for (final error in errors) error.field: error};
}

class DeviceIdentity {
  static const _key = 'truereport.technician.device_id';
  static String? _cached;

  static Future<String> deviceId() async {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      var value = prefs.getString(_key);
      if (value == null || value.isEmpty) {
        value = const Uuid().v4();
        await prefs.setString(_key, value);
      }
      _cached = value;
      return value;
    } on Object {
      // Plugin unavailable (e.g. widget tests): keep a session-stable id.
      final value = const Uuid().v4();
      _cached = value;
      return value;
    }
  }
}
