import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/gemma_repository.dart';

/// 말풍선에 표시할 데이터
class SpeechBubbleData {
  /// Gemma가 생성한 소크라테스식 질문
  final String message;

  /// 말풍선을 표시할 화면 좌표 (드로잉 중심 좌표)
  final Offset position;

  const SpeechBubbleData({required this.message, required this.position});
}

class GemmaState {
  final AsyncValue<SpeechBubbleData?> bubble;
  const GemmaState({this.bubble = const AsyncValue.data(null)});

  GemmaState copyWith({AsyncValue<SpeechBubbleData?>? bubble}) =>
      GemmaState(bubble: bubble ?? this.bubble);
}

class GemmaNotifier extends StateNotifier<GemmaState> {
  final GemmaRepository _repository = GemmaRepository();

  GemmaNotifier() : super(const GemmaState());

  /// [selectedTexts]: 드로잉으로 선택된 텍스트 목록
  /// [position]: 말풍선을 표시할 화면 좌표 (드로잉 중심)
  Future<void> ask({
    required List<String> selectedTexts,
    required Offset position,
  }) async {
    if (selectedTexts.isEmpty) return;

    state = state.copyWith(bubble: const AsyncValue.loading());
    try {
      final message = await _repository.askSocraticQuestion(selectedTexts);
      state = state.copyWith(
        bubble: AsyncValue.data(
          SpeechBubbleData(message: message, position: position),
        ),
      );
    } catch (e, st) {
      state = state.copyWith(bubble: AsyncValue.error(e, st));
    }
  }

  void dismiss() {
    state = state.copyWith(bubble: const AsyncValue.data(null));
  }
}

final gemmaProvider =
    StateNotifierProvider<GemmaNotifier, GemmaState>(
  (ref) => GemmaNotifier(),
);
