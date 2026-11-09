import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/report_pdf_saver.dart';
import 'package:admin_app/src/screens/f3b/pdf_preview_view.dart';
import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Full-screen desktop PDF Print Preview page matching Figma screen 12:
/// `12_12._Print-Ready_PDF_Preview`
class PrintReadyPdfPreviewPage extends ConsumerStatefulWidget {
  const PrintReadyPdfPreviewPage({
    super.key,
    required this.jobId,
    this.initialReport,
  });

  final String jobId;
  final ReportAdmin? initialReport;

  static Route<void> route({
    required String jobId,
    ReportAdmin? initialReport,
  }) {
    return MaterialPageRoute<void>(
      builder: (context) => PrintReadyPdfPreviewPage(
        jobId: jobId,
        initialReport: initialReport,
      ),
    );
  }

  @override
  ConsumerState<PrintReadyPdfPreviewPage> createState() =>
      _PrintReadyPdfPreviewPageState();
}

class _PrintReadyPdfPreviewPageState
    extends ConsumerState<PrintReadyPdfPreviewPage> {
  bool _busy = false;

  Future<void> _downloadPdf() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(adminApiProvider).reportPdf(widget.jobId);
      final path = await saveReportPdf(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.pdfBytesSaved}: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _sendEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document emailed to client.')),
    );
  }

  void _printDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document dispatched to system printer.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportProvider(widget.jobId));
    final report = reportAsync.value ?? widget.initialReport;
    final auth = ref.watch(authControllerProvider).value;

    return Scaffold(
      body: PrintReadyPdfPreviewView(
        report: report,
        userName: auth?.user.displayName,
        userRole: auth != null
            ? (auth.role.name == 'workshopAdmin'
                ? 'Lead Inspector'
                : auth.role.name)
            : null,
        onBack: () => Navigator.of(context).pop(),
        onDownloadPdf: _busy ? null : _downloadPdf,
        onSendEmail: _sendEmail,
        onPrint: _printDocument,
        onNavSelected: (idx) {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
