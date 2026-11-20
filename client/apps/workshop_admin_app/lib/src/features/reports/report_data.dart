import 'package:workshop_admin_app/src/models.dart';

/// Everything the certificate reads from [ReportAdmin.content], parsed once.
///
/// The admin payload is a `ReportSnapshot` (see the server record): vehicle,
/// coverage, keyFindings, categories, verificationHash. Optional keys are
/// guarded rather than assumed, and a missing value stays `null` so the screen
/// can leave the row out instead of printing a zero.
class ReportSummary {
  const ReportSummary({
    required this.vehicle,
    required this.keyFindings,
    required this.categories,
    required this.findingsCount,
    required this.safetyCriticalCount,
    this.customerName,
    this.plate,
    this.vin,
    this.odometer,
    this.scope,
    this.technicianName,
    this.workshopName,
    this.completedChecks,
    this.applicableChecks,
    this.totalChecks,
    this.passedCount,
    this.score,
    this.grade,
    this.safetyCapApplied = false,
    this.safetyCapReason,
    this.verificationHash,
  });

  final Map<String, dynamic> vehicle;
  final List<Map<String, dynamic>> keyFindings;
  final List<Map<String, dynamic>> categories;
  final int findingsCount;
  final int safetyCriticalCount;
  final String? customerName;
  final String? plate;
  final String? vin;
  final String? odometer;
  final String? scope;
  final String? technicianName;
  final String? workshopName;
  final int? completedChecks;
  final int? applicableChecks;
  final int? totalChecks;
  final int? passedCount;
  final num? score;
  final String? grade;
  final bool safetyCapApplied;
  final String? safetyCapReason;
  final String? verificationHash;

  /// Vehicle identity line: "Toyota Land Cruiser 2022", skipping blanks.
  String get vehicleLine => <String>[
    ReportData.text(vehicle['make']),
    ReportData.text(vehicle['model']),
    ReportData.text(vehicle['year']),
  ].where((part) => part.isNotEmpty).join(' ');

  bool get hasScore => score != null;

  /// Focal coverage figure, only when both halves of the pair exist.
  String? get coverageText {
    final completed = completedChecks;
    final applicable = applicableChecks;
    if (completed == null || applicable == null) {
      return null;
    }
    return '$completed / $applicable';
  }

  int? get coveragePercent {
    final completed = completedChecks;
    final applicable = applicableChecks;
    if (completed == null || applicable == null || applicable <= 0) {
      return null;
    }
    return (completed * 100 / applicable).round();
  }
}

abstract final class ReportData {
  static String text(dynamic value) {
    if (value == null) {
      return '';
    }
    final raw = '$value'.trim();
    return raw == 'null' ? '' : raw;
  }

  static Map<String, dynamic> map(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry('$key', item));
    }
    return const <String, dynamic>{};
  }

  static int? integer(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    final raw = text(value);
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw) ?? double.tryParse(raw)?.round();
  }

  static num? number(dynamic value) {
    if (value is num) {
      return value;
    }
    final raw = text(value);
    if (raw.isEmpty) {
      return null;
    }
    return num.tryParse(raw);
  }

  static List<Map<String, dynamic>> maps(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .map(map)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  /// Returns the English value from a bilingual snapshot entry.
  static String localized(Map<String, dynamic> item, String prefix) {
    return text(item['${prefix}En']);
  }

  static ReportSummary summarize(ReportAdmin report) {
    final content = report.content ?? const <String, dynamic>{};
    final coverage = map(content['coverage']);
    final keyFindings = maps(content['keyFindings']);
    final categories = maps(content['categories']);
    final vehicle = map(content['vehicle']);
    final inspection = map(content['inspection']);
    final workshop = map(content['workshop']);
    final technician = map(content['technician']);
    final customer = map(content['customer']);

    var safetyCritical = 0;
    for (final item in keyFindings) {
      final code = text(item['severityCode']).toUpperCase();
      if (code == 'SAFETY_CRITICAL') {
        safetyCritical++;
      }
    }

    var passed = 0;
    var sawItems = false;
    for (final category in categories) {
      final items = maps(category['items']);
      if (items.isNotEmpty) {
        sawItems = true;
      }
      for (final item in items) {
        if (text(item['resultCode']).toUpperCase() == 'NO_ISSUE_OBSERVED') {
          passed++;
        }
      }
    }

    final odometerValue = integer(vehicle['odometerValue']);
    final odometerUnit = text(vehicle['odometerUnit']);
    final odometer = text(vehicle['odometer']).isNotEmpty
        ? text(vehicle['odometer'])
        : odometerValue == null
        ? null
        : '$odometerValue${odometerUnit.isEmpty ? '' : ' $odometerUnit'}';

    final nameFromCustomer = text(customer['name']);
    final customerName = text(content['customerName']).isNotEmpty
        ? text(content['customerName'])
        : nameFromCustomer.isNotEmpty
        ? nameFromCustomer
        : null;

    final plate = text(vehicle['plate']);
    final vinMasked = text(vehicle['vinMasked']);
    final vinRaw = text(vehicle['vin']);
    final hash = text(content['verificationHash']);

    return ReportSummary(
      vehicle: vehicle,
      keyFindings: keyFindings,
      categories: categories,
      findingsCount: keyFindings.length,
      safetyCriticalCount: safetyCritical,
      customerName: customerName,
      plate: plate.isEmpty ? null : plate,
      vin: vinMasked.isNotEmpty
          ? vinMasked
          : vinRaw.isNotEmpty
          ? vinRaw
          : null,
      odometer: odometer == null || odometer.isEmpty ? null : odometer,
      scope: text(inspection['scope']).isEmpty
          ? null
          : text(inspection['scope']),
      technicianName: text(technician['displayName']).isEmpty
          ? null
          : text(technician['displayName']),
      workshopName: text(workshop['name']).isEmpty
          ? null
          : text(workshop['name']),
      completedChecks: integer(coverage['completed']),
      applicableChecks: integer(coverage['applicable']),
      totalChecks: integer(coverage['total']),
      passedCount: sawItems ? passed : null,
      score: number(content['score']),
      grade: text(content['gradeCode']).isEmpty
          ? null
          : text(content['gradeCode']),
      safetyCapApplied: content['safetyCapApplied'] == true,
      safetyCapReason: text(content['safetyCapReason']).isEmpty
          ? null
          : text(content['safetyCapReason']),
      verificationHash: hash.isNotEmpty
          ? hash
          : text(report.snapshotHash).isEmpty
          ? null
          : text(report.snapshotHash),
    );
  }
}
