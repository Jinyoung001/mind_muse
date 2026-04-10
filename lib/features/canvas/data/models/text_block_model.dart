import 'package:flutter/painting.dart';

/// ML Kit에서 추출한 텍스트 블록 하나를 나타낸다.
/// [boundingBox]는 화면 좌표계(dp) 기준이다 — CoordinateTransformService가 변환 완료 후 저장함.
class TextBlockModel {
  /// 인식된 텍스트 내용
  final String text;

  /// 화면 dp 기준 위치 및 크기 (CoordinateTransformService 변환 후)
  final Rect boundingBox;

  const TextBlockModel({
    required this.text,
    required this.boundingBox,
  });
}
