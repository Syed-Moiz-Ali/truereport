import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/shared/technician_intl.dart';
import 'package:technician_app/src/shared/technician_kit.dart';
import 'package:technician_app/src/ui_helpers.dart';

/// Screen 11. Dense mechanical checklist rebuilt on the Figma card rhythm using
/// the pinned checklist items and the existing result/severity/note fields.
class DenseMechanicalView extends StatefulWidget {
  const DenseMechanicalView({
    required this.checklist,
    required this.onResult,
    required this.onSaveItem,
    required this.onOpenItem,
    required this.onContinue,
    this.onBack,
    this.onProfile,
    this.finalized = false,
    this.busyItemId,
    this.initialExpandedId,
    this.focusedItemId,
    super.key,
  });

  final InspectionChecklist checklist;
  final void Function(InspectionItem item, String result) onResult;
  final Future<void> Function(
    InspectionItem item,
    String result,
    String? severity,
    String note,
  )
  onSaveItem;
  final ValueChanged<InspectionItem> onOpenItem;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final bool finalized;
  final String? busyItemId;
  final String? initialExpandedId;
  final String? focusedItemId;

  static const _primary = <String>[
    'NO_ISSUE_OBSERVED',
    'ATTENTION_RECOMMENDED',
    'DEFECT_FOUND',
  ];
  static const _secondary = <String>[
    'NOT_CHECKED',
    'COULD_NOT_VERIFY',
    'NOT_APPLICABLE',
  ];
  static const _icons = <String>[
    '1_8241',
    '1_8255',
    '1_8288',
    '1_8309',
    '1_8323',
    '1_8331',
  ];

  static (double, double) iconDimensions(String id) => switch (id) {
        '1_8241' => (16.5, 16.5),
        '1_8255' => (18.33, 18.33),
        '1_8288' => (14.67, 17.42),
        '1_8309' => (18.42, 18.33),
        '1_8323' => (14.67, 18.33),
        _ => (17.0, 17.0),
      };

  @override
  State<DenseMechanicalView> createState() => _DenseMechanicalViewState();
}

class _DenseMechanicalViewState extends State<DenseMechanicalView> {
  String? _expandedId;
  String? _focusedId;
  final Map<String, TextEditingController> _notes = {};

  @override
  void initState() {
    super.initState();
    _expandedId = widget.initialExpandedId;
    _focusedId = widget.focusedItemId;
  }

  @override
  void dispose() {
    for (final controller in _notes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _noteFor(InspectionItem item) {
    return _notes.putIfAbsent(
      item.inspectionItemId,
      () => TextEditingController(text: item.assessment?.note ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final checklist = widget.checklist;
    final derivedInitials = fxInitials(
      checklist.job.assignedTechnicianName ?? '',
    );
    final category = checklist.items.isEmpty
        ? l10n.checklist
        : _categoryOf(checklist.items.first, context);
    return Scaffold(
      backgroundColor: Fx.white,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              _M.gutter,
              80,
              _M.gutter,
              116,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Fx.text(
                            12,
                            16,
                            FontWeight.w600,
                            0.6,
                            color: Fx.outline,
                          ),
                        ),
                        Text(
                          '${formatCountLocalized(checklist.completed, localeName)} ${l10n.technicianChecksDone} / ${formatCountLocalized(checklist.total, localeName)}',
                          style: Fx.body13.copyWith(color: Fx.muted),
                        ),
                      ],
                    ),
                  ),
                  // Reference stays LTR in RTL locales; no visual change.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: F2bStatusPill(
                      height: 26,
                      label: checklist.job.reference,
                      background: Fx.container,
                      foreground: Fx.ink,
                      dot: Fx.emerald,
                      dotSize: 8,
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w600,
                        0.275,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _M.gutter),
              for (var index = 0; index < checklist.items.length; index++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: _M.gutter),
                  child: _ItemCard(
                    item: checklist.items[index],
                    iconId: DenseMechanicalView
                        ._icons[index % DenseMechanicalView._icons.length],
                    expanded:
                        _expandedId == checklist.items[index].inspectionItemId,
                    focused:
                        _focusedId == checklist.items[index].inspectionItemId,
                    finalized: widget.finalized,
                    busy:
                        widget.busyItemId ==
                        checklist.items[index].inspectionItemId,
                    noteController: _noteFor(checklist.items[index]),
                    onExpand: () => setState(() {
                      _expandedId =
                          _expandedId == checklist.items[index].inspectionItemId
                          ? null
                          : checklist.items[index].inspectionItemId;
                    }),
                    onResult: (code) =>
                        widget.onResult(checklist.items[index], code),
                    onSave: (result, severity, note) => widget.onSaveItem(
                      checklist.items[index],
                      result,
                      severity,
                      note,
                    ),
                    onOpen: () => widget.onOpenItem(checklist.items[index]),
                  ),
                ),
            ],
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            // Header-level focus frame for the FxHeader back button; borderless
            // when unfocused so the 1.0x geometry is unchanged.
            child: F2bFocusFrame(
              borderRadius: BorderRadius.zero,
              child: FxHeader(
                title: l10n.checklist,
                showBack: widget.onBack != null,
                leading: widget.onBack != null
                    ? Semantics(
                        button: true,
                        label: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        child: InkResponse(
                          onTap: widget.onBack,
                          radius: 24,
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: FxIcon(
                                id: '1_8343',
                                width: 11.77,
                                height: 20,
                                color: Fx.ink,
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
                titleInset: 4,
                actions: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: F2bFocusFrame(
                      borderRadius: BorderRadius.circular(Fx.pillRadius),
                      child: FxProfileButton(
                        initials: derivedInitials.isEmpty
                            ? 'TR'
                            : derivedInitials,
                        iconId: '1_8348',
                        onPressed: widget.onProfile,
                        semanticLabel: l10n.technicianProfileTitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(
                _M.gutter,
                _M.gutter,
                _M.gutter,
                _M.gutter,
              ),
              decoration: const BoxDecoration(gradient: F2b.fadeGradient),
              child: SafeArea(
                top: false,
                child: F2bFocusFrame(
                  child: FxButton(
                    label: l10n.reviewAndFinalize,
                    onPressed: widget.finalized ? null : widget.onContinue,
                    icon: const FxIcon(
                      id: '1_8335',
                      size: 20.17,
                      color: Fx.white,
                    ),
                    trailingIcon: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryOf(InspectionItem item, BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? item.categoryLabelAr
      : item.categoryLabelEn;
}

class _ItemCard extends StatefulWidget {
  const _ItemCard({
    required this.item,
    required this.iconId,
    required this.expanded,
    required this.focused,
    required this.finalized,
    required this.busy,
    required this.noteController,
    required this.onExpand,
    required this.onResult,
    required this.onSave,
    required this.onOpen,
  });

  final InspectionItem item;
  final String iconId;
  final bool expanded;
  final bool focused;
  final bool finalized;
  final bool busy;
  final TextEditingController noteController;
  final VoidCallback onExpand;
  final ValueChanged<String> onResult;
  final Future<void> Function(String result, String? severity, String note)
  onSave;
  final VoidCallback onOpen;

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  String? _severity;
  String? _result;
  final FocusNode _headerFocus = FocusNode();
  bool _headerFocused = false;

  @override
  void initState() {
    super.initState();
    _result = widget.item.assessment?.resultCode;
    _severity = widget.item.assessment?.severityCode;
    _headerFocus.addListener(_handleHeaderFocus);
  }

  void _handleHeaderFocus() {
    if (mounted && _headerFocused != _headerFocus.hasFocus) {
      setState(() => _headerFocused = _headerFocus.hasFocus);
    }
  }

  @override
  void didUpdateWidget(covariant _ItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.assessment?.resultCode !=
        widget.item.assessment?.resultCode) {
      _result = widget.item.assessment?.resultCode;
    }
    if (oldWidget.item.assessment?.severityCode !=
        widget.item.assessment?.severityCode) {
      _severity = widget.item.assessment?.severityCode;
    }
  }

  @override
  void dispose() {
    _headerFocus
      ..removeListener(_handleHeaderFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = widget.item;
    final result = _result;
    final primaryIndex = DenseMechanicalView._primary.indexOf(result ?? '');
    final secondaryIndex = DenseMechanicalView._secondary.indexOf(result ?? '');
    final defect =
        result == 'DEFECT_FOUND' || result == 'ATTENTION_RECOMMENDED';
    final label = Localizations.localeOf(context).languageCode == 'ar'
        ? item.labelAr
        : item.labelEn;
    final instruction = Localizations.localeOf(context).languageCode == 'ar'
        ? item.instructionAr
        : item.instructionEn;
    final done = result != null;

    // The whole card is no longer the tap target: only the header expands,
    // so inner fields and buttons keep their own gestures. The header row is
    // 60 px tall, giving every state icon an invisible >= 48 dp hit area with
    // no visual change; the focus ring appears on keyboard focus only.
    return FxCard(
      radius: 32,
      padding: const EdgeInsets.all(_M.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: !widget.finalized,
            expanded: widget.expanded,
            label: label,
            child: FocusableActionDetector(
              enabled: !widget.finalized,
              focusNode: _headerFocus,
              mouseCursor: widget.finalized
                  ? MouseCursor.defer
                  : SystemMouseCursors.click,
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    widget.onExpand();
                    return null;
                  },
                ),
              },
              child: GestureDetector(
                onTap: widget.finalized ? null : widget.onExpand,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Fx.tileRadius),
                    border: _headerFocused
                        ? Border.all(color: Fx.deepGreen, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Fx.container,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: FxIcon(
                            id: widget.iconId,
                            width: DenseMechanicalView.iconDimensions(
                              widget.iconId,
                            ).$1,
                            height: DenseMechanicalView.iconDimensions(
                              widget.iconId,
                            ).$2,
                            color: Fx.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Fx.text(
                                18,
                                24,
                                FontWeight.w700,
                                -0.45,
                                color: Fx.ink,
                              ),
                            ),
                            if (instruction.isNotEmpty)
                              Text(
                                instruction,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Fx.text(
                                  13,
                                  18,
                                  FontWeight.w400,
                                  0,
                                  color: Fx.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: _M.gapSmall),
                      // Covered by the header semantics above; the row itself
                      // is the >= 48 dp hit area for these sub-48 visuals.
                      ExcludeSemantics(
                        child: widget.expanded
                            ? Container(
                                height: 22,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9E7ED),
                                  borderRadius: BorderRadius.circular(
                                    Fx.pillRadius,
                                  ),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: Fx.text(
                                    11,
                                    14,
                                    FontWeight.w700,
                                    0.55,
                                    color: const Color(0xFF3C4A42),
                                  ),
                                ),
                              )
                            : done
                                ? Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: F2b.emeraldWash,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: FxIcon(
                                        id: '1_8249',
                                        size: 16.67,
                                        color: Fx.emerald,
                                      ),
                                    ),
                                  )
                                : widget.focused
                                    ? Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          color: Fx.container,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: FxIcon(
                                            id: '1_8296',
                                            size: 16.67,
                                            color: Fx.outline,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          color: Fx.container,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: FxIcon(
                                            id: '1_8317',
                                            size: 10,
                                            color: Fx.muted,
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
          if (widget.focused && !widget.expanded) ...[
            const SizedBox(height: 14),
            F2bSegmented(
              height: 36,
              optionHeight: 28,
              labels: DenseMechanicalView._primary
                  .map((code) => resultLabel(l10n, code))
                  .toList(growable: false),
              selectedIndex: primaryIndex < 0 ? null : primaryIndex,
              onSelected: widget.finalized
                  ? (_) {}
                  : (index) {
                      final code = DenseMechanicalView._primary[index];
                      setState(() => _result = code);
                      widget.onResult(code);
                    },
            ),
          ],
          if (widget.expanded) ...[
            const SizedBox(height: 16),
            F2bSegmented(
              height: 40,
              optionHeight: 32,
              labels: DenseMechanicalView._primary
                  .map((code) => resultLabel(l10n, code))
                  .toList(growable: false),
              selectedIndex: primaryIndex < 0 ? null : primaryIndex,
              selectedShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
              onSelected: widget.finalized
                  ? (_) {}
                  : (index) {
                      final code = DenseMechanicalView._primary[index];
                      setState(() => _result = code);
                      widget.onResult(code);
                    },
            ),
            const SizedBox(height: _M.gapSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in DenseMechanicalView._secondary)
                  F2bChip(
                    label: resultLabel(l10n, code),
                    selected:
                        secondaryIndex >= 0 &&
                        DenseMechanicalView._secondary[secondaryIndex] == code,
                    onTap: widget.finalized
                        ? () {}
                        : () {
                            setState(() => _result = code);
                            widget.onResult(code);
                          },
                  ),
              ],
            ),
            if (defect) ...[
              const SizedBox(height: _M.gapMid),
              F2bSectionLabel(l10n.severity),
              const SizedBox(height: _M.gapXSmall),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final code in const [
                    'MINOR',
                    'MODERATE',
                    'MAJOR',
                    'SAFETY_CRITICAL',
                  ])
                    F2bChip(
                      label: severityLabel(l10n, code),
                      selected: _severity == code,
                      onTap: widget.finalized
                          ? () {}
                          : () => setState(() => _severity = code),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Container(
              height: 76,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: widget.noteController,
                maxLines: 2,
                style: Fx.text(
                  14,
                  20,
                  FontWeight.w500,
                  -0.07,
                  color: Fx.ink,
                ),
                cursorColor: Fx.emerald,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: l10n.note,
                  hintStyle: Fx.text(
                    14,
                    20,
                    FontWeight.w500,
                    -0.07,
                    color: Fx.outline,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: F2bFocusFrame(
                    child: FxButton(
                      label: l10n.addPhoto,
                      onPressed: widget.finalized ? null : widget.onOpen,
                      tone: FxButtonTone.primary,
                      height: 48,
                      icon: const FxIcon(
                        id: '1_8277',
                        size: 16.67,
                        color: Fx.white,
                      ),
                      trailingIcon: false,
                    ),
                  ),
                ),
                const SizedBox(width: _M.gapMid),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: F2bFocusFrame(
                    borderRadius: BorderRadius.circular(Fx.pillRadius),
                    child: InkResponse(
                      onTap: widget.finalized ? null : widget.onOpen,
                      radius: 24,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Fx.container,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: FxIcon(
                            id: '1_8282',
                            size: 16.67,
                            color: Fx.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                F2bFocusFrame(
                  child: FxButton(
                    label: l10n.saveAnswer,
                    onPressed: widget.finalized || result == null || widget.busy
                        ? null
                        : () => widget.onSave(
                            result,
                            _severity,
                            widget.noteController.text,
                          ),
                    tone: FxButtonTone.primary,
                    height: 48,
                    expand: false,
                    trailingIcon: false,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Figma-exact spacing for this screen (F2-A `_M` pattern).
abstract final class _M {
  static const double gapXSmall = 4;
  static const double gapSmall = 8;
  static const double gapMid = 12;
  static const double gutter = 20;
}
