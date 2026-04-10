import 'package:flutter/painting.dart';
import '../../data/models/text_block_model.dart';

/// ML Kit이 반환하는 원본 이미지 픽셀 좌표를
/// Flutter 화면의 dp 좌표로 변환하는 서비스.
///
/// [왜 필요한가?]
/// - ML Kit은 원본 이미지 해상도(예: 4032×3024px) 기준으로 BBox를 반환한다.
/// - Flutter는 Image.file()로 이미지를 표시할 때 화면 크기에 맞게 자동 축소한다.
/// - 사용자의 드로잉 좌표는 화면(dp) 기준이다.
/// - 세 좌표계가 일치해야 IntersectionService의 충돌 계산이 정확하다.
class CoordinateTransformService {
  const CoordinateTransformService._(); // 인스턴스화 방지

  /// [imageSize]: ML Kit이 처리한 원본 이미지의 픽셀 크기 (예: Size(4032, 3024))
  /// [displaySize]: Flutter 화면에서 이미지가 실제로 표시되는 dp 크기
  /// [blocks]: ML Kit이 반환한 원본 좌표 기준 TextBlockModel 목록
  /// 반환값: 화면 dp 좌표로 변환된 TextBlockModel 목록
  static List<TextBlockModel> transform({
    required Size imageSize,
    required Size displaySize,
    required List<TextBlockModel> blocks,
  }) {
    // 가로/세로 각각의 스케일 비율 계산
    // 예: 원본 4032px → 화면 412dp 이면 scaleX = 412/4032 ≈ 0.102
    final double scaleX = displaySize.width / imageSize.width;
    final double scaleY = displaySize.height / imageSize.height;

    return blocks.map((block) {
      // 원본 BBox의 각 좌표에 스케일 적용
      final scaledRect = Rect.fromLTWH(
        block.boundingBox.left * scaleX,
        block.boundingBox.top * scaleY,
        block.boundingBox.width * scaleX,
        block.boundingBox.height * scaleY,
      );

      return TextBlockModel(
        text: block.text,
        boundingBox: scaledRect,
      );
    }).toList();
  }
}
