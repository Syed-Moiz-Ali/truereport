import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';

class EvidenceCaptureRequest {
  const EvidenceCaptureRequest({
    this.captionEn,
    this.capturePoster = false,
    this.source = EvidenceSource.camera,
  });

  final String? captionEn;
  final bool capturePoster;
  final EvidenceSource source;
}

Future<EvidenceCaptureRequest?> showEvidenceCaptureSheet(
  BuildContext context, {
  required List<ReferenceRecord> evidenceTypes,
  required String evidenceType,
}) {
  return showAppBottomSheet<EvidenceCaptureRequest>(
    context,
    child: EvidenceCaptureSheet(
      evidenceTypes: evidenceTypes,
      evidenceType: evidenceType,
      onSubmit: (request) => Navigator.of(context).pop(request),
    ),
  );
}

class EvidenceCaptureSheet extends StatefulWidget {
  const EvidenceCaptureSheet({
    required this.evidenceTypes,
    required this.evidenceType,
    required this.onSubmit,
    super.key,
  });

  final List<ReferenceRecord> evidenceTypes;
  final String evidenceType;
  final ValueChanged<EvidenceCaptureRequest> onSubmit;

  @override
  State<EvidenceCaptureSheet> createState() => _EvidenceCaptureSheetState();
}

class _EvidenceCaptureSheetState extends State<EvidenceCaptureSheet> {
  final TextEditingController _captionEn = TextEditingController();
  bool _poster = false;

  @override
  void dispose() {
    _captionEn.dispose();
    super.dispose();
  }

  void _submit(EvidenceSource source) {
    widget.onSubmit(
      EvidenceCaptureRequest(
        captionEn: _captionEn.text.trim().isEmpty
            ? null
            : _captionEn.text.trim(),
        capturePoster: _poster,
        source: source,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TechnicianSectionTitle(
            title: t(TechnicianKeys.technicianEvidence),
            subtitle: evidenceTypeLabel(
              widget.evidenceTypes,
              widget.evidenceType,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            // gate-allow: behaviour - capture rule hint, not an evidence-type label.
            switch (widget.evidenceType) {
              'VIDEO' => t(
                TechnicianKeys.technicianVideoWindow,
              ), // gate-allow: behaviour
              'PHOTO' => t(
                TechnicianKeys.technicianPhotoGuide,
              ), // gate-allow: behaviour
              _ => t(TechnicianKeys.technicianDocumentGuide),
            },
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.md),
          AppTextField(
            key: const Key('evidence-caption-en'),
            controller: _captionEn,
            label: t(TechnicianKeys.technicianCaptionsEn),
            labelAbove: true,
          ),
          SizedBox(height: context.spacing.sm),
          if (widget.evidenceType == 'VIDEO') ...[
            SizedBox(height: context.spacing.sm),
            Semantics(
              checked: _poster,
              label: t(TechnicianKeys.technicianCapturePoster),
              child: InkWell(
                onTap: () => setState(() => _poster = !_poster),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Checkbox(
                        value: _poster,
                        onChanged: (value) =>
                            setState(() => _poster = value ?? false),
                      ),
                    ),
                    SizedBox(width: context.spacing.xs),
                    Expanded(
                      child: Text(
                        t(TechnicianKeys.technicianCapturePoster),
                        style: context.texts.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: context.spacing.lg),
          if (widget.evidenceType == 'PHOTO' || widget.evidenceType == 'VIDEO')
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t(TechnicianKeys.technicianChooseSource),
                  style: context.texts.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.spacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        key: const Key('evidence-capture-camera'),
                        label: t(TechnicianKeys.photoSourceCamera),
                        icon: Icons.photo_camera_outlined,
                        variant: AppButtonVariant.tonal,
                        expand: true,
                        onPressed: () => _submit(EvidenceSource.camera),
                      ),
                    ),
                    SizedBox(width: context.spacing.sm),
                    Expanded(
                      child: AppButton(
                        key: const Key('evidence-capture-files'),
                        label: t(TechnicianKeys.technicianSourceFiles),
                        icon: Icons.folder_open_outlined,
                        variant: AppButtonVariant.tonal,
                        expand: true,
                        onPressed: () => _submit(EvidenceSource.file),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            AppButton(
              key: const Key('evidence-capture-document'),
              label: t(TechnicianKeys.technicianChooseDocument),
              icon: Icons.attach_file_outlined,
              expand: true,
              onPressed: () => _submit(EvidenceSource.file),
            ),
        ],
      ),
    );
  }
}
