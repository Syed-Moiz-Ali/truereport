import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
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
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 30,
                          offset: Offset(0, -4),
                        ),
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 60,
                          offset: Offset(0, -18),
                        ),
                      ],
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
                          Center(
                            child: Container(
                              width: 44,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3E2E7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
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
                                            color: Color(0xFFF59E0B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            category,
                                            maxLines: 1,
                                            overflow: TextOverflow.clip,
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
                                    const SizedBox(height: 4),
                                    Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: Fx.display26.copyWith(
                                        color: Fx.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
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
                          const SizedBox(height: 24),
                          F2bSectionLabel(l10n.result),
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 24),
                          F2bSectionLabel(l10n.severity),
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: F2bSectionLabel(l10n.attachments),
                              ),
                              Text(
                                '${photos.length} / ${item.minPhotos > 0 ? item.minPhotos : 1}',
                                style: Fx.caption.copyWith(color: Fx.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: F2bEvidenceTile(
                                  label: photos.isNotEmpty
                                      ? l10n.attachments
                                      : l10n.addPhoto,
                                  caption: photos.isNotEmpty
                                      ? photos.first.createdAt.toIso8601String()
                                      : l10n.photoRequired,
                                  image: photos.isEmpty
                                      ? null
                                      : MemoryImage(
                                          Uint8List.fromList(
                                            photos.first.bytes,
                                          ),
                                        ),
                                  onTap: onAddPhoto,
                                ),
                              ),
                              const SizedBox(width: 16),
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
                          const SizedBox(height: 20),
                          F2bNoteField(
                            controller: noteController,
                            hint: l10n.note,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          FxButton(
                            label: l10n.saveAnswer,
                            onPressed: busy || finalized ? null : onSave,
                            icon: const FxIcon(
                              id: '1_8134',
                              size: 13.58,
                              color: Fx.white,
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
    return SizedBox(
      height: 320,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  F2bIconButton(
                    iconId: '1_8026',
                    semanticLabel: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    onPressed: onClose,
                    size: 48,
                    iconSize: 14,
                  ),
                  const Spacer(),
                  F2bStatusPill(
                    label:
                        '${job.reference} • ${technicianStatusLabel(l10n, job.status).toUpperCase()}',
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
                  const Spacer(),
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
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsetsDirectional.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Fx.surfaceLow,
                  borderRadius: BorderRadius.circular(Fx.cardRadius),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TechnicianVehicleSilhouette(
                      height: 120,
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
