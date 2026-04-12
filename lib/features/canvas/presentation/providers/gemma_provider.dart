import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/gemma_repository.dart';
import '../../data/repositories/misconception_repository.dart';
import '../../data/repositories/absurdity_repository.dart';

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

  /// Absurdity Engine 생성 중 여부 ("부조리한 세계를 만드는 중...")
  final bool isGeneratingAbsurdity;

  /// 생성된 HTML 시뮬레이션 (null이면 WebView 비활성)
  final String? absurdityHtml;

  /// 같은 세션 내 Absurdity Engine 재발동 방지 플래그
  final bool absurdityTriggered;

  const GemmaState({
    this.compositeImage,
    this.turns = const [],
    this.isLoading = false,
    this.isFinished = false,
    this.error,
    this.isGeneratingAbsurdity = false,
    this.absurdityHtml,
    this.absurdityTriggered = false,
  });

  GemmaState copyWith({
    Uint8List? compositeImage,
    List<ConversationTurn>? turns,
    bool? isLoading,
    bool? isFinished,
    String? error,
    bool? isGeneratingAbsurdity,
    String? absurdityHtml,
    bool clearAbsurdityHtml = false,
    bool? absurdityTriggered,
  }) =>
      GemmaState(
        compositeImage: compositeImage ?? this.compositeImage,
        turns: turns ?? this.turns,
        isLoading: isLoading ?? this.isLoading,
        isFinished: isFinished ?? this.isFinished,
        error: error,
        isGeneratingAbsurdity:
            isGeneratingAbsurdity ?? this.isGeneratingAbsurdity,
        absurdityHtml:
            clearAbsurdityHtml ? null : (absurdityHtml ?? this.absurdityHtml),
        absurdityTriggered: absurdityTriggered ?? this.absurdityTriggered,
      );

  /// 현재 진행 중인 턴 (마지막 턴)
  ConversationTurn? get currentTurn =>
      turns.isEmpty ? null : turns.last;

  /// 대화가 활성화된 상태인지 (패널을 보여줄지)
  bool get isActive => turns.isNotEmpty || isLoading;
}

class GemmaNotifier extends StateNotifier<GemmaState> {
  final GemmaRepository _repository = GemmaRepository();
  final MisconceptionRepository _misconceptionRepository =
      MisconceptionRepository();
  final AbsurdityRepository _absurdityRepository = AbsurdityRepository();

  GemmaNotifier() : super(const GemmaState());

  /// 드로잉 완료 또는 버튼으로 호출 — 합성 이미지를 받아 첫 질문 생성
  /// [hasDrawing] false이면 전체 이미지 기반 질문 생성
  Future<void> startConversation(Uint8List compositeImage,
      {bool hasDrawing = true}) async {
    state = GemmaState(
      compositeImage: compositeImage,
      isLoading: true,
    );

    try {
      final question = await _repository.askInitialQuestion(compositeImage,
          hasDrawing: hasDrawing);

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

  static const _fallbackHints = [
    '표시한 부분의 핵심 단어에 집중해보세요.',
    '이 정보가 어떤 상황에서 쓰일지 상상해보세요.',
    '비슷한 개념이나 예시를 떠올려보세요.',
  ];

  /// 힌트 사전 생성 (백그라운드). API 실패 시 기본 힌트로 폴백.
  Future<void> _prefetchHints(
    Uint8List imageBytes,
    String question,
    int turnIndex,
  ) async {
    List<String> hints;
    try {
      hints = await _repository.generateHints(imageBytes, question);
    } catch (_) {
      hints = _fallbackHints;
    }

    if (!mounted) return;
    final updatedTurns = List<ConversationTurn>.from(state.turns);
    if (turnIndex < updatedTurns.length) {
      updatedTurns[turnIndex] =
          updatedTurns[turnIndex].copyWith(hints: hints);
      state = state.copyWith(turns: updatedTurns);
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

  /// 사용자 답변 제출 — 오개념 탐지 분기 후 평가 + 후속 질문 생성
  Future<void> submitAnswer(String answer) async {
    if (state.compositeImage == null || state.turns.isEmpty) return;

    // 현재 턴에 답변 저장
    final turns = List<ConversationTurn>.from(state.turns);
    turns[turns.length - 1] = turns.last.copyWith(userAnswer: answer);
    state = state.copyWith(turns: turns, isLoading: true, error: null);

    // absurdityTriggered이면 탐지 스킵하고 기존 소크라테스 흐름 유지
    if (state.absurdityTriggered) {
      await _evaluateAndContinue(turns);
      return;
    }

    // 오개념 탐지 실행
    try {
      final history = turns
          .map((t) => {
                'question': t.aiQuestion,
                'answer': t.userAnswer ?? '',
              })
          .toList();

      final misconception = await _misconceptionRepository.detect(
        imageBytes: state.compositeImage!,
        history: history,
        latestAnswer: answer,
      );

      if (!mounted) return;

      if (misconception.hasMisconception) {
        // 오개념 감지: triggerPhrase를 새 턴으로 추가하고 HTML 시뮬레이션 생성
        final triggerTurn =
            ConversationTurn(aiQuestion: misconception.triggerPhrase);
        final newTurns = [...state.turns, triggerTurn];

        state = state.copyWith(
          turns: newTurns,
          isLoading: false,
          absurdityTriggered: true,
          isGeneratingAbsurdity: true,
        );

        // HTML 시뮬레이션 생성 (백그라운드)
        _generateAbsurdity(
          falseAssumption: misconception.falseAssumption,
          absurdExtreme: misconception.absurdExtreme,
          subject: misconception.subject,
        );
      } else {
        // 오개념 없음: 기존 소크라테스 흐름 유지
        await _evaluateAndContinue(turns);
      }
    } catch (e) {
      if (!mounted) return;
      // 탐지 실패 시 기존 흐름 유지 (안전망)
      await _evaluateAndContinue(turns);
    }
  }

  /// HTML 시뮬레이션 생성 (백그라운드, 실패 시 fallback HTML 사용)
  Future<void> _generateAbsurdity({
    required String falseAssumption,
    required String absurdExtreme,
    required String subject,
  }) async {
    final html = await _absurdityRepository.generateHtml(
      falseAssumption: falseAssumption,
      absurdExtreme: absurdExtreme,
      subject: subject,
    );

    if (!mounted) return;
    state = state.copyWith(
      isGeneratingAbsurdity: false,
      absurdityHtml: html,
    );
  }

  /// 기존 소크라테스 흐름: 답변 평가 + 후속 질문 또는 마지막 라운드 정리
  Future<void> _evaluateAndContinue(List<ConversationTurn> turns) async {
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

      if (!mounted) return;

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
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: '응답 생성 실패: $e',
      );
    }
  }

  /// WebView 내 "이상한 것 같아..." 버튼 클릭 시 호출
  /// WebView 닫고 Truth Mode 설명을 생성한 후 소크라테스 대화 완전 종료
  Future<void> onStudentDoubt() async {
    if (state.compositeImage == null) return;

    state = state.copyWith(
      clearAbsurdityHtml: true,
      isLoading: true,
    );

    try {
      final history = state.turns
          .map((t) => {
                'question': t.aiQuestion,
                'answer': t.userAnswer ?? '',
              })
          .toList();

      final truthResponse = await _repository.generateTruthMode(
        imageBytes: state.compositeImage!,
        history: history,
      );

      if (!mounted) return;

      final truthTurn = ConversationTurn(aiQuestion: truthResponse);
      state = state.copyWith(
        turns: [...state.turns, truthTurn],
        isLoading: false,
        isFinished: true,
      );
    } catch (e) {
      if (!mounted) return;
      // 실패해도 대화는 종료 처리
      const fallbackTurn = ConversationTurn(
        aiQuestion: '스스로 발견했네! 정말 잘했어요. 궁금한 게 있으면 새 이미지로 다시 물어봐요.',
      );
      state = state.copyWith(
        turns: [...state.turns, fallbackTurn],
        isLoading: false,
        isFinished: true,
        error: 'Truth Mode 생성 실패: $e',
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
