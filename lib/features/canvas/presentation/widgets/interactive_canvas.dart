import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/drawn_stroke_model.dart';
import 'drawing_painter.dart';

/// 이미지 + 드로잉 레이어를 겹쳐서 표시한다.
/// OCR 레이어는 제거됨 — Gemma 멀티모달이 이미지를 직접 처리한다.
class InteractiveCanvas extends StatelessWidget {
  final File imageFile;
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

          // 레이어 2: 사용자 드로잉
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
