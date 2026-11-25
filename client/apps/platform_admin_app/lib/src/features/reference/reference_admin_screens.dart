import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_shell.dart';
import '../../platform_providers.dart';
import '../../platform_features.dart';
import '../../platform_theme.dart';

import 'reference_dialogs.dart';
import 'reference_failures.dart';
import 'reference_record_form.dart';
import 'reference_rows.dart';

const _statusTypes = <String>[
  'job',
  'review',
  'publication',
  'document',
  'sync',
  'evidence',
  'template',
  'workshop',
  'checklist',
  'health',
  'chip',
];

const _enumCodes = <String>[
  'role',
  'severity',
  'result',
  'grade',
  'measurement-unit',
  'evidence-type',
];

// Read-only dropdown viewer: the seven set codes it exposes are a fixed
// catalogue of served dropdown sets, not a selectable taxonomy in an editor;
// each set's values still come from dropdownProvider.
// gate-allow: codes
const _dropdownSets = <String>[
  'ISSUE_TYPE',
  'LOCATION',
  'COMPONENT',
  'ACTION',
  'URGENCY',
  'REASON',
  'UNIT',
];

/// Reference taxonomy screens.
///
/// Statuses and enums carry the full lifecycle (create/edit/publish/retire,
/// plus reorder for statuses). Dropdowns stay read-only and link to the
/// option-set editor (D4).
class ReferenceStatusesScreen extends StatelessWidget {
  const ReferenceStatusesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformShell(
      currentRoute: '/configuration/statuses',
      child: ReferenceStatusesBody(),
    );
  }
}

class ReferenceEnumsScreen extends StatelessWidget {
  const ReferenceEnumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformShell(
      currentRoute: '/configuration/enums',
      child: ReferenceEnumsBody(),
    );
  }
}

class ReferenceDropdownsScreen extends StatelessWidget {
  const ReferenceDropdownsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformShell(
      currentRoute: '/configuration/dropdowns',
      child: ReferenceDropdownsBody(),
    );
  }
}

class ReferenceStatusesBody extends ConsumerStatefulWidget {
  const ReferenceStatusesBody({super.key});

  @override
  ConsumerState<ReferenceStatusesBody> createState() =>
      _ReferenceStatusesBodyState();
}

class _ReferenceStatusesBodyState extends ConsumerState<ReferenceStatusesBody> {
  String _type = _statusTypes.first;
  bool _busy = false;

  void _refresh() {
    ref.invalidate(adminStatusesProvider(_type));
    ref.invalidate(statusesProvider(_type));
  }

  Future<void> _openForm({ReferenceRecord? record}) async {
    final strings = ref.read(uiStringsProvider);
    final records =
        ref.read(adminStatusesProvider(_type)).value ??
        const <ReferenceRecord>[];
    final nextOrder = records.fold<int>(
      0,
      (next, item) => item.order >= next ? item.order + 1 : next,
    );
    final saved = await showReferenceRecordForm(
      context: context,
      strings: strings,
      actions: ref.read(referenceAdminProvider),
      domain: _type,
      isEnum: false,
      record: record,
      nextOrder: nextOrder,
    );
    if (saved == null || !mounted) return;
    _refresh();
    _showMessage(context, strings.tKey(PlatformAdminKeys.referenceSaved));
  }

  Future<void> _publish(ReferenceRecord record) async {
    final strings = ref.read(uiStringsProvider);
    setState(() => _busy = true);
    try {
      await ref.read(referenceAdminProvider).publishStatus(_type, record.code);
      _refresh();
      if (mounted) {
        _showMessage(
          context,
          strings.tKey(PlatformAdminKeys.referencePublished),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        _refresh();
        _showMessage(context, referenceErrorText(strings, error), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retire(ReferenceRecord record) async {
    final strings = ref.read(uiStringsProvider);
    final actions = ref.read(referenceAdminProvider);
    setState(() => _busy = true);
    ReferenceImpact impact;
    try {
      impact = await actions.impact(_type, record.code);
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(
        context,
        strings.tKey(PlatformAdminKeys.referenceImpactLoadError),
        error: true,
      );
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final confirmed = await showReferenceRetireDialog(
      context: context,
      strings: strings,
      code: record.code,
      impact: impact,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await actions.retireStatus(_type, record.code);
      _refresh();
      if (mounted) {
        _showMessage(context, strings.tKey(PlatformAdminKeys.referenceRetired));
      }
    } on Object catch (error) {
      if (!mounted) return;
      final failure = error is AppFailure ? error : null;
      if (failure?.code == 'REFERENCE_IN_USE') {
        final counts = impact.isEmpty
            ? (impactFromDetail(failure?.detail) ?? impact)
            : impact;
        _refresh();
        setState(() => _busy = false);
        await showReferenceInUseDialog(
          context: context,
          strings: strings,
          impact: counts,
        );
        return;
      }
      _refresh();
      _showMessage(context, referenceErrorText(strings, error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(
    List<ReferenceRecord> records,
    int index,
    int delta,
  ) async {
    final target = index + delta;
    if (target < 0 || target >= records.length) return;
    final strings = ref.read(uiStringsProvider);
    final ordered = <ReferenceRecord>[...records];
    ordered.insert(target, ordered.removeAt(index));
    final entries = <({String code, int order})>[
      for (var i = 0; i < ordered.length; i++)
        (code: ordered[i].code, order: i),
    ];
    setState(() => _busy = true);
    try {
      await ref.read(referenceAdminProvider).reorderStatuses(_type, entries);
      _refresh();
      if (mounted) {
        _showMessage(
          context,
          strings.tKey(PlatformAdminKeys.referenceReordered),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage(context, referenceErrorText(strings, error), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final admin = ref.watch(adminStatusesProvider(_type));
    final published = ref.watch(statusesProvider(_type));
    final records = admin.asData?.value;
    final drafts = records == null || !published.hasValue
        ? null
        : draftCodes(records, published.requireValue);
    return _TaxonomyPage(
      strings: strings,
      title: strings.tKey(PlatformAdminKeys.taxonomyStatusesTitle),
      subtitle: strings.tKey(PlatformAdminKeys.taxonomyStatusesSubtitle),
      headerActions: <Widget>[
        if (ref.watch(workflowEditingEnabledProvider))
          PlatformSecondaryButton(
            key: const Key('reference-open-transitions'),
            label: strings.tKey(PlatformAdminKeys.referenceTransitionsTitle),
            icon: Icons.swap_horiz_rounded,
            onPressed: () => context.go('/configuration/transitions'),
          ),
        PlatformPrimaryButton(
          key: const Key('reference-create'),
          label: strings.tKey(PlatformAdminKeys.referenceCreate),
          icon: Icons.add_rounded,
          onPressed: _busy ? null : () => _openForm(),
        ),
      ],
      pickerIds: _statusTypes,
      selectedId: _type,
      onSelected: (value) => setState(() => _type = value),
      detailList: ReferenceRecordList(
        strings: strings,
        admin: admin,
        published: published,
        onRetry: _refresh,
        row: (all, draftSet, index, record) => ReferenceRecordRow(
          code: record.code,
          labelKey: record.labelKey,
          label: strings.resolveFlatKey(record.labelKey),
          selectable: record.selectable,
          isDraft: draftSet.contains(record.code),
          position: index + 1,
          total: all.length,
          strings: strings,
          busy: _busy,
          onEdit: () => _openForm(record: record),
          onPublish: () => _publish(record),
          onRetire: () => _retire(record),
          onMoveUp: index == 0 ? null : () => _move(all, index, -1),
          onMoveDown: index == all.length - 1
              ? null
              : () => _move(all, index, 1),
        ),
      ),
      footer: drafts == null || records == null
          ? null
          : Text(
              strings.tArgsKey(
                PlatformAdminKeys.referenceRecordSummary,
                <String, Object?>{
                  'total': '${records.length}',
                  'drafts': '${drafts.length}',
                },
              ),
              style: PtTheme.font(
                12.5,
                lineHeight: 18,
                weight: FontWeight.w600,
                color: PtTheme.muted,
              ),
            ),
    );
  }
}

class ReferenceEnumsBody extends ConsumerStatefulWidget {
  const ReferenceEnumsBody({super.key});

  @override
  ConsumerState<ReferenceEnumsBody> createState() => _ReferenceEnumsBodyState();
}

class _ReferenceEnumsBodyState extends ConsumerState<ReferenceEnumsBody> {
  String _code = _enumCodes.first;
  bool _busy = false;

  void _refresh() {
    ref.invalidate(adminEnumsProvider(_code));
    ref.invalidate(enumsProvider(_code));
  }

  Future<void> _openForm({ReferenceRecord? record}) async {
    final strings = ref.read(uiStringsProvider);
    final records =
        ref.read(adminEnumsProvider(_code)).value ?? const <ReferenceRecord>[];
    final nextOrder = records.fold<int>(
      0,
      (next, item) => item.order >= next ? item.order + 1 : next,
    );
    final saved = await showReferenceRecordForm(
      context: context,
      strings: strings,
      actions: ref.read(referenceAdminProvider),
      domain: _code,
      isEnum: true,
      record: record,
      nextOrder: nextOrder,
    );
    if (saved == null || !mounted) return;
    _refresh();
    _showMessage(context, strings.tKey(PlatformAdminKeys.referenceSaved));
  }

  Future<void> _publish(ReferenceRecord record) async {
    final strings = ref.read(uiStringsProvider);
    setState(() => _busy = true);
    try {
      await ref.read(referenceAdminProvider).publishEnum(_code, record.code);
      _refresh();
      if (mounted) {
        _showMessage(
          context,
          strings.tKey(PlatformAdminKeys.referencePublished),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        _refresh();
        _showMessage(context, referenceErrorText(strings, error), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retire(ReferenceRecord record) async {
    final strings = ref.read(uiStringsProvider);
    final actions = ref.read(referenceAdminProvider);
    setState(() => _busy = true);
    ReferenceImpact impact;
    try {
      impact = await actions.impact(_code, record.code);
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(
        context,
        strings.tKey(PlatformAdminKeys.referenceImpactLoadError),
        error: true,
      );
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final confirmed = await showReferenceRetireDialog(
      context: context,
      strings: strings,
      code: record.code,
      impact: impact,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await actions.retireEnum(_code, record.code);
      _refresh();
      if (mounted) {
        _showMessage(context, strings.tKey(PlatformAdminKeys.referenceRetired));
      }
    } on Object catch (error) {
      if (!mounted) return;
      final failure = error is AppFailure ? error : null;
      if (failure?.code == 'REFERENCE_IN_USE') {
        final counts = impact.isEmpty
            ? (impactFromDetail(failure?.detail) ?? impact)
            : impact;
        _refresh();
        setState(() => _busy = false);
        await showReferenceInUseDialog(
          context: context,
          strings: strings,
          impact: counts,
        );
        return;
      }
      _refresh();
      _showMessage(context, referenceErrorText(strings, error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _moveEnums(
    List<ReferenceRecord> records,
    int index,
    int delta,
  ) async {
    final target = index + delta;
    if (target < 0 || target >= records.length) return;
    final strings = ref.read(uiStringsProvider);
    final ordered = <ReferenceRecord>[...records];
    ordered.insert(target, ordered.removeAt(index));
    final entries = <({String code, int order})>[
      for (var i = 0; i < ordered.length; i++)
        (code: ordered[i].code, order: i),
    ];
    setState(() => _busy = true);
    try {
      await ref.read(referenceAdminProvider).reorderEnums(_code, entries);
      _refresh();
      if (mounted) {
        _showMessage(
          context,
          strings.tKey(PlatformAdminKeys.referenceReordered),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage(context, referenceErrorText(strings, error), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final admin = ref.watch(adminEnumsProvider(_code));
    final published = ref.watch(enumsProvider(_code));
    final records = admin.asData?.value;
    final drafts = records == null || !published.hasValue
        ? null
        : draftCodes(records, published.requireValue);
    return _TaxonomyPage(
      strings: strings,
      title: strings.tKey(PlatformAdminKeys.taxonomyEnumsTitle),
      subtitle: strings.tKey(PlatformAdminKeys.taxonomyEnumsSubtitle),
      headerActions: <Widget>[
        PlatformPrimaryButton(
          key: const Key('reference-create'),
          label: strings.tKey(PlatformAdminKeys.referenceCreate),
          icon: Icons.add_rounded,
          onPressed: _busy ? null : () => _openForm(),
        ),
      ],
      pickerIds: _enumCodes,
      selectedId: _code,
      onSelected: (value) => setState(() => _code = value),
      detailList: ReferenceRecordList(
        strings: strings,
        admin: admin,
        published: published,
        onRetry: _refresh,
        row: (all, draftSet, index, record) => ReferenceRecordRow(
          code: record.code,
          labelKey: record.labelKey,
          label: strings.resolveFlatKey(record.labelKey),
          selectable: record.selectable,
          isDraft: draftSet.contains(record.code),
          position: index + 1,
          total: all.length,
          strings: strings,
          busy: _busy,
          onEdit: () => _openForm(record: record),
          onPublish: () => _publish(record),
          onRetire: () => _retire(record),
          onMoveUp: index == 0 ? null : () => _moveEnums(all, index, -1),
          onMoveDown: index == all.length - 1
              ? null
              : () => _moveEnums(all, index, 1),
        ),
      ),
      footer: drafts == null || records == null
          ? null
          : Text(
              strings.tArgsKey(
                PlatformAdminKeys.referenceRecordSummary,
                <String, Object?>{
                  'total': '${records.length}',
                  'drafts': '${drafts.length}',
                },
              ),
              style: PtTheme.font(
                12.5,
                lineHeight: 18,
                weight: FontWeight.w600,
                color: PtTheme.muted,
              ),
            ),
    );
  }
}

class ReferenceDropdownsBody extends ConsumerStatefulWidget {
  const ReferenceDropdownsBody({super.key});

  @override
  ConsumerState<ReferenceDropdownsBody> createState() =>
      _ReferenceDropdownsBodyState();
}

class _ReferenceDropdownsBodyState
    extends ConsumerState<ReferenceDropdownsBody> {
  String _set = _dropdownSets.first;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final async = ref.watch(dropdownProvider(_set));
    final values = async.asData?.value;
    return _TaxonomyPage(
      strings: strings,
      title: strings.tKey(PlatformAdminKeys.taxonomyDropdownsTitle),
      subtitle: strings.tKey(PlatformAdminKeys.taxonomyDropdownsSubtitle),
      headerActions: <Widget>[
        PlatformSecondaryButton(
          key: const Key('reference-open-option-sets'),
          label: strings.tKey(PlatformAdminKeys.taxonomyOptionSetsLink),
          icon: Icons.tune_rounded,
          onPressed: () => context.go('/checklist/option-sets'),
        ),
      ],
      pickerIds: _dropdownSets,
      selectedId: _set,
      onSelected: (value) => setState(() => _set = value),
      detailList: ReferenceValueList<ReferenceValue>(
        strings: strings,
        async: async,
        onRetry: () => ref.invalidate(dropdownProvider(_set)),
        row: (index, value) => ReferenceValueRow(
          code: value.code,
          labelKey: value.labelKey,
          label: strings.resolveFlatKey(value.labelKey),
          selectable: value.selectable,
          parentCode: value.parentCode,
          position: index + 1,
          total: values?.length ?? 0,
          strings: strings,
        ),
      ),
      footer: values == null
          ? null
          : Text(
              strings.tArgsKey(
                PlatformAdminKeys.referenceValueSummary,
                <String, Object?>{'count': '${values.length}'},
              ),
              style: PtTheme.font(
                12.5,
                lineHeight: 18,
                weight: FontWeight.w600,
                color: PtTheme.muted,
              ),
            ),
    );
  }
}

/// Direction A page frame shared by the taxonomy screens.
///
/// Header (title, subtitle, context actions), managed note, a horizontal
/// type picker, one ledger, and a muted footer summary. The whole page
/// scrolls; nothing is pinned.
class _TaxonomyPage extends StatelessWidget {
  const _TaxonomyPage({
    required this.strings,
    required this.title,
    required this.subtitle,
    required this.headerActions,
    required this.pickerIds,
    required this.selectedId,
    required this.onSelected,
    required this.detailList,
    this.footer,
  });

  final UiMessageStrings strings;
  final String title;
  final String subtitle;
  final List<Widget> headerActions;
  final List<String> pickerIds;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final Widget detailList;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return PlatformPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PlatformPageHeader(
            title: title,
            subtitle: subtitle,
            actions: headerActions,
          ),
          const SizedBox(height: 12),
          _ManagedNote(strings: strings),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final id in pickerIds) ...<Widget>[
                  if (id != pickerIds.first) const SizedBox(width: 8),
                  PlatformFilterChip(
                    key: Key('reference-picker-$id'),
                    label: id,
                    selected: selectedId == id,
                    onTap: () => onSelected(id),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          detailList,
          if (footer != null) ...<Widget>[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}

class _ManagedNote extends StatelessWidget {
  const _ManagedNote({required this.strings});

  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('reference-managed-note'),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: PtTheme.muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strings.tKey(PlatformAdminKeys.taxonomyManagedNote),
              style: PtTheme.caption,
            ),
          ),
        ],
      ),
    );
  }
}

void _showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? PtTheme.rose : PtTheme.deepGreen,
        content: Text(message, style: PtTheme.font(12.5, color: PtTheme.white)),
      ),
    );
}
