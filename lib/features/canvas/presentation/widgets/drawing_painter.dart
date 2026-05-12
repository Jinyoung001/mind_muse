import 'package:flutter/material.dart';
import '../../data/models/drawn_stroke_model.dart';

/// 사용자가 그린 모든 획과 현재 그리고 있는 획을 캔버스에 그린다.
class DrawingPainter extends CustomPainter {
  final List<DrawnStrokeModel> strokes;
  final List<Offset> currentPoints;
  final Size? imageNaturalSize;

  DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    this.imageNaturalSize,
  });

  final _strokePaint = Paint()
    ..color = const Color(0xFFE74C3C)
    ..strokeWidth = 4.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  /// BoxFit.contain 기준 이미지 표시 영역 (정규화 좌표의 기준)
  Rect _imageRect(Size canvasSize) {
    if (imageNaturalSize == null) return Offset.zero & canvasSize;
    final fitted = applyBoxFit(BoxFit.contain, imageNaturalSize!, canvasSize);
    final d = fitted.destination;
    return Rect.fromLTWH(
      (canvasSize.width - d.width) / 2,
      (canvasSize.height - d.height) / 2,
      d.width,
      d.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = _imageRect(size);
    for (final stroke in strokes) {
      _drawPoints(canvas, _denormalize(stroke.points, r));
    }
    if (currentPoints.length >= 2) {
      _drawPoints(canvas, _denormalize(currentPoints, r));
    }
  }

  List<Offset> _denormalize(List<Offset> points, Rect r) {
    return points
        .map((p) => Offset(r.left + p.dx * r.width, r.top + p.dy * r.height))
        .toList();
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
