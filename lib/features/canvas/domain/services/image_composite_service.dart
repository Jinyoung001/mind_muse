import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../../data/models/drawn_stroke_model.dart';
import '../../canvas_layout_utils.dart';

class ImageCompositeService {
  Future<Uint8List> composite({
    required File imageFile,
    required List<DrawnStrokeModel> strokes,
    required Size containerSize,
  }) async {
    if (containerSize.width <= 0 || containerSize.height <= 0) {
      throw ArgumentError('containerSize must have positive dimensions');
    }

    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final srcImage = frame.image;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final imageSize = Size(srcImage.width.toDouble(), srcImage.height.toDouble());
      final imageRect = containedImageRect(imageSize, containerSize);

      canvas.drawImageRect(
        srcImage,
        Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
        imageRect,
        Paint(),
      );

      final strokePaint = drawingStrokePaint();
      for (final stroke in strokes) {
        if (stroke.points.length < 2) continue;
        final pts = denormalizePoints(stroke.points, imageRect);
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (int i = 1; i < pts.length; i++) {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
        canvas.drawPath(path, strokePaint);
      }

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
