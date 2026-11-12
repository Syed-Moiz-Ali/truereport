import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

class EvidenceCaptureRequest {
  const EvidenceCaptureRequest({
    this.captionEn,
    this.captionAr,
    this.capturePoster = false,
  });

  final String? captionEn;
  final String? captionAr;
  final bool capturePoster;
}

Future<EvidenceCaptureRequest?> showEvidenceCaptureSheet(
  BuildContext context, {
  required String evidenceType,
}) {
  return showAppBottomSheet<EvidenceCaptureRequest>(
    context,
    child: EvidenceCaptureSheet(
      evidenceType: evidenceType,
      onSubmit: (request) => Navigator.of(context).pop(request),
    ),
  );
}

class EvidenceCaptureSheet extends StatefulWidget {
  const EvidenceCaptureSheet({
    required this.evidenceType,
    required this.onSubmit,
    super.key,
  });

  final String evidenceType;
  final ValueChanged<EvidenceCaptureRequest> onSubmit;

  @override
  State<EvidenceCaptureSheet> createState() => _EvidenceCaptureSheetState();
}

class _EvidenceCaptureSheetState extends State<EvidenceCaptureSheet> {
  final _captionEn = TextEditingController();
  final _captionAr = TextEditingController();
  bool _poster = false;

  @override
  void dispose() {
    _captionEn.dispose();
    _captionAr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TechnicianSectionTitle(
            title: l10n.technicianEvidence,
            subtitle: widget.evidenceType,
          ),
          SizedBox(height: context.spacing.md),
          AppTextField(
            key: const Key('evidence-caption-en'),
            controller: _captionEn,
            label: l10n.technicianCaptionsEn,
            labelAbove: true,
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            key: const Key('evidence-caption-ar'),
            controller: _captionAr,
            label: l10n.technicianCaptionsAr,
            labelAbove: true,
            textDirection: TextDirection.rtl,
          ),
          if (widget.evidenceType == 'VIDEO') ...[
            SizedBox(height: context.spacing.sm),
            CheckboxListTile(
              value: _poster,
              onChanged: (value) => setState(() => _poster = value ?? false),
              title: Text(l10n.technicianCapturePoster),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
          SizedBox(height: context.spacing.lg),
          AppButton(
            key: const Key('evidence-capture-submit'),
            label: l10n.technicianCapture,
            icon: Icons.camera_alt_outlined,
            expand: true,
            onPressed: () {
              widget.onSubmit(
                EvidenceCaptureRequest(
                  captionEn: _captionEn.text.trim().isEmpty
                      ? null
                      : _captionEn.text.trim(),
                  captionAr: _captionAr.text.trim().isEmpty
                      ? null
                      : _captionAr.text.trim(),
                  capturePoster: _poster,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
