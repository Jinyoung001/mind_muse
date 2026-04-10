import 'package:flutter/painting.dart';
import '../../data/models/text_block_model.dart';

/// ML Kit이 반환하는 원본 이미지 픽셀 좌표를
/// Flutter 화면의 dp 좌표로 변환하는 서비스.
///
/// [왜 필요한가?]
/// - ML Kit은 원본 이미지 해상도(예: 4032×3024px) 기준으로 BBox를 반환한다.
/// - Flutter는 Image.file()로 이미지를 BoxFit.contain으로 표시할 때 화면 크기에 맞게 축소하며,
///   비율 유지를 위해 상하 또는 좌우에 여백(letterbox/pillarbox)이 생긴다.
/// - 사용자의 드로잉 좌표는 컨테이너(InteractiveCanvas) 전체 기준이다.
/// - applyBoxFit을 사용하여 실제 이미지 렌더 영역을 계산하고, 여백 오프셋을 BBox에 반영한다.
class CoordinateTransformService {
  const CoordinateTransformService._(); // 인스턴스화 방지

  /// [imageSize]: ML Kit이 처리한 원본 이미지의 픽셀 크기 (예: Size(4032, 3024))
  /// [containerSize]: Flutter에서 이미지를 담는 컨테이너(InteractiveCanvas)의 dp 크기
  /// [blocks]: ML Kit이 반환한 원본 좌표 기준 TextBlockModel 목록
  /// 반환값: 컨테이너 dp 좌표 기준으로 변환된 TextBlockModel 목록
  ///         (BoxFit.contain 여백 오프셋 포함)
  static List<TextBlockModel> transform({
    required Size imageSize,
    required Size containerSize,
    required List<TextBlockModel> blocks,
  }) {
    // BoxFit.contain 시 실제 렌더되는 이미지 크기 계산
    // applyBoxFit은 이미지 비율을 유지하면서 컨테이너에 맞는 실제 렌더 크기를 반환한다
    final FittedSizes fittedSizes = applyBoxFit(
      BoxFit.contain,
      imageSize,    // 원본 이미지 크기
      containerSize, // 컨테이너 크기
    );
    final Size renderedSize = fittedSizes.destination;

    // 이미지가 컨테이너 중앙에 배치되므로 여백(offset) 계산
    // 예: 컨테이너 너비 400dp, 렌더된 이미지 너비 300dp → offsetX = 50dp
    final double offsetX = (containerSize.width - renderedSize.width) / 2;
    final double offsetY = (containerSize.height - renderedSize.height) / 2;

    // 실제 이미지 영역에 대한 스케일 비율
    final double scaleX = renderedSize.width / imageSize.width;
    final double scaleY = renderedSize.height / imageSize.height;

    return blocks.map((block) {
      // 원본 BBox를 실제 렌더 영역 좌표로 변환 후 여백 오프셋 추가
      final scaledRect = Rect.fromLTWH(
        block.boundingBox.left * scaleX + offsetX,  // 여백 오프셋 포함
        block.boundingBox.top * scaleY + offsetY,
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
