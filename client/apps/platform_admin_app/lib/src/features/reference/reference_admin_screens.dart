import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

import 'reference_dialogs.dart';
import 'reference_failures.dart';
import 'reference_record_form.dart';

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
    return _ReferencePage(
      title: strings.tKey(PlatformAdminKeys.taxonomyStatusesTitle),
      subtitle: strings.tKey(PlatformAdminKeys.taxonomyStatusesSubtitle),
      pickerLabel: strings.tKey(PlatformAdminKeys.taxonomyStatusType),
      values: _statusTypes,
      selected: _type,
      onSelected: (value) => setState(() => _type = value),
      actions: <Widget>[
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
      strings: strings,
      child: _RecordsView(
        strings: strings,
        admin: ref.watch(adminStatusesProvider(_type)),
        published: ref.watch(statusesProvider(_type)),
        onRetry: _refresh,
        row: (records, drafts, index, record) => _RecordCard(
          code: record.code,
          labelKey: record.labelKey,
          label: strings.resolveFlatKey(record.labelKey),
          tone: record.tone,
          order: record.order,
          selectable: record.selectable,
          visibleFor: record.visibleFor,
          version: record.version,
          isDraft: drafts.contains(record.code),
          strings: strings,
          busy: _busy,
          onEdit: () => _openForm(record: record),
          onPublish: () => _publish(record),
          onRetire: () => _retire(record),
          onMoveUp: index == 0 ? null : () => _move(records, index, -1),
          onMoveDown: index == records.length - 1
              ? null
              : () => _move(records, index, 1),
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
    return _ReferencePage(
      title: strings.tKey(PlatformAdminKeys.taxonomyEnumsTitle),
      subtitle: strings.tKey(PlatformAdminKeys.taxonomyEnumsSubtitle),
      pickerLabel: strings.tKey(PlatformAdminKeys.taxonomyEnumCode),
      values: _enumCodes,
      selected: _code,
      onSelected: (value) => setState(() => _code = value),
      actions: <Widget>[
        PlatformPrimaryButton(
          key: const Key('reference-create'),
          label: strings.tKey(PlatformAdminKeys.referenceCreate),
          icon: Icons.add_rounded,
          onPressed: _busy ? null : () => _openForm(),
        ),
      ],
      strings: strings,
      child: _RecordsView(
        strings: strings,
        admin: ref.watch(adminEnumsProvider(_code)),
        published: ref.watch(enumsProvider(_code)),
        onRetry: _refresh,
        row: (records, drafts, index, record) => _RecordCard(
          code: record.code,
          labelKey: record.labelKey,
          label: strings.resolveFlatKey(record.labelKey),
          tone: record.tone,
          order: record.order,
          selectable: record.selectable,
          visibleFor: record.visibleFor,
          version: record.version,
          isDraft: drafts.contains(record.code),
          strings: strings,
          busy: _busy,
          onEdit: () => _openForm(record: record),
          onPublish: () => _publish(record),
          onRetire: () => _retire(record),
          onMoveUp: index == 0 ? null : () => _moveEnums(records, index, -1),
          onMoveDown: index == records.length - 1
              ? null
              : () => _moveEnums(records, index, 1),
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
    return _ReferencePage(
      title: strings.tKey(PlatformAdminKeys.taxonomyDropdownsTitle),
      subtitle: strings.tKey(PlatformAdminKeys.taxonomyDropdownsSubtitle),
      pickerLabel: strings.tKey(PlatformAdminKeys.taxonomySetCode),
      values: _dropdownSets,
      selected: _set,
      onSelected: (value) => setState(() => _set = value),
      actions: <Widget>[
        PlatformSecondaryButton(
          key: const Key('reference-open-option-sets'),
          label: strings.tKey(PlatformAdminKeys.taxonomyOptionSetsLink),
          icon: Icons.tune_rounded,
          onPressed: () => context.go('/checklist/option-sets'),
        ),
      ],
      strings: strings,
      child: _ListView<ReferenceValue>(
        strings: strings,
        async: async,
        onRetry: () => ref.invalidate(dropdownProvider(_set)),
        row: (value) => _ValueCard(
          code: value.code,
          labelKey: value.labelKey,
          label: strings.resolveFlatKey(value.labelKey),
          order: value.order,
          selectable: value.selectable,
          parentCode: value.parentCode,
          version: value.version,
          strings: strings,
        ),
      ),
    );
  }
}

class _ReferencePage extends StatelessWidget {
  const _ReferencePage({
    required this.strings,
    required this.title,
    required this.subtitle,
    required this.pickerLabel,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.child,
    this.actions = const <Widget>[],
  });

  final UiMessageStrings strings;
  final String title;
  final String subtitle;
  final String pickerLabel;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return PlatformPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PlatformPageHeader(
            title: title,
            subtitle: subtitle,
            actions: actions,
          ),
          const SizedBox(height: 12),
          Text(
            pickerLabel,
            style: PtTheme.font(
              12,
              weight: FontWeight.w600,
              color: PtTheme.muted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final value in values)
                PlatformFilterChip(
                  key: Key('reference-picker-$value'),
                  label: value,
                  selected: selected == value,
                  onTap: () => onSelected(value),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ManagedNote(strings: strings),
          const SizedBox(height: 12),
          child,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(8),
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

/// Renders the draft-aware record list.
///
/// The admin read includes drafts and the client read is published-only, so
/// the difference is the draft set. Both must resolve before the list paints:
/// otherwise every row would flash as a draft.
class _RecordsView extends StatelessWidget {
  const _RecordsView({
    required this.strings,
    required this.admin,
    required this.published,
    required this.onRetry,
    required this.row,
  });

  final UiMessageStrings strings;
  final AsyncValue<List<ReferenceRecord>> admin;
  final AsyncValue<List<ReferenceRecord>> published;
  final VoidCallback onRetry;
  final Widget Function(
    List<ReferenceRecord> records,
    Set<String> drafts,
    int index,
    ReferenceRecord record,
  )
  row;

  @override
  Widget build(BuildContext context) {
    if (admin.hasError || published.hasError) {
      return PlatformErrorView(
        message: strings.tKey(PlatformAdminKeys.taxonomyError),
        retryLabel: strings.tKey(PlatformAdminKeys.taxonomyRetry),
        onRetry: onRetry,
      );
    }
    if (!admin.hasValue || !published.hasValue) {
      return const PlatformSkeletonList(rows: 4);
    }
    final records = admin.requireValue;
    final drafts = draftCodes(records, published.requireValue);
    if (records.isEmpty) {
      return PlatformEmptyView(
        title: strings.tKey(PlatformAdminKeys.taxonomyEmpty),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < records.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          row(records, drafts, i, records[i]),
        ],
      ],
    );
  }
}

class _ListView<T> extends StatelessWidget {
  const _ListView({
    required this.strings,
    required this.async,
    required this.onRetry,
    required this.row,
  });

  final UiMessageStrings strings;
  final AsyncValue<List<T>> async;
  final VoidCallback onRetry;
  final Widget Function(T value) row;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const PlatformSkeletonList(rows: 4),
      error: (error, _) => PlatformErrorView(
        message: strings.tKey(PlatformAdminKeys.taxonomyError),
        retryLabel: strings.tKey(PlatformAdminKeys.taxonomyRetry),
        onRetry: onRetry,
      ),
      data: (items) {
        if (items.isEmpty) {
          return PlatformEmptyView(
            title: strings.tKey(PlatformAdminKeys.taxonomyEmpty),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (var i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 8),
              row(items[i]),
            ],
          ],
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.code,
    required this.labelKey,
    required this.label,
    required this.tone,
    required this.order,
    required this.selectable,
    required this.visibleFor,
    required this.version,
    required this.isDraft,
    required this.strings,
    required this.busy,
    required this.onEdit,
    required this.onPublish,
    required this.onRetire,
    this.onMoveUp,
    this.onMoveDown,
  });

  final String code;
  final String labelKey;
  final String? label;
  final String tone;
  final int order;
  final bool selectable;
  final List<String> visibleFor;
  final int version;
  final bool isDraft;
  final UiMessageStrings strings;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onRetire;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final reorderable = onMoveUp != null || onMoveDown != null;
    return _RowFrame(
      key: Key('reference-record-$code'),
      code: code,
      label: label,
      labelKey: labelKey,
      draft: isDraft,
      badge: PlatformStatusChip(
        key: Key('reference-state-$code'),
        status: isDraft ? 'DRAFT' : 'PUBLISHED',
        label: strings.tKey(
          isDraft
              ? PlatformAdminKeys.referenceDraftBadge
              : PlatformAdminKeys.referencePublishedBadge,
        ),
      ),
      fields: <Widget>[
        _pill(strings, PlatformAdminKeys.taxonomyTone, tone),
        _pill(strings, PlatformAdminKeys.taxonomyOrder, '$order'),
        _pill(
          strings,
          PlatformAdminKeys.taxonomySelectable,
          selectable
              ? strings.tKey(PlatformAdminKeys.taxonomyYes)
              : strings.tKey(PlatformAdminKeys.taxonomyNo),
        ),
        _pill(
          strings,
          PlatformAdminKeys.taxonomyVisibility,
          visibleFor.isEmpty ? '*' : visibleFor.join(', '),
        ),
        _pill(strings, PlatformAdminKeys.taxonomyVersion, '$version'),
      ],
      actions: <Widget>[
        if (reorderable) ...<Widget>[
          IconButton(
            key: Key('reference-move-up-$code'),
            tooltip: strings.tKey(CommonKeys.buttonMoveUp),
            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            onPressed: busy ? null : onMoveUp,
          ),
          IconButton(
            key: Key('reference-move-down-$code'),
            tooltip: strings.tKey(CommonKeys.buttonMoveDown),
            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
            onPressed: busy ? null : onMoveDown,
          ),
        ],
        PlatformGhostButton(
          key: Key('reference-edit-$code'),
          label: strings.tKey(CommonKeys.buttonEdit),
          icon: Icons.edit_outlined,
          onPressed: busy ? null : onEdit,
        ),
        if (isDraft)
          PlatformSecondaryButton(
            key: Key('reference-publish-$code'),
            label: strings.tKey(PlatformAdminKeys.referencePublish),
            icon: Icons.publish_rounded,
            onPressed: busy ? null : onPublish,
          )
        else
          PlatformSecondaryButton(
            key: Key('reference-retire-$code'),
            label: strings.tKey(PlatformAdminKeys.referenceRetire),
            icon: Icons.archive_outlined,
            destructive: true,
            onPressed: busy ? null : onRetire,
          ),
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.code,
    required this.labelKey,
    required this.label,
    required this.order,
    required this.selectable,
    required this.parentCode,
    required this.version,
    required this.strings,
  });

  final String code;
  final String labelKey;
  final String? label;
  final int order;
  final bool selectable;
  final String? parentCode;
  final int version;
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    return _RowFrame(
      key: Key('reference-value-$code'),
      code: code,
      label: label,
      labelKey: labelKey,
      fields: <Widget>[
        _pill(strings, PlatformAdminKeys.taxonomyOrder, '$order'),
        _pill(
          strings,
          PlatformAdminKeys.taxonomySelectable,
          selectable
              ? strings.tKey(PlatformAdminKeys.taxonomyYes)
              : strings.tKey(PlatformAdminKeys.taxonomyNo),
        ),
        if (parentCode != null && parentCode!.isNotEmpty)
          _pill(strings, PlatformAdminKeys.taxonomyVisibility, parentCode!),
        _pill(strings, PlatformAdminKeys.taxonomyVersion, '$version'),
      ],
    );
  }
}

class _RowFrame extends StatelessWidget {
  const _RowFrame({
    required this.code,
    required this.label,
    required this.labelKey,
    required this.fields,
    this.badge,
    this.actions = const <Widget>[],
    this.draft = false,
    super.key,
  });

  final String code;
  final String? label;
  final String labelKey;
  final List<Widget> fields;
  final Widget? badge;
  final List<Widget> actions;
  final bool draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: draft ? const Color(0xFFFFFBEB) : PtTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: draft ? PtTheme.amber.withValues(alpha: 0.35) : PtTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ?badge,
              PlatformMetadataChip(label: code),
              Text(
                label ?? labelKey,
                style: PtTheme.font(13, weight: FontWeight.w600),
              ),
              PlatformMetadataChip(label: labelKey),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6, children: fields),
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

Widget _pill(UiMessageStrings strings, UiMessageKey key, String value) {
  return PlatformMetaPill(label: strings.tKey(key), value: value);
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
