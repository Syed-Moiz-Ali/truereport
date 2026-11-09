import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/screens/f3a/queue_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Screen 2 — Workshop Live Job Queue View (`03_2._Live_Job_Queue`).
///
/// Pixel-perfect desktop layout (1280 x 1125) matching Figma specification.
/// Features:
/// - 96px left navigation rail with TrueReport logo and active Queue button
/// - 80px floating top header with Bay status, search, and user profile
/// - Real-Time Dispatch eyebrow, Live Job Queue title, and Active Bays stat card
/// - "+ New Job" primary CTA
/// - Filter chips: All, In Progress, Pending Review, Completed
/// - Job cards (1104 x 150) with vehicle thumbnail, status pill, VIN, assignee, and progress/review metrics
/// - Live sync footer strip
class WorkshopQueueView extends StatefulWidget {
  const WorkshopQueueView({
    super.key,
    this.selectedNavIndex = 1,
    this.onNavSelected,
    this.onNewJob,
    this.onSearch,
    this.onProfileTap,
    this.onSignOut,
    this.onToggleLocale,
    this.onOpenJob,
    this.jobs,
    this.userName,
    this.userRole,
    this.searchController,
    this.customImages,
    this.customSvgs,
  });

  final int selectedNavIndex;
  final ValueChanged<int>? onNavSelected;
  final VoidCallback? onNewJob;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSignOut;
  final VoidCallback? onToggleLocale;
  final ValueChanged<WorkshopJob>? onOpenJob;
  final List<WorkshopJob>? jobs;
  final String? userName;
  final String? userRole;
  final TextEditingController? searchController;
  final Map<String, ui.Image>? customImages;
  final Map<String, String>? customSvgs;

  static const double width = 1280;
  static const double height = 1125;

  @override
  State<WorkshopQueueView> createState() => _WorkshopQueueViewState();
}

class _WorkshopQueueViewState extends State<WorkshopQueueView> {
  int _activeFilterIndex = 0; // 0: All, 1: In Progress, 2: Pending Review, 3: Completed
  Map<String, ui.Image>? _decodedImages;

  @override
  void initState() {
    super.initState();
    _decodeImages();
  }

  Future<void> _decodeImages() async {
    if (widget.customImages != null) return;
    try {
      final v1 = await _decodePng(QueueAssets.v1Bytes);
      final v2 = await _decodePng(QueueAssets.v2Bytes);
      final v3 = await _decodePng(QueueAssets.v3Bytes);
      final v4 = await _decodePng(QueueAssets.v4Bytes);
      if (mounted) {
        setState(() {
          _decodedImages = {'v1': v1, 'v2': v2, 'v3': v3, 'v4': v4};
        });
      }
    } catch (_) {
      // Fallback if image decode fails
    }
  }

  Future<ui.Image> _decodePng(List<int> bytes) async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  String _svgString(String key) {
    if (widget.customSvgs != null && widget.customSvgs!.containsKey(key)) {
      return widget.customSvgs![key]!;
    }
    switch (key) {
      case 'plus':
        return QueueAssets.plus;
      case 'sort':
        return QueueAssets.sort;
      case 'filter':
        return QueueAssets.filter;
      case 'person1':
        return QueueAssets.person1;
      case 'person3':
        return QueueAssets.person3;
      case 'person4':
        return QueueAssets.person4;
      case 'chev1':
        return QueueAssets.chev1;
      case 'chev2':
        return QueueAssets.chev2;
      case 'chev3':
        return QueueAssets.chev3;
      case 'chev4':
        return QueueAssets.chev4;
      case 'bldg':
        return QueueAssets.bldg;
      case 'clock':
        return QueueAssets.clock;
      case 'search':
        return QueueAssets.search;
      case 'avatarUser':
        return QueueAssets.avatarUser;
      case 'logo':
        return QueueAssets.logo;
      case 'dash':
        return QueueAssets.dash;
      case 'jobs':
        return QueueAssets.jobs;
      case 'gear':
        return QueueAssets.gear;
      case 'help':
        return QueueAssets.help;
      default:
        return '';
    }
  }

  ui.Image? _image(String key) {
    if (widget.customImages != null && widget.customImages!.containsKey(key)) {
      return widget.customImages![key];
    }
    return _decodedImages?[key];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: WorkshopQueueView.width,
          height: WorkshopQueueView.height,
          child: ColoredBox(
            color: Fx.white,
            child: Stack(
              children: [
                Positioned(
                  left: _M.ninetySix,
                  top: _M.zero,
                  width: 1184,
                  height: 1125,
                  child: ColoredBox(color: Fx.white, child: _main(context)),
                ),
                Positioned(
                  key: const ValueKey('f3a-header'),
                  left: _M.ninetySix,
                  top: _M.zero,
                  width: 1184,
                  height: _M.eighty,
                  child: _header(context),
                ),
                Positioned(
                  left: _M.zero,
                  top: _M.zero,
                  width: _M.ninetySix,
                  height: 1101,
                  child: _rail(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _main(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _M.forty,
        _M.eighty,
        _M.forty,
        _M.fortyEight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(context),
          const SizedBox(height: _M.forty),
          _filterRow(),
          const SizedBox(height: _M.thirtyTwo),
          _card(_CardData.porsche, 'v1'),
          const SizedBox(height: _M.twentyFour),
          _card(_CardData.ford, 'v2'),
          const SizedBox(height: _M.twentyFour),
          _card(_CardData.renault, 'v3'),
          const SizedBox(height: _M.twentyFour),
          _card(_CardData.bmw, 'v4'),
          const SizedBox(height: _M.fortyEight),
          _footer(),
        ],
      ),
    );
  }

  Widget _titleRow(BuildContext context) {
    return SizedBox(
      width: 1104,
      height: 107,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 412.73,
            height: 107,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(),
                const SizedBox(height: _M.nine),
                SizedBox(
                  width: 412.73,
                  height: _M.fortySix,
                  child: Padding(
                    padding: const EdgeInsets.only(top: _M.eight),
                    child: _t(
                      'Live Job Queue',
                      412.73,
                      _M.thirtyEight,
                      Fx.text(32, 38, FontWeight.w800, -0.8, color: Fx.ink),
                    ),
                  ),
                ),
                const SizedBox(height: _M.six),
                _t(
                  'All vehicles currently in bays or scheduled for inspection',
                  412.73,
                  _M.twentyFour,
                  Fx.text(16, 24, FontWeight.w500, -0.16, color: Fx.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 238.24),
          SizedBox(
            width: 453.03,
            height: _M.sixtyFour,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statCard(),
                const SizedBox(width: _M.sixteen),
                _newJobButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow() {
    return Container(
      width: 164.39,
      height: _M.twentyTwo,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: _M.twelve),
          Container(
            width: _M.eight,
            height: _M.eight,
            decoration: const BoxDecoration(
              color: Fx.emerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: _M.eight),
          _t(
            'REAL-TIME DISPATCH',
            124.39,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
          ),
          const SizedBox(width: _M.twelve),
        ],
      ),
    );
  }

  Widget _statCard() {
    return Container(
      key: const ValueKey('f3a-stat-card'),
      width: 279.89,
      height: _M.sixtyFour,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _M.twentyFour,
          _M.fourteen,
          _M.twentyFour,
          _M.fourteen,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 73.92,
              height: _M.thirtySix,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _t(
                    'ACTIVE BAYS',
                    73.92,
                    _M.fourteen,
                    Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                  ),
                  _t(
                    '06 / 08',
                    73.92,
                    _M.twentyTwo,
                    Fx.stat16.copyWith(color: Fx.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(width: _M.twentyFour),
            Container(width: _M.one, height: _M.thirtyTwo, color: Fx.divider),
            const SizedBox(width: _M.twentyFour),
            SizedBox(
              width: 108.97,
              height: _M.thirtySix,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _t(
                    'AVG TURNAROUND',
                    108.97,
                    _M.fourteen,
                    Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                  ),
                  _t(
                    '42m',
                    108.97,
                    _M.twentyTwo,
                    Fx.stat16.copyWith(color: Fx.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newJobButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onNewJob,
        borderRadius: const BorderRadius.all(Radius.circular(_M.sixteen)),
        child: Container(
          key: const ValueKey('f3a-new-job'),
          width: 157.14,
          height: _M.fiftySix,
          decoration: const BoxDecoration(
            color: Fx.emerald,
            borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
            boxShadow: Fx.ctaShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: _M.thirtyTwo),
              _svg('plus', 12.83, 12.83),
              const SizedBox(width: _M.twelve),
              _t(
                '+ New Job',
                68.31,
                _M.eighteen,
                Fx.label14.copyWith(color: Fx.white),
              ),
              const SizedBox(width: _M.thirtyTwo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    return SizedBox(
      width: 1104,
      height: _M.fortyEight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key: const ValueKey('f3a-filters'),
            width: 542.1,
            height: _M.fortyEight,
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_M.six),
              child: Row(
                children: [
                  _filterButton('All (12)', 86.52, 0),
                  const SizedBox(width: _M.four),
                  _filterButton('In Progress (4)', 134.06, 1),
                  const SizedBox(width: _M.four),
                  _filterButton('Pending Review (3)', 161.94, 2),
                  const SizedBox(width: _M.four),
                  _filterButton('Completed (5)', 135.58, 3),
                ],
              ),
            ),
          ),
          const SizedBox(width: 398.54),
          SizedBox(
            width: 163.36,
            height: _M.forty,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 111.36,
                  height: _M.thirty,
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: _M.sixteen),
                      _svg('sort', 13.5, 9),
                      const SizedBox(width: _M.eight),
                      _t(
                        'Bay Order',
                        57.86,
                        _M.fourteen,
                        Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.ink),
                      ),
                      const SizedBox(width: _M.sixteen),
                    ],
                  ),
                ),
                const SizedBox(width: _M.twelve),
                Container(
                  width: _M.forty,
                  height: _M.forty,
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12.5),
                      _svg('filter', 15, 10),
                      const SizedBox(width: 12.5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, double width, int index) {
    final active = _activeFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeFilterIndex = index),
      child: Container(
        width: width,
        height: _M.thirtySix,
        decoration: BoxDecoration(
          color: active ? Fx.white : const Color(0x00000000),
          borderRadius: const BorderRadius.all(Radius.circular(Fx.pillRadius)),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: Fx.label12.copyWith(color: active ? Fx.ink : Fx.muted),
        ),
      ),
    );
  }

  Widget _card(_CardData data, String imageKey) {
    return Container(
      key: ValueKey('f3a-card-${data.key}'),
      width: 1104,
      height: 150,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
        boxShadow: Fx.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(_M.thirtyTwo),
        child: SizedBox(
          width: 1040,
          height: 86,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: data.leftWidth,
                height: 86,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _thumb(imageKey),
                    const SizedBox(width: _M.twenty),
                    SizedBox(
                      width: data.textWidth,
                      height: 86,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _t(
                            data.title,
                            data.titleWidth,
                            _M.twentyEight,
                            Fx.heading22.copyWith(color: Fx.ink),
                          ),
                          const SizedBox(height: _M.twelve),
                          _chip(data),
                          const SizedBox(height: _M.six),
                          _vinRow(data),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: data.middleGap),
              SizedBox(
                width: data.middleWidth,
                height: _M.fortyEight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _assignee(data),
                    const SizedBox(width: _M.twentyFour),
                    _metricBlock(data),
                    const SizedBox(width: _M.twentyFour),
                    _chevron(data),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(String imageKey) {
    final img = _image(imageKey);
    return Container(
      width: _M.eighty,
      height: _M.eighty,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: img == null
          ? const SizedBox.shrink()
          : ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(_M.sixteen),
              ),
              child: SizedBox(
                width: _M.eighty,
                height: _M.eighty,
                child: RawImage(image: img, scale: 2),
              ),
            ),
    );
  }

  Widget _chip(_CardData data) {
    return Container(
      width: data.chipWidth,
      height: _M.twentyTwo,
      decoration: BoxDecoration(
        color: data.chipColor,
        borderRadius: const BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: _M.fourteen),
          _t(
            data.chip,
            data.chipTextWidth,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.275, color: data.chipText),
          ),
          const SizedBox(width: _M.fourteen),
        ],
      ),
    );
  }

  Widget _vinRow(_CardData data) {
    return SizedBox(
      width: data.textWidth,
      height: _M.eighteen,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _t(
              'VIN',
              20.28,
              _M.fourteen,
              Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.ink),
            ),
            const SizedBox(width: _M.six),
            _t(data.vin, data.vinWidth, _M.eighteen, Fx.body13Medium),
            const SizedBox(width: _M.sixteen),
            _t(
              '•',
              6.97,
              _M.eighteen,
              Fx.text(13, 18, FontWeight.w400, 0, color: Fx.surfaceHighest),
            ),
            const SizedBox(width: _M.sixteen),
            _svg(data.sideIcon, data.sideIconSize, data.sideIconSize),
            const SizedBox(width: _M.six),
            _t(data.customer, data.customerWidth, _M.eighteen, Fx.body13),
          ],
        ),
      ),
    );
  }

  Widget _assignee(_CardData data) {
    return SizedBox(
      width: data.assigneeWidth,
      height: _M.forty,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: _M.forty,
            height: _M.forty,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 11.5),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  data.initials,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  style: Fx.label12Bold.copyWith(color: data.initialsColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: _M.twelve),
          SizedBox(
            width: data.assigneeTextWidth,
            height: _M.thirty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _t(
                  'ASSIGNED TECH',
                  93.3,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                ),
                _t(data.assignee, data.assigneeTextWidth, _M.sixteen, Fx.label12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBlock(_CardData data) {
    switch (data.kind) {
      case _CardKind.progress:
        return SizedBox(
          width: data.metricWidth,
          height: _M.thirtyTwo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _t(
                'PROGRESS',
                64.47,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
              SizedBox(
                width: data.metricWidth,
                height: _M.eighteen,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    width: data.metricWidth - _M.sixteen,
                    height: _M.eighteen,
                    child: Stack(
                      children: [
                        Positioned(
                          left: _M.zero,
                          top: 7,
                          width: _M.ninetySix,
                          height: _M.eight,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Fx.container,
                              borderRadius: BorderRadius.all(
                                Radius.circular(Fx.pillRadius),
                              ),
                            ),
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              width: data.fillWidth,
                              height: _M.eight,
                              decoration: const BoxDecoration(
                                color: Fx.emerald,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(Fx.pillRadius),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 104,
                          top: _M.zero,
                          width: data.metricValueWidth,
                          height: _M.fourteen,
                          child: Transform.translate(
                            offset: const Offset(0, -1),
                            child: Text(
                              data.metricValue,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w600,
                                0.44,
                                color: Fx.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case _CardKind.review:
        return SizedBox(
          width: data.metricWidth,
          height: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _t(
                'REVIEW ITEMS',
                81.39,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
              SizedBox(
                width: data.metricWidth,
                height: _M.twenty,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    width: 103.48,
                    height: _M.twenty,
                    child: Stack(
                      children: [
                        Positioned(
                          left: _M.zero,
                          top: _M.eight,
                          width: _M.eight,
                          height: _M.eight,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFBA1A1A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: _M.fourteen,
                          top: _M.four,
                          width: 89.48,
                          height: _M.sixteen,
                          child: Text(
                            '2 Flags Marked',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: Fx.label12.copyWith(color: Fx.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case _CardKind.slot:
        return SizedBox(
          width: data.metricWidth,
          height: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _t(
                'SLOT TIME',
                58.97,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
              SizedBox(
                width: data.metricWidth,
                height: _M.twenty,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    width: 91.8,
                    height: _M.twenty,
                    child: Stack(
                      children: [
                        Positioned(
                          left: _M.zero,
                          top: 5.33,
                          width: 13.33,
                          height: 13.33,
                          child: _svg('clock', 13.33, 13.33),
                        ),
                        Positioned(
                          left: 19.33,
                          top: _M.four,
                          width: 72.47,
                          height: _M.sixteen,
                          child: Text(
                            '14:30 Today',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: Fx.label12.copyWith(color: Fx.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _chevron(_CardData data) {
    return SizedBox(
      width: _M.fiftySix,
      height: _M.fortyEight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: _M.eight),
          Container(
            width: _M.fortyEight,
            height: _M.fortyEight,
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: _svg(data.chevron, 7.4, 12),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: 1104,
      height: _M.fifty,
      decoration: const BoxDecoration(
        color: Fx.container99,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _M.twentyFour,
          _M.sixteen,
          _M.twentyFour,
          _M.sixteen,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 275.33,
              height: _M.eighteen,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: _M.ten,
                    height: _M.ten,
                    decoration: const BoxDecoration(
                      color: Fx.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: _M.twelve),
                  _t(
                    'Live sync active. Updated 4 seconds ago.',
                    253.33,
                    _M.eighteen,
                    Fx.body13.copyWith(color: Fx.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 406.15),
            SizedBox(
              width: 374.52,
              height: _M.sixteen,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _t(
                    'Export Daily Log',
                    97.52,
                    _M.sixteen,
                    Fx.label12.copyWith(color: Fx.muted),
                  ),
                  const SizedBox(width: _M.twentyFour),
                  _t(
                    'Batch Reassign',
                    91.47,
                    _M.sixteen,
                    Fx.label12.copyWith(color: Fx.muted),
                  ),
                  const SizedBox(width: _M.twentyFour),
                  _t(
                    'Bay Schedule Matrix →',
                    137.53,
                    _M.sixteen,
                    Fx.label12Bold.copyWith(color: Fx.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final effectiveUser = (widget.userName != null && widget.userName!.isNotEmpty)
        ? widget.userName!
        : 'Marcus Vance';
    final effectiveRole = (widget.userRole != null && widget.userRole!.isNotEmpty)
        ? widget.userRole!
        : 'Lead Inspector';

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          width: 1184,
          height: _M.eighty,
          color: Fx.whiteE5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _M.forty),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 229.72,
                  height: _M.thirtyTwo,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: _M.sixteen),
                      Container(
                        width: _M.ten,
                        height: _M.ten,
                        decoration: const BoxDecoration(
                          color: Fx.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: _M.twelve),
                      _t(
                        'BAY ACTIVE',
                        67.8,
                        _M.fourteen,
                        Fx.text(
                          11,
                          14,
                          FontWeight.w600,
                          0.55,
                          color: const Color(0xFF3C4A42),
                        ),
                      ),
                      const SizedBox(width: _M.twelve),
                      _t(
                        'Shop Floor #04',
                        95.92,
                        _M.sixteen,
                        Fx.label12Bold.copyWith(color: Fx.ink),
                      ),
                      const SizedBox(width: _M.sixteen),
                    ],
                  ),
                ),
                const SizedBox(width: 405.89),
                SizedBox(
                  width: 468.39,
                  height: 34,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 299,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Fx.container,
                          borderRadius: BorderRadius.all(
                            Radius.circular(Fx.pillRadius),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: _M.sixteen),
                            _svg('search', 15, 15),
                            const SizedBox(width: _M.twelve),
                            Expanded(
                              child: TextField(
                                controller: widget.searchController,
                                onChanged: widget.onSearch,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  hintText: 'Search VIN, tech, job ticket...',
                                  hintStyle: Fx.text(
                                    13,
                                    16,
                                    FontWeight.w400,
                                    0,
                                    color: Fx.muted,
                                  ),
                                ),
                                style: Fx.text(
                                  13,
                                  16,
                                  FontWeight.w400,
                                  0,
                                  color: Fx.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: _M.sixteen),
                          ],
                        ),
                      ),
                      const SizedBox(width: _M.twentyFour),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onProfileTap ?? () => _showUserMenu(context),
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 137.39,
                            height: _M.thirtyTwo,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 93.39,
                                  height: _M.thirtyTwo,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _t(
                                        effectiveUser,
                                        93.39,
                                        _M.eighteen,
                                        Fx.text(
                                          14,
                                          17.5,
                                          FontWeight.w700,
                                          -0.14,
                                          color: Fx.ink,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 93.39,
                                        height: _M.fourteen,
                                        child: Transform.translate(
                                          offset: const Offset(0, -1),
                                          child: Text(
                                            effectiveRole,
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.clip,
                                            textAlign: TextAlign.right,
                                            style: Fx.text(
                                              11,
                                              14,
                                              FontWeight.w600,
                                              0.44,
                                              color: Fx.muted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: _M.twelve),
                                Container(
                                  width: _M.thirtyTwo,
                                  height: _M.thirtyTwo,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF006C49),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: _svg('avatarUser', 12, 12),
                                ),
                              ],
                            ),
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
    );
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Toggle Language (EN / AR)'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onToggleLocale?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                widget.onSignOut?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _rail(BuildContext context) {
    return Container(
      width: _M.ninetySix,
      height: 1101,
      color: Fx.white,
      child: Stack(
        children: [
          Positioned(
            left: _M.twentyFour,
            top: _M.thirtyTwo,
            width: _M.fortyEight,
            height: _M.fortyEight,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                boxShadow: Fx.cardShadow,
              ),
              alignment: Alignment.center,
              child: _svg('logo', 21.67, 21.67),
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 128,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: _navButton(
              index: 0,
              icon: 'dash',
              iconWidth: 18,
              iconHeight: 18,
              isActive: widget.selectedNavIndex == 0,
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 208,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: _navButton(
              index: 1,
              icon: 'jobs',
              iconWidth: 18,
              iconHeight: 20,
              isActive: widget.selectedNavIndex == 1,
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 288,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: _navButton(
              index: 2,
              icon: 'gear',
              iconWidth: 18,
              iconHeight: 18,
              isActive: widget.selectedNavIndex == 2,
            ),
          ),
          Positioned(
            left: _M.twentyEight,
            top: 1029,
            width: _M.forty,
            height: _M.forty,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onSignOut ?? () => _showUserMenu(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _svg('help', 18.33, 17.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required int index,
    required String icon,
    required double iconWidth,
    required double iconHeight,
    required bool isActive,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onNavSelected?.call(index),
        borderRadius: const BorderRadius.all(Radius.circular(_M.sixteen)),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Fx.emerald : Fx.container,
            borderRadius:
                const BorderRadius.all(Radius.circular(_M.sixteen)),
            boxShadow: isActive ? Fx.ctaShadow : null,
          ),
          alignment: Alignment.center,
          child: _svg(icon, iconWidth, iconHeight),
        ),
      ),
    );
  }

  Widget _t(String data, double width, double height, TextStyle style) {
    final size = style.fontSize ?? 14;
    final dy = size == 11
        ? -1.0
        : size == 32
        ? 1.0
        : 0.0;
    final text = Text(
      data,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      style: style,
    );
    return SizedBox(
      width: width,
      height: height,
      child: dy == 0
          ? text
          : Transform.translate(offset: Offset(0, dy), child: text),
    );
  }

  Widget _svg(String key, double width, double height) {
    final raw = _svgString(key);
    if (raw.isEmpty) {
      return SizedBox(width: width, height: height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.string(raw, width: width, height: height),
    );
  }
}

enum _CardKind { progress, review, slot }

class _CardData {
  const _CardData({
    required this.key,
    required this.title,
    required this.titleWidth,
    required this.chip,
    required this.chipWidth,
    required this.chipTextWidth,
    required this.chipColor,
    required this.chipText,
    required this.vin,
    required this.vinWidth,
    required this.sideIcon,
    required this.sideIconSize,
    required this.customer,
    required this.customerWidth,
    required this.leftWidth,
    required this.textWidth,
    required this.middleGap,
    required this.middleWidth,
    required this.assignee,
    required this.assigneeWidth,
    required this.assigneeTextWidth,
    required this.initials,
    required this.initialsColor,
    required this.kind,
    required this.metricWidth,
    required this.metricValue,
    required this.metricValueWidth,
    required this.fillWidth,
    required this.chevron,
  });

  final int key;
  final String title;
  final double titleWidth;
  final String chip;
  final double chipWidth;
  final double chipTextWidth;
  final Color chipColor;
  final Color chipText;
  final String vin;
  final double vinWidth;
  final String sideIcon;
  final double sideIconSize;
  final String customer;
  final double customerWidth;
  final double leftWidth;
  final double textWidth;
  final double middleGap;
  final double middleWidth;
  final String assignee;
  final double assigneeWidth;
  final double assigneeTextWidth;
  final String initials;
  final Color initialsColor;
  final _CardKind kind;
  final double metricWidth;
  final String metricValue;
  final double metricValueWidth;
  final double fillWidth;
  final String chevron;

  static const porsche = _CardData(
    key: 1,
    title: 'Porsche Taycan 4S',
    titleWidth: 195.45,
    chip: 'BAY 04 \u2022 HIGH PRIORITY',
    chipWidth: 167.36,
    chipTextWidth: 139.36,
    chipColor: Fx.container,
    chipText: Fx.deepGreen,
    vin: 'WP0AA2Y12MSA89201',
    vinWidth: 137.64,
    sideIcon: 'person1',
    sideIconSize: 10.67,
    customer: 'Al Futtaim Motors Fleet',
    customerWidth: 134.34,
    leftWidth: 444.62,
    textWidth: 344.62,
    middleGap: 48.33,
    middleWidth: 547.05,
    assignee: 'Layla Haddad',
    assigneeWidth: 125.77,
    assigneeTextWidth: 73.77,
    initials: 'LH',
    initialsColor: Fx.deepGreen,
    kind: _CardKind.progress,
    metricWidth: 263.28,
    metricValue: '85%',
    metricValueWidth: 26.28,
    fillWidth: 81.6,
    chevron: 'chev1',
  );

  static const ford = _CardData(
    key: 2,
    title: 'Ford Transit Custom',
    titleWidth: 192.17,
    chip: 'BAY 02 \u2022 STANDARD FLEET',
    chipWidth: 164.75,
    chipTextWidth: 136.75,
    chipColor: Color(0xFFFEF3C7),
    chipText: Color(0xFF92400E),
    vin: 'WF0XXXTTFXMA20391',
    vinWidth: 139.69,
    sideIcon: 'bldg',
    sideIconSize: 13.33,
    customer: 'DHL Express UAE',
    customerWidth: 99.42,
    leftWidth: 441.34,
    textWidth: 341.34,
    middleGap: 96.6,
    middleWidth: 502.06,
    assignee: 'Marcus Vance',
    assigneeWidth: 133.58,
    assigneeTextWidth: 81.58,
    initials: 'MV',
    initialsColor: Color(0xFFB45309),
    kind: _CardKind.review,
    metricWidth: 212.48,
    metricValue: '',
    metricValueWidth: 0,
    fillWidth: 0,
    chevron: 'chev2',
  );

  static const renault = _CardData(
    key: 3,
    title: 'Renault M\u00e9gane E-Tech',
    titleWidth: 226.55,
    chip: 'BAY 01 \u2022 FLEET CHECK',
    chipWidth: 147.28,
    chipTextWidth: 119.28,
    chipColor: Fx.container,
    chipText: Fx.deepGreen,
    vin: 'VF1RJB00067891234',
    vinWidth: 136.42,
    sideIcon: 'person3',
    sideIconSize: 10.67,
    customer: 'GreenCab Dubai',
    customerWidth: 96.72,
    leftWidth: 475.72,
    textWidth: 375.72,
    middleGap: 46.22,
    middleWidth: 518.06,
    assignee: 'David Vance',
    assigneeWidth: 121.78,
    assigneeTextWidth: 69.78,
    initials: 'DV',
    initialsColor: Color(0xFF1D4ED8),
    kind: _CardKind.progress,
    metricWidth: 234.28,
    metricValue: '45%',
    metricValueWidth: 26.28,
    fillWidth: 43.2,
    chevron: 'chev3',
  );

  static const bmw = _CardData(
    key: 4,
    title: 'BMW iX xDrive50',
    titleWidth: 169.58,
    chip: 'BAY 06 \u2022 INTAKE PENDING',
    chipWidth: 161.44,
    chipTextWidth: 133.44,
    chipColor: Fx.container,
    chipText: Fx.ink,
    vin: 'WBY23CF04NCK58921',
    vinWidth: 141.02,
    sideIcon: 'person4',
    sideIconSize: 10.67,
    customer: 'Private Client',
    customerWidth: 72.86,
    leftWidth: 418.75,
    textWidth: 318.75,
    middleGap: 109.84,
    middleWidth: 511.41,
    assignee: 'Unassigned',
    assigneeWidth: 122.61,
    assigneeTextWidth: 70.61,
    initials: '--',
    initialsColor: Fx.muted,
    kind: _CardKind.slot,
    metricWidth: 232.8,
    metricValue: '',
    metricValueWidth: 0,
    fillWidth: 0,
    chevron: 'chev4',
  );
}

abstract final class _M {
  static const double zero = 0;
  static const double one = 1;
  static const double four = 4;
  static const double six = 6;
  static const double eight = 8;
  static const double nine = 9;
  static const double ten = 10;
  static const double twelve = 12;
  static const double fourteen = 14;
  static const double sixteen = 16;
  static const double eighteen = 18;
  static const double twenty = 20;
  static const double twentyTwo = 22;
  static const double twentyFour = 24;
  static const double twentyEight = 28;
  static const double thirty = 30;
  static const double thirtyTwo = 32;
  static const double thirtySix = 36;
  static const double thirtyEight = 38;
  static const double forty = 40;
  static const double fortySix = 46;
  static const double fortyEight = 48;
  static const double fifty = 50;
  static const double fiftySix = 56;
  static const double sixtyFour = 64;
  static const double eighty = 80;
  static const double ninetySix = 96;
}
