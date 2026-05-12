import 'package:flutter/material.dart';
import '../../data/models/drawn_stroke_model.dart';
import '../../canvas_layout_utils.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawnStrokeModel> strokes;
  final List<Offset> currentPoints;
  final Size? imageNaturalSize;

  DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    this.imageNaturalSize,
  });

  final _strokePaint = drawingStrokePaint();

  Rect _imageRect(Size canvasSize) {
    if (imageNaturalSize == null) return Offset.zero & canvasSize;
    return containedImageRect(imageNaturalSize!, canvasSize);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = _imageRect(size);
    for (final stroke in strokes) {
      _drawPoints(canvas, denormalizePoints(stroke.points, r));
    }
    if (currentPoints.length >= 2) {
      _drawPoints(canvas, denormalizePoints(currentPoints, r));
    }
  }

  void _drawPoints(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, _strokePaint);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.currentPoints != currentPoints ||
      oldDelegate.imageNaturalSize != imageNaturalSize;
}
