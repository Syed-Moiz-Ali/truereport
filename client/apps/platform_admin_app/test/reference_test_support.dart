import 'dart:convert';
import 'dart:io';

import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

/// Loads the real backend catalogs so tests prove every key exists.
UiMessageStrings loadReferenceStrings() {
  Map<String, String> flatten(String path) {
    final json =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    return <String, String>{
      for (final entry in json.entries) entry.key: '${entry.value}',
    };
  }

  return UiMessageStrings(
    catalogs: <String, Map<String, Map<String, String>>>{
      'en': <String, Map<String, String>>{
        'common': flatten(
          '../../../server/src/main/resources/i18n/common/en.json',
        ),
        'platform_admin': flatten(
          '../../../server/src/main/resources/i18n/platform_admin/en.json',
        ),
      },
    },
    activeLanguage: 'en',
    defaultLanguage: 'en',
  );
}

ReferenceRecord record(
  String code, {
  String labelKey = 'status.active',
  String tone = 'neutral',
  int order = 0,
  bool selectable = true,
  List<String> visibleFor = const <String>[
    'platform_admin',
    'workshop_admin',
    'technician',
  ],
  int version = 1,
}) {
  return ReferenceRecord(
    code: code,
    labelKey: labelKey,
    tone: tone,
    order: order,
    selectable: selectable,
    visibleFor: visibleFor,
    version: version,
  );
}

/// In-memory [ReferenceAdminActions] double. Never talks to the network.
class FakeReferenceAdmin implements ReferenceAdminActions {
  FakeReferenceAdmin({
    this.impactResult = const ReferenceImpact(),
    this.failCreateStatus,
    this.failPublish,
    this.failRetire,
    this.failReplaceTransitions,
  });

  final ReferenceImpact impactResult;
  final Object? failCreateStatus;
  final Object? failPublish;
  final Object? failRetire;
  final Object? failReplaceTransitions;
  final List<String> calls = <String>[];
  ReferenceWrite? lastWrite;
  List<ReferenceTransition>? lastTransitions;
  List<({String code, int order})>? lastReorder;

  @override
  Future<ReferenceRecord> createStatus(
    String type,
    ReferenceWrite write,
  ) async {
    calls.add('createStatus:$type');
    lastWrite = write;
    if (failCreateStatus != null) throw failCreateStatus!;
    return _fromWrite(write);
  }

  @override
  Future<ReferenceRecord> updateStatus(
    String type,
    String code,
    ReferenceWrite write,
  ) async {
    calls.add('updateStatus:$type:$code');
    lastWrite = write;
    if (failCreateStatus != null) throw failCreateStatus!;
    return _fromWrite(write);
  }

  @override
  Future<ReferenceRecord> publishStatus(String type, String code) async {
    calls.add('publishStatus:$type:$code');
    if (failPublish != null) throw failPublish!;
    return record(code);
  }

  @override
  Future<ReferenceRecord> retireStatus(String type, String code) async {
    calls.add('retireStatus:$type:$code');
    if (failRetire != null) throw failRetire!;
    return record(code);
  }

  @override
  Future<List<ReferenceRecord>> reorderStatuses(
    String type,
    List<({String code, int order})> entries,
  ) async {
    calls.add('reorderStatuses:$type');
    lastReorder = entries;
    return <ReferenceRecord>[
      for (final entry in entries) record(entry.code, order: entry.order),
    ];
  }

  @override
  Future<ReferenceRecord> createEnum(
    String enumCode,
    ReferenceWrite write,
  ) async {
    calls.add('createEnum:$enumCode');
    lastWrite = write;
    if (failCreateStatus != null) throw failCreateStatus!;
    return _fromWrite(write);
  }

  @override
  Future<ReferenceRecord> updateEnum(
    String enumCode,
    String code,
    ReferenceWrite write,
  ) async {
    calls.add('updateEnum:$enumCode:$code');
    lastWrite = write;
    if (failCreateStatus != null) throw failCreateStatus!;
    return _fromWrite(write);
  }

  @override
  Future<ReferenceRecord> publishEnum(String enumCode, String code) async {
    calls.add('publishEnum:$enumCode:$code');
    if (failPublish != null) throw failPublish!;
    return record(code);
  }

  @override
  Future<ReferenceRecord> retireEnum(String enumCode, String code) async {
    calls.add('retireEnum:$enumCode:$code');
    if (failRetire != null) throw failRetire!;
    return record(code);
  }

  @override
  Future<List<ReferenceRecord>> reorderEnums(
    String enumCode,
    List<({String code, int order})> entries,
  ) async {
    calls.add('reorderEnums:$enumCode');
    lastReorder = entries;
    return <ReferenceRecord>[
      for (final entry in entries) record(entry.code, order: entry.order),
    ];
  }

  @override
  Future<List<ReferenceTransition>> replaceTransitions(
    String entity,
    List<ReferenceTransition> entries,
  ) async {
    calls.add('replaceTransitions:$entity');
    lastTransitions = entries;
    if (failReplaceTransitions != null) throw failReplaceTransitions!;
    return entries;
  }

  @override
  Future<ReferenceImpact> impact(String domain, String code) async {
    calls.add('impact:$domain:$code');
    return impactResult;
  }

  ReferenceRecord _fromWrite(ReferenceWrite write) => record(
    write.code,
    labelKey: write.labelKey,
    tone: write.tone,
    order: write.order,
    selectable: write.selectable,
    visibleFor: write.visibleFor,
  );
}
