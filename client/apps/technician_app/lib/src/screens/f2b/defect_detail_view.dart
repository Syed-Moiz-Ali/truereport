import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/screens/f2b/f2b_intl.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';
import 'package:technician_app/src/ui_helpers.dart';

/// Screen 9. Defect detail and evidence, rebuilt on the Figma layout using only
/// existing assessment fields (result, severity, note, evidence).
class DefectDetailView extends StatelessWidget {
  const DefectDetailView({
    required this.job,
    required this.item,
    required this.photos,
    required this.noteController,
    required this.selectedResult,
    required this.selectedSeverity,
    required this.onResult,
    required this.onSeverity,
    required this.onSave,
    required this.onAddPhoto,
    required this.onClose,
    this.onProfile,
    this.busy = false,
    this.photoBusy = false,
    this.finalized = false,
    super.key,
  });

  final TechnicianJob job;
  final InspectionItem item;
  final List<LocalEvidence> photos;
  final TextEditingController noteController;
  final String? selectedResult;
  final String? selectedSeverity;
  final ValueChanged<String> onResult;
  final ValueChanged<String> onSeverity;
  final VoidCallback onSave;
  final VoidCallback onAddPhoto;
  final VoidCallback onClose;
  final VoidCallback? onProfile;
  final bool busy;
  final bool photoBusy;
  final bool finalized;

  static const _primaryResults = <String>[
    'NO_ISSUE_OBSERVED',
    'ATTENTION_RECOMMENDED',
    'DEFECT_FOUND',
  ];
  static const _secondaryResults = <String>[
    'NOT_CHECKED',
    'COULD_NOT_VERIFY',
    'NOT_APPLICABLE',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final category = Localizations.localeOf(context).languageCode == 'ar'
        ? item.categoryLabelAr
        : item.categoryLabelEn;
    final label = Localizations.localeOf(context).languageCode == 'ar'
        ? item.labelAr
        : item.labelEn;
    final primaryIndex = _primaryResults.indexOf(selectedResult ?? '');
    final secondaryIndex = _secondaryResults.indexOf(selectedResult ?? '');
    final defect =
        selectedResult == 'DEFECT_FOUND' ||
        selectedResult == 'ATTENTION_RECOMMENDED';

    return Scaffold(
      backgroundColor: Fx.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                _ContextHalf(
                  job: job,
                  item: item,
                  l10n: l10n,
                  onClose: onClose,
                  onProfile: onProfile,
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Fx.white,
                      borderRadius: BorderRadiusDirectional.vertical(
                        top: Radius.circular(48),
                      ),
                      boxShadow: Fx.upShadow,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        16,
                        20,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(
                            height: 10,
                            child: Center(
                              child: _GrabHandle(),
                            ),
                          ),
                          const SizedBox(height: _M.padLarge),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: F2b.amber,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: _M.gapSmall),
                                        Flexible(
                                          child: Text(
                                            category,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Fx.text(
                                              11,
                                              14,
                                              FontWeight.w600,
                                              0.55,
                                              color: Fx.muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: _M.gapXSmall),
                                    Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Fx.display26.copyWith(
                                        color: Fx.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: _M.gapMid),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Fx.container,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: FxIcon(
                                    id: '1_8070',
                                    size: 15,
                                    color: Fx.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: _M.padLarge),
                          F2bSectionLabel(l10n.result),
                          const SizedBox(height: _M.gapXSmall),
                          F2bSegmented(
                            labels: _primaryResults
                                .map((code) => resultLabel(l10n, code))
                                .toList(growable: false),
                            selectedIndex: primaryIndex < 0
                                ? null
                                : primaryIndex,
                            onSelected: finalized
                                ? (_) {}
                                : (index) => onResult(_primaryResults[index]),
                          ),
                          const SizedBox(height: _M.gapSmall),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final code in _secondaryResults)
                                F2bChip(
                                  label: resultLabel(l10n, code),
                                  selected:
                                      secondaryIndex >= 0 &&
                                      _secondaryResults[secondaryIndex] == code,
                                  onTap: finalized
                                      ? () {}
                                      : () => onResult(code),
                                ),
                            ],
                          ),
                          const SizedBox(height: _M.padLarge),
                          F2bSectionLabel(l10n.severity),
                          const SizedBox(height: _M.gapXSmall),
                          Opacity(
                            opacity: defect ? 1 : 0.5,
                            child: Wrap(
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
                                    selected: selectedSeverity == code,
                                    onTap: finalized || !defect
                                        ? () {}
                                        : () => onSeverity(code),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: _M.padLarge),
                          Row(
                            children: [
                              Expanded(
                                child: F2bSectionLabel(l10n.attachments),
                              ),
                              Text(
                                '${formatCountLocalized(photos.length, localeName)} / ${formatCountLocalized(item.minPhotos > 0 ? item.minPhotos : 1, localeName)}',
                                textDirection: TextDirection.ltr,
                                style: Fx.caption.copyWith(color: Fx.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: _M.gapXSmall),
                          Row(
                            children: [
                              Expanded(
                                child: F2bEvidenceTile(
                                  label: photos.isNotEmpty
                                      ? l10n.attachments
                                      : l10n.addPhoto,
                                  caption: l10n.photoRequired,
                                  image: photos.isEmpty
                                      ? null
                                      : MemoryImage(
                                          Uint8List.fromList(
                                            photos.first.bytes,
                                          ),
                                        ),
                                  onTap: finalized ? null : onAddPhoto,
                                ),
                              ),
                              const SizedBox(width: _M.padMid),
                              Expanded(
                                child: F2bEvidenceTile(
                                  label: l10n.addPhoto,
                                  caption: l10n.photoRequired,
                                  busy: photoBusy,
                                  onTap: finalized ? null : onAddPhoto,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: _M.padLarge),
                          F2bNoteField(
                            controller: noteController,
                            hint: l10n.note,
                            maxLines: 2,
                          ),
                          const SizedBox(height: _M.padLarge),
                          F2bFocusFrame(
                            child: FxButton(
                              label: l10n.saveAnswer,
                              onPressed: busy || finalized ? null : onSave,
                              icon: const FxIcon(
                                id: '1_8134',
                                size: 13.58,
                                color: Fx.white,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    // Figma node 1:8059: 44x6 bar, fill #E3E2E7, pill radius. No Fx token
    // covers this exact neutral, so the Figma value is kept (I7).
    return Container(
      width: 44,
      height: 6,
      decoration: BoxDecoration(
        color: F2b.grabTrack,
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
    );
  }
}

class _ContextHalf extends StatelessWidget {
  const _ContextHalf({
    required this.job,
    required this.item,
    required this.l10n,
    required this.onClose,
    this.onProfile,
  });

  final TechnicianJob job;
  final InspectionItem item;
  final AppLocalizations l10n;
  final VoidCallback onClose;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    // Figma 1:8022: 390x320, side padding 20. Figma 1:8023: 350x56 bar with
    // 8px top pad holding two 48px buttons; the total (8 + 48) is the 56px.
    final statusLabel =
        '\u2066${job.reference.toUpperCase()}\u2069 • ${technicianStatusLabel(l10n, job.status).toUpperCase()}';
    return SizedBox(
      height: 320,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(_M.gutter, 0, _M.gutter, 0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: _M.gapSmall),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    F2bIconButton(
                      iconId: '1_8026',
                      semanticLabel: l10n.close,
                      onPressed: onClose,
                      size: 48,
                      iconSize: 14,
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: F2bStatusPill(
                            label: statusLabel,
                            background: Fx.whiteE5,
                            foreground: Fx.ink,
                            dot: Fx.emerald,
                            style: Fx.text(
                              11,
                              14,
                              FontWeight.w600,
                              0.55,
                              color: Fx.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    F2bIconButton(
                      iconId: '1_8033',
                      semanticLabel: l10n.technicianInspection,
                      onPressed: null,
                      size: 48,
                      iconSize: 18.33,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _M.gapXSmall),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsetsDirectional.symmetric(
                  vertical: _M.gapXSmall,
                ),                decoration: BoxDecoration(
                  color: Fx.surfaceLow,
                  borderRadius: BorderRadius.circular(Fx.cardRadius),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TechnicianVehicleSilhouette(
                      height: 140,
                      semanticLabel: l10n.technicianVehicleSilhouette,
                    ),
                    PositionedDirectional(
                      bottom: 16,
                      child: F2bStatusPill(
                        label: l10n.technicianInspection,
                        background: Fx.whiteE5,
                        foreground: Fx.ink,
                        style: Fx.caption.copyWith(color: Fx.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma-exact spacing for this screen (F2-A `_M` pattern).
abstract final class _M {
  static const double gapXSmall = 4;
  static const double gapSmall = 8;
  static const double gapMid = 12;
  static const double padMid = 16;
  static const double gutter = 20;
  static const double padLarge = 24;
}
