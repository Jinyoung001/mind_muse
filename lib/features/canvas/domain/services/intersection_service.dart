import 'package:flutter/painting.dart';
import '../../data/models/drawn_stroke_model.dart';
import '../../data/models/text_block_model.dart';

/// 사용자가 그린 획(stroke)과 ML Kit 텍스트 블록의 BBox가
/// 겹치는지 계산하여, 선택된 텍스트를 추출하는 서비스.
///
/// [알고리즘 개요]
/// - DrawnStrokeModel.boundingBox (획 전체를 감싸는 최소 직사각형)와
///   TextBlockModel.boundingBox를 Rect.overlaps()로 교차 검사한다.
/// - 단순 BBox 교차 검사는 빠르고 구현이 간단하며, 태블릿 UX에서 충분히 정확하다.
class IntersectionService {
  const IntersectionService._(); // 인스턴스화 방지

  /// [stroke]: 사용자가 완성한 하나의 획
  /// [textBlocks]: OcrProvider에서 가져온 화면 좌표 기준 텍스트 블록 목록
  /// 반환값: stroke BBox와 겹치는 텍스트 블록의 text 목록
  static List<String> findHits({
    required DrawnStrokeModel stroke,
    required List<TextBlockModel> textBlocks,
  }) {
    // stroke의 바운딩 박스 (획 전체를 감싸는 최소 직사각형)
    final Rect strokeBBox = stroke.boundingBox;

    // strokeBBox가 너무 작으면 (점에 가까우면) 무시
    // → 실수로 탭한 것과 의도적인 드로잉을 구분
    if (strokeBBox.width < 10 && strokeBBox.height < 10) return [];

    final List<String> hitTexts = [];

    for (final block in textBlocks) {
      // Rect.overlaps(): 두 직사각형이 1px이라도 겹치면 true
      // 참고: overlaps()는 경계선만 닿는 경우(width=0 교차)는 false 반환
      if (strokeBBox.overlaps(block.boundingBox)) {
        hitTexts.add(block.text);
      }
    }

    return hitTexts;
  }
}
