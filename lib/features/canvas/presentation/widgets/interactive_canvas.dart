import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/drawn_stroke_model.dart';
import 'drawing_painter.dart';

/// 이미지 + 드로잉 레이어를 겹쳐서 표시한다.
class InteractiveCanvas extends StatelessWidget {
  final File imageFile;
  final Size? imageNaturalSize;
  final List<DrawnStrokeModel> strokes;
  final List<Offset> currentPoints;
  final void Function(Offset) onPanStart;
  final void Function(Offset) onPanUpdate;
  final void Function() onPanEnd;

  const InteractiveCanvas({
    super.key,
    required this.imageFile,
    required this.strokes,
    required this.currentPoints,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.imageNaturalSize,
  });

  /// BoxFit.contain 기준으로 이미지가 실제 표시되는 영역을 계산한다.
  Rect _imageRect(double w, double h) {
    if (imageNaturalSize == null) return Rect.fromLTWH(0, 0, w, h);
    final fitted = applyBoxFit(BoxFit.contain, imageNaturalSize!, Size(w, h));
    final d = fitted.destination;
    return Rect.fromLTWH((w - d.width) / 2, (h - d.height) / 2, d.width, d.height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final r = _imageRect(w, h);

        return GestureDetector(
          onPanStart: (details) => onPanStart(Offset(
            ((details.localPosition.dx - r.left) / r.width).clamp(0.0, 1.0),
            ((details.localPosition.dy - r.top) / r.height).clamp(0.0, 1.0),
          )),
          onPanUpdate: (details) => onPanUpdate(Offset(
            ((details.localPosition.dx - r.left) / r.width).clamp(0.0, 1.0),
            ((details.localPosition.dy - r.top) / r.height).clamp(0.0, 1.0),
          )),
          onPanEnd: (_) => onPanEnd(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(imageFile, fit: BoxFit.contain),
              CustomPaint(
                painter: DrawingPainter(
                  strokes: strokes,
                  currentPoints: currentPoints,
                  imageNaturalSize: imageNaturalSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
