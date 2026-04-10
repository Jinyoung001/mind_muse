import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/text_block_model.dart';
import 'ocr_debug_painter.dart';

/// 이미지 레이어 + OCR 디버그 레이어를 겹쳐서 표시하는 위젯.
/// Phase 3에서 드로잉 레이어, Phase 4에서 말풍선 레이어가 추가된다.
class InteractiveCanvas extends StatelessWidget {
  final File imageFile;
  final List<TextBlockModel> textBlocks;
  final bool showDebug;

  const InteractiveCanvas({
    super.key,
    required this.imageFile,
    required this.textBlocks,
    this.showDebug = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 레이어 1: 교과서 이미지
        Image.file(
          imageFile,
          fit: BoxFit.contain,
        ),

        // 레이어 2: OCR BBox 디버그 오버레이
        CustomPaint(
          painter: OcrDebugPainter(
            textBlocks: textBlocks,
            showDebug: showDebug,
          ),
        ),
      ],
    );
  }
}
