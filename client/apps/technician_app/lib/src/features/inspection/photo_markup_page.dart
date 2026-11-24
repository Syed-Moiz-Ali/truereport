import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as codec;
import 'package:l10n/ui_strings.dart';

/// Which mark the technician is drawing.
enum MarkupTool { circle, pen }

/// One mark, in coordinates normalised to the photo (0..1 on both axes) so a
/// stroke survives any display size and renders at the photo's resolution.
class MarkupStroke {
  MarkupStroke({
    required this.tool,
    required this.colour,
    required this.points,
  });

  final MarkupTool tool;
  final Color colour;

  /// Circle: first point is the drag start, last point the drag end.
  /// Pen: the whole polyline.
  final List<Offset> points;

  Offset get start => points.first;

  Offset get end => points.last;

  Rect get bounds {
    if (tool == MarkupTool.circle) {
      return Rect.fromPoints(start, end);
    }
    var minX = points.first.dx;
    var maxX = minX;
    var minY = points.first.dy;
    var maxY = minY;
    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

/// The marked photo, ready to be uploaded as ordinary photo evidence.
class MarkedPhoto {
  const MarkedPhoto({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Paints normalised strokes onto a canvas of [size].
void paintMarkup(
  Canvas canvas,
  List<MarkupStroke> strokes,
  Size size, {
  Color halo = const Color(0xFFFFFFFF),
}) {
  if (strokes.isEmpty || size.isEmpty) {
    return;
  }
  final unit = size.shortestSide;
  final width = (unit * 0.009).clamp(3.0, 12.0);
  for (final stroke in strokes) {
    _paintStroke(
      canvas,
      stroke,
      size,
      width + 2.5,
      halo.withValues(alpha: 0.85),
    );
    _paintStroke(canvas, stroke, size, width, stroke.colour);
  }
}

void _paintStroke(
  Canvas canvas,
  MarkupStroke stroke,
  Size size,
  double width,
  Color colour,
) {
  final paint = Paint()
    ..color = colour
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  Offset toPixels(Offset point) =>
      Offset(point.dx * size.width, point.dy * size.height);

  if (stroke.tool == MarkupTool.circle) {
    final rect = Rect.fromPoints(toPixels(stroke.start), toPixels(stroke.end));
    canvas.drawOval(rect, paint);
    return;
  }
  final path = Path()
    ..moveTo(
      stroke.points.first.dx * size.width,
      stroke.points.first.dy * size.height,
    );
  for (final point in stroke.points.skip(1)) {
    path.lineTo(point.dx * size.width, point.dy * size.height);
  }
  canvas.drawPath(path, paint);
}

/// Marks damage on a photo and returns the marked image as JPEG.
///
/// The photo is shown on a dark lightbox; strokes are circle (drag an oval
/// around the damage) or freehand, drawn in a colour with a white halo so they
/// read on any paintwork. The saved image is rendered at the photo's own
/// resolution (capped), so it behaves like any other camera capture.
class PhotoMarkupPage extends StatefulWidget {
  const PhotoMarkupPage({
    required this.photoBytes,
    required this.title,
    super.key,
  });

  final Uint8List photoBytes;
  final String title;

  @override
  State<PhotoMarkupPage> createState() => _PhotoMarkupPageState();
}

class _PhotoMarkupPageState extends State<PhotoMarkupPage> {
  static const _colours = <Color>[
    Color(0xFFD14B64),
    Color(0xFFB7791F),
    Color(0xFFFFFFFF),
  ];

  ui.Image? _image;
  Object? _decodeError;
  final List<MarkupStroke> _strokes = <MarkupStroke>[];
  MarkupStroke? _active;
  MarkupTool _tool = MarkupTool.circle;
  int _colour = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      final image = await decodeImageFromList(widget.photoBytes);
      if (!mounted) {
        return;
      }
      setState(() => _image = image);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _decodeError = error);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  bool get _hasMark => _strokes.isNotEmpty;

  void _undo() {
    if (_strokes.isEmpty) {
      return;
    }
    setState(() => _strokes.removeLast());
  }

  void _clear() {
    if (_strokes.isEmpty) {
      return;
    }
    setState(() => _strokes.clear());
  }

  Future<void> _save() async {
    final image = _image;
    if (image == null || _strokes.isEmpty || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final marked = await renderMarkedPhoto(image, _strokes);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(marked);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      body: SafeArea(
        child: Column(
          children: [
            _Bar(
              title: widget.title,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 8),
                child: _decodeError != null
                    ? Center(
                        child: Text(
                          t(TechnicianKeys.technicianEvidenceFailed),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    : _Canvas(
                        image: _image,
                        strokes: _strokes,
                        active: _active,
                        onStart: _startStroke,
                        onUpdate: _extendStroke,
                        onEnd: _endStroke,
                      ),
              ),
            ),
            _Toolbar(
              tool: _tool,
              colour: _colour,
              colours: _colours,
              canUndo: _hasMark,
              onTool: (tool) => setState(() => _tool = tool),
              onColour: (index) => setState(() => _colour = index),
              onUndo: _undo,
              onClear: _clear,
              onCreate: _save,
              busy: _saving,
            ),
          ],
        ),
      ),
    );
  }

  void _startStroke(Offset normalised) {
    setState(() {
      _active = MarkupStroke(
        tool: _tool,
        colour: _colours[_colour],
        points: <Offset>[normalised],
      );
    });
  }

  void _extendStroke(Offset normalised) {
    final active = _active;
    if (active == null) {
      return;
    }
    setState(() {
      if (active.tool == MarkupTool.circle) {
        // A circle needs only the two corners of the drag.
        active.points
          ..removeRange(1, active.points.length)
          ..add(normalised);
      } else {
        active.points.add(normalised);
      }
    });
  }

  void _endStroke() {
    final active = _active;
    if (active == null) {
      return;
    }
    final bounds = active.bounds;
    setState(() {
      _active = null;
      // A tap is not a mark; ignore strokes smaller than 1.5% of the photo.
      if (bounds.width >= 0.015 || bounds.height >= 0.015) {
        _strokes.add(active);
      }
    });
  }
}

/// Renders the photo at its own resolution (capped at 2400 px wide) with the
/// strokes drawn on top, encoded as JPEG quality 88.
Future<MarkedPhoto> renderMarkedPhoto(
  ui.Image image,
  List<MarkupStroke> strokes,
) async {
  const capWidth = 2400.0;
  final scale = image.width > capWidth ? capWidth / image.width : 1.0;
  final width = (image.width * scale).round();
  final height = (image.height * scale).round();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..filterQuality = FilterQuality.high,
  );
  paintMarkup(
    canvas,
    strokes,
    Size(width.toDouble(), height.toDouble()),
    halo: const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final rendered = await picture.toImage(width, height);
  final rgba = await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
  rendered.dispose();
  picture.dispose();
  if (rgba == null) {
    throw StateError('The marked photo could not be rendered');
  }
  final frame = codec.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba.buffer,
    numChannels: 4,
  );
  final jpeg = codec.encodeJpg(frame, quality: 88);
  return MarkedPhoto(
    bytes: Uint8List.fromList(jpeg),
    width: width,
    height: height,
  );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 16, 2),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: MaterialLocalizations.of(context).closeButtonLabel,
            child: GestureDetector(
              onTap: onClose,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t(TechnicianKeys.technicianMarkDamage),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.image,
    required this.strokes,
    required this.active,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  final ui.Image? image;
  final List<MarkupStroke> strokes;
  final MarkupStroke? active;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    if (image == null) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white70,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = applyBoxFit(
          BoxFit.contain,
          Size(image.width.toDouble(), image.height.toDouble()),
          constraints.biggest,
        ).destination;
        final rect = Alignment.center.inscribe(
          fitted,
          Offset.zero & constraints.biggest,
        );
        return Stack(
          children: [
            Positioned.fromRect(
              rect: rect,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) =>
                    onStart(_normalise(details.localPosition, rect.size)),
                onPanUpdate: (details) =>
                    onUpdate(_normalise(details.localPosition, rect.size)),
                onPanEnd: (_) => onEnd(),
                onPanCancel: onEnd,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CustomPaint(
                    painter: _MarkupPainter(
                      image: image,
                      strokes: [...strokes, ?active],
                    ),
                    size: rect.size,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Offset _normalise(Offset local, Size size) => Offset(
    (local.dx / size.width).clamp(0.0, 1.0),
    (local.dy / size.height).clamp(0.0, 1.0),
  );
}

class _MarkupPainter extends CustomPainter {
  const _MarkupPainter({required this.image, required this.strokes});

  final ui.Image image;
  final List<MarkupStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
    paintMarkup(canvas, strokes, size);
  }

  @override
  bool shouldRepaint(covariant _MarkupPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.image != image;
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.tool,
    required this.colour,
    required this.colours,
    required this.canUndo,
    required this.onTool,
    required this.onColour,
    required this.onUndo,
    required this.onClear,
    required this.onCreate,
    required this.busy,
  });

  final MarkupTool tool;
  final int colour;
  final List<Color> colours;
  final bool canUndo;
  final ValueChanged<MarkupTool> onTool;
  final ValueChanged<int> onColour;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onCreate;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF11161D),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Tool(
                label: t(TechnicianKeys.technicianMarkupCircle),
                icon: Icons.circle_outlined,
                selected: tool == MarkupTool.circle,
                onTap: () => onTool(MarkupTool.circle),
              ),
              const SizedBox(width: 8),
              _Tool(
                label: t(TechnicianKeys.technicianMarkupPen),
                icon: Icons.gesture_rounded,
                selected: tool == MarkupTool.pen,
                onTap: () => onTool(MarkupTool.pen),
              ),
              const Spacer(),
              for (var index = 0; index < colours.length; index++) ...[
                _Swatch(
                  colour: colours[index],
                  selected: colour == index,
                  onTap: () => onColour(index),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _IconAction(
                icon: Icons.undo_rounded,
                label: t(TechnicianKeys.technicianUndo),
                onTap: canUndo ? onUndo : null,
              ),
              const SizedBox(width: 8),
              _IconAction(
                icon: Icons.layers_clear_outlined,
                label: t(TechnicianKeys.technicianClear),
                onTap: canUndo ? onClear : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: canUndo && !busy ? onCreate : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.brand.ink,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      canUndo
                          ? t(TechnicianKeys.technicianMarkupSave)
                          : t(TechnicianKeys.technicianMarkupEmpty),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  final Color colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colour,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.25),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: colour.computeLuminance() > 0.6
                      ? const Color(0xFF14171C)
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Icon(
              icon,
              size: 19,
              color: enabled ? Colors.white : Colors.white24,
            ),
          ),
        ),
      ),
    );
  }
}
