import 'package:flutter/painting.dart';

/// 사용자가 한 번 손가락/펜을 대고 뗄 때까지 그린 하나의 획(stroke).
class DrawnStrokeModel {
  /// 획을 구성하는 연속된 좌표 목록 (화면 dp 기준)
  final List<Offset> points;

  const DrawnStrokeModel({required this.points});

  /// 이 획 전체를 감싸는 최소 직사각형 (BBox 계산에 사용)
  Rect get boundingBox {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 이 획의 중심 좌표 (말풍선 위치 계산에 사용)
  Offset get center => boundingBox.center;
}
