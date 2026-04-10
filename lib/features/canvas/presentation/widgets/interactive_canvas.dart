import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/drawn_stroke_model.dart';
import '../../data/models/text_block_model.dart';
import 'drawing_painter.dart';
import 'ocr_debug_painter.dart';

/// 이미지 + OCR 디버그 + 드로잉 레이어를 겹쳐서 표시.
class InteractiveCanvas extends StatelessWidget {
  final File imageFile;
  final List<TextBlockModel> textBlocks;
  final List<DrawnStrokeModel> strokes;
  final List<Offset> currentPoints;
  final bool showDebug;
  final void Function(Offset) onPanStart;
  final void Function(Offset) onPanUpdate;
  final void Function() onPanEnd;

  const InteractiveCanvas({
    super.key,
    required this.imageFile,
    required this.textBlocks,
    required this.strokes,
    required this.currentPoints,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.showDebug = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => onPanStart(details.localPosition),
      onPanUpdate: (details) => onPanUpdate(details.localPosition),
      onPanEnd: (_) => onPanEnd(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 레이어 1: 교과서 이미지
          Image.file(imageFile, fit: BoxFit.contain),

          // 레이어 2: OCR BBox 디버그
          CustomPaint(
            painter: OcrDebugPainter(
              textBlocks: textBlocks,
              showDebug: showDebug,
            ),
          ),

          // 레이어 3: 사용자 드로잉
          CustomPaint(
            painter: DrawingPainter(
              strokes: strokes,
              currentPoints: currentPoints,
            ),
          ),
        ],
      ),
    );
  }
}
