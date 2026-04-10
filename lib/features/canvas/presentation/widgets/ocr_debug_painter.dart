import 'package:flutter/material.dart';
import '../../data/models/text_block_model.dart';

/// ML Kit OCR 결과 BBox를 화면에 연하게 그려 디버깅에 사용한다.
/// Phase 2 전용 — 실제 배포 시 비활성화 가능.
class OcrDebugPainter extends CustomPainter {
  final List<TextBlockModel> textBlocks;
  final bool showDebug;

  OcrDebugPainter({required this.textBlocks, this.showDebug = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showDebug) return;

    // 반투명 하늘색 박스 + 텍스트 라벨
    final boxPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final block in textBlocks) {
      canvas.drawRect(block.boundingBox, boxPaint);
      canvas.drawRect(block.boundingBox, borderPaint);

      // 텍스트 라벨 (BBox 상단에 표시)
      final textPainter = TextPainter(
        text: TextSpan(
          text: block.text.length > 20
              ? '${block.text.substring(0, 20)}...'
              : block.text,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 10,
            backgroundColor: Color(0xCCFFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(block.boundingBox.left, block.boundingBox.top - 12),
      );
    }
  }

  @override
  bool shouldRepaint(OcrDebugPainter oldDelegate) =>
      oldDelegate.textBlocks != textBlocks ||
      oldDelegate.showDebug != showDebug;
}
