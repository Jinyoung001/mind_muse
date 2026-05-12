import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/drawn_stroke_model.dart';
import '../../canvas_layout_utils.dart';
import 'drawing_painter.dart';

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final r = imageNaturalSize != null
            ? containedImageRect(imageNaturalSize!, canvasSize)
            : Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);

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
