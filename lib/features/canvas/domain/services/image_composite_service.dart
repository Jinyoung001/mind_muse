import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../../data/models/drawn_stroke_model.dart';

/// 원본 이미지 파일 위에 드로잉 획을 합성하여 PNG bytes를 반환한다.
///
/// 드로잉 좌표는 InteractiveCanvas의 display 좌표(dp) 기준이다.
/// 이미지를 [containerSize]에 BoxFit.contain으로 맞춰 그린 뒤,
/// 동일 좌표계로 드로잉 선을 올려서 합성한다.
class ImageCompositeService {
  Future<Uint8List> composite({
    required File imageFile,
    required List<DrawnStrokeModel> strokes,
    required Size containerSize,
  }) async {
    if (containerSize.width <= 0 || containerSize.height <= 0) {
      throw ArgumentError('containerSize must have positive dimensions');
    }

    // 1. 원본 이미지 디코딩
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final srcImage = frame.image;

    try {
      // 2. containerSize 크기의 캔버스 생성
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // 3. BoxFit.contain으로 이미지를 캔버스 중앙에 그리기
      final imageSize = Size(
        srcImage.width.toDouble(),
        srcImage.height.toDouble(),
      );
      final fittedSizes = applyBoxFit(BoxFit.contain, imageSize, containerSize);
      final dstSize = fittedSizes.destination;
      final offsetX = (containerSize.width - dstSize.width) / 2;
      final offsetY = (containerSize.height - dstSize.height) / 2;

      canvas.drawImageRect(
        srcImage,
        Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
        Rect.fromLTWH(offsetX, offsetY, dstSize.width, dstSize.height),
        Paint(),
      );

      // 4. 드로잉 선 합성 (DrawingPainter와 동일한 스타일)
      final strokePaint = Paint()
        ..color = const Color(0xFFE74C3C)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final stroke in strokes) {
        if (stroke.points.length < 2) continue;
        // 정규화 좌표(0-1)를 containerSize 기준으로 역정규화
        final pts = stroke.points
            .map((p) => Offset(
                  p.dx * containerSize.width,
                  p.dy * containerSize.height,
                ))
            .toList();
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (int i = 1; i < pts.length; i++) {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
        canvas.drawPath(path, strokePaint);
      }

      // 5. PNG bytes로 변환
      final picture = recorder.endRecording();
      final compositeImage = await picture.toImage(
        containerSize.width.round(),
        containerSize.height.round(),
      );
      picture.dispose();

      try {
        final byteData = await compositeImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData == null) {
          throw StateError('PNG 인코딩 실패: toByteData가 null을 반환했습니다.');
        }
        return byteData.buffer.asUint8List();
      } finally {
        compositeImage.dispose();
      }
    } finally {
      srcImage.dispose();
    }
  }
}
