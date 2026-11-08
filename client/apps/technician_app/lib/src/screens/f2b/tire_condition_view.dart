import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';
import 'package:technician_app/src/ui_helpers.dart';

/// Screen 12. Tire Condition Capture screen built pixel-perfect to Figma spec.
class TireConditionView extends StatefulWidget {
  const TireConditionView({
    this.job,
    this.isFigma = false,
    this.onSave,
    this.onBack,
    this.onProfile,
    this.onSelectTire,
    super.key,
  });

  final TechnicianJob? job;
  final bool isFigma;
  final VoidCallback? onSave;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final ValueChanged<String>? onSelectTire;

  @override
  State<TireConditionView> createState() => _TireConditionViewState();
}

class _TireConditionViewState extends State<TireConditionView> {
  String _selectedTire = 'RLT';
  String _selectedCondition = 'As New';
  double _treadDepth = 7.2;

  void _selectTire(String code) {
    setState(() {
      _selectedTire = code;
    });
    widget.onSelectTire?.call(code);
  }

  void _stepDepth(double delta) {
    setState(() {
      _treadDepth = ((_treadDepth + delta) * 10).round() / 10;
      if (_treadDepth < 0) _treadDepth = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 80, 20, 40),
              children: <Widget>[
                _buildProgressSequence(l10n),
                const SizedBox(height: 24),
                _buildChassisCard(),
                const SizedBox(height: 24),
                _buildDetailSheet(l10n),
              ],
            ),
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: F2bFocusFrame(
              borderRadius: BorderRadius.zero,
              child: FxHeader(
                title: widget.isFigma
                    ? 'Vehicle Walkaround Inspection'
                    : 'Vehicle Walkaround Inspection',
                titleInset: 4.5,
                titleStyle: Fx.text(
                  18,
                  24,
                  FontWeight.w700,
                  -0.45,
                  color: const Color(0xFF1A1B1F),
                ),
                showBack: widget.onBack != null,
                leading: widget.onBack != null
                    ? Semantics(
                        button: true,
                        label: 'Back',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: widget.onBack,
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: FxIcon(
                                  id: '1_8627',
                                  width: 11.78,
                                  height: 20,
                                  color: Color(0xFF1A1B1F),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
                actions: <Widget>[
                  Semantics(
                    button: true,
                    label: l10n?.technicianProfileTitle ?? 'Profile',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: widget.onProfile,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF006C49),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const FxIcon(
                            id: '1_8632',
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSequence(AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Kicker row (y: 80 to 94)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'INSPECTION SEQUENCE',
              style: Fx.text(
                11,
                14,
                FontWeight.w600,
                1.1,
                color: const Color(0xFF5E5D69),
              ),
            ),
            Text(
              '6 of 8 Completed',
              style: Fx.text(
                11,
                14,
                FontWeight.w700,
                0.44,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Progress bar (y: 98 to 104)
        Container(
          width: 350,
          height: 6,
          decoration: BoxDecoration(
            
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: 0.75,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Heading 2 (y: 116 to 180)
        Text(
          'Step 6: Set condition for\neach tyre',
          style: Fx.text(
            26,
            32,
            FontWeight.w800,
            -0.65,
            color: const Color(0xFF1A1B1F),
          ),
        ),
        const SizedBox(height: 4),
        // Subtitle (y: 184 to 220)
        Text(
          'Tap any wheel position on the chassis to log physical\nwear.',
          style: Fx.text(
            13,
            18,
            FontWeight.w400,
            0,
            color: const Color(0xFF5E5D69),
          ),
        ),
      ],
    );
  }

  Widget _buildChassisCard() {
    return Container(
      key: const ValueKey('chassis-card'),
      width: 350,
      height: 288,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 50,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: <Widget>[
            // Chassis wireframe illustration
            Positioned(
              left: 87,
              top: 16,
              width: 176,
              height: 256,
              child: FxIcon(
                id: 'Minimalist_SVG_Top-Down_Car_Chassis-1_8499',
                width: 176,
                height: 256,
              ),
            ),
            // Front Left (FL) pin
            Positioned(
              left: 40,
              top: 48,
              child: _buildPin(
                label: 'FL',
                selected: _selectedTire == 'FL',
                onTap: () => _selectTire('FL'),
              ),
            ),
            // Front Right (FR) pin
            Positioned(
              left: 282,
              top: 48,
              child: _buildPin(
                label: 'FR',
                selected: _selectedTire == 'FR',
                onTap: () => _selectTire('FR'),
              ),
            ),
            // Rear Right (RR) pin
            Positioned(
              left: 282,
              top: 204,
              child: _buildPin(
                label: 'RR',
                selected: _selectedTire == 'RR',
                onTap: () => _selectTire('RR'),
              ),
            ),
            // Rear Left (RLT) pin & callout
            Positioned(
              left: 24,
              top: 173,
              child: _buildActiveRltPin(),
            ),
            // Micro diagnostic legend indicator: Active Zone
            Positioned(
              left: 234.5,
              top: 247.5,
              child: Container(
                width: 99.5,
                height: 28.5,
                padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
                decoration: BoxDecoration(
                  color: const Color(0xE5FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Zone',
                      maxLines: 1,
                      softWrap: false,
                      style: Fx.text(
                        11,
                        16.5,
                        FontWeight.w600,
                        -0.28,
                        color: const Color(0xFF1A1B1F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPin({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Fx.text(
            11,
            14,
            FontWeight.w700,
            0.44,
            color: const Color(0xFF5E5D69),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRltPin() {
    return GestureDetector(
      onTap: () => _selectTire('RLT'),
      child: SizedBox(
        width: 36,
        height: 59,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: <Widget>[
            // Bottom RLT pill FIRST so emerald glow casts over it
            Positioned(
              bottom: 0,
              child: Container(
                width: 34.6,
                height: 19,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'RLT',
                  style: Fx.text(
                    10,
                    15,
                    FontWeight.w800,
                    0.5,
                    color: const Color(0xFF1A1B1F),
                  ),
                ),
              ),
            ),
            // 36x36 emerald circle button SECOND
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x5910B981),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const FxIcon(
                id: '1_8522',
                width: 13.6,
                height: 10,
                color: Colors.white,
              ),
            ),
            // Top-right indicator dot (12x12 white, 8x8 emerald)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSheet(AppLocalizations? l10n) {
    return Container(
      key: const ValueKey('detail-card'),
      width: 350,
      height: 489.5,
      padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 50,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header row with axle placement and quick status (y: 580 to 620)
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F3F8),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const FxIcon(
                  id: '1_8541',
                  width: 20.2,
                  height: 17.4,
                  color: Color(0xFF1A1B1F),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'RLT — Rear Left Tyre',
                      style: Fx.text(
                        16,
                        22,
                        FontWeight.w700,
                        -0.4,
                        color: const Color(0xFF1A1B1F),
                      ),
                    ),
                    Text(
                      'Axle 2 • Michelin Pilot Sport 4S',
                      style: Fx.text(
                        13,
                        18,
                        FontWeight.w400,
                        0,
                        color: const Color(0xFF5E5D69),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Verified',
                  style: Fx.text(
                    11,
                    14,
                    FontWeight.w700,
                    0.44,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Physical wear assessment (y: 640 to 656)
          Text(
            'Physical Wear Assessment',
            style: Fx.text(
              12,
              16,
              FontWeight.w600,
              0.24,
              color: const Color(0xFF5E5D69),
            ),
          ),
          const SizedBox(height: 8),
          // 2 buttons (y: 664 to 756)
          Row(
            children: <Widget>[
              // As New button
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCondition = 'As New'),
                  child: Container(
                    height: 93,
                    decoration: BoxDecoration(
                      color: _selectedCondition == 'As New'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF4F3F8),
                      boxShadow: _selectedCondition == 'As New'
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x4010B981),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 16),
                        FxIcon(
                          id: '1_8557',
                          width: 22,
                          height: 20,
                          color: _selectedCondition == 'As New'
                              ? Colors.white
                              : const Color(0xFF5E5D69),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'As New',
                          style: Fx.text(
                            14,
                            18,
                            FontWeight.w700,
                            -0.14,
                            color: _selectedCondition == 'As New'
                                ? Colors.white
                                : const Color(0xFF1A1B1F),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'OEM Standard (>6mm)',
                          style: Fx.text(
                            11,
                            16.5,
                            FontWeight.w400,
                            0,
                            color: _selectedCondition == 'As New'
                                ? Colors.white
                                : const Color(0xFF5E5D69),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Part Worn button
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCondition = 'Part Worn'),
                  child: Container(
                    height: 93,
                    decoration: BoxDecoration(
                      color: _selectedCondition == 'Part Worn'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF4F3F8),
                      boxShadow: _selectedCondition == 'Part Worn'
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x4010B981),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 16),
                        FxIcon(
                          id: '1_8566',
                          size: 20,
                          color: _selectedCondition == 'Part Worn'
                              ? Colors.white
                              : const Color(0xFF5E5D69),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Part Worn',
                          style: Fx.text(
                            14,
                            18,
                            FontWeight.w700,
                            -0.14,
                            color: _selectedCondition == 'Part Worn'
                                ? Colors.white
                                : const Color(0xFF1A1B1F),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Usable Wear (3-6mm)',
                          style: Fx.text(
                            11,
                            16.5,
                            FontWeight.w400,
                            0,
                            color: _selectedCondition == 'Part Worn'
                                ? Colors.white
                                : const Color(0xFF5E5D69),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Measured groove depth (y: 773 to 789)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Measured Groove Depth',
                style: Fx.text(
                  12,
                  16,
                  FontWeight.w600,
                  0.24,
                  color: const Color(0xFF5E5D69),
                ),
              ),
              Text(
                'Legal Minimum: 1.6 mm',
                style: Fx.text(
                  11,
                  14,
                  FontWeight.w700,
                  0.44,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stepper container (y: 797 to 865)
          Container(
            height: 68,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 25,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const FxIcon(
                    id: '1_8582',
                    width: 15,
                    height: 9,
                    color: Color(0xFF1A1B1F),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tread Depth\n(mm)',
                  style: Fx.text(
                    14,
                    20,
                    FontWeight.w600,
                    -0.07,
                    color: const Color(0xFF1A1B1F),
                  ),
                ),
                const Spacer(),
                // Minus button
                GestureDetector(
                  onTap: () => _stepDepth(-0.1),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const FxIcon(
                      id: '1_8588',
                      width: 9.3,
                      height: 1.3,
                      color: Color(0xFF1A1B1F),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tread value box
                Container(
                  width: 64,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsetsDirectional.only(start: 13),
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    _treadDepth.toStringAsFixed(1),
                    style: Fx.text(
                      16,
                      22,
                      FontWeight.w700,
                      -0.16,
                      color: const Color(0xFF1A1B1F),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Plus button
                GestureDetector(
                  onTap: () => _stepDepth(0.1),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const FxIcon(
                      id: '1_8598',
                      size: 9.3,
                      color: Color(0xFF1A1B1F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Tire wall & pressure quick snapshot (y: 885 to 941.5)
          Row(
            children: <Widget>[
              // Cold pressure
              Expanded(
                child: Container(
                  height: 56.5,
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F3F8),
                  ),
                  child: Row(
                    children: <Widget>[
                      const FxIcon(
                        id: '1_8602',
                        width: 16.7,
                        height: 13.3,
                        color: Color(0xFF5E5D69),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Cold Pressure',
                              maxLines: 1,
                              softWrap: false,
                              style: Fx.text(
                                11,
                                16.5,
                                FontWeight.w400,
                                0,
                                color: const Color(0xFF5E5D69),
                              ),
                            ),
                            Text(
                              '34.5 PSI (Norm)',
                              maxLines: 1,
                              softWrap: false,
                              style: Fx.text(
                                12,
                                16,
                                FontWeight.w700,
                                0.24,
                                color: const Color(0xFF1A1B1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sidewall
              Expanded(
                child: Container(
                  height: 56.5,
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F3F8),
                  ),
                  child: Row(
                    children: <Widget>[
                      const FxIcon(
                        id: '1_8610',
                        width: 13.3,
                        height: 16.7,
                        color: Color(0xFF5E5D69),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Sidewall',
                              maxLines: 1,
                              softWrap: false,
                              style: Fx.text(
                                11,
                                16.5,
                                FontWeight.w400,
                                0,
                                color: const Color(0xFF5E5D69),
                              ),
                            ),
                            Text(
                              'No Gouges / Flaws',
                              maxLines: 1,
                              softWrap: false,
                              style: Fx.text(
                                12,
                                16,
                                FontWeight.w700,
                                0.24,
                                color: const Color(0xFF1A1B1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // SAVE CTA button (y: 965.5 to 1021.5)
          Semantics(
            button: true,
            label: 'SAVE',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: widget.onSave,
                child: Container(
                  key: const ValueKey('save-button'),
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x4D10B981),
                        blurRadius: 25,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const FxIcon(
                        id: '1_8619',
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SAVE',
                        style: Fx.text(
                          14,
                          18,
                          FontWeight.w700,
                          0.35,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
