import 'package:flutter/material.dart';

/// High-fidelity modal dialog for creating a new inspection template,
/// matching the TrueReport Figma design system.
class NewTemplateDialog extends StatefulWidget {
  const NewTemplateDialog({
    super.key,
    required this.onCreate,
  });

  final Future<void> Function({
    required String name,
    required String description,
    required String serviceType,
    required String vehicleType,
  }) onCreate;

  static Future<bool?> show(
    BuildContext context, {
    required Future<void> Function({
      required String name,
      required String description,
      required String serviceType,
      required String vehicleType,
    }) onCreate,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (ctx) => NewTemplateDialog(onCreate: onCreate),
    );
  }

  @override
  State<NewTemplateDialog> createState() => _NewTemplateDialogState();
}

class _NewTemplateDialogState extends State<NewTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _serviceType = 'FULL';
  String _vehicleType = 'CAR';
  bool _busy = false;

  final List<({String key, String label})> _serviceOptions = const [
    (key: 'FULL', label: 'Full Inspection (360°)'),
    (key: 'SAFETY', label: 'Safety & Compliance'),
    (key: 'MECHANICAL', label: 'Mechanical & Brakes'),
    (key: 'PRE_PURCHASE', label: 'Pre-Purchase (PPI)'),
  ];

  final List<({String key, String label})> _vehicleOptions = const [
    (key: 'CAR', label: 'Passenger Car / SUV'),
    (key: 'LIGHT_COMMERCIAL', label: 'Van / Ute'),
    (key: 'HEAVY_TRUCK', label: 'Heavy Commercial'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await widget.onCreate(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        serviceType: _serviceType,
        vehicleType: _vehicleType,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create template: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: Container(
          width: 520,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0F000000),
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 20),
                blurRadius: 48,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F3F8),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE3E2E7), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1B1F),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.dashboard_customize_rounded,
                            color: Color(0xFF10B981),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Inspection Template',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1B1F),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Configure service scope & launch visual checklist builder',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                color: Color(0xFF5E5D69),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close, color: Color(0xFF5E5D69), size: 20),
                      ),
                    ],
                  ),
                ),

                // Form Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Template Name
                        const Text(
                          'TEMPLATE NAME',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.55,
                            color: Color(0xFF5E5D69),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          autofocus: true,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1B1F),
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 120-Point Comprehensive EV Inspection',
                            hintStyle: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: Color(0xFF9E9DA8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF4F3F8),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF10B981),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Please enter a template name' : null,
                        ),
                        const SizedBox(height: 20),

                        // Description
                        const Text(
                          'DESCRIPTION',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.55,
                            color: Color(0xFF5E5D69),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descController,
                          maxLines: 2,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            color: Color(0xFF1A1B1F),
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Complete multi-point mechanical, structural, and electrical safety check.',
                            hintStyle: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: Color(0xFF9E9DA8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF4F3F8),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF10B981),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Service Scope Chips
                        const Text(
                          'SERVICE SCOPE',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.55,
                            color: Color(0xFF5E5D69),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _serviceOptions.map((opt) {
                            final isSel = _serviceType == opt.key;
                            return InkWell(
                              onTap: () => setState(() => _serviceType = opt.key),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF1A1B1F) : const Color(0xFFF4F3F8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF1A1B1F) : const Color(0xFFE3E2E7),
                                  ),
                                ),
                                child: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    color: isSel ? Colors.white : const Color(0xFF1A1B1F),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Vehicle Classification Chips
                        const Text(
                          'VEHICLE CATEGORY',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.55,
                            color: Color(0xFF5E5D69),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _vehicleOptions.map((opt) {
                            final isSel = _vehicleType == opt.key;
                            return InkWell(
                              onTap: () => setState(() => _vehicleType = opt.key),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF006C49) : const Color(0xFFF4F3F8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF006C49) : const Color(0xFFE3E2E7),
                                  ),
                                ),
                                child: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    color: isSel ? Colors.white : const Color(0xFF1A1B1F),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F3F8),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE3E2E7), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5E5D69),
                          side: const BorderSide(color: Color(0xFFE3E2E7)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_task_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Create & Open Builder',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
    );
  }
}
