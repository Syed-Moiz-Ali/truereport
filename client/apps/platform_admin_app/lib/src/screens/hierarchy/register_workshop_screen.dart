import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class RegisterWorkshopScreen extends ConsumerStatefulWidget {
  const RegisterWorkshopScreen({super.key});

  @override
  ConsumerState<RegisterWorkshopScreen> createState() =>
      _RegisterWorkshopScreenState();
}

class _RegisterWorkshopScreenState
    extends ConsumerState<RegisterWorkshopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedTemplate = '100-Point Standard Check v2.0';
  String _templateSubtitle =
      'Verified fleet standard • Mechanical, OBD-II, and Body Exterior';
  bool _autoSyncMasterCatalog = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<Map<String, String>> _availableTemplates = [
    {
      'title': '100-Point Standard Check v2.0',
      'subtitle':
          'Verified fleet standard • Mechanical, OBD-II, and Body Exterior',
    },
    {
      'title': 'Heavy Commercial Powertrain Audit',
      'subtitle':
          'Multi-axle torque matrices, hydraulic baseline & pneumatic seals',
    },
    {
      'title': 'Express EV Health Scan v1.4',
      'subtitle':
          'HV battery state-of-health, regenerative brake loop & thermal loop',
    },
    {
      'title': 'Quick Safety & Fluids Baseline',
      'subtitle':
          'Rapid 35-point safety inspection for turnaround fleet maintenance',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _demoQuickFill() {
    setState(() {
      _nameController.text = 'Apex Fleet Central';
      _locationController.text = 'San Francisco Bay Area';
      _emailController.text = 'operations@apexfleet.com';
      _selectedTemplate = '100-Point Standard Check v2.0';
      _templateSubtitle =
          'Verified fleet standard • Mechanical, OBD-II, and Body Exterior';
      _autoSyncMasterCatalog = true;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Workshop business name is required.');
      return;
    }
    if (email.isNotEmpty && !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid contact email address.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(platformApiProvider);
      HierarchyWorkshop newWorkshop;
      try {
        newWorkshop = await api.registerWorkshop(
          name: name,
          location: location.isEmpty ? 'Primary Facility' : location,
          contactEmail: email.isEmpty
              ? 'operations@${name.toLowerCase().replaceAll(RegExp(r'\s+'), '')}.com'
              : email,
          initialTemplate: _selectedTemplate,
          autoSyncMasterCatalog: _autoSyncMasterCatalog,
        );
      } catch (_) {
        // Standalone / offline mock fallback
        final id = 'workshop-${DateTime.now().millisecondsSinceEpoch}';
        newWorkshop = HierarchyWorkshop(
          id: id,
          name: name,
          branchName: location.isEmpty ? 'Global Regional Station' : location,
          status: 'ACTIVE',
          memberCount: 1,
          bayCount: 6,
          assignedCapacityPercent: 0,
          contactEmail: email,
          initialTemplate: _selectedTemplate,
          autoSyncMasterCatalog: _autoSyncMasterCatalog,
          admins: [],
          technicians: [],
          pendingInvitations: [],
        );
      }

      // Add to local state so tree navigator & dropdowns immediately reflect it
      ref.read(localWorkshopsProvider.notifier).addWorkshop(newWorkshop);
      ref.read(selectedWorkshopIdProvider.notifier).select(newWorkshop.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PtTheme.deepGreen,
            content: Text(
              'Workshop "$name" provisioned successfully.',
              style: PtTheme.font(14, color: PtTheme.white, weight: FontWeight.w600),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        _returnToWorkshops();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to create workshop: ${e.toString()}';
        });
      }
    }
  }

  void _returnToWorkshops() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/workshops');
    }
  }

  void _showTemplatePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PtTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Initial Inspection Template',
                      style: PtTheme.font(
                        16,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._availableTemplates.map((tpl) {
                  final isSelected = tpl['title'] == _selectedTemplate;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _selectedTemplate = tpl['title']!;
                        _templateSubtitle = tpl['subtitle']!;
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? PtTheme.deepGreen.withValues(alpha: 0.06)
                            : PtTheme.canvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? PtTheme.deepGreen
                              : PtTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            size: 20,
                            color: isSelected
                                ? PtTheme.deepGreen
                                : PtTheme.muted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tpl['title']!,
                                  style: PtTheme.font(
                                    14,
                                    weight: FontWeight.w600,
                                    color: PtTheme.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tpl['subtitle']!,
                                  style: PtTheme.font(
                                    12,
                                    color: PtTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 880;

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sidebar (Visible on desktop)
          if (isDesktop)
            PlatformSidebar(
              currentRoute: '/workshops',
              onNavigate: (route) => context.go(route),
            ),

          // 2. Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Global Header
                const PlatformHeader(),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: 32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 896),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Breadcrumbs & Page Identification
                            _buildBreadcrumbsAndHeader(),

                            const SizedBox(height: 28),

                            // 2. Massive Centered Pure White Card
                            _buildRegistrationCard(context, isDesktop),
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

  Widget _buildBreadcrumbsAndHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb Trail
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text(
              'PLATFORM',
              style: PtTheme.font(
                11,
                lineHeight: 14,
                weight: FontWeight.w700,
                color: PtTheme.muted,
                tracking: 0.6,
              ),
            ),
            Text(
              '/',
              style: PtTheme.font(
                11,
                lineHeight: 14,
                color: PtTheme.muted,
              ),
            ),
            InkWell(
              onTap: _returnToWorkshops,
              child: Text(
                'WORKSHOPS',
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                  tracking: 0.6,
                ),
              ),
            ),
            Text(
              '/',
              style: PtTheme.font(
                11,
                lineHeight: 14,
                color: PtTheme.muted,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: PtTheme.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                'NEW ENTITY',
                style: PtTheme.font(
                  10,
                  lineHeight: 12,
                  weight: FontWeight.w700,
                  color: PtTheme.emerald,
                  tracking: 0.6,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // H1 Heading
        Text(
          'Register New Workshop',
          style: PtTheme.font(
            32,
            lineHeight: 38,
            weight: FontWeight.w800,
            color: PtTheme.ink,
            tracking: -0.6,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle Description
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'Deploy a new operational node to your inspection grid. Provision baseline inspection profiles, localized diagnostics, and technician seat configurations.',
            style: PtTheme.font(
              14,
              lineHeight: 20,
              weight: FontWeight.w400,
              color: PtTheme.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationCard(BuildContext context, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 60,
            offset: Offset(0, 20),
          ),
        ],
      ),
      padding: EdgeInsets.all(isDesktop ? 40 : 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error banner if any
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFB91C1C), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: PtTheme.font(
                          13,
                          lineHeight: 18,
                          weight: FontWeight.w500,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section 1: Entity Information Group
            _buildField(
              key: const Key('input-workshop-name'),
              controller: _nameController,
              label: 'Workshop Business Name',
              badge: 'REQUIRED',
              hintText: 'e.g. Apex Fleet Central',
              helperText:
                  'The legal or operational hub identifier used in multi-facility reporting.',
              icon: Icons.business_outlined,
            ),

            const SizedBox(height: 28),

            _buildField(
              key: const Key('input-workshop-location'),
              controller: _locationController,
              label: 'Location / Region',
              hintText: 'e.g. San Francisco Bay Area',
              helperText:
                  'Determines regional compliance standards and daylight calibration defaults.',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 28),

            _buildField(
              key: const Key('input-workshop-email'),
              controller: _emailController,
              label: 'Primary Contact Email',
              hintText: 'e.g. operations@apexfleet.com',
              helperText:
                  'Receives root node provisioning credentials and critical shift digests.',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 32),

            // Section 2: Initial Inspection Template Assignment
            _buildTemplateSelector(),

            const SizedBox(height: 28),

            // Section 3: Node Configuration Pill Selector
            _buildSyncPillSelector(),

            const SizedBox(height: 36),

            // Section 4: Submission Row
            _buildSubmissionRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String helperText,
    required IconData icon,
    String? badge,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + optional Badge
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              label,
              style: PtTheme.font(
                14,
                lineHeight: 20,
                weight: FontWeight.w600,
                color: PtTheme.ink,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: PtTheme.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  badge,
                  style: PtTheme.font(
                    10,
                    lineHeight: 12,
                    weight: FontWeight.w700,
                    color: PtTheme.emerald,
                    tracking: 0.5,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Input Field
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PtTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: key,
                  controller: controller,
                  keyboardType: keyboardType,
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    weight: FontWeight.w500,
                    color: PtTheme.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: PtTheme.font(
                      14,
                      lineHeight: 20,
                      weight: FontWeight.w400,
                      color: PtTheme.muted.withValues(alpha: 0.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  icon,
                  size: 18,
                  color: PtTheme.muted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Helper explanation text
        Text(
          helperText,
          style: PtTheme.font(
            12,
            lineHeight: 16,
            weight: FontWeight.w400,
            color: PtTheme.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Initial Template',
          style: PtTheme.font(
            14,
            lineHeight: 20,
            weight: FontWeight.w600,
            color: PtTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('template-selector-card'),
            onTap: _showTemplatePicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: PtTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PtTheme.border),
              ),
              child: Row(
                children: [
                  // Green Pill Indicator Dot
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: PtTheme.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Template Title & Description
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTemplate,
                          style: PtTheme.font(
                            14,
                            lineHeight: 20,
                            weight: FontWeight.w700,
                            color: PtTheme.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _templateSubtitle,
                          style: PtTheme.font(
                            12,
                            lineHeight: 16,
                            weight: FontWeight.w400,
                            color: PtTheme.muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Trailing Dropdown Arrow Button
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: PtTheme.canvas,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: PtTheme.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncPillSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Green Leading Sync Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: PtTheme.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.sync_rounded,
                size: 20,
                color: PtTheme.emerald,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automatic Master Catalog Sync',
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    weight: FontWeight.w600,
                    color: PtTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Propagate centralized OEM repair schemas and torque matrices immediately',
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
                    weight: FontWeight.w400,
                    color: PtTheme.muted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Tactile Switch
          Switch.adaptive(
            key: const Key('switch-master-catalog-sync'),
            value: _autoSyncMasterCatalog,
            activeThumbColor: PtTheme.emerald,
            activeTrackColor: PtTheme.emerald.withValues(alpha: 0.3),
            onChanged: (val) {
              setState(() => _autoSyncMasterCatalog = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          final discardButton = InkWell(
            key: const Key('btn-discard-return'),
            onTap: _returnToWorkshops,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: PtTheme.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Discard & Return',
                    style: PtTheme.font(
                      14,
                      lineHeight: 20,
                      weight: FontWeight.w600,
                      color: PtTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          );

          final demoFillButton = TextButton(
            key: const Key('btn-demo-quick-fill'),
            onPressed: _demoQuickFill,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'DEMO FILL',
              style: PtTheme.font(
                12,
                weight: FontWeight.w700,
                color: PtTheme.deepGreen,
                tracking: 0.4,
              ),
            ),
          );

          final submitButton = Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('btn-create-workshop'),
              onTap: _isSubmitting ? null : _submit,
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: PtTheme.emerald,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2610B981),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSubmitting) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PtTheme.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      'Create Workshop',
                      style: PtTheme.font(
                        15,
                        lineHeight: 20,
                        weight: FontWeight.w700,
                        color: PtTheme.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: PtTheme.white,
                    ),
                  ],
                ),
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: submitButton),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    discardButton,
                    demoFillButton,
                  ],
                ),
              ],
            );
          }

          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              discardButton,
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  demoFillButton,
                  submitButton,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
