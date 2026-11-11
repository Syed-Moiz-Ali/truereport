import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({super.key});

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  final _nameEnController = TextEditingController();
  final _nameArController = TextEditingController();
  final List<_GradeRow> _grades = [];
  String? _mode;
  String? _capGrade;
  bool _capEnabled = true;
  bool _busy = false;
  String? _syncedRuleId;
  int? _syncedVersion;
  bool? _syncedPending;

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    for (final row in _grades) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(scoringRuleProvider);

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      appBar: AppBar(
        backgroundColor: PtTheme.white,
        foregroundColor: PtTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.scoringRules,
          style: PtTheme.font(
            18,
            lineHeight: 24,
            weight: FontWeight.w800,
            color: PtTheme.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: detail.when(
          loading: () => const _CenteredLoading(),
          error: (error, stackTrace) => _CenteredError(
            onRetry: () => ref.invalidate(scoringRuleProvider),
          ),
          data: (detail) {
            _syncFromDetail(detail);
            return _buildBody(context, l10n, detail);
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    ScoringRuleDetail detail,
  ) {
    final rule = detail.rule;
    final coverageValid = _coverageValid();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 28,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _InfoChip(
                              label: rule.code,
                              color: PtTheme.deepGreen,
                            ),
                            _InfoChip(
                              label: l10n.active,
                              color: PtTheme.emerald,
                            ),
                            if (rule.pendingApproval)
                              _InfoChip(
                                label: l10n.pendingApproval,
                                color: PtTheme.amber,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.scoringRules,
                          style: PtTheme.font(
                            22,
                            lineHeight: 28,
                            weight: FontWeight.w800,
                            color: PtTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ResponsiveFieldWrap(
                          children: [
                            _FieldBox(
                              child: TextField(
                                controller: _nameEnController,
                                decoration: InputDecoration(
                                  labelText: l10n.labelEn,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            _FieldBox(
                              child: TextField(
                                controller: _nameArController,
                                decoration: InputDecoration(
                                  labelText: l10n.labelAr,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            _FieldBox(
                              child: DropdownButtonFormField<String>(
                                initialValue: _mode ?? 'CONFIGURED',
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: l10n.categoryWeightMode,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'CONFIGURED',
                                    child: Text('CONFIGURED'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'EQUAL',
                                    child: Text('EQUAL'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _mode = value);
                                  }
                                },
                              ),
                            ),
                            _FieldBox(
                              child: Row(
                                children: [
                                  Switch(
                                    value: _capEnabled,
                                    onChanged: (value) =>
                                        setState(() => _capEnabled = value),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      l10n.safetyCap,
                                      style: PtTheme.font(
                                        13,
                                        weight: FontWeight.w600,
                                        color: PtTheme.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _FieldBox(
                              child: DropdownButtonFormField<String>(
                                initialValue: _capGrade ?? 'A',
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: l10n.capGrade,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'A',
                                    child: Text('A'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'B',
                                    child: Text('B'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'C',
                                    child: Text('C'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'D',
                                    child: Text('D'),
                                  ),
                                ],
                                onChanged: _capEnabled
                                    ? (value) {
                                        if (value != null) {
                                          setState(() => _capGrade = value);
                                        }
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _proposeChange(rule.id),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: Text(l10n.proposeChange),
                              style: FilledButton.styleFrom(
                                backgroundColor: PtTheme.deepGreen,
                              ),
                            ),
                            if (rule.pendingApproval)
                              OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _approveRule(rule.id),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: Text(l10n.approveChange),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: PtTheme.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: PtTheme.amber,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.safetyCap,
                                style: PtTheme.font(
                                  14,
                                  weight: FontWeight.w700,
                                  color: PtTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${l10n.capGrade}: ${_capGrade ?? 'A'}. '
                                'When enabled, any hard failure caps the overall grade at the selected grade.',
                                style: PtTheme.font(13, color: PtTheme.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            Text(
                              l10n.gradeBoundaries,
                              style: PtTheme.font(
                                16,
                                weight: FontWeight.w700,
                                color: PtTheme.ink,
                              ),
                            ),
                            _InfoChip(
                              label: coverageValid
                                  ? l10n.coverageValid
                                  : l10n.coverageInvalid,
                              color: coverageValid
                                  ? PtTheme.emerald
                                  : PtTheme.rose,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _addGrade,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: Text(l10n.addGrade),
                            ),
                            FilledButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _saveBoundaries(rule.id, l10n),
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: Text(l10n.save),
                              style: FilledButton.styleFrom(
                                backgroundColor: PtTheme.deepGreen,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _approveBoundaries(rule.id),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: Text(l10n.approveChange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_grades.isEmpty)
                          Text(
                            l10n.noData,
                            style: PtTheme.font(13, color: PtTheme.muted),
                          )
                        else
                          for (final row in _grades)
                            _GradeRowCard(
                              row: row,
                              onChanged: () => setState(() {}),
                              onDelete: () => _removeGrade(row),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _syncFromDetail(ScoringRuleDetail detail) {
    final rule = detail.rule;
    if (_syncedRuleId == rule.id &&
        _syncedVersion == rule.version &&
        _syncedPending == rule.pendingApproval) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_syncedRuleId == rule.id &&
          _syncedVersion == rule.version &&
          _syncedPending == rule.pendingApproval) {
        return;
      }
      setState(() {
        _syncedRuleId = rule.id;
        _syncedVersion = rule.version;
        _syncedPending = rule.pendingApproval;
        _nameEnController.text = rule.nameEn;
        _nameArController.text = rule.nameAr;
        _mode = rule.categoryWeightMode.isEmpty
            ? 'CONFIGURED'
            : rule.categoryWeightMode;
        _capEnabled = rule.hardFailCapEnabled;
        _capGrade = rule.hardFailCapGrade.isEmpty ? 'A' : rule.hardFailCapGrade;
        for (final row in _grades) {
          row.dispose();
        }
        _grades
          ..clear()
          ..addAll(
            (detail.gradeBoundaries.isEmpty
                    ? _seedBoundaries()
                    : detail.gradeBoundaries)
                .map(_GradeRow.fromBoundary),
          );
      });
    });
  }

  List<GradeBoundary> _seedBoundaries() {
    return const [
      GradeBoundary(
        gradeCode: 'A',
        minScore: 90,
        maxScore: 100,
        labelEn: 'A',
        labelAr: 'A',
        sortOrder: 1,
        approved: true,
      ),
      GradeBoundary(
        gradeCode: 'B',
        minScore: 80,
        maxScore: 89,
        labelEn: 'B',
        labelAr: 'B',
        sortOrder: 2,
        approved: true,
      ),
      GradeBoundary(
        gradeCode: 'C',
        minScore: 65,
        maxScore: 79,
        labelEn: 'C',
        labelAr: 'C',
        sortOrder: 3,
        approved: true,
      ),
      GradeBoundary(
        gradeCode: 'D',
        minScore: 0,
        maxScore: 64,
        labelEn: 'D',
        labelAr: 'D',
        sortOrder: 4,
        approved: true,
      ),
    ];
  }

  bool _coverageValid() {
    if (_grades.isEmpty) return false;
    final spans = <({int min, int max})>[];
    for (final row in _grades) {
      final min = int.tryParse(row.minController.text.trim());
      final max = int.tryParse(row.maxController.text.trim());
      if (min == null || max == null) return false;
      if (min < 0 || max > 100 || min > max) return false;
      spans.add((min: min, max: max));
    }
    spans.sort((a, b) => a.min.compareTo(b.min));
    if (spans.first.min != 0 || spans.last.max != 100) return false;
    for (var index = 1; index < spans.length; index++) {
      if (spans[index].min != spans[index - 1].max + 1) return false;
    }
    return true;
  }

  void _addGrade() {
    setState(() {
      _grades.add(
        _GradeRow(
          gradeCode: '',
          minScore: '0',
          maxScore: '0',
          labelEn: '',
          labelAr: '',
          sortOrder: '${_grades.length + 1}',
          approved: false,
        ),
      );
    });
  }

  void _removeGrade(_GradeRow row) {
    setState(() => _grades.remove(row));
    row.dispose();
  }

  Future<void> _proposeChange(String id) async {
    await _run(() async {
      await ref.read(platformConfigActionsProvider).updateScoringRule(id, {
        'nameEn': _nameEnController.text.trim(),
        'nameAr': _nameArController.text.trim(),
        'categoryWeightMode': _mode ?? 'CONFIGURED',
        'hardFailCapEnabled': _capEnabled,
        'hardFailCapGrade': _capGrade ?? 'A',
      });
    }, successMessage: AppLocalizations.of(context).pendingApproval);
  }

  Future<void> _approveRule(String id) async {
    await _run(() async {
      await ref.read(platformConfigActionsProvider).approveScoringRule(id);
    }, successMessage: AppLocalizations.of(context).published);
  }

  Future<void> _saveBoundaries(String id, AppLocalizations l10n) async {
    if (!_coverageValid()) {
      _snack(l10n.coverageInvalid);
      return;
    }
    await _run(() async {
      await ref
          .read(platformConfigActionsProvider)
          .saveGradeBoundaries(
            id,
            _grades.map((row) => row.toBoundary()).toList(growable: false),
          );
    });
  }

  Future<void> _approveBoundaries(String id) async {
    await _run(() async {
      await ref.read(platformConfigActionsProvider).approveGradeBoundaries(id);
      if (!mounted) return;
      setState(() {
        for (final row in _grades) {
          row.approved = true;
        }
      });
    }, successMessage: AppLocalizations.of(context).published);
  }

  Future<void> _run(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (successMessage != null) _snack(successMessage);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey);
    } catch (_) {
      if (!mounted) return;
      _snack(AppLocalizations.of(context).genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GradeRow {
  _GradeRow({
    required String gradeCode,
    required String minScore,
    required String maxScore,
    required String labelEn,
    required String labelAr,
    required String sortOrder,
    required this.approved,
  }) : codeController = TextEditingController(text: gradeCode),
       minController = TextEditingController(text: minScore),
       maxController = TextEditingController(text: maxScore),
       labelEnController = TextEditingController(text: labelEn),
       labelArController = TextEditingController(text: labelAr),
       sortOrderController = TextEditingController(text: sortOrder);

  factory _GradeRow.fromBoundary(GradeBoundary boundary) {
    return _GradeRow(
      gradeCode: boundary.gradeCode,
      minScore: '${boundary.minScore}',
      maxScore: '${boundary.maxScore}',
      labelEn: boundary.labelEn,
      labelAr: boundary.labelAr,
      sortOrder: '${boundary.sortOrder}',
      approved: boundary.approved,
    );
  }

  final TextEditingController codeController;
  final TextEditingController minController;
  final TextEditingController maxController;
  final TextEditingController labelEnController;
  final TextEditingController labelArController;
  final TextEditingController sortOrderController;
  bool approved;

  GradeBoundary toBoundary() {
    return GradeBoundary(
      gradeCode: codeController.text.trim(),
      minScore: int.tryParse(minController.text.trim()) ?? 0,
      maxScore: int.tryParse(maxController.text.trim()) ?? 0,
      labelEn: labelEnController.text.trim(),
      labelAr: labelArController.text.trim(),
      sortOrder: int.tryParse(sortOrderController.text.trim()) ?? 0,
      approved: approved,
    );
  }

  void dispose() {
    codeController.dispose();
    minController.dispose();
    maxController.dispose();
    labelEnController.dispose();
    labelArController.dispose();
    sortOrderController.dispose();
  }
}

class _GradeRowCard extends StatelessWidget {
  const _GradeRowCard({
    required this.row,
    required this.onChanged,
    required this.onDelete,
  });

  final _GradeRow row;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoChip(
                label: row.codeController.text.isEmpty
                    ? l10n.grade
                    : row.codeController.text,
                color: PtTheme.deepGreen,
              ),
              _InfoChip(
                label:
                    '${l10n.status}: ${row.approved ? l10n.published : l10n.pending}',
                color: row.approved ? PtTheme.emerald : PtTheme.amber,
              ),
              IconButton(
                tooltip: l10n.delete,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: PtTheme.rose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width > 900 ? 3 : (width >= 600 ? 2 : 1);
              final fieldWidth = (width - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _fieldBox(
                    fieldWidth,
                    TextField(
                      controller: row.codeController,
                      onChanged: (_) => onChanged(),
                      decoration: InputDecoration(
                        labelText: l10n.grade,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  _fieldBox(
                    fieldWidth,
                    TextField(
                      controller: row.minController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => onChanged(),
                      decoration: InputDecoration(
                        labelText: l10n.minScore,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  _fieldBox(
                    fieldWidth,
                    TextField(
                      controller: row.maxController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => onChanged(),
                      decoration: InputDecoration(
                        labelText: l10n.maxScore,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  _fieldBox(
                    fieldWidth,
                    TextField(
                      controller: row.labelEnController,
                      decoration: InputDecoration(
                        labelText: l10n.labelEn,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  _fieldBox(
                    fieldWidth,
                    TextField(
                      controller: row.labelArController,
                      decoration: InputDecoration(
                        labelText: l10n.labelAr,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  _fieldBox(
                    fieldWidth,
                    TextField(
                      controller: row.sortOrderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sort order',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _fieldBox(double width, Widget child) {
    return SizedBox(width: width, child: child);
  }
}

class _ResponsiveFieldWrap extends StatelessWidget {
  const _ResponsiveFieldWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 900 ? 3 : (width >= 600 ? 2 : 1);
        final fieldWidth = (width - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children)
              SizedBox(width: fieldWidth, child: child),
          ],
        );
      },
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: child,
    );
  }
}

class _CenteredLoading extends StatelessWidget {
  const _CenteredLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: PtTheme.deepGreen),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).loading,
            style: PtTheme.font(13, color: PtTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _CenteredError extends StatelessWidget {
  const _CenteredError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: PtTheme.rose, size: 34),
            const SizedBox(height: 12),
            Text(
              l10n.unhealthy,
              style: PtTheme.font(
                16,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: PtTheme.deepGreen),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
