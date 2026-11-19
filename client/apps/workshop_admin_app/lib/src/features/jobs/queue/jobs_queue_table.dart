import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_scroll_fade.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_status_badge.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_technician.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_digits.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Columns the loaded page can be sorted by. Scheduled is the default order
/// but is not offered as a clickable sort (the server has no schedule order).
enum JobsSort { job, vehicle, customer, technician, scheduled }

/// The sheet: a tonal header band, 64 px hairline-zebra rows and edge-to-edge
/// selection. Wide pages scroll the body inside the sheet so the header stays.
///
/// The technician column folds away below 780 px of sheet width; the fact is
/// still in the inspector and the detail page, so nothing is lost, only moved.
class JobsQueueTable extends StatefulWidget {
  const JobsQueueTable({
    required this.items,
    required this.staff,
    required this.selectedId,
    required this.sort,
    required this.ascending,
    required this.onSort,
    required this.onSelect,
    this.scrollable = true,
    super.key,
  });

  final List<CleanJob> items;
  final List<StaffMember>? staff;
  final String? selectedId;
  final JobsSort sort;
  final bool ascending;
  final ValueChanged<JobsSort> onSort;
  final ValueChanged<String> onSelect;
  final bool scrollable;

  @override
  State<JobsQueueTable> createState() => _JobsQueueTableState();
}

class _JobsQueueTableState extends State<JobsQueueTable> {
  final Map<String, FocusNode> _focusNodes = {};
  List<CleanJob> _ordered = const [];

  FocusNode _nodeFor(String id) => _focusNodes.putIfAbsent(id, FocusNode.new);

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _move(int delta) {
    if (_ordered.isEmpty) {
      return;
    }
    final current = _ordered.indexWhere((job) => job.id == widget.selectedId);
    final next = current < 0
        ? (delta > 0 ? 0 : _ordered.length - 1)
        : (current + delta).clamp(0, _ordered.length - 1);
    _select(_ordered[next].id);
  }

  void _jump(bool toEnd) {
    if (_ordered.isEmpty) {
      return;
    }
    _select(_ordered[toEnd ? _ordered.length - 1 : 0].id);
  }

  void _select(String id) {
    widget.onSelect(id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nodeFor(id).requestFocus();
      }
    });
  }

  KeyEventResult _onKey(String id, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _jump(false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _jump(true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    _ordered = _sort(widget.items);
    return LayoutBuilder(
      builder: (context, constraints) {
        final showTechnician = constraints.maxWidth >= 780;
        final body = widget.scrollable
            ? Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _ordered.length,
                      itemBuilder: (context, index) => _row(
                        _ordered[index],
                        index: index,
                        showTechnician: showTechnician,
                      ),
                    ),
                    const PositionedDirectional(
                      start: 0,
                      end: 0,
                      bottom: 0,
                      height: 24,
                      child: JobsScrollFade(key: Key('jobs-queue-fade')),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < _ordered.length; index++)
                    _row(
                      _ordered[index],
                      index: index,
                      showTechnician: showTechnician,
                    ),
                ],
              );
        return Container(
          key: const Key('jobs-queue-sheet'),
          decoration: BoxDecoration(
            color: context.ws.surface,
            borderRadius: BorderRadius.circular(context.ws.cardRadius),
            border: Border.all(color: context.ws.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, showTechnician: showTechnician),
              body,
            ],
          ),
        );
      },
    );
  }

  Widget _row(
    CleanJob job, {
    required int index,
    required bool showTechnician,
  }) => _JobRow(
    key: Key('job-${job.id}'),
    job: job,
    staff: widget.staff,
    showTechnician: showTechnician,
    zebra: index.isOdd,
    selected: job.id == widget.selectedId,
    focusNode: _nodeFor(job.id),
    onTap: () => widget.onSelect(job.id),
    onKeyEvent: (event) => _onKey(job.id, event),
  );

  Widget _header(BuildContext context, {required bool showTechnician}) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return Container(
      decoration: BoxDecoration(
        color: ws.canvas.withValues(alpha: 0.75),
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.cardPadding,
        vertical: 2,
      ),
      child: Row(
        children: [
          _cell(
            flex: 5,
            child: _SortHeader(
              label: l10n.jobsListColumnJob,
              sort: JobsSort.job,
              active: widget.sort,
              ascending: widget.ascending,
              onTap: widget.onSort,
            ),
          ),
          _cell(
            flex: 4,
            child: _SortHeader(
              label: l10n.jobsListColumnVehicle,
              sort: JobsSort.vehicle,
              active: widget.sort,
              ascending: widget.ascending,
              onTap: widget.onSort,
            ),
          ),
          _cell(
            flex: 3,
            child: _SortHeader(
              label: l10n.jobsListColumnCustomer,
              sort: JobsSort.customer,
              active: widget.sort,
              ascending: widget.ascending,
              onTap: widget.onSort,
            ),
          ),
          if (showTechnician)
            _cell(
              flex: 3,
              child: _SortHeader(
                label: l10n.jobsListColumnTechnician,
                sort: JobsSort.technician,
                active: widget.sort,
                ascending: widget.ascending,
                onTap: widget.onSort,
              ),
            ),
          _cell(
            flex: 6,
            child: Text(
              l10n.status,
              style: ws.eyebrow.copyWith(color: ws.muted),
            ),
          ),
          _cell(
            flex: 4,
            last: true,
            child: Align(
              key: const Key('jobs-header-scheduled'),
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.jobsListColumnScheduled,
                style: ws.eyebrow.copyWith(color: ws.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell({required int flex, required Widget child, bool last = false}) =>
      Expanded(
        flex: flex,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            end: last ? 0 : context.spacing.md,
          ),
          child: child,
        ),
      );

  List<CleanJob> _sort(List<CleanJob> items) {
    final copy = List<CleanJob>.of(items);
    copy.sort((a, b) {
      if (widget.sort == JobsSort.scheduled) {
        final left = a.scheduledAt?.trim() ?? '';
        final right = b.scheduledAt?.trim() ?? '';
        if (left.isEmpty && right.isEmpty) {
          return 0;
        }
        if (left.isEmpty) {
          return 1;
        }
        if (right.isEmpty) {
          return -1;
        }
        final result = left.compareTo(right);
        return widget.ascending ? result : -result;
      }
      final result = switch (widget.sort) {
        JobsSort.job => a.reference.toLowerCase().compareTo(
          b.reference.toLowerCase(),
        ),
        JobsSort.vehicle => _vehicle(
          a,
        ).toLowerCase().compareTo(_vehicle(b).toLowerCase()),
        JobsSort.customer => a.customerName.toLowerCase().compareTo(
          b.customerName.toLowerCase(),
        ),
        JobsSort.technician => _technician(
          a,
        ).toLowerCase().compareTo(_technician(b).toLowerCase()),
        JobsSort.scheduled => 0,
      };
      return widget.ascending ? result : -result;
    });
    return copy;
  }

  String _vehicle(CleanJob job) =>
      '${job.vehicleMake} ${job.vehicleModel}'.trim();

  String _technician(CleanJob job) => job.assignedTechnicianName?.trim() ?? '';
}

class _SortHeader extends StatefulWidget {
  const _SortHeader({
    required this.label,
    required this.sort,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final JobsSort sort;
  final JobsSort active;
  final bool ascending;
  final ValueChanged<JobsSort> onTap;

  @override
  State<_SortHeader> createState() => _SortHeaderState();
}

class _SortHeaderState extends State<_SortHeader> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final selected = widget.active == widget.sort;
    return Semantics(
      button: true,
      label: widget.label,
      child: AnimatedContainer(
        duration: context.motionDuration(const Duration(milliseconds: 120)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: _focused ? Border.all(color: ws.focus, width: 2) : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => widget.onTap(widget.sort),
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: BorderRadius.circular(8),
            hoverColor: ws.surface,
            focusColor: ws.accentSoft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.xs,
                  vertical: spacing.sm,
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 2,
                        style: ws.eyebrow.copyWith(
                          color: selected ? ws.ink : ws.muted,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      SizedBox(width: spacing.xxs),
                      Icon(
                        widget.ascending ? Icons.north : Icons.south,
                        size: 12,
                        color: ws.accent,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobRow extends StatefulWidget {
  const _JobRow({
    required this.job,
    required this.staff,
    required this.showTechnician,
    required this.zebra,
    required this.selected,
    required this.focusNode,
    required this.onTap,
    required this.onKeyEvent,
    super.key,
  });

  final CleanJob job;
  final List<StaffMember>? staff;
  final bool showTechnician;
  final bool zebra;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final KeyEventResult Function(KeyEvent) onKeyEvent;

  @override
  State<_JobRow> createState() => _JobRowState();
}

class _JobRowState extends State<_JobRow> {
  bool _focused = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(covariant _JobRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocus);
      widget.focusNode.addListener(_handleFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() {
    if (mounted) {
      setState(() => _focused = widget.focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final job = widget.job;
    final Color? background = widget.selected
        ? ws.accentSoft
        : _hovered
        ? ws.canvas
        : widget.zebra
        ? ws.canvas.withValues(alpha: 0.45)
        : null;
    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: (_, event) => widget.onKeyEvent(event),
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: '${job.reference}, ${job.customerName}',
        child: AnimatedContainer(
          duration: context.motionDuration(const Duration(milliseconds: 120)),
          decoration: BoxDecoration(
            color: background,
            border: BorderDirectional(
              bottom: BorderSide(color: ws.border),
              start: widget.selected
                  ? BorderSide(color: ws.accent, width: 3)
                  : BorderSide.none,
            ),
          ),
          foregroundDecoration: _focused
              ? BoxDecoration(border: Border.all(color: ws.focus, width: 2))
              : null,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              onHover: (value) => setState(() => _hovered = value),
              canRequestFocus: false,
              hoverColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: ws.cardPadding,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(end: spacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                job.reference,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: ws.bodyStrong.copyWith(
                                  color: ws.ink,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _template(context, job),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: ws.meta.copyWith(color: ws.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(end: spacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _vehicle(job),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ws.body.copyWith(color: ws.ink),
                              ),
                              if ((job.vehiclePlate ?? '').trim().isNotEmpty)
                                Text(
                                  job.vehiclePlate!.trim(),
                                  maxLines: 1,
                                  textDirection: TextDirection.ltr,
                                  style: ws.meta.copyWith(color: ws.muted),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(end: spacing.md),
                          child: Text(
                            job.customerName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ws.body.copyWith(color: ws.ink),
                          ),
                        ),
                      ),
                      if (widget.showTechnician)
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: spacing.md,
                            ),
                            child: Text(
                              jobTechnicianName(l10n, job, widget.staff),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ws.meta.copyWith(
                                color:
                                    job.assignedTechnicianName == null ||
                                        job.assignedTechnicianName!.isEmpty
                                    ? ws.muted
                                    : ws.ink,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(end: spacing.md),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: JobStatusBadge(status: job.status),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Align(
                          key: Key('job-scheduled-${job.id}'),
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            _schedule(context, job),
                            maxLines: 2,
                            textDirection: TextDirection.ltr,
                            style: ws.meta.copyWith(
                              color: ws.muted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _vehicle(CleanJob job) {
  final title = '${job.vehicleMake} ${job.vehicleModel}'.trim();
  return title.isEmpty ? job.customerName : title;
}

String _template(BuildContext context, CleanJob job) {
  final name = localizedText(
    context,
    en: job.templateNameEn,
    ar: job.templateNameAr,
  );
  if (name.trim().isEmpty) {
    return AppLocalizations.of(context).commonNotAvailable;
  }
  return job.templateVersionNo == null
      ? name
      : '$name · v${job.templateVersionNo}';
}

String _schedule(BuildContext context, CleanJob job) {
  final label = pinDigits(formatInstant(context, job.scheduledAt));
  return label.isEmpty ? '—' : label;
}
