import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../../reference_status_lookup.dart';

import 'reference_failures.dart';

/// Entities the live contract exposes for `PUT /reference/transitions/{entity}`.
const List<String> referenceTransitionEntities = <String>[
  'job',
  'review',
  'publication',
];

class ReferenceTransitionsScreen extends StatelessWidget {
  const ReferenceTransitionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformShell(
      currentRoute: '/configuration/transitions',
      child: ReferenceTransitionsBody(),
    );
  }
}

class ReferenceTransitionsBody extends ConsumerStatefulWidget {
  const ReferenceTransitionsBody({super.key});

  @override
  ConsumerState<ReferenceTransitionsBody> createState() =>
      _ReferenceTransitionsBodyState();
}

class _ReferenceTransitionsBodyState
    extends ConsumerState<ReferenceTransitionsBody> {
  String _entity = referenceTransitionEntities.first;

  void _refresh(UiMessageStrings strings) {
    ref.invalidate(transitionRulesProvider(_entity));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: PtTheme.deepGreen,
          content: Text(
            strings.tKey(PlatformAdminKeys.referenceTransitionSaved),
            style: PtTheme.font(12.5, color: PtTheme.white),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final async = ref.watch(transitionRulesProvider(_entity));
    return PlatformPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PlatformPageHeader(
            title: strings.tKey(PlatformAdminKeys.referenceTransitionsTitle),
            subtitle: strings.tKey(
              PlatformAdminKeys.referenceTransitionsSubtitle,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.tKey(PlatformAdminKeys.referenceEntityLabel),
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
              for (final entity in referenceTransitionEntities)
                PlatformFilterChip(
                  key: Key('reference-transition-entity-$entity'),
                  label: entity,
                  selected: _entity == entity,
                  onTap: () => setState(() => _entity = entity),
                ),
            ],
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const PlatformSkeletonList(rows: 4),
            error: (error, _) => PlatformErrorView(
              message: strings.tKey(
                PlatformAdminKeys.referenceTransitionsLoadError,
              ),
              retryLabel: strings.tKey(PlatformAdminKeys.taxonomyRetry),
              onRetry: () => ref.invalidate(transitionRulesProvider(_entity)),
            ),
            data: (edges) => _TransitionEditor(
              key: ValueKey<String>(_entity),
              strings: strings,
              entity: _entity,
              initial: edges,
              actions: ref.read(referenceAdminProvider),
              onSaved: () => _refresh(strings),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransitionEditor extends StatefulWidget {
  const _TransitionEditor({
    super.key,
    required this.strings,
    required this.entity,
    required this.initial,
    required this.actions,
    required this.onSaved,
  });

  final UiMessageStrings strings;
  final String entity;
  final List<ReferenceTransition> initial;
  final ReferenceAdminActions actions;
  final VoidCallback onSaved;

  @override
  State<_TransitionEditor> createState() => _TransitionEditorState();
}

class _TransitionEditorState extends State<_TransitionEditor> {
  late List<_EdgeDraft> _edges;
  final Map<String, Map<String, Object?>> _guards =
      <String, Map<String, Object?>>{};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _edges = <_EdgeDraft>[
      for (final edge in widget.initial)
        _EdgeDraft(from: edge.fromCode, to: edge.toCode, role: edge.role),
    ];
    for (final edge in widget.initial) {
      if (edge.guard.isNotEmpty) {
        _guards['${edge.fromCode}->${edge.toCode}'] = edge.guard;
      }
    }
  }

  @override
  void dispose() {
    for (final edge in _edges) {
      edge.dispose();
    }
    super.dispose();
  }

  void _addEdge() {
    setState(() {
      _edges.add(_EdgeDraft());
      _error = null;
    });
  }

  void _removeEdge(int index) {
    setState(() {
      _edges.removeAt(index).dispose();
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final entries = <ReferenceTransition>[];
    for (final edge in _edges) {
      final from = edge.from.text.trim();
      final to = edge.to.text.trim();
      if (from.isEmpty || to.isEmpty) {
        setState(
          () => _error = widget.strings.tKey(
            PlatformAdminKeys.referenceErrorTransitionInvalid,
          ),
        );
        return;
      }
      entries.add(
        ReferenceTransition(
          fromCode: from,
          toCode: to,
          role: edge.role,
          guard: _guards['$from->$to'] ?? const <String, Object?>{},
        ),
      );
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.actions.replaceTransitions(widget.entity, entries);
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSaved();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = referenceErrorText(widget.strings, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                strings.tArgsKey(PlatformAdminKeys.referenceEdgeCount, {
                  'count': _edges.length,
                }),
                style: PtTheme.bodyMuted,
              ),
            ),
            PlatformSecondaryButton(
              key: const Key('reference-transition-add'),
              label: strings.tKey(PlatformAdminKeys.referenceAddEdge),
              icon: Icons.add_rounded,
              onPressed: _saving ? null : _addEdge,
            ),
            const SizedBox(width: 8),
            PlatformPrimaryButton(
              key: const Key('reference-transition-save'),
              label: strings.tKey(PlatformAdminKeys.referenceSaveTransitions),
              icon: Icons.check_rounded,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            key: const Key('reference-transition-error'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PtTheme.rose.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PtTheme.rose.withValues(alpha: 0.3)),
            ),
            child: Text(
              _error!,
              style: PtTheme.font(12.5, color: PtTheme.rose),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_edges.isEmpty)
          PlatformEmptyView(
            title: strings.tKey(PlatformAdminKeys.referenceTransitionsEmpty),
          )
        else
          for (var i = 0; i < _edges.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 8),
            _EdgeCard(
              index: i,
              draft: _edges[i],
              strings: strings,
              enabled: !_saving,
              onRemove: () => _removeEdge(i),
            ),
          ],
      ],
    );
  }
}

class _EdgeCard extends ConsumerWidget {
  const _EdgeCard({
    required this.index,
    required this.draft,
    required this.strings,
    required this.enabled,
    required this.onRemove,
  });

  final int index;
  final _EdgeDraft draft;
  final UiMessageStrings strings;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(enumsProvider('role')).value;
    final roleCodes = <String>[
      for (final record in roles ?? const <ReferenceRecord>[])
        if (record.selectable) record.code,
    ];
    if (draft.role.isNotEmpty && !roleCodes.contains(draft.role)) {
      roleCodes.add(draft.role);
    }
    final from = PlatformTextField(
      key: Key('reference-edge-from-$index'),
      controller: draft.from,
      label: strings.tKey(PlatformAdminKeys.referenceFromLabel),
      hint: 'DRAFT',
      enabled: enabled,
    );
    final to = PlatformTextField(
      key: Key('reference-edge-to-$index'),
      controller: draft.to,
      label: strings.tKey(PlatformAdminKeys.referenceToLabel),
      hint: 'SCHEDULED',
      enabled: enabled,
    );
    final role = PlatformDropdown<String>(
      key: Key('reference-edge-role-$index'),
      label: strings.tKey(CommonKeys.tableRole),
      value: draft.role,
      items: <DropdownMenuItem<String>>[
        for (final role in roleCodes)
          DropdownMenuItem<String>(
            value: role,
            child: Text(_roleLabel(strings, roles, role)),
          ),
      ],
      onChanged: enabled
          ? (value) {
              if (value != null) draft.role = value;
            }
          : (_) {},
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              PlatformMetadataChip(label: '${index + 1}'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.tKey(PlatformAdminKeys.referenceTransitionRoleHelper),
                  style: PtTheme.caption,
                ),
              ),
              IconButton(
                key: Key('reference-edge-remove-$index'),
                tooltip: strings.tKey(PlatformAdminKeys.referenceRemoveEdge),
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: enabled ? onRemove : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 720) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 5, child: from),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: PtTheme.muted,
                        ),
                      ),
                    ),
                    Expanded(flex: 5, child: to),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: role),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  from,
                  const SizedBox(height: 8),
                  to,
                  const SizedBox(height: 8),
                  role,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EdgeDraft {
  _EdgeDraft({String from = '', String to = '', this.role = 'WORKSHOP_ADMIN'})
    : from = TextEditingController(text: from),
      to = TextEditingController(text: to);

  final TextEditingController from;
  final TextEditingController to;
  String role;

  void dispose() {
    from.dispose();
    to.dispose();
  }
}

String _roleLabel(
  UiMessageStrings strings,
  Iterable<ReferenceRecord>? records,
  String role,
) => referenceCodeLabel(strings, records, role);
