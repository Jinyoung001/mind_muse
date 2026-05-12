import 'package:flutter/material.dart';

/// BoxFit.contain 기준으로 [naturalSize] 이미지가 [canvasSize] 안에서
/// 실제로 표시되는 영역을 반환한다.
Rect containedImageRect(Size naturalSize, Size canvasSize) {
  final fitted = applyBoxFit(BoxFit.contain, naturalSize, canvasSize);
  final d = fitted.destination;
  return Rect.fromLTWH(
    (canvasSize.width - d.width) / 2,
    (canvasSize.height - d.height) / 2,
    d.width,
    d.height,
  );
}

/// 정규화 좌표(0~1)를 [rect] 기준 절대 좌표로 역변환한다.
List<Offset> denormalizePoints(List<Offset> points, Rect rect) =>
    points
        .map((p) => Offset(
              rect.left + p.dx * rect.width,
              rect.top + p.dy * rect.height,
            ))
        .toList();

/// 드로잉 획의 공통 Paint 스타일을 반환한다.
Paint drawingStrokePaint() => Paint()
  ..color = const Color(0xFFE74C3C)
  ..strokeWidth = 4.0
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..style = PaintingStyle.stroke;
