import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/alien_models.dart';
import '../../data/repositories/alien_repository.dart';

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
  final Uint8List? compositeImage;
  final List<ConversationTurn> turns;
  final bool isLoading;
  final String? error;
  final String? lastFailedAnswer;

  const AlienState({
    this.compositeImage,
    this.turns = const [],
    this.isLoading = false,
    this.error,
    this.lastFailedAnswer,
  });

  AlienState copyWith({
    Uint8List? compositeImage,
    List<ConversationTurn>? turns,
    bool? isLoading,
    String? error,
    String? lastFailedAnswer,
  }) =>
      AlienState(
        compositeImage: compositeImage ?? this.compositeImage,
        turns: turns ?? this.turns,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastFailedAnswer: lastFailedAnswer ?? this.lastFailedAnswer,
      );

  ConversationTurn? get currentTurn =>
      turns.isEmpty ? null : turns.last;

  /// 대화 패널을 표시할지 여부
  bool get isActive => turns.isNotEmpty || isLoading;
}

class AlienNotifier extends StateNotifier<AlienState> {
  final AlienRepository _repository = AlienRepository();

  AlienNotifier() : super(const AlienState());

  static const _maxRetries = 3;

  Future<void> _streamResponseIntoLastTurn(Stream<String> stream) async {
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
  }

  Future<void> startConversation(Uint8List compositeImage) async {
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
        await _streamResponseIntoLastTurn(stream);
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

  Future<void> submitAnswer(String answer) async {
    if (state.compositeImage == null || state.turns.isEmpty) return;

    final turns = List<ConversationTurn>.from(state.turns);
    turns[turns.length - 1] = turns.last.copyWith(userAnswer: answer);

    final history = <AlienMessage>[];
    history.add(const AlienMessage(role: 'user', content: '이 그림에 대해 조사해 줘.'));
    for (int i = 0; i < turns.length - 1; i++) {
      history.add(AlienMessage(role: 'model', content: turns[i].aiQuestion));
      if (turns[i].userAnswer != null) {
        history.add(AlienMessage(role: 'user', content: turns[i].userAnswer!));
      }
    }
    history.add(AlienMessage(role: 'model', content: turns.last.aiQuestion));

    state = state.copyWith(
      turns: [...turns, const ConversationTurn(aiQuestion: "")],
      isLoading: true,
      error: null,
    );

    final imageBase64 = state.compositeImage != null
        ? base64Encode(state.compositeImage!)
        : null;

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      if (attempt > 0) {
        final t = List<ConversationTurn>.from(state.turns);
        t[t.length - 1] = const ConversationTurn(aiQuestion: "");
        state = state.copyWith(turns: t, isLoading: true, error: null);
      }

      try {
        final stream = _repository.chat(
          message: answer,
          history: history,
          imageBase64: imageBase64,
        );
        await _streamResponseIntoLastTurn(stream);
        return;
      } catch (e) {
        if (attempt < _maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 2));
        } else {
          state = state.copyWith(
            isLoading: false,
            error: '응답 생성 실패: $e',
            lastFailedAnswer: answer,
          );
        }
      }
    }
  }

  Future<void> retry() async {
    final answer = state.lastFailedAnswer;
    if (answer == null) return;

    final turns = List<ConversationTurn>.from(state.turns);
    // 빈 AI 응답 턴 제거
    if (turns.isNotEmpty && turns.last.aiQuestion.isEmpty && turns.last.userAnswer == null) {
      turns.removeLast();
    }
    // userAnswer 초기화 (submitAnswer가 다시 추가)
    if (turns.isNotEmpty) {
      turns[turns.length - 1] = ConversationTurn(aiQuestion: turns.last.aiQuestion);
    }

    state = AlienState(
      compositeImage: state.compositeImage,
      turns: turns,
    );

    await submitAnswer(answer);
  }

  void updateCompositeImage(Uint8List bytes) {
    state = state.copyWith(compositeImage: bytes);
  }

  void dismiss() {
    state = const AlienState();
  }
}

final alienProvider =
    StateNotifierProvider<AlienNotifier, AlienState>(
  (ref) => AlienNotifier(),
);
