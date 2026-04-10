import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/text_block_model.dart';

/// ML Kit Text Recognition API를 호출하고 결과를 TextBlockModel 목록으로 반환한다.
/// 좌표는 원본 이미지 px 기준이다 — CoordinateTransformService에서 변환할 것.
class OcrRepository {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// [imageFile]: 분석할 이미지 파일
  /// 반환값: 원본 이미지 px 좌표 기준 TextBlockModel 목록
  Future<List<TextBlockModel>> recognize(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText result = await _recognizer.processImage(inputImage);

    final List<TextBlockModel> blocks = [];

    for (final block in result.blocks) {
      for (final line in block.lines) {
        // line 단위로 분리하여 더 정밀한 BBox 제공
        final rect = line.boundingBox;
        blocks.add(TextBlockModel(
          text: line.text,
          boundingBox: Rect.fromLTWH(
            rect.left.toDouble(),
            rect.top.toDouble(),
            rect.width.toDouble(),
            rect.height.toDouble(),
          ),
        ));
      }
    }

    return blocks;
  }

  void dispose() {
    _recognizer.close();
  }
}
