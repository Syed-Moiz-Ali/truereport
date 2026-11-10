import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/shared/technician_kit.dart';
import 'package:technician_app/src/ui_helpers.dart';

/// Screen 09. 9._Defect_Detail_&_Evidence (node `1:8021`, 390 x 1031.67).
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
    this.wireframeImage,
    this.evidenceImage,
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
  final ui.Image? wireframeImage;
  final ui.Image? evidenceImage;

  static const _primaryResults = <String>[
    'NO_ISSUE_OBSERVED',
    'ATTENTION_RECOMMENDED',
    'DEFECT_FOUND',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final category = isAr ? item.categoryLabelAr : item.categoryLabelEn;
    final label = isAr ? item.labelAr : item.labelEn;
    final primaryIndex = _primaryResults.indexOf(selectedResult ?? '');

    return Scaffold(
      backgroundColor: Fx.white,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _ContextHalf(
                  job: job,
                  l10n: l10n,
                  onClose: onClose,
                  wireframeImage: wireframeImage,
                ),
                _Sheet(
                  item: item,
                  category: category,
                  title: label,
                  photos: photos,
                  noteController: noteController,
                  primaryIndex: primaryIndex < 0 ? 1 : primaryIndex,
                  selectedSeverity: selectedSeverity,
                  onResult: onResult,
                  onSeverity: onSeverity,
                  onSave: onSave,
                  onAddPhoto: onAddPhoto,
                  busy: busy,
                  photoBusy: photoBusy,
                  finalized: finalized,
                  evidenceImage: evidenceImage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextHalf extends StatelessWidget {
  const _ContextHalf({
    required this.job,
    required this.l10n,
    required this.onClose,
    this.wireframeImage,
  });

  final TechnicianJob job;
  final AppLocalizations l10n;
  final VoidCallback onClose;
  final ui.Image? wireframeImage;

  @override
  Widget build(BuildContext context) {
    final statusLabel =
        '\u2066${job.reference.toUpperCase()}\u2069 \u2022 ${technicianStatusLabel(l10n, job.status).toUpperCase()}';

    return SizedBox(
      width: double.infinity,
      height: 320,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      F2bIconButton(
                        iconId: '1_8026',
                        semanticLabel: l10n.close,
                        onPressed: onClose,
                        size: 48,
                        iconSize: 14,
                      ),
                      Flexible(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: F2bStatusPill(
                              label: statusLabel,
                              background: Fx.whiteE5,
                              foreground: Fx.ink,
                              dot: Fx.emerald,
                              dotSize: 8,
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              shadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
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
                        onPressed: () {},
                        size: 48,
                        iconSize: 18.33,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 264,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 350,
                      height: 256,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (wireframeImage != null)
                            RawImage(image: wireframeImage, scale: 2)
                          else
                            const Center(
                              child: FxIcon(
                                id: '1_8036',
                                width: 350,
                                height: 256,
                              ),
                            ),
                          const PositionedDirectional(
                            start: 139.86,
                            top: 90,
                            width: 70.28,
                            height: 76,
                            child: _Pin(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Fx.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x59F59E0B),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const FxIcon(
                        id: '1_8052',
                        size: 13.5,
                        color: Fx.white,
                      ),
                    ),
                  ),
                  const PositionedDirectional(
                    start: -4,
                    top: -4,
                    width: 48,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x33FBBF24),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            height: 32,
            padding: const EdgeInsets.fromLTRB(12, 8.5, 12, 9.5),
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'PIN #03',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Fx.text(11, 14, FontWeight.w600, 0.275, color: Fx.ink),
            ),
          ),
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.item,
    required this.category,
    required this.title,
    required this.photos,
    required this.noteController,
    required this.primaryIndex,
    required this.selectedSeverity,
    required this.onResult,
    required this.onSeverity,
    required this.onSave,
    required this.onAddPhoto,
    required this.busy,
    required this.photoBusy,
    required this.finalized,
    this.evidenceImage,
  });

  final InspectionItem item;
  final String category;
  final String title;
  final List<LocalEvidence> photos;
  final TextEditingController noteController;
  final int primaryIndex;
  final String? selectedSeverity;
  final ValueChanged<String> onResult;
  final ValueChanged<String> onSeverity;
  final VoidCallback onSave;
  final VoidCallback onAddPhoto;
  final bool busy;
  final bool photoBusy;
  final bool finalized;
  final ui.Image? evidenceImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(F2b.radiusLarge),
        ),
        boxShadow: Fx.upShadow,
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 10,
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: _GrabBar(),
            ),
          ),
          const SizedBox(height: 24),
          _Header(category: category, title: title),
          const SizedBox(height: 24),
          _StatusBlock(
            primaryIndex: primaryIndex,
            onResult: onResult,
            finalized: finalized,
          ),
          const SizedBox(height: 24),
          _ClassificationBlock(
            selectedSeverity: selectedSeverity,
            onSeverity: onSeverity,
            finalized: finalized,
          ),
          const SizedBox(height: 24.5),
          _EvidenceBlock(
            item: item,
            photos: photos,
            photoBusy: photoBusy,
            finalized: finalized,
            onAddPhoto: onAddPhoto,
            evidenceImage: evidenceImage,
          ),
          const SizedBox(height: 23.5),
          _NoteRow(noteController: noteController),
          const SizedBox(height: 24),
          _SaveBlock(onSave: onSave, busy: busy, finalized: finalized),
        ],
      ),
    );
  }
}

class _GrabBar extends StatelessWidget {
  const _GrabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 6,
      decoration: const BoxDecoration(
        color: F2b.grabTrack,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.category, required this.title});

  final String category;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 14,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: F2b.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.display26,
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const FxIcon(id: '1_8070', size: 15, color: Fx.muted),
          ),
        ],
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.primaryIndex,
    required this.onResult,
    required this.finalized,
  });

  final int primaryIndex;
  final ValueChanged<String> onResult;
  final bool finalized;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 14),
            child: F2bSectionLabel(l10n.result),
          ),
          const SizedBox(height: 4),
          F2bSegmented(
            labels: [
              l10n.noIssueObserved,
              l10n.attentionRecommended,
              l10n.defectFound,
            ],
            selectedIndex: primaryIndex,
            selectedColor: const Color(0xFFFED7AA),
            selectedShadow: const [
              BoxShadow(
                color: Color(0x2EFB923C),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            selectedTextStyle: Fx.text(
              12,
              16,
              FontWeight.w700,
              0.24,
              color: Fx.ink,
            ),
            unselectedTextStyle: Fx.text(
              12,
              16,
              FontWeight.w600,
              0.24,
              color: Fx.muted,
            ),
            onSelected: finalized
                ? (_) {}
                : (index) => onResult(DefectDetailView._primaryResults[index]),
          ),
        ],
      ),
    );
  }
}

class _ClassificationBlock extends StatelessWidget {
  const _ClassificationBlock({
    required this.selectedSeverity,
    required this.onSeverity,
    required this.finalized,
  });

  final String? selectedSeverity;
  final ValueChanged<String> onSeverity;
  final bool finalized;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (MediaQuery.textScalerOf(context).scale(1) > 1.1)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                F2bSectionLabel(l10n.severity),
                Text(
                  selectedSeverity != null
                      ? '1 ${l10n.itemsSelected}'
                      : '0 ${l10n.itemsSelected}',
                  style: Fx.text(
                    11,
                    14,
                    FontWeight.w700,
                    0.44,
                    color: Fx.emerald,
                  ),
                ),
              ],
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: F2bSectionLabel(l10n.severity)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      selectedSeverity != null
                          ? '1 ${l10n.itemsSelected}'
                          : '0 ${l10n.itemsSelected}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w700,
                        0.44,
                        color: Fx.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            height: 70,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: 350,
                height: 70,
                child: Stack(
                  children: [
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      child: Semantics(
                        button: true,
                        label: severityLabel(l10n, 'MINOR'),
                        child: GestureDetector(
                          onTap: finalized ? null : () => onSeverity('MINOR'),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEEDF3),
                              borderRadius: BorderRadius.all(
                                Radius.circular(Fx.pillRadius),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const FxIcon(
                                  id: '1_8090',
                                  size: 9.33,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  severityLabel(l10n, 'MINOR'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Fx.text(
                                    11,
                                    14,
                                    FontWeight.w600,
                                    0.44,
                                    color: Fx.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 140.61,
                      top: 0,
                      child: Semantics(
                        button: true,
                        label: severityLabel(l10n, 'MODERATE'),
                        child: GestureDetector(
                          onTap: finalized
                              ? null
                              : () => onSeverity('MODERATE'),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: const BoxDecoration(
                              color: Fx.container,
                              borderRadius: BorderRadius.all(
                                Radius.circular(Fx.pillRadius),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              severityLabel(l10n, 'MODERATE'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w600,
                                0.44,
                                color: Fx.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 0,
                      top: 40,
                      child: Semantics(
                        button: true,
                        label: severityLabel(l10n, 'MAJOR'),
                        child: GestureDetector(
                          onTap: finalized ? null : () => onSeverity('MAJOR'),
                          child: Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: const BoxDecoration(
                              color: Fx.container,
                              borderRadius: BorderRadius.all(
                                Radius.circular(Fx.pillRadius),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              severityLabel(l10n, 'MAJOR'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w600,
                                0.44,
                                color: Fx.muted,
                              ),
                            ),
                          ),
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
    );
  }
}

class _EvidenceBlock extends StatelessWidget {
  const _EvidenceBlock({
    required this.item,
    required this.photos,
    required this.photoBusy,
    required this.finalized,
    required this.onAddPhoto,
    this.evidenceImage,
  });

  final InspectionItem item;
  final List<LocalEvidence> photos;
  final bool photoBusy;
  final bool finalized;
  final VoidCallback onAddPhoto;
  final ui.Image? evidenceImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countText =
        '${photos.length} of ${item.minPhotos > 0 ? item.minPhotos : 1} Required';

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 185),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (MediaQuery.textScalerOf(context).scale(1) > 1.1)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                F2bSectionLabel(l10n.attachments),
                Text(
                  countText,
                  style: Fx.text(
                    11,
                    14,
                    FontWeight.w600,
                    0.44,
                    color: Fx.muted,
                  ),
                ),
              ],
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: F2bSectionLabel(l10n.attachments)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      countText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w600,
                        0.44,
                        color: Fx.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            height: 167,
            child: Row(
              children: [
                Expanded(
                  child: _FilledTile(
                    image: evidenceImage,
                    photo: photos.isNotEmpty ? photos.first : null,
                    onTap: finalized ? null : onAddPhoto,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _EmptyTile(
                    onTap: finalized ? null : onAddPhoto,
                    busy: photoBusy,
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

class _FilledTile extends StatelessWidget {
  const _FilledTile({this.image, this.photo, this.onTap});

  final ui.Image? image;
  final LocalEvidence? photo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return F2bEvidenceTile(
      label: l10n.attachments,
      caption: 'Tagged',
      onTap: onTap,
      decoration: const BoxDecoration(
        color: Fx.container,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (image != null)
            Positioned.fill(child: RawImage(image: image, scale: 2))
          else if (photo != null)
            Positioned.fill(
              child: Image.memory(
                Uint8List.fromList(photo!.bytes),
                fit: BoxFit.cover,
              ),
            )
          else
            const SizedBox.expand(),
          PositionedDirectional(
            end: 8,
            top: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: Fx.pillShadow,
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: Fx.whiteE5,
                    alignment: Alignment.center,
                    child: const FxIcon(id: '1_8107', size: 12, color: Fx.ink),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 8,
            bottom: 8,
            child: Container(
              height: 18,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
                boxShadow: Fx.pillShadow,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(Fx.pillRadius),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: Fx.whiteE5,
                    padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: F2b.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tagged',
                          maxLines: 1,
                          style: Fx.text(
                            11,
                            14,
                            FontWeight.w600,
                            0.44,
                            color: Fx.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({this.onTap, this.busy = false});

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return F2bEvidenceTile(
      label: l10n.addPhoto,
      caption: l10n.photoRequired,
      busy: busy,
      onTap: onTap,
      decoration: const BoxDecoration(
        color: Fx.white,
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Fx.tintEmerald,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const FxIcon(id: '1_8115', size: 25, color: Fx.emerald),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.addPhoto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Fx.text(14, 18, FontWeight.w700, -0.35, color: Fx.ink),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.photoRequired,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Fx.caption,
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.noteController});

  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    return Container(
      height: 56.67,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Fx.container),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 12.83,
            height: 17.42,
            child: Center(
              child: FxIcon(id: '1_8122', size: 17.42, color: Fx.muted),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: noteController,
              style: Fx.body13.copyWith(color: Fx.ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: l10n!.note,
                hintStyle: Fx.body13.copyWith(color: Fx.muted),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 16.67,
            height: 24.67,
            padding: const EdgeInsets.only(bottom: 8),
            alignment: Alignment.topCenter,
            child: const FxIcon(id: '1_8128', size: 16.67, color: Fx.muted),
          ),
        ],
      ),
    );
  }
}

class _SaveBlock extends StatelessWidget {
  const _SaveBlock({
    required this.onSave,
    required this.busy,
    required this.finalized,
  });

  final VoidCallback onSave;
  final bool busy;
  final bool finalized;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4.5, bottom: 7.5),
      child: FxButton(
        key: const ValueKey('f2b3-save-button'),
        label: l10n.saveAnswer.toUpperCase(),
        labelStyle: Fx.text(14, 18, FontWeight.w700, 0.7, color: Fx.white),
        onPressed: busy || finalized ? null : onSave,
        icon: const FxIcon(id: '1_8134', size: 13.58, color: Fx.white),
      ),
    );
  }
}
