import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/text_block_model.dart';
import '../../data/repositories/ocr_repository.dart';
import '../../domain/services/coordinate_transform_service.dart';

/// OCR 상태: 인식된 텍스트 블록 목록 (화면 좌표 기준)
class OcrState {
  final AsyncValue<List<TextBlockModel>> blocks;
  const OcrState({this.blocks = const AsyncValue.data([])});

  OcrState copyWith({AsyncValue<List<TextBlockModel>>? blocks}) =>
      OcrState(blocks: blocks ?? this.blocks);
}

class OcrNotifier extends StateNotifier<OcrState> {
  final OcrRepository _repository = OcrRepository();

  OcrNotifier() : super(const OcrState());

  /// OCR 실행 후 화면 좌표로 변환하여 저장
  /// [imageFile]: 분석할 이미지
  /// [imageSize]: 원본 이미지 픽셀 크기
  /// [containerSize]: 이미지를 담는 컨테이너(InteractiveCanvas)의 dp 크기
  Future<void> runOcr({
    required File imageFile,
    required Size imageSize,
    required Size containerSize,
  }) async {
    state = state.copyWith(blocks: const AsyncValue.loading());
    try {
      // 1. ML Kit 실행 (원본 px 좌표)
      final rawBlocks = await _repository.recognize(imageFile);

      // 2. 컨테이너 dp 좌표로 변환 (BoxFit.contain 여백 오프셋 포함)
      final transformedBlocks = CoordinateTransformService.transform(
        imageSize: imageSize,
        containerSize: containerSize,
        blocks: rawBlocks,
      );

      state = state.copyWith(blocks: AsyncValue.data(transformedBlocks));
    } catch (e, st) {
      state = state.copyWith(blocks: AsyncValue.error(e, st));
    }
  }

  /// 외부에서 에러 상태를 직접 설정할 때 사용
  /// (예: 캔버스 크기 측정 실패 등 OCR 실행 전 오류)
  void setError(String message) {
    state = state.copyWith(
      blocks: AsyncValue.error(Exception(message), StackTrace.current),
    );
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}

final ocrProvider = StateNotifierProvider<OcrNotifier, OcrState>(
  (ref) => OcrNotifier(),
);
