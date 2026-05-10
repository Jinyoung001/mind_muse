import 'package:flutter/material.dart';
import '../../data/models/drawn_stroke_model.dart';

/// 사용자가 그린 모든 획과 현재 그리고 있는 획을 캔버스에 그린다.
class DrawingPainter extends CustomPainter {
  final List<DrawnStrokeModel> strokes;
  final List<Offset> currentPoints;

  DrawingPainter({
    required this.strokes,
    required this.currentPoints,
  });

  final _strokePaint = Paint()
    ..color = const Color(0xFFE74C3C)  // 붉은색 형광펜 느낌
    ..strokeWidth = 4.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // 완성된 모든 획 그리기 (정규화 0-1 → 현재 캔버스 크기로 역정규화)
    for (final stroke in strokes) {
      _drawPoints(canvas, _denormalize(stroke.points, size));
    }

    // 현재 그리는 중인 획 그리기
    if (currentPoints.length >= 2) {
      _drawPoints(canvas, _denormalize(currentPoints, size));
    }
  }

  List<Offset> _denormalize(List<Offset> points, Size size) {
    return points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
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
      oldDelegate.currentPoints != currentPoints;
}
