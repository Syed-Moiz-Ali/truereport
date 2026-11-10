import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

enum AnnotationTool { draw, undo, crop }

/// Screen 10. Photo Annotation & Markup (node `1:8135`, 390 x 884).
class PhotoAnnotationView extends StatefulWidget {
  const PhotoAnnotationView({
    this.title,
    this.itemName,
    this.fileName,
    this.defectCallout,
    this.defectMeasurement,
    this.strokeWidth = '4.0 pt',
    this.selectedTool = AnnotationTool.draw,
    this.onSelectTool,
    this.onSave,
    this.onBack,
    this.onTogglePreview,
    this.photoImage,
    super.key,
  });

  final String? title;
  final String? itemName;
  final String? fileName;
  final String? defectCallout;
  final String? defectMeasurement;
  final String strokeWidth;
  final AnnotationTool selectedTool;
  final ValueChanged<AnnotationTool>? onSelectTool;
  final VoidCallback? onSave;
  final VoidCallback? onBack;
  final VoidCallback? onTogglePreview;
  final ui.Image? photoImage;

  @override
  State<PhotoAnnotationView> createState() => _PhotoAnnotationViewState();
}

class _PhotoAnnotationViewState extends State<PhotoAnnotationView> {
  late AnnotationTool _tool = widget.selectedTool;

  @override
  void didUpdateWidget(PhotoAnnotationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTool != oldWidget.selectedTool) {
      _tool = widget.selectedTool;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final effectiveTitle = widget.title ?? l10n.technicianInspection;
    final effectiveItemName = widget.itemName ?? l10n.attachments;
    final effectiveFileName = widget.fileName ?? 'PHOTO_01.JPG';
    final effectiveCallout = widget.defectCallout ?? '1 Defect';
    final effectiveMeasurement = widget.defectMeasurement ?? 'Scuff';

    return Scaffold(
      backgroundColor: Fx.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          height: 64,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
          decoration: const BoxDecoration(
            color: Color(0xCCFFFFFF),
            boxShadow: [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: MaterialLocalizations.of(context).backButtonTooltip,
                      child: InkResponse(
                        onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                        radius: 22,
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: FxIcon(
                              id: '1_8214',
                              width: 11.77,
                              height: 20,
                              color: Fx.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.5),
                    Expanded(
                      child: Text(
                        effectiveTitle,
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
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF006C49),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const FxIcon(
                  id: '1_8219',
                  size: 12,
                  color: Fx.white,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Context row (y: 64..112, height 48).
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0x2610B981),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const FxIcon(
                                  id: '1_8142',
                                  size: 16,
                                  color: Color(0xFF006C49),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  effectiveItemName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Fx.text(
                                    12,
                                    16,
                                    FontWeight.w600,
                                    0.24,
                                    color: Fx.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 22,
                          padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
                          decoration: const BoxDecoration(
                            color: Fx.white,
                            borderRadius: BorderRadius.all(
                              Radius.circular(Fx.pillRadius),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Fx.emerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Markup Active',
                                maxLines: 1,
                                style: Fx.text(
                                  11,
                                  14,
                                  FontWeight.w600,
                                  0.275,
                                  color: Fx.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Photo Canvas Card (y: 112..549.5, height 437.5).
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                  child: Container(
                    key: const ValueKey('photo-annotation-card'),
                    width: 350,
                    height: 437.5,
                    decoration: const BoxDecoration(
                      color: Fx.white,
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x04000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Color(0x0B000000),
                          blurRadius: 40,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Base photo.
                        if (widget.photoImage != null)
                          Positioned.fill(
                            child: RawImage(
                              image: widget.photoImage!,
                              scale: 2,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Positioned.fill(
                            child: Container(color: Fx.container),
                          ),

                        // Gradient overlay.
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x33000000),
                                  Color(0x00000000),
                                  Color(0x4D000000),
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // SVG Annotation Markup Overlay.
                        const Positioned.fill(
                          child: Center(
                            child: FxIcon(
                              id: 'SVG-1_8162',
                              width: 350,
                              height: 437.5,
                            ),
                          ),
                        ),

                        // Top controls row: File badge + Expand button.
                        PositionedDirectional(
                          start: 16,
                          top: 16,
                          end: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 26,
                                padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 6),
                                decoration: const BoxDecoration(
                                  color: Fx.whiteE5,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(Fx.pillRadius),
                                  ),
                                  boxShadow: Fx.pillShadow,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const FxIcon(
                                      id: '1_8156',
                                      size: 14,
                                      color: Color(0xFF006C49),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      effectiveFileName,
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
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Fx.whiteE5,
                                  shape: BoxShape.circle,
                                  boxShadow: Fx.pillShadow,
                                ),
                                alignment: Alignment.center,
                                child: IconButton(
                                  icon: const FxIcon(
                                    id: '1_8161',
                                    size: 13.5,
                                    color: Fx.ink,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: widget.onTogglePreview,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom badges row: Defect count + Measurement.
                        PositionedDirectional(
                          start: 16,
                          bottom: 16,
                          end: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 26,
                                padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xF2FFFFFF),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(Fx.pillRadius),
                                  ),
                                  boxShadow: Fx.pillShadow,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Fx.emerald,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      effectiveCallout,
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
                              Container(
                                height: 26,
                                padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xF2FFFFFF),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(Fx.pillRadius),
                                  ),
                                  boxShadow: Fx.pillShadow,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  effectiveMeasurement,
                                  maxLines: 1,
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Annotation Tools Card (y: 569.5..829.5, height 260).
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                  child: Container(
                    key: const ValueKey('photo-annotation-tools'),
                    width: 350,
                    constraints: const BoxConstraints(minHeight: 260),
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                    decoration: const BoxDecoration(
                      color: Fx.white,
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 50,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title row (h: 44).
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Annotation Tools',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Fx.text(
                                          16,
                                          22,
                                          FontWeight.w700,
                                          -0.16,
                                          color: Fx.ink,
                                        ),
                                      ),
                                      Text(
                                        'Tap draw to circle surface damages',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Fx.text(
                                          13,
                                          18,
                                          FontWeight.w400,
                                          0.0,
                                          color: Fx.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 22,
                                  padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF4F3F8),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(Fx.pillRadius),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const FxIcon(
                                        id: '1_8185',
                                        size: 12,
                                        color: Color(0xFF006C49),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.strokeWidth,
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
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 3 Tool buttons row (h: 80).
                        SizedBox(
                          height: 80,
                          child: Row(
                            children: [
                              Expanded(
                                child: _ToolButton(
                                  key: const ValueKey('photo-annotation-draw'),
                                  label: l10n.technicianDraw,
                                  iconId: '1_8191',
                                  iconSize: 20,
                                  selected: _tool == AnnotationTool.draw,
                                  onTap: () {
                                    setState(() => _tool = AnnotationTool.draw);
                                    widget.onSelectTool?.call(AnnotationTool.draw);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ToolButton(
                                  label: l10n.technicianUndo,
                                  iconId: '1_8196',
                                  iconSize: 17,
                                  selected: _tool == AnnotationTool.undo,
                                  onTap: () {
                                    setState(() => _tool = AnnotationTool.undo);
                                    widget.onSelectTool?.call(AnnotationTool.undo);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ToolButton(
                                  label: l10n.technicianCrop,
                                  iconId: '1_8201',
                                  iconSize: 22,
                                  selected: _tool == AnnotationTool.crop,
                                  onTap: () {
                                    setState(() => _tool = AnnotationTool.crop);
                                    widget.onSelectTool?.call(AnnotationTool.crop);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Save Photo button (h: 56).
                        FxButton(
                          label: l10n.technicianSavePhoto,
                          trailingIcon: false,
                          icon: const FxIcon(
                            id: '1_8206',
                            size: 16.7,
                            color: Fx.white,
                          ),
                          onPressed: widget.onSave,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.iconId,
    required this.iconSize,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String iconId;
  final double iconSize;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: selected ? Fx.emerald : const Color(0xFFF4F3F8),
            borderRadius: const BorderRadius.all(Radius.circular(32)),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x4010B981),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FxIcon(
                id: iconId,
                size: iconSize,
                color: selected ? Fx.white : Fx.muted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                style: Fx.text(
                  12,
                  16,
                  FontWeight.w600,
                  0.24,
                  color: selected ? Fx.white : Fx.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
