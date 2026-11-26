import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'fieldwork_ui.dart';

/// A resolved fact about the current item (evidence owed, measurement, prior
/// result). The page resolves the copy; this widget only lays it out.
class FieldworkFact {
  const FieldworkFact({
    required this.label,
    required this.icon,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final IconData icon;
  final StatusTone tone;
}

/// One category of the run sheet.
class WorkspaceStation {
  const WorkspaceStation({
    required this.code,
    required this.label,
    required this.icon,
    required this.done,
    required this.total,
  });

  final String code;
  final String label;
  final IconData icon;
  final int done;
  final int total;

  bool get complete => total > 0 && done >= total;
}

/// The item the hub is currently pointing at.
class WorkspaceFocus {
  const WorkspaceFocus({
    required this.number,
    required this.total,
    required this.categoryLabel,
    required this.label,
    required this.instruction,
    required this.spec,
    required this.safety,
    required this.safetyLabel,
    this.facts = const <FieldworkFact>[],
    this.resultLabel,
    this.resultTone = StatusTone.neutral,
  });

  final int number;
  final int total;
  final String categoryLabel;
  final String label;
  final String instruction;
  final String spec;
  final bool safety;
  final String safetyLabel;
  final List<FieldworkFact> facts;

  /// Present when the current item already carries a served result.
  final String? resultLabel;
  final StatusTone resultTone;
}

/// One row of the up-next list.
class WorkspaceNext {
  const WorkspaceNext({
    required this.itemCode,
    required this.number,
    required this.label,
    required this.metaLabel,
    required this.safety,
  });

  final String itemCode;
  final int number;
  final String label;
  final String metaLabel;
  final bool safety;
}

/// One row of the selected section's full item list.
class WorkspaceSectionItem {
  const WorkspaceSectionItem({
    required this.itemCode,
    required this.number,
    required this.label,
    required this.statusLabel,
    required this.statusTone,
    required this.safety,
    this.current = false,
  });

  final String itemCode;
  final int number;
  final String label;
  final String statusLabel;
  final StatusTone statusTone;
  final bool safety;

  /// The item the hub is pointing at.
  final bool current;
}

/// Job identity and progress for the top bar.
class WorkspaceHeader {
  const WorkspaceHeader({
    required this.title,
    required this.reference,
    required this.vehicle,
    required this.plate,
    required this.statusLabel,
    required this.statusTone,
    required this.slotLabel,
    required this.done,
    required this.total,
    this.syncLabel,
    this.syncTone = StatusTone.neutral,
    this.syncIcon = Icons.cloud_done_outlined,
  });

  final String title;
  final String reference;
  final String vehicle;
  final String plate;
  final String statusLabel;
  final StatusTone statusTone;
  final String slotLabel;
  final int done;
  final int total;
  final String? syncLabel;
  final StatusTone syncTone;
  final IconData syncIcon;

  double get progress => total <= 0 ? 0 : done / total;
}

/// Every string the hub needs, resolved by the page wrapper.
class WorkspaceCopy {
  const WorkspaceCopy({
    required this.runSheetLabel,
    required this.upNextLabel,
    required this.upNextHeading,
    required this.upNextSubheading,
    required this.upNextEmpty,
    required this.summaryLabel,
    required this.openLabel,
    required this.allAnsweredTitle,
    required this.allAnsweredBody,
    required this.noCategoriesTitle,
    required this.noCategoriesBody,
    required this.noItemsTitle,
    required this.noItemsBody,
    required this.noItemsHint,
    required this.stepSemanticLabel,
    required this.progressSemanticLabel,
    required this.safetyLabel,
  });

  final String runSheetLabel;
  final String upNextLabel;
  final String upNextHeading;
  final String upNextSubheading;
  final String upNextEmpty;
  final String summaryLabel;
  final String openLabel;
  final String allAnsweredTitle;
  final String allAnsweredBody;
  final String noCategoriesTitle;
  final String noCategoriesBody;
  final String noItemsTitle;
  final String noItemsBody;
  final String noItemsHint;
  final String stepSemanticLabel;
  final String progressSemanticLabel;

  /// Words for the safety-critical shield in the section list.
  final String safetyLabel;
}

/// Direction A — Fieldwork hub.
///
/// The run sheet shows position without becoming a table, the focus card holds
/// the current item, and the section list below it holds every item of the
/// selected section. It never saves: the primary opens the current item, and
/// the item screen owns the verdict.
class FieldworkWorkspace extends StatelessWidget {
  const FieldworkWorkspace({
    required this.copy,
    required this.header,
    required this.stations,
    required this.ticks,
    required this.tickSemanticLabel,
    required this.upNext,
    required this.sectionItems,
    required this.readOnly,
    required this.onBack,
    required this.onStation,
    required this.onTick,
    required this.onOpenCurrent,
    required this.onOpenItem,
    required this.onOpenSectionItem,
    required this.onSummary,
    this.focus,
    this.selectedStationCode,
    this.sectionEmpty = false,
    this.banner,
    this.headerTrailing,
    super.key,
  });

  final WorkspaceCopy copy;
  final WorkspaceHeader header;
  final List<WorkspaceStation> stations;
  final List<FieldworkTick> ticks;
  final String tickSemanticLabel;
  final WorkspaceFocus? focus;

  /// The few unchecked items after the current one; the compact layout's list.
  final List<WorkspaceNext> upNext;

  /// Every item of the selected section; the wide layout's list under the card.
  final List<WorkspaceSectionItem> sectionItems;
  final bool readOnly;
  final VoidCallback onBack;
  final ValueChanged<String> onStation;
  final ValueChanged<String> onTick;
  final VoidCallback onOpenCurrent;
  final ValueChanged<WorkspaceNext> onOpenItem;
  final ValueChanged<WorkspaceSectionItem> onOpenSectionItem;
  final VoidCallback onSummary;
  final String? selectedStationCode;

  /// True when the selected run-sheet section has no items at all.
  final bool sectionEmpty;
  final Widget? banner;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return Column(
        children: [
          _TopBar(
            header: header,
            wide: false,
            progressLabel: copy.progressSemanticLabel,
            onBack: onBack,
            trailing: headerTrailing,
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(20),
                  child: EmptyState(
                    title: copy.noCategoriesTitle,
                    body: copy.noCategoriesBody,
                    icon: Icons.checklist_rounded,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= FieldworkMetrics.railBreakpoint;
        final selected = _selectedStation();
        return Column(
          children: [
            _TopBar(
              header: header,
              wide: wide,
              progressLabel: copy.progressSemanticLabel,
              onBack: onBack,
              trailing: headerTrailing,
            ),
            if (!wide)
              _CompactStepper(
                copy: copy,
                station: selected,
                ticks: ticks,
                tickSemanticLabel: tickSemanticLabel,
                onTick: onTick,
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide)
                    SizedBox(
                      width: FieldworkMetrics.runSheetWidth,
                      child: _RunSheet(
                        copy: copy,
                        header: header,
                        stations: stations,
                        selectedCode: selected?.code,
                        onStation: onStation,
                      ),
                    ),
                  Expanded(
                    child: wide
                        ? _WideBody(
                            banner: banner,
                            readOnly: readOnly,
                            copy: copy,
                            focus: focus,
                            sectionEmpty: sectionEmpty,
                            section: selected,
                            sectionItems: sectionItems,
                            onOpenCurrent: onOpenCurrent,
                            onOpenSectionItem: onOpenSectionItem,
                            onSummary: onSummary,
                          )
                        : _NarrowBody(
                            banner: banner,
                            copy: copy,
                            focus: focus,
                            upNext: upNext,
                            readOnly: readOnly,
                            sectionEmpty: sectionEmpty,
                            onOpenCurrent: onOpenCurrent,
                            onOpenItem: onOpenItem,
                            onSummary: onSummary,
                          ),
                  ),
                ],
              ),
            ),
            if (!wide)
              _MobileDock(
                header: header,
                copy: copy,
                primaryLabel: readOnly ? copy.summaryLabel : copy.openLabel,
                primaryIcon: focus == null || readOnly
                    ? Icons.fact_check_outlined
                    : Icons.arrow_forward_rounded,
                onPrimary: focus == null || readOnly
                    ? onSummary
                    : onOpenCurrent,
              ),
          ],
        );
      },
    );
  }

  WorkspaceStation? _selectedStation() {
    if (stations.isEmpty) {
      return null;
    }
    final code = selectedStationCode;
    if (code != null) {
      for (final station in stations) {
        if (station.code == code) {
          return station;
        }
      }
    }
    for (final station in stations) {
      if (station.done < station.total) {
        return station;
      }
    }
    return stations.first;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.header,
    required this.wide,
    required this.progressLabel,
    required this.onBack,
    this.trailing,
  });

  final WorkspaceHeader header;
  final bool wide;
  final String progressLabel;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest,
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(wide ? 16 : 10, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: FieldworkIconButton(
              icon: rtl
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
              semanticLabel: backLabel,
              onPressed: onBack,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  header.title,
                  maxLines: wide ? 2 : 1,
                  overflow: wide ? null : TextOverflow.ellipsis,
                  style: fieldworkText(
                    context,
                    17,
                    weight: FontWeight.w800,
                    height: 21,
                    tracking: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  header.vehicle,
                  maxLines: 2,
                  style: fieldworkText(
                    context,
                    13,
                    weight: FontWeight.w700,
                    height: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (header.plate.trim().isNotEmpty)
                      _Plate(label: header.plate),
                    if (header.reference.trim().isNotEmpty)
                      Text(
                        header.reference,
                        textDirection: TextDirection.ltr,
                        style: fieldworkNumber(
                          context,
                          12,
                          weight: FontWeight.w600,
                          height: 16,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    if (header.slotLabel.trim().isNotEmpty)
                      _Meta(
                        icon: Icons.schedule_rounded,
                        label: header.slotLabel,
                      ),
                    FieldworkPill(
                      label: header.statusLabel,
                      tone: header.statusTone,
                      dense: true,
                    ),
                    if (header.syncLabel != null)
                      FieldworkPill(
                        label: header.syncLabel!,
                        tone: header.syncTone,
                        icon: header.syncIcon,
                        dense: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: _ProgressPill(
              header: header,
              showBar: wide,
              semanticLabel: progressLabel,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 7,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Text(
        label,
        textDirection: TextDirection.ltr,
        style: fieldworkNumber(
          context,
          11.5,
          weight: FontWeight.w700,
          height: 15,
          tracking: 0.4,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          textDirection: TextDirection.ltr,
          style: fieldworkNumber(
            context,
            12,
            weight: FontWeight.w600,
            height: 16,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.header,
    required this.showBar,
    required this.semanticLabel,
  });

  final WorkspaceHeader header;
  final bool showBar;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Container(
        height: 34,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(FieldworkMetrics.chipRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${header.done}',
                    style: fieldworkNumber(context, 14, height: 18),
                  ),
                  TextSpan(
                    text: '/${header.total}',
                    style: fieldworkNumber(
                      context,
                      11.5,
                      weight: FontWeight.w700,
                      height: 15,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              textDirection: TextDirection.ltr,
            ),
            if (showBar) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: FieldworkBar(value: header.progress, height: 4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactStepper extends StatelessWidget {
  const _CompactStepper({
    required this.copy,
    required this.station,
    required this.ticks,
    required this.tickSemanticLabel,
    required this.onTick,
  });

  final WorkspaceCopy copy;
  final WorkspaceStation? station;
  final List<FieldworkTick> ticks;
  final String tickSemanticLabel;
  final ValueChanged<String> onTick;

  @override
  Widget build(BuildContext context) {
    if (ticks.isEmpty) {
      return const SizedBox.shrink();
    }
    final current = station;
    return Container(
      color: context.colors.surfaceLowest,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  copy.runSheetLabel,
                  maxLines: 2,
                  style: fieldworkEyebrow(context),
                ),
              ),
              if (current != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${current.label} · ${current.done}/${current.total}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: fieldworkNumber(
                      context,
                      11.5,
                      weight: FontWeight.w700,
                      height: 15,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          FieldworkTicks(
            ticks: ticks,
            semanticLabel: tickSemanticLabel,
            onTap: (tick) => onTick(tick.categoryCode),
          ),
        ],
      ),
    );
  }
}

class _RunSheet extends StatelessWidget {
  const _RunSheet({
    required this.copy,
    required this.header,
    required this.stations,
    required this.selectedCode,
    required this.onStation,
  });

  final WorkspaceCopy copy;
  final WorkspaceHeader header;
  final List<WorkspaceStation> stations;
  final String? selectedCode;
  final ValueChanged<String> onStation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest,
        border: BorderDirectional(
          end: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.runSheetLabel, style: fieldworkEyebrow(context)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${header.done}',
                            style: fieldworkNumber(context, 38, height: 42),
                          ),
                          TextSpan(
                            text: ' / ${header.total}',
                            style: fieldworkNumber(
                              context,
                              14,
                              weight: FontWeight.w700,
                              height: 18,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FieldworkBar(
                  value: header.progress,
                  height: 6,
                  semanticLabel: copy.progressSemanticLabel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: stations.isEmpty
                ? Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                    child: Text(
                      copy.noCategoriesBody,
                      style: fieldworkText(
                        context,
                        12.5,
                        height: 18,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      2,
                      12,
                      12,
                    ),
                    itemCount: stations.length,
                    itemBuilder: (context, index) => _Station(
                      station: stations[index],
                      selected: stations[index].code == selectedCode,
                      onTap: () => onStation(stations[index].code),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Station extends StatelessWidget {
  const _Station({
    required this.station,
    required this.selected,
    required this.onTap,
  });

  final WorkspaceStation station;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = station.total <= 0 ? 0.0 : station.done / station.total;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 2),
      child: FieldworkPress(
        onTap: onTap,
        selected: selected,
        semanticLabel: '${station.label} · ${station.done}/${station.total}',
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 10, 9),
          decoration: BoxDecoration(
            color: selected ? context.brand.container : Colors.transparent,
            borderRadius: BorderRadius.circular(FieldworkMetrics.controlRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? context.brand.ink
                      : station.complete
                      ? context.statusColors.success.background
                      : colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  station.complete && !selected
                      ? Icons.check_rounded
                      : station.icon,
                  size: 16,
                  color: selected
                      ? colors.surfaceLowest
                      : station.complete
                      ? context.statusColors.success.foreground
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      station.label,
                      maxLines: 2,
                      style: fieldworkText(
                        context,
                        13,
                        weight: FontWeight.w700,
                        height: 17,
                        tracking: -0.1,
                        color: selected
                            ? context.brand.onContainer
                            : colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${station.done}/${station.total}',
                          textDirection: TextDirection.ltr,
                          style: fieldworkNumber(
                            context,
                            11,
                            weight: FontWeight.w700,
                            height: 14,
                            color: selected
                                ? context.brand.onContainer
                                : colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (station.total > 0)
                          Expanded(
                            child: FieldworkBar(
                              value: progress,
                              height: 3,
                              color: station.complete
                                  ? context.statusColors.success.foreground
                                  : selected
                                  ? context.brand.ink
                                  : colors.outline,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideBody extends StatelessWidget {
  const _WideBody({
    required this.banner,
    required this.readOnly,
    required this.copy,
    required this.focus,
    required this.sectionEmpty,
    required this.section,
    required this.sectionItems,
    required this.onOpenCurrent,
    required this.onOpenSectionItem,
    required this.onSummary,
  });

  final Widget? banner;
  final bool readOnly;
  final WorkspaceCopy copy;
  final WorkspaceFocus? focus;
  final bool sectionEmpty;
  final WorkspaceStation? section;
  final List<WorkspaceSectionItem> sectionItems;
  final VoidCallback onOpenCurrent;
  final ValueChanged<WorkspaceSectionItem> onOpenSectionItem;
  final VoidCallback onSummary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FieldworkMetrics.focusMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (banner != null) ...[banner!, const SizedBox(height: 12)],
              if (sectionEmpty)
                _SectionEmpty(copy: copy)
              else if (focus == null)
                _AllAnswered(copy: copy, showAction: true, onSummary: onSummary)
              else
                _FocusCard(
                  copy: copy,
                  focus: focus!,
                  readOnly: readOnly,
                  showActions: true,
                  showSummaryLink: false,
                  primaryLabel: readOnly ? copy.summaryLabel : copy.openLabel,
                  onPrimary: readOnly ? onSummary : onOpenCurrent,
                  onSummary: onSummary,
                ),
              if (sectionItems.isNotEmpty) ...[
                const SizedBox(height: 22),
                _SectionList(
                  title: section?.label ?? copy.upNextHeading,
                  meta: copy.upNextSubheading,
                  safetyLabel: copy.safetyLabel,
                  items: sectionItems,
                  readOnly: readOnly,
                  onOpen: onOpenSectionItem,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NarrowBody extends StatelessWidget {
  const _NarrowBody({
    required this.banner,
    required this.copy,
    required this.focus,
    required this.upNext,
    required this.readOnly,
    required this.sectionEmpty,
    required this.onOpenCurrent,
    required this.onOpenItem,
    required this.onSummary,
  });

  final Widget? banner;
  final WorkspaceCopy copy;
  final WorkspaceFocus? focus;
  final List<WorkspaceNext> upNext;
  final bool readOnly;
  final bool sectionEmpty;
  final VoidCallback onOpenCurrent;
  final ValueChanged<WorkspaceNext> onOpenItem;
  final VoidCallback onSummary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 24),
      children: [
        if (banner != null) ...[banner!, const SizedBox(height: 12)],
        if (sectionEmpty)
          _SectionEmpty(copy: copy)
        else if (focus == null)
          _AllAnswered(copy: copy, showAction: false, onSummary: onSummary)
        else
          _FocusCard(
            copy: copy,
            focus: focus!,
            readOnly: readOnly,
            showActions: false,
            showSummaryLink: !readOnly,
            primaryLabel: copy.openLabel,
            onPrimary: onOpenCurrent,
            onSummary: onSummary,
          ),
        if (!sectionEmpty && focus != null && upNext.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(copy.upNextLabel, style: fieldworkEyebrow(context)),
          const SizedBox(height: 6),
          for (final item in upNext)
            _NextRow(
              item: item,
              readOnly: readOnly,
              onTap: () => onOpenItem(item),
            ),
        ] else if (!sectionEmpty && focus != null) ...[
          const SizedBox(height: 16),
          Text(
            copy.upNextEmpty,
            style: fieldworkText(
              context,
              12.5,
              height: 18,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// The selected section in full: one surface, hairline rows, every item of the
/// category with its served status. Not a table and not a card-in-card.
class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.title,
    required this.meta,
    required this.safetyLabel,
    required this.items,
    required this.readOnly,
    required this.onOpen,
  });

  final String title;
  final String meta;
  final String safetyLabel;
  final List<WorkspaceSectionItem> items;
  final bool readOnly;
  final ValueChanged<WorkspaceSectionItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                style: fieldworkText(
                  context,
                  16,
                  weight: FontWeight.w800,
                  height: 21,
                  tracking: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              meta,
              textDirection: TextDirection.ltr,
              style: fieldworkNumber(
                context,
                12,
                weight: FontWeight.w700,
                height: 16,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceLowest,
            borderRadius: BorderRadius.circular(FieldworkMetrics.cardRadius),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(FieldworkMetrics.cardRadius),
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  _SectionRow(
                    item: items[index],
                    safetyLabel: safetyLabel,
                    readOnly: readOnly,
                    onTap: () => onOpen(items[index]),
                  ),
                  if (index != items.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 14,
                      endIndent: 14,
                      color: colors.outlineVariant,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.item,
    required this.safetyLabel,
    required this.readOnly,
    required this.onTap,
  });

  final WorkspaceSectionItem item;
  final String safetyLabel;
  final bool readOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final tone = context.statusColors.forTone(item.statusTone);
    final current = item.current;
    final content = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 10, 9),
      decoration: BoxDecoration(
        color: current ? context.brand.container : Colors.transparent,
        border: BorderDirectional(
          start: BorderSide(
            color: current ? context.brand.ink : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${item.number}'.padLeft(2, '0'),
              textDirection: TextDirection.ltr,
              style: fieldworkNumber(
                context,
                12,
                weight: FontWeight.w800,
                height: 16,
                color: current
                    ? context.brand.onContainer
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  maxLines: 2,
                  style: fieldworkText(
                    context,
                    13.5,
                    weight: FontWeight.w700,
                    height: 18,
                    tracking: -0.1,
                    color: current
                        ? context.brand.onContainer
                        : colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tone.foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        item.statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fieldworkText(
                          context,
                          11,
                          weight: FontWeight.w600,
                          height: 14,
                          color: current
                              ? context.brand.onContainer
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (item.safety) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: item.statusLabel,
              excludeFromSemantics: true,
              child: Icon(
                Icons.health_and_safety_outlined,
                size: 17,
                color: context.statusColors.danger.foreground,
              ),
            ),
          ],
          if (!readOnly) ...[
            const SizedBox(width: 6),
            Icon(
              rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
    if (readOnly) {
      return content;
    }
    return FieldworkPress(
      onTap: onTap,
      radius: 0,
      selected: current,
      semanticLabel:
          '${item.number}. ${item.label} · ${item.statusLabel}'
          '${item.safety ? ' · $safetyLabel' : ''}',
      child: content,
    );
  }
}

class _NextRow extends StatelessWidget {
  const _NextRow({
    required this.item,
    required this.readOnly,
    required this.onTap,
  });

  final WorkspaceNext item;
  final bool readOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return FieldworkPress(
      onTap: readOnly ? null : onTap,
      semanticLabel: '${item.number}. ${item.label} · ${item.metaLabel}',
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 9, 6, 9),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.number}'.padLeft(2, '0'),
                textDirection: TextDirection.ltr,
                style: fieldworkNumber(
                  context,
                  11,
                  weight: FontWeight.w800,
                  height: 14,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    maxLines: 2,
                    style: fieldworkText(
                      context,
                      12.5,
                      weight: FontWeight.w700,
                      height: 16,
                      tracking: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: item.safety
                              ? context.statusColors.danger.foreground
                              : context.colors.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item.metaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: fieldworkText(
                            context,
                            11,
                            height: 14,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!readOnly) ...[
              const SizedBox(width: 4),
              Icon(
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 18,
                color: context.colors.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.copy,
    required this.focus,
    required this.readOnly,
    required this.showActions,
    required this.showSummaryLink,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onSummary,
  });

  final WorkspaceCopy copy;
  final WorkspaceFocus focus;
  final bool readOnly;
  final bool showActions;
  final bool showSummaryLink;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSummary;

  @override
  Widget build(BuildContext context) {
    return FieldworkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldworkTint(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 18),
            child: FieldworkHero(
              eyebrowNumber: '${focus.number} / ${focus.total}',
              eyebrow: '· ${focus.categoryLabel}',
              label: focus.label,
              instruction: focus.instruction,
              spec: focus.spec,
              safety: focus.safety,
              safetyLabel: focus.safetyLabel,
              numberLabel: '${focus.number}'.padLeft(2, '0'),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (focus.resultLabel != null) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FieldworkPill(
                      label: focus.resultLabel!,
                      tone: focus.resultTone,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (focus.facts.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final fact in focus.facts)
                        FieldworkPill(
                          label: fact.label,
                          tone: fact.tone,
                          icon: fact.icon,
                          dense: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (showActions)
                  Row(
                    children: [
                      Expanded(
                        child: FieldworkButton(
                          label: primaryLabel,
                          icon: readOnly
                              ? Icons.fact_check_outlined
                              : Icons.arrow_forward_rounded,
                          expand: true,
                          onPressed: onPrimary,
                        ),
                      ),
                      if (!readOnly) ...[
                        const SizedBox(width: 10),
                        FieldworkButton(
                          label: copy.summaryLabel,
                          variant: FieldworkButtonVariant.ghost,
                          onPressed: onSummary,
                        ),
                      ],
                    ],
                  )
                else if (showSummaryLink)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SizedBox(
                      width: 140,
                      child: FieldworkButton(
                        label: copy.summaryLabel,
                        icon: Icons.fact_check_outlined,
                        variant: FieldworkButtonVariant.text,
                        height: FieldworkMetrics.secondaryHeight,
                        expand: true,
                        onPressed: onSummary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.copy});

  final WorkspaceCopy copy;

  @override
  Widget build(BuildContext context) {
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.checklist_rounded,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            copy.noItemsTitle,
            style: fieldworkText(
              context,
              18,
              weight: FontWeight.w800,
              height: 24,
              tracking: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            copy.noItemsBody,
            style: fieldworkText(
              context,
              13.5,
              height: 20,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            copy.noItemsHint,
            style: fieldworkText(
              context,
              12,
              height: 17,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllAnswered extends StatelessWidget {
  const _AllAnswered({
    required this.copy,
    required this.showAction,
    required this.onSummary,
  });

  final WorkspaceCopy copy;
  final bool showAction;
  final VoidCallback onSummary;

  @override
  Widget build(BuildContext context) {
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.statusColors.success.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_rounded,
              color: context.statusColors.success.foreground,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            copy.allAnsweredTitle,
            style: fieldworkText(
              context,
              20,
              weight: FontWeight.w800,
              height: 26,
              tracking: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            copy.allAnsweredBody,
            style: fieldworkText(
              context,
              13.5,
              height: 20,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (showAction) ...[
            const SizedBox(height: 16),
            FieldworkButton(
              label: copy.summaryLabel,
              icon: Icons.fact_check_outlined,
              onPressed: onSummary,
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileDock extends StatelessWidget {
  const _MobileDock({
    required this.header,
    required this.copy,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
  });

  final WorkspaceHeader header;
  final WorkspaceCopy copy;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            FieldworkRing(
              value: header.progress,
              center: '${header.done}',
              sub: '/${header.total}',
              semanticLabel: copy.progressSemanticLabel,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FieldworkButton(
                label: primaryLabel,
                icon: primaryIcon,
                expand: true,
                onPressed: onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
