import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/gemma_repository.dart';

const int kMaxRounds = 3;

/// 한 라운드의 소크라테스 대화 데이터
class ConversationTurn {
  final String aiQuestion;
  final String? userAnswer;
  final List<String> hints;      // 미리 생성된 힌트 3개
  final int revealedHints;       // 현재 공개된 힌트 수 (0~3)

  const ConversationTurn({
    required this.aiQuestion,
    this.userAnswer,
    this.hints = const [],
    this.revealedHints = 0,
  });

  ConversationTurn copyWith({
    String? userAnswer,
    List<String>? hints,
    int? revealedHints,
  }) =>
      ConversationTurn(
        aiQuestion: aiQuestion,
        userAnswer: userAnswer ?? this.userAnswer,
        hints: hints ?? this.hints,
        revealedHints: revealedHints ?? this.revealedHints,
      );
}

class GemmaState {
  /// 합성된 이미지 bytes (라운드 간 재사용)
  final Uint8List? compositeImage;

  /// 대화 턴 목록
  final List<ConversationTurn> turns;

  /// AI 응답 대기 중 여부
  final bool isLoading;

  /// 3라운드 완료 여부
  final bool isFinished;

  /// 에러 메시지 (null이면 정상)
  final String? error;

  const GemmaState({
    this.compositeImage,
    this.turns = const [],
    this.isLoading = false,
    this.isFinished = false,
    this.error,
  });

  GemmaState copyWith({
    Uint8List? compositeImage,
    List<ConversationTurn>? turns,
    bool? isLoading,
    bool? isFinished,
    String? error,
  }) =>
      GemmaState(
        compositeImage: compositeImage ?? this.compositeImage,
        turns: turns ?? this.turns,
        isLoading: isLoading ?? this.isLoading,
        isFinished: isFinished ?? this.isFinished,
        error: error,
      );

  /// 현재 진행 중인 턴 (마지막 턴)
  ConversationTurn? get currentTurn =>
      turns.isEmpty ? null : turns.last;

  /// 대화가 활성화된 상태인지 (패널을 보여줄지)
  bool get isActive => turns.isNotEmpty || isLoading;
}

class GemmaNotifier extends StateNotifier<GemmaState> {
  final GemmaRepository _repository = GemmaRepository();

  GemmaNotifier() : super(const GemmaState());

  /// 드로잉 완료 시 호출 — 합성 이미지를 받아 첫 질문 생성
  Future<void> startConversation(Uint8List compositeImage) async {
    state = GemmaState(
      compositeImage: compositeImage,
      isLoading: true,
    );

    try {
      final question = await _repository.askInitialQuestion(compositeImage);

      final firstTurn = ConversationTurn(aiQuestion: question);
      state = state.copyWith(
        turns: [firstTurn],
        isLoading: false,
      );

      // 힌트를 백그라운드에서 미리 생성
      _prefetchHints(compositeImage, question, 0);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '질문 생성 실패: $e',
      );
    }
  }

  /// 힌트 사전 생성 (백그라운드, 실패해도 무시)
  Future<void> _prefetchHints(
    Uint8List imageBytes,
    String question,
    int turnIndex,
  ) async {
    try {
      final hints = await _repository.generateHints(imageBytes, question);
      if (!mounted) return;
      final updatedTurns = List<ConversationTurn>.from(state.turns);
      if (turnIndex < updatedTurns.length) {
        updatedTurns[turnIndex] =
            updatedTurns[turnIndex].copyWith(hints: hints);
        state = state.copyWith(turns: updatedTurns);
      }
    } catch (_) {
      // 힌트 생성 실패는 무시 — 힌트 버튼이 비활성화로 표시됨
    }
  }

  /// 힌트 한 단계 공개
  void revealNextHint() {
    final turns = List<ConversationTurn>.from(state.turns);
    if (turns.isEmpty) return;
    final last = turns.last;
    if (last.revealedHints >= last.hints.length) return;
    turns[turns.length - 1] =
        last.copyWith(revealedHints: last.revealedHints + 1);
    state = state.copyWith(turns: turns);
  }

  /// 사용자 답변 제출 — 평가 + 후속 질문 생성
  Future<void> submitAnswer(String answer) async {
    if (state.compositeImage == null || state.turns.isEmpty) return;

    // 현재 턴에 답변 저장
    final turns = List<ConversationTurn>.from(state.turns);
    turns[turns.length - 1] = turns.last.copyWith(userAnswer: answer);
    state = state.copyWith(turns: turns, isLoading: true, error: null);

    try {
      final history = turns
          .map((t) => {
                'question': t.aiQuestion,
                'answer': t.userAnswer ?? '',
              })
          .toList();

      final isLastRound = turns.length >= kMaxRounds;

      final response = await _repository.evaluateAndContinue(
        imageBytes: state.compositeImage!,
        history: history,
        isLastRound: isLastRound,
      );

      if (isLastRound) {
        // 마지막 라운드: 격려 메시지를 마지막 턴 다음에 추가하고 종료
        final finalTurn = ConversationTurn(aiQuestion: response);
        state = state.copyWith(
          turns: [...state.turns, finalTurn],
          isLoading: false,
          isFinished: true,
        );
      } else {
        // 다음 라운드 시작
        final nextTurn = ConversationTurn(aiQuestion: response);
        final newTurns = [...state.turns, nextTurn];
        state = state.copyWith(turns: newTurns, isLoading: false);

        // 다음 라운드 힌트도 미리 생성
        _prefetchHints(
          state.compositeImage!,
          response,
          newTurns.length - 1,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '응답 생성 실패: $e',
      );
    }
  }

  /// 대화 종료 및 상태 초기화
  void dismiss() {
    state = const GemmaState();
  }
}

final gemmaProvider =
    StateNotifierProvider<GemmaNotifier, GemmaState>(
  (ref) => GemmaNotifier(),
);
