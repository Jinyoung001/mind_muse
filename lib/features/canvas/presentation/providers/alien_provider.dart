import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/alien_models.dart';
import '../../data/repositories/alien_repository.dart';

/// 한 라운드의 외계인 대화 데이터
class ConversationTurn {
  final String aiQuestion;
  final String? userAnswer;

  const ConversationTurn({
    required this.aiQuestion,
    this.userAnswer,
  });

  ConversationTurn copyWith({
    String? aiQuestion,
    String? userAnswer,
  }) =>
      ConversationTurn(
        aiQuestion: aiQuestion ?? this.aiQuestion,
        userAnswer: userAnswer ?? this.userAnswer,
      );
}

class AlienState {
  /// 합성된 이미지 bytes
  final Uint8List? compositeImage;

  /// 대화 턴 목록
  final List<ConversationTurn> turns;

  /// AI 응답 대기 중 여부
  final bool isLoading;

  /// 에러 메시지 (null이면 정상)
  final String? error;

  const AlienState({
    this.compositeImage,
    this.turns = const [],
    this.isLoading = false,
    this.error,
  });

  AlienState copyWith({
    Uint8List? compositeImage,
    List<ConversationTurn>? turns,
    bool? isLoading,
    String? error,
  }) =>
      AlienState(
        compositeImage: compositeImage ?? this.compositeImage,
        turns: turns ?? this.turns,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  /// 현재 진행 중인 턴 (마지막 턴)
  ConversationTurn? get currentTurn =>
      turns.isEmpty ? null : turns.last;

  /// 대화가 활성화된 상태인지 (패널을 보여줄지)
  bool get isActive => turns.isNotEmpty || isLoading;
}

class AlienNotifier extends StateNotifier<AlienState> {
  final AlienRepository _repository = AlienRepository();

  AlienNotifier() : super(const AlienState());

  static const _maxRetries = 3;

  /// 드로잉 완료 또는 버튼으로 호출 — 합성 이미지를 받아 첫 질문 생성
  Future<void> startConversation(Uint8List compositeImage,
      {bool hasDrawing = true}) async {
    state = AlienState(compositeImage: compositeImage, isLoading: true);

    final imageBase64 = base64Encode(compositeImage);
    const initialMessage = "이 그림에 대해 조사해 줘.";

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      state = state.copyWith(
        turns: [const ConversationTurn(aiQuestion: "")],
        isLoading: true,
        error: null,
      );

      try {
        final stream = _repository.chat(
          message: initialMessage,
          history: [],
          imageBase64: imageBase64,
        );

        String fullResponse = "";
        await for (final token in stream) {
          if (!mounted) return;
          fullResponse += token;

          final updatedTurns = List<ConversationTurn>.from(state.turns);
          updatedTurns[0] = updatedTurns[0].copyWith(aiQuestion: fullResponse);
          state = state.copyWith(turns: updatedTurns, isLoading: false);
        }

        final cleaned = AlienRepository.cleanResponse(fullResponse);
        if (cleaned.isNotEmpty && cleaned != fullResponse) {
          final updatedTurns = List<ConversationTurn>.from(state.turns);
          updatedTurns[0] = updatedTurns[0].copyWith(aiQuestion: cleaned);
          state = state.copyWith(turns: updatedTurns);
        }
        return;
      } catch (e) {
        if (attempt < _maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 1));
        } else {
          state = state.copyWith(isLoading: false, error: '질문 생성 실패: $e');
        }
      }
    }
  }

  /// 사용자 답변 제출
  Future<void> submitAnswer(String answer) async {
    if (state.compositeImage == null || state.turns.isEmpty) return;

    // 현재 턴에 답변 저장
    final turns = List<ConversationTurn>.from(state.turns);
    turns[turns.length - 1] = turns.last.copyWith(userAnswer: answer);

    // 대화 이력 구성 (재시도 시 동일하게 사용)
    final history = <AlienMessage>[];
    history.add(const AlienMessage(role: 'user', content: '이 그림에 대해 조사해 줘.'));
    for (int i = 0; i < turns.length - 1; i++) {
      history.add(AlienMessage(role: 'model', content: turns[i].aiQuestion));
      if (turns[i].userAnswer != null) {
        history.add(AlienMessage(role: 'user', content: turns[i].userAnswer!));
      }
    }
    history.add(AlienMessage(role: 'model', content: turns.last.aiQuestion));

    // 새 빈 턴 추가
    state = state.copyWith(
      turns: [...turns, const ConversationTurn(aiQuestion: "")],
      isLoading: true,
      error: null,
    );

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      // 재시도 시 마지막 턴 초기화
      if (attempt > 0) {
        final t = List<ConversationTurn>.from(state.turns);
        t[t.length - 1] = const ConversationTurn(aiQuestion: "");
        state = state.copyWith(turns: t, isLoading: true, error: null);
      }

      try {
        final stream = _repository.chat(
          message: answer,
          history: history,
          imageBase64: state.compositeImage != null
              ? base64Encode(state.compositeImage!)
              : null,
        );

        String fullResponse = "";
        await for (final token in stream) {
          if (!mounted) return;
          fullResponse += token;

          final updatedTurns = List<ConversationTurn>.from(state.turns);
          updatedTurns[updatedTurns.length - 1] =
              updatedTurns.last.copyWith(aiQuestion: fullResponse);
          state = state.copyWith(turns: updatedTurns, isLoading: false);
        }

        final cleaned = AlienRepository.cleanResponse(fullResponse);
        if (cleaned.isNotEmpty && cleaned != fullResponse) {
          final updatedTurns = List<ConversationTurn>.from(state.turns);
          updatedTurns[updatedTurns.length - 1] =
              updatedTurns.last.copyWith(aiQuestion: cleaned);
          state = state.copyWith(turns: updatedTurns);
        }
        return;
      } catch (e) {
        if (attempt < _maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 1));
        } else {
          state = state.copyWith(isLoading: false, error: '응답 생성 실패: $e');
        }
      }
    }
  }

  /// 드로잉 완료 시 합성 이미지만 교체 (대화 흐름 유지)
  void updateCompositeImage(Uint8List bytes) {
    state = state.copyWith(compositeImage: bytes);
  }

  /// 대화 종료 및 상태 초기화
  void dismiss() {
    state = const AlienState();
  }
}

final alienProvider =
    StateNotifierProvider<AlienNotifier, AlienState>(
  (ref) => AlienNotifier(),
);
