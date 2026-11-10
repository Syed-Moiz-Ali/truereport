import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

/// Screen 6 — Master Item Content & Translation Editor
/// (`06_6._Master_Item_Content_&_Translation_Editor`)
///
/// Features:
/// - Context Header with breadcrumb ("MASTER LIBRARY • Checkpoint #042") and "Active Specification" pill
/// - Subsystem, measurement metric, OEM minimum threshold, and sync status telemetry cards
/// - Dual-language side-by-side content translation editor:
///   - English (Primary Source - EN-US)
///   - Arabic (Auto-synchronized - AR-SA RTL)
/// - Visual Reference & Schematic upload dropzone and asset management
/// - Audit trace footer ("Last modified by Inspector Lead Vance") with Cancel and Save CTAs
/// - Fully responsive across mobile (stacked) and desktop (side-by-side split)
class MasterItemEditorScreen extends ConsumerStatefulWidget {
  const MasterItemEditorScreen({
    super.key,
    this.itemId,
  });

  final String? itemId;

  @override
  ConsumerState<MasterItemEditorScreen> createState() =>
      _MasterItemEditorScreenState();
}

class _MasterItemEditorScreenState
    extends ConsumerState<MasterItemEditorScreen> {
  late final TextEditingController _titleEnController;
  late final TextEditingController _descEnController;
  late final TextEditingController _titleArController;
  late final TextEditingController _descArController;

  late final TextEditingController _subsystemController;
  late final TextEditingController _metricController;
  late final TextEditingController _thresholdController;

  bool _isSaving = false;
  final String _activeViewMode = 'Dual Language View';
  final List<String> _attachedSchematics = [
    'caliper_alignment_v2.png (2.4 MB • Current Master)',
    'rotor_wear_tolerance.png (1.8 MB • Cross-Section)',
  ];

  @override
  void initState() {
    super.initState();
    // Default pre-fill matching Screen 6 specifications
    _titleEnController = TextEditingController(
      text: 'Brake Pad Thickness & Rotor Runout',
    );
    _descEnController = TextEditingController(
      text:
          'Measure inner and outer friction material using digital caliper. Flag if below 3.0mm OEM spec.',
    );
    _titleArController = TextEditingController(
      text: 'سماكة تيل الفرامل وانحراف القرص',
    );
    _descArController = TextEditingController(
      text:
          'قم بقياس مادة الاحتكاك الداخلية والخارجية باستخدام الفرجار الرقمي. يتم الإبلاغ إذا كانت القراءة أقل من 3.0 مم وفقاً لمواصفات المصنّع.',
    );
    _subsystemController =
        TextEditingController(text: 'Braking & Hydraulic');
    _metricController = TextEditingController(text: 'Caliper (Millimeters)');
    _thresholdController = TextEditingController(text: '3.00 mm Standard');

    // If editing a specific item, initialize with that item's data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.itemId != null) {
        final items = ref.read(masterItemsListProvider);
        final found = items.firstWhere(
          (i) => i.id == widget.itemId || i.code == widget.itemId,
          orElse: () => sampleMasterInspectionItems.first,
        );
        _titleEnController.text = found.title;
        _descEnController.text = found.description;
        _subsystemController.text = found.category;
      }
    });
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _descEnController.dispose();
    _titleArController.dispose();
    _descArController.dispose();
    _subsystemController.dispose();
    _metricController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final updated = MasterInspectionItem(
      id: widget.itemId ?? 'item-${DateTime.now().millisecondsSinceEpoch}',
      code: widget.itemId != null && widget.itemId!.startsWith('CHK-')
          ? widget.itemId!
          : 'CHK-BRK-042',
      title: _titleEnController.text.trim(),
      description: _descEnController.text.trim(),
      category: _subsystemController.text.trim(),
      requirementLevel: 'Mandatory',
      tags: const ['Laser Caliper Supported', 'Mandatory Photo'],
      requiresPhoto: true,
      translations: {
        'ar': _titleArController.text.trim(),
        'ar_desc': _descArController.text.trim(),
      },
    );

    if (widget.itemId != null) {
      ref.read(masterItemsListProvider.notifier).updateItem(updated);
    } else {
      ref.read(masterItemsListProvider.notifier).addItem(updated);
    }

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: PtTheme.deepGreen,
        content: Text(
          Localizations.of<AppLocalizations>(context, AppLocalizations)?.masterCheckpointSaved ??
              'Master checkpoint specification saved and broadcasted.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    try {
      context.go('/master-library');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sidebar
          if (isDesktop)
            PlatformSidebar(
              currentRoute: '/master-library',
              onNavigate: (route) => context.go(route),
            ),

          // 2. Main Content
          Expanded(
            child: Column(
              children: [
                // Top Global Header
                const PlatformHeader(),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Section 0: Top Action / Context Row
                            _buildContextAndTitleRow(),

                            const SizedBox(height: 20),

                            // Section 1: Quick Metadata Strip (4 Cards)
                            _buildMetadataStrip(),

                            const SizedBox(height: 24),

                            // Section 2: Dual Language Content Split (English vs Arabic)
                            _buildDualLanguageSection(),

                            const SizedBox(height: 24),

                            // Section 3: Visual Reference & Schematic Card
                            _buildVisualSchematicCard(),

                            const SizedBox(height: 28),

                            // Section 4: Bottom Actions Bar
                            _buildBottomActionBar(),
                          ],
                        ),
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

  Widget _buildContextAndTitleRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow and Status Capsule
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                InkWell(
                  onTap: () => context.go('/master-library'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 15,
                        color: PtTheme.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MASTER LIBRARY',
                        style: PtTheme.font(
                          11,
                          lineHeight: 14,
                          weight: FontWeight.w700,
                          color: PtTheme.muted,
                          tracking: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '•',
                  style: PtTheme.font(11, lineHeight: 14, color: PtTheme.muted),
                ),
                Text(
                  'Checkpoint #042',
                  style: PtTheme.font(
                    11,
                    lineHeight: 14,
                    weight: FontWeight.w600,
                    color: PtTheme.ink,
                  ),
                ),
              ],
            ),

            // Active Specification Capsule
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: PtTheme.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: PtTheme.emerald.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: PtTheme.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Active Specification',
                    style: PtTheme.font(
                      11,
                      lineHeight: 14,
                      weight: FontWeight.w700,
                      color: PtTheme.deepGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Title and Mode Switcher
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Text(
                    widget.itemId != null
                        ? 'Edit Master Item: Brake Pad Thickness'
                        : 'New Master Inspection Checkpoint',
                    style: PtTheme.font(
                      26,
                      lineHeight: 32,
                      weight: FontWeight.w800,
                      color: PtTheme.ink,
                      tracking: -0.5,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: PtTheme.white,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: PtTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.translate_rounded,
                            size: 14,
                            color: PtTheme.ink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _activeViewMode,
                            style: PtTheme.font(
                              12,
                              lineHeight: 16,
                              weight: FontWeight.w600,
                              color: PtTheme.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: PtTheme.canvas,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: PtTheme.border),
                      ),
                      child: Center(
                        child: Text(
                          'Audit Version 4.1',
                          style: PtTheme.font(
                            12,
                            lineHeight: 16,
                            weight: FontWeight.w600,
                            color: PtTheme.muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetadataStrip() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 600
            ? constraints.maxWidth
            : (constraints.maxWidth - 36) / 4;

        final items = [
          _buildMetaCard(
            caption: 'SUBSYSTEM',
            value: 'Braking & Hydraulic',
            icon: Icons.alt_route_rounded,
            width: cardWidth,
          ),
          _buildMetaCard(
            caption: 'MEASUREMENT METRIC',
            value: 'Caliper (Millimeters)',
            icon: Icons.straighten_rounded,
            width: cardWidth,
          ),
          _buildMetaCard(
            caption: 'OEM MINIMUM THRESHOLD',
            value: '3.00 mm Standard',
            icon: Icons.verified_outlined,
            width: cardWidth,
          ),
          _buildMetaCard(
            caption: 'SYNC STATUS',
            value: 'Live across 18 Hubs',
            icon: Icons.hub_outlined,
            valueColor: PtTheme.deepGreen,
            width: cardWidth,
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items,
        );
      },
    );
  }

  Widget _buildMetaCard({
    required String caption,
    required String value,
    required IconData icon,
    required double width,
    Color? valueColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  caption,
                  style: PtTheme.font(
                    10,
                    lineHeight: 14,
                    weight: FontWeight.w700,
                    color: PtTheme.muted,
                    tracking: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 14, color: PtTheme.muted),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: PtTheme.font(
              14,
              lineHeight: 18,
              weight: FontWeight.w700,
              color: valueColor ?? PtTheme.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualLanguageSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 750;

        final enCard = _buildLanguageCard(
          language: 'English',
          subtag: 'Primary Source',
          code: 'EN-US',
          isPrimary: true,
          titleLabel: 'Label',
          titleController: _titleEnController,
          titleKey: const Key('input-item-title-en'),
          descLabel: 'Instructions',
          descSubtitle: 'Field Technician Guide',
          descController: _descEnController,
          descKey: const Key('input-item-desc-en'),
          helpText:
              'Displays on technician rugged tablets during Step 2 of Chassis Inspection.',
          isRtl: false,
        );

        final arCard = _buildLanguageCard(
          language: 'عربي (Arabic)',
          subtag: 'Auto-synchronized',
          code: 'AR-SA (RTL)',
          isPrimary: false,
          titleLabel: 'التسمية (العنوان)',
          titleController: _titleArController,
          titleKey: const Key('input-item-title-ar'),
          descLabel: 'تعليمات الفحص',
          descSubtitle: 'دليل الفني الميداني',
          descController: _descArController,
          descKey: const Key('input-item-desc-ar'),
          helpText:
              'تم التحقق من دقة المصطلحات الفنية الميكانيكية باللغة العربية المعتمدة.',
          isRtl: true,
        );

        if (isStacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              enCard,
              const SizedBox(height: 20),
              arCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: enCard),
            const SizedBox(width: 20),
            Expanded(child: arCard),
          ],
        );
      },
    );
  }

  Widget _buildLanguageCard({
    required String language,
    required String subtag,
    required String code,
    required bool isPrimary,
    required String titleLabel,
    required TextEditingController titleController,
    required Key titleKey,
    required String descLabel,
    required String descSubtitle,
    required TextEditingController descController,
    required Key descKey,
    required String helpText,
    required bool isRtl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    language,
                    style: PtTheme.font(
                      17,
                      lineHeight: 22,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? PtTheme.deepGreen.withValues(alpha: 0.1)
                          : PtTheme.canvas,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subtag,
                      style: PtTheme.font(
                        10,
                        lineHeight: 14,
                        weight: FontWeight.w700,
                        color: isPrimary ? PtTheme.deepGreen : PtTheme.muted,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                code,
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w600,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Title field
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                titleLabel,
                style: PtTheme.font(
                  13,
                  lineHeight: 18,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              Text(
                isRtl ? 'مطلوب' : 'Required',
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w600,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            key: titleKey,
            controller: titleController,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            style: PtTheme.font(
              15,
              lineHeight: 20,
              weight: FontWeight.w600,
              color: PtTheme.ink,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: PtTheme.canvas,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: PtTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: PtTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: PtTheme.deepGreen, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Description / Instructions field
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                descLabel,
                style: PtTheme.font(
                  13,
                  lineHeight: 18,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              Text(
                descSubtitle,
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w600,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            key: descKey,
            controller: descController,
            maxLines: 4,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            style: PtTheme.font(
              14,
              lineHeight: 20,
              weight: FontWeight.w400,
              color: PtTheme.ink,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: PtTheme.canvas,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: PtTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: PtTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: PtTheme.deepGreen, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Helper note
          Text(
            helpText,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            style: PtTheme.font(
              11,
              lineHeight: 16,
              weight: FontWeight.w400,
              color: PtTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualSchematicCard() {
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visual Reference & Schematic',
            style: PtTheme.font(
              18,
              lineHeight: 24,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional guide illustration for caliper positioning',
            style: PtTheme.font(
              13,
              lineHeight: 18,
              weight: FontWeight.w400,
              color: PtTheme.muted,
            ),
          ),

          const SizedBox(height: 16),

          // Upload dropzone box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PtTheme.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: PtTheme.deepGreen.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 22,
                        color: PtTheme.deepGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload Guide Image',
                    style: PtTheme.font(
                      15,
                      lineHeight: 20,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Drag diagnostic diagram or reference illustration here (PNG, JPG up to 10MB)',
                    textAlign: TextAlign.center,
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w400,
                      color: PtTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildChipPill('Vector / Micro-diagrams Accepted'),
                      _buildChipPill('Auto-rotated for In-shop Tablets'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Attached schematic files list
          for (final file in _attachedSchematics) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PtTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 18,
                    color: PtTheme.deepGreen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      file,
                      style: PtTheme.font(
                        13,
                        lineHeight: 18,
                        weight: FontWeight.w600,
                        color: PtTheme.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: PtTheme.muted,
                    ),
                    onPressed: () {
                      setState(() => _attachedSchematics.remove(file));
                    },
                  ),
                ],
              ),
            ),
          ],

          OutlinedButton.icon(
            key: const Key('btn-add-schematic-angle'),
            onPressed: () {
              setState(() {
                _attachedSchematics.add(
                  'caliper_secondary_angle_${DateTime.now().second}.png (1.2 MB)',
                );
              });
            },
            icon: const Icon(Icons.add, size: 16, color: PtTheme.deepGreen),
            label: Text(
              '+ Add Secondary Angle',
              style: PtTheme.font(
                12,
                lineHeight: 16,
                weight: FontWeight.w700,
                color: PtTheme.deepGreen,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: PtTheme.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PtTheme.border),
      ),
      child: Text(
        text,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w500,
          color: PtTheme.muted,
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        // Audit modification info
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 15,
              color: PtTheme.muted,
            ),
            Text(
              'Last modified 14 minutes ago by Inspector Lead Vance',
              style: PtTheme.font(
                13,
                lineHeight: 18,
                weight: FontWeight.w400,
                color: PtTheme.muted,
              ),
            ),
          ],
        ),

        // Action Buttons
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('btn-cancel-edit-item'),
              onPressed: () => context.go('/master-library'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: PtTheme.border, width: 1.5),
                backgroundColor: PtTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: Text(
                'Cancel',
                style: PtTheme.font(
                  14,
                  lineHeight: 20,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                ),
              ),
            ),
            ElevatedButton(
              key: const Key('btn-save-master-item'),
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: PtTheme.deepGreen,
                foregroundColor: PtTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
                elevation: 2,
                shadowColor: const Color(0x33006C49),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PtTheme.white,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: PtTheme.font(
                        14,
                        lineHeight: 20,
                        weight: FontWeight.w700,
                        color: PtTheme.white,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
