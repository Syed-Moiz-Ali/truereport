import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_ui.dart';
import 'package:technician_app/src/features/shell/fieldwork/shell_nav.dart';

/// Test-only strings for the shell goldens. The production shell resolves the
/// same labels from the backend bundle; the sample body is a neutral stand-in.
class PreviewShellData {
  const PreviewShellData({required this.arabic});

  final bool arabic;

  String t(String en, String ar) => arabic ? ar : en;

  TechnicianNavData get nav => TechnicianNavData(
    jobsLabel: t('Jobs', 'المهام'),
    profileLabel: t('Profile', 'الملف الشخصي'),
    markLabel: t('TrueReport', 'ترو ريبورت'),
  );

  String get jobsTitle => t('Jobs', 'المهام');
  String get profileTitle => t('Profile', 'الملف الشخصي');
  String get subtitle => t('Neutral sample body', 'محتوى تجريبي محايد');
  String get cardTitle =>
      t('The page fills this space', 'تملأ الصفحة هذه المساحة');
  String get cardBody => t(
    'The production shell only supplies the dock or the rail. This body is a '
        'stand-in for a real screen and carries no app logic.',
    'يوفر الغلاف الإنتاجي الشريط السفلي أو الجانبي فقط. هذا المحتوى بديل عن '
        'شاشة حقيقية ولا يحمل أي منطق للتطبيق.',
  );
}

/// Test-only fixture around the **production** shell frame.
class ShellPreviewScreen extends StatefulWidget {
  const ShellPreviewScreen({
    required this.data,
    required this.initialIndex,
    super.key,
  });

  final PreviewShellData data;
  final int initialIndex;

  @override
  State<ShellPreviewScreen> createState() => _ShellPreviewScreenState();
}

class _ShellPreviewScreenState extends State<ShellPreviewScreen> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return TechnicianShellFrame(
      index: _index,
      data: data.nav,
      onSelected: (next) {
        if (next == _index) return;
        setState(() => _index = next);
      },
      body: _SampleBody(
        title: _index == 1 ? data.profileTitle : data.jobsTitle,
        subtitle: data.subtitle,
        cardTitle: data.cardTitle,
        cardBody: data.cardBody,
      ),
    );
  }
}

/// Deliberately neutral: a header and one placeholder surface, no app logic.
class _SampleBody extends StatelessWidget {
  const _SampleBody({
    required this.title,
    required this.subtitle,
    required this.cardTitle,
    required this.cardBody,
  });

  final String title;
  final String subtitle;
  final String cardTitle;
  final String cardBody;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.surfaceContainerLow,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 18, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: fieldworkText(
                    context,
                    24,
                    weight: FontWeight.w800,
                    height: 30,
                    tracking: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: fieldworkText(
                    context,
                    12.5,
                    weight: FontWeight.w600,
                    height: 17,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardTitle,
                        style: fieldworkText(
                          context,
                          18,
                          weight: FontWeight.w800,
                          height: 24,
                          tracking: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cardBody,
                        style: fieldworkText(
                          context,
                          13,
                          height: 20,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (var line = 0; line < 3; line++) ...[
                        if (line > 0) const SizedBox(height: 10),
                        Container(
                          height: 10,
                          width: line == 2 ? 220 : double.infinity,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ],
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
