import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

/// Screen 2 — Add Staff / Create Account (`02_2._Add_Staff_-_Create_Account`).
///
/// Pixel-perfect 440px wide slide-out creation panel matching Figma specification.
/// Features:
/// - Slide-out drawer layout (440px width) with soft drop shadow
/// - Header with "Create Staff Account" and subtitle
/// - Circular close button trigger (`Key('btn-close-add-staff')`)
/// - Full Name input field (`Key('input-staff-name')`)
/// - Email Address input field (`Key('input-staff-email')`)
/// - Temporary Password input field with visibility toggle (`Key('input-staff-password')`)
/// - Assign Role dropdown with status dot (`Key('dropdown-staff-role')`)
/// - Assign Workshop dropdown with status dot (`Key('dropdown-staff-workshop')`)
/// - Secure credential dispatch notice banner
/// - Primary Create Account pill button (`Key('btn-create-staff-submit')`)
class AddStaffSlideOutPanel extends ConsumerStatefulWidget {
  const AddStaffSlideOutPanel({
    super.key,
    required this.onClose,
    this.initialWorkshopId,
    this.onAccountCreated,
  });

  final VoidCallback onClose;
  final String? initialWorkshopId;
  final ValueChanged<PlatformAccount>? onAccountCreated;

  @override
  ConsumerState<AddStaffSlideOutPanel> createState() =>
      _AddStaffSlideOutPanelState();
}

class _AddStaffSlideOutPanelState extends ConsumerState<AddStaffSlideOutPanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Precision-Auth-2024');

  bool _obscurePassword = false;
  bool _submitting = false;
  String? _errorMessage;

  String _selectedRole = 'Workshop Admin';
  late String _selectedWorkshopId;

  static const _roles = [
    'Workshop Admin',
    'Lead Inspector',
    'Diagnostic Tech',
    'Shop Floor Supervisor',
    'Optics & Sensor Calibration',
  ];

  @override
  void initState() {
    super.initState();
    _selectedWorkshopId = widget.initialWorkshopId ?? 'workshop-1';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemo() {
    setState(() {
      _nameController.text = 'Marcus Vance';
      _emailController.text = 'm.vance@coreos-grid.internal';
      _passwordController.text = 'Precision-Auth-2024';
      _selectedRole = 'Workshop Admin';
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(platformApiProvider);
      final account = await api.createUser(
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        temporaryPassword: _passwordController.text.trim(),
        role: _selectedRole,
        workshopId: _selectedWorkshopId,
      );

      if (!mounted) return;

      // Invalidate hierarchy provider so list refreshes
      ref.invalidate(hierarchyStateProvider);

      widget.onAccountCreated?.call(account);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Staff account for "${account.displayName}" created successfully.',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      widget.onClose();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to create staff account: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hierarchyAsync = ref.watch(hierarchyStateProvider);
    final workshops = hierarchyAsync.value?.workshops ?? sampleWorkshops;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = screenWidth < 460 ? screenWidth : 440.0;
    final isCompact = screenWidth < 460;

    return Container(
      width: panelWidth,
      decoration: const BoxDecoration(
        color: PtTheme.white,
        border: Border(
          left: BorderSide(color: Color(0xFFE9E7ED)),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(-6, 0),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 40,
            offset: Offset(-16, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 20 : 32,
                  isCompact ? 20 : 32,
                  isCompact ? 20 : 32,
                  16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Panel Header & Close Trigger
                      _buildHeader(),

                      const SizedBox(height: 24),

                      // Demo Quick-Fill Pill
                      InkWell(
                        key: const Key('btn-fill-staff-demo'),
                        onTap: _fillDemo,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_fix_high_rounded,
                                size: 14,
                                color: Color(0xFF006C49),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Quick-fill Figma sample staff',
                                style: PtTheme.font(
                                  11,
                                  lineHeight: 14,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF006C49),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Error message if any
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: PtTheme.font(
                                    12,
                                    lineHeight: 16,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 2. Field: Full Name
                      _buildFieldLabel('FULL NAME'),
                      const SizedBox(height: 8),
                      _buildTextInput(
                        key: const Key('input-staff-name'),
                        controller: _nameController,
                        hintText: 'e.g. Marcus Vance',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 3. Field: Email Address
                      _buildFieldLabel('EMAIL ADDRESS'),
                      const SizedBox(height: 8),
                      _buildTextInput(
                        key: const Key('input-staff-email'),
                        controller: _emailController,
                        hintText: 'm.vance@coreos-grid.internal',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email address is required';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 4. Field: Temporary Password
                      _buildFieldLabel('TEMPORARY PASSWORD'),
                      const SizedBox(height: 8),
                      _buildTextInput(
                        key: const Key('input-staff-password'),
                        controller: _passwordController,
                        hintText: 'Precision-Auth-2024',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          key: const Key('btn-toggle-staff-password'),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: PtTheme.muted,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Temporary password is required';
                          }
                          if (v.trim().length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 5. Dropdown: Assign Role
                      _buildFieldLabel('ASSIGN ROLE'),
                      const SizedBox(height: 8),
                      _buildDropdown<String>(
                        key: const Key('dropdown-staff-role'),
                        value: _selectedRole,
                        items: _roles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  role,
                                  style: PtTheme.font(
                                    14,
                                    lineHeight: 20,
                                    weight: FontWeight.w600,
                                    color: PtTheme.ink,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRole = val);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // 6. Dropdown: Assign Workshop
                      _buildFieldLabel('ASSIGN WORKSHOP'),
                      const SizedBox(height: 8),
                      _buildDropdown<String>(
                        key: const Key('dropdown-staff-workshop'),
                        value: _selectedWorkshopId,
                        items: workshops.map((w) {
                          final label = '${w.name} - ${w.branchName}';
                          return DropdownMenuItem<String>(
                            value: w.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    label,
                                    overflow: TextOverflow.ellipsis,
                                    style: PtTheme.font(
                                      14,
                                      lineHeight: 20,
                                      weight: FontWeight.w600,
                                      color: PtTheme.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedWorkshopId = val);
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // 7. Notification Banner / Micro Context
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F3F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Credentials and activation token will be dispatched instantly via secure push.',
                                style: PtTheme.font(
                                  11,
                                  lineHeight: 16,
                                  weight: FontWeight.w500,
                                  color: PtTheme.muted,
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
            ),

            // Bottom Action CTA Footer
            Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 20 : 32,
                16,
                isCompact ? 20 : 32,
                isCompact ? 20 : 32,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  key: const Key('btn-create-staff-submit'),
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: PtTheme.white,
                    disabledBackgroundColor:
                        const Color(0xFF10B981).withValues(alpha: 0.5),
                    elevation: 3,
                    shadowColor: const Color(0x3310B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Create Account',
                              style: PtTheme.font(
                                14,
                                lineHeight: 18,
                                weight: FontWeight.w700,
                                color: PtTheme.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
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

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Staff Account',
                style: PtTheme.font(
                  22,
                  lineHeight: 28,
                  weight: FontWeight.w700,
                  tracking: -0.55,
                  color: PtTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Provision platform and workshop credentials',
                style: PtTheme.font(
                  13,
                  lineHeight: 18,
                  weight: FontWeight.w400,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Close Button (40x40 circle)
        Material(
          color: const Color(0xFFF4F3F8),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            key: const Key('btn-close-add-staff'),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: PtTheme.muted,
            onPressed: widget.onClose,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
            tooltip: Localizations.of<AppLocalizations>(context, AppLocalizations)?.close ?? 'Close',
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: PtTheme.font(
        11,
        lineHeight: 14,
        weight: FontWeight.w700,
        tracking: 0.8,
        color: PtTheme.muted,
      ),
    );
  }

  Widget _buildTextInput({
    required Key key,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9E7ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
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
            color: PtTheme.muted,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required Key key,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9E7ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          key: key,
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF10B981),
            size: 20,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
