# MindMuse 멀티모달 소크라테스 튜터 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** OCR 레이어를 제거하고 Gemma 4 멀티모달로 이미지를 직접 전달하여, 소크라테스 3라운드 대화 + 단계별 힌트 기능을 구현한다.

**Architecture:** 사용자가 드로잉을 완료하면 원본 이미지에 빨간 선을 합성한 PNG를 Gemma 4에 전달한다. Gemma는 질문과 힌트 3개를 반환하고, 사용자가 답변하면 Gemma가 평가 + 후속 질문을 생성하는 방식으로 최대 3라운드 대화를 이어간다. 대화 UI는 기존 말풍선에서 하단 패널로 교체한다.

**Tech Stack:** Flutter, Riverpod, google_generative_ai ^0.4.6, dart:ui (이미지 합성)

---

## 파일 구조

### 삭제
- `lib/features/canvas/data/repositories/ocr_repository.dart`
- `lib/features/canvas/presentation/providers/ocr_provider.dart`
- `lib/features/canvas/presentation/widgets/ocr_debug_painter.dart`
- `lib/features/canvas/data/models/text_block_model.dart`
- `lib/features/canvas/domain/services/coordinate_transform_service.dart`
- `lib/features/canvas/domain/services/intersection_service.dart`

### 신규
- `lib/features/canvas/domain/services/image_composite_service.dart` — 이미지+드로잉 합성
- `lib/features/canvas/presentation/widgets/conversation_panel.dart` — 대화 UI

### 수정
- `pubspec.yaml` — google_mlkit_text_recognition 제거
- `lib/features/canvas/data/repositories/gemma_repository.dart` — 멀티모달+대화+힌트
- `lib/features/canvas/presentation/providers/gemma_provider.dart` — 멀티턴 상태
- `lib/features/canvas/presentation/widgets/interactive_canvas.dart` — OCR 레이어 제거
- `lib/features/canvas/presentation/canvas_screen.dart` — 대화 패널 연결

---

## Task 1: OCR 인프라 제거

**Files:**
- Delete: `lib/features/canvas/data/repositories/ocr_repository.dart`
- Delete: `lib/features/canvas/presentation/providers/ocr_provider.dart`
- Delete: `lib/features/canvas/presentation/widgets/ocr_debug_painter.dart`
- Delete: `lib/features/canvas/data/models/text_block_model.dart`
- Delete: `lib/features/canvas/domain/services/coordinate_transform_service.dart`
- Delete: `lib/features/canvas/domain/services/intersection_service.dart`
- Modify: `pubspec.yaml`

- [ ] **Step 1: OCR 관련 파일 6개 삭제**

```bash
cd "D:/00_개인프로젝트/gemma_4_good_haackathon/mind_muse"
rm lib/features/canvas/data/repositories/ocr_repository.dart
rm lib/features/canvas/presentation/providers/ocr_provider.dart
rm lib/features/canvas/presentation/widgets/ocr_debug_painter.dart
rm lib/features/canvas/data/models/text_block_model.dart
rm lib/features/canvas/domain/services/coordinate_transform_service.dart
rm lib/features/canvas/domain/services/intersection_service.dart
```

- [ ] **Step 2: pubspec.yaml에서 google_mlkit_text_recognition 제거**

`pubspec.yaml` 의 dependencies에서 다음 줄을 삭제한다:
```yaml
  google_mlkit_text_recognition: ^0.13.1
```

최종 dependencies 섹션:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  google_generative_ai: ^0.4.6
  image_picker: ^1.1.2
  flutter_dotenv: ^5.2.1
```

- [ ] **Step 3: flutter pub get 실행**

```bash
JAVA_HOME="/c/Program Files/Android/Android Studio/jbr" \
ANDROID_HOME="C:/Users/JinYoung/AppData/Local/Android/Sdk" \
C:/flutter/bin/flutter pub get
```

기대 결과: `Got dependencies!` 출력, 에러 없음

- [ ] **Step 4: 커밋**

```bash
git add -A
git commit -m "feat: OCR 레이어 전체 제거, pubspec에서 mlkit 의존성 삭제"
```

---

## Task 2: ImageCompositeService 작성

**Files:**
- Create: `lib/features/canvas/domain/services/image_composite_service.dart`

- [ ] **Step 1: 파일 생성**

`lib/features/canvas/domain/services/image_composite_service.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../../data/models/drawn_stroke_model.dart';

/// 원본 이미지 파일 위에 드로잉 획을 합성하여 PNG bytes를 반환한다.
///
/// 드로잉 좌표는 InteractiveCanvas의 display 좌표(dp) 기준이다.
/// 이미지를 [containerSize]에 BoxFit.contain으로 맞춰 그린 뒤,
/// 동일 좌표계로 드로잉 선을 올려서 합성한다.
class ImageCompositeService {
  Future<Uint8List> composite({
    required File imageFile,
    required List<DrawnStrokeModel> strokes,
    required Size containerSize,
  }) async {
    // 1. 원본 이미지 디코딩
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    // 2. containerSize 크기의 캔버스 생성
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // 3. BoxFit.contain으로 이미지를 캔버스 중앙에 그리기
    final imageSize = Size(
      srcImage.width.toDouble(),
      srcImage.height.toDouble(),
    );
    final fittedSizes = applyBoxFit(BoxFit.contain, imageSize, containerSize);
    final dstSize = fittedSizes.destination;
    final offsetX = (containerSize.width - dstSize.width) / 2;
    final offsetY = (containerSize.height - dstSize.height) / 2;

    canvas.drawImageRect(
      srcImage,
      Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
      Rect.fromLTWH(offsetX, offsetY, dstSize.width, dstSize.height),
      Paint(),
    );

    // 4. 드로잉 선 합성 (DrawingPainter와 동일한 스타일)
    final strokePaint = Paint()
      ..color = const Color(0xFFE74C3C)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }

    // 5. PNG bytes로 변환
    final picture = recorder.endRecording();
    final compositeImage = await picture.toImage(
      containerSize.width.round(),
      containerSize.height.round(),
    );
    final byteData = await compositeImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/canvas/domain/services/image_composite_service.dart
git commit -m "feat: ImageCompositeService - 이미지+드로잉 합성 PNG 생성"
```

---

## Task 3: GemmaRepository 멀티모달 + 대화 + 힌트

**Files:**
- Modify: `lib/features/canvas/data/repositories/gemma_repository.dart`

- [ ] **Step 1: gemma_repository.dart 전체 교체**

```dart
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/constants/api_constants.dart';

/// Gemma 4 멀티모달 API를 호출하는 Repository.
/// 이미지 bytes를 직접 전달하여 OCR 없이 소크라테스 대화를 진행한다.
class GemmaRepository {
  late final GenerativeModel _model;

  GemmaRepository() {
    _model = GenerativeModel(
      model: ApiConstants.gemmaModel,
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  /// 합성 이미지를 보내 첫 번째 소크라테스 질문을 생성한다.
  Future<String> askInitialQuestion(Uint8List imageBytes) async {
    const prompt = '''학생이 교과서 이미지에서 빨간 선으로 표시한 부분을 보고,
그 내용에 대해 스스로 생각하도록 유도하는 소크라테스식 질문을 한국어로 1~2문장으로 만들어주세요.
답을 직접 알려주지 말고, 학생의 호기심을 자극해주세요.
질문 문장만 출력하고 다른 설명은 절대 출력하지 마세요.''';

    final response = await _model.generateContent([
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(prompt),
      ]),
    ]);
    return response.text?.trim() ?? '이 부분에 대해 어떻게 생각하나요?';
  }

  /// 첫 질문 직후 백그라운드에서 힌트 3개를 미리 생성한다.
  /// 반환 형식: List<String> 길이 3
  Future<List<String>> generateHints(
    Uint8List imageBytes,
    String question,
  ) async {
    final prompt = '''다음 질문에 대한 힌트를 3개 만들어주세요.
질문: "$question"

규칙:
- 힌트는 1→2→3으로 갈수록 더 구체적으로
- 답을 직접 알려주지 말 것
- 한국어로 작성
- 반드시 다음 형식으로만 출력 (다른 텍스트 없이):
힌트1내용|||힌트2내용|||힌트3내용''';

    final response = await _model.generateContent([
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(prompt),
      ]),
    ]);

    final text = response.text?.trim() ?? '';
    final parts = text.split('|||');
    if (parts.length >= 3) {
      return parts.take(3).map((s) => s.trim()).toList();
    }
    return [
      '표시한 부분의 핵심 단어에 집중해보세요.',
      '이 정보가 어떤 상황에서 쓰일지 상상해보세요.',
      '수치나 단위가 있다면 그것이 의미하는 바를 생각해보세요.',
    ];
  }

  /// 학생 답변을 평가하고 후속 질문(또는 마지막 라운드 정리)을 생성한다.
  ///
  /// [history]: [{question: ..., answer: ...}, ...] 형태의 대화 히스토리
  /// [isLastRound]: true이면 격려 + 핵심 정리, false이면 후속 소크라테스 질문
  Future<String> evaluateAndContinue({
    required Uint8List imageBytes,
    required List<Map<String, String>> history,
    required bool isLastRound,
  }) async {
    final historyText = history
        .map((h) => 'AI: ${h['question']}\n학생: ${h['answer']}')
        .join('\n\n');

    final prompt = isLastRound
        ? '''다음은 교과서 내용에 대한 소크라테스 대화입니다:

$historyText

학생의 마지막 답변을 격려하고, 오늘 학습한 핵심을 2~3문장으로 정리해주세요.
한국어로만 출력하세요. 다른 설명은 출력하지 마세요.'''
        : '''다음은 교과서 내용에 대한 소크라테스 대화입니다:

$historyText

학생의 마지막 답변을 한 문장으로 간단히 평가하고,
더 깊이 생각하도록 유도하는 후속 소크라테스 질문을 1~2문장으로 이어 작성해주세요.
한국어로만 출력하세요. 다른 설명은 출력하지 마세요.''';

    final response = await _model.generateContent([
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(prompt),
      ]),
    ]);
    return response.text?.trim() ?? '좋은 생각이에요! 조금 더 생각해볼까요?';
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/canvas/data/repositories/gemma_repository.dart
git commit -m "feat: GemmaRepository 멀티모달 전환, 힌트 생성, 대화 평가 API 추가"
```

---

## Task 4: GemmaProvider 멀티턴 대화 상태로 교체

**Files:**
- Modify: `lib/features/canvas/presentation/providers/gemma_provider.dart`

- [ ] **Step 1: gemma_provider.dart 전체 교체**

```dart
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

      // 첫 턴 추가
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

  /// 힌트 사전 생성 (백그라운드)
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
        updatedTurns[turnIndex] = updatedTurns[turnIndex].copyWith(hints: hints);
        state = state.copyWith(turns: updatedTurns);
      }
    } catch (_) {
      // 힌트 생성 실패는 무시 (힌트 버튼 비활성화로 처리)
    }
  }

  /// 힌트 한 단계 공개
  void revealNextHint() {
    final turns = List<ConversationTurn>.from(state.turns);
    final last = turns.last;
    if (last.revealedHints >= last.hints.length) return;
    turns[turns.length - 1] = last.copyWith(
      revealedHints: last.revealedHints + 1,
    );
    state = state.copyWith(turns: turns);
  }

  /// 사용자 답변 제출 — 평가 + 후속 질문 생성
  Future<void> submitAnswer(String answer) async {
    if (state.compositeImage == null || state.turns.isEmpty) return;

    // 현재 턴에 답변 저장
    final turns = List<ConversationTurn>.from(state.turns);
    turns[turns.length - 1] = turns.last.copyWith(userAnswer: answer);
    state = state.copyWith(turns: turns, isLoading: true);

    try {
      final history = turns
          .map((t) => {'question': t.aiQuestion, 'answer': t.userAnswer ?? ''})
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
        _prefetchHints(state.compositeImage!, response, newTurns.length - 1);
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
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/canvas/presentation/providers/gemma_provider.dart
git commit -m "feat: GemmaProvider 멀티턴 대화 상태 관리, 힌트 사전 생성"
```

---

## Task 5: ConversationPanel 위젯

**Files:**
- Create: `lib/features/canvas/presentation/widgets/conversation_panel.dart`

- [ ] **Step 1: 파일 생성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gemma_provider.dart';

/// 화면 하단에 고정되는 소크라테스 대화 패널.
/// 대화 히스토리 + 답변 입력 + 힌트 버튼을 포함한다.
class ConversationPanel extends ConsumerStatefulWidget {
  const ConversationPanel({super.key});

  @override
  ConsumerState<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends ConsumerState<ConversationPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gemmaProvider);

    // 새 메시지가 추가되면 스크롤 아래로
    ref.listen(gemmaProvider, (_, __) => _scrollToBottom());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFF4A90D9), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'MindMuse 튜터',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90D9),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (!state.isLoading)
                  TextButton(
                    onPressed: () {
                      ref.read(gemmaProvider.notifier).dismiss();
                    },
                    child: const Text('닫기',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 대화 히스토리
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35,
            ),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.turns.length,
              itemBuilder: (context, index) {
                final turn = state.turns[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI 질문
                    _AiMessage(message: turn.aiQuestion),
                    const SizedBox(height: 6),

                    // 공개된 힌트
                    for (int h = 0; h < turn.revealedHints; h++)
                      if (h < turn.hints.length)
                        _HintMessage(
                            hint: '힌트 ${h + 1}: ${turn.hints[h]}'),

                    // 사용자 답변
                    if (turn.userAnswer != null) ...[
                      const SizedBox(height: 6),
                      _UserMessage(message: turn.userAnswer!),
                    ],
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),

          // 로딩 인디케이터
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('생각 중...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // 에러 메시지
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          // 입력 영역 (완료되지 않은 경우에만)
          if (!state.isFinished && !state.isLoading && state.turns.isNotEmpty)
            _InputArea(
              controller: _controller,
              canHint: () {
                final turn = state.currentTurn;
                if (turn == null) return false;
                return turn.revealedHints < turn.hints.length;
              },
              onHint: () => ref.read(gemmaProvider.notifier).revealNextHint(),
              onSubmit: (answer) {
                if (answer.trim().isEmpty) return;
                _controller.clear();
                ref.read(gemmaProvider.notifier).submitAnswer(answer.trim());
              },
            ),

          // 완료 메시지
          if (state.isFinished)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () => ref.read(gemmaProvider.notifier).dismiss(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('학습 완료!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90D9),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          // 키보드 패딩
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _AiMessage extends StatelessWidget {
  final String message;
  const _AiMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 12,
          backgroundColor: Color(0xFF4A90D9),
          child: Icon(Icons.lightbulb_outline, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserMessage extends StatelessWidget {
  final String message;
  const _UserMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90D9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 14, color: Colors.white, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _HintMessage extends StatelessWidget {
  final String hint;
  const _HintMessage({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 32, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        hint,
        style: TextStyle(
            fontSize: 12, color: Colors.amber.shade900, height: 1.4),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool Function() canHint;
  final VoidCallback onHint;
  final void Function(String) onSubmit;

  const _InputArea({
    required this.controller,
    required this.canHint,
    required this.onHint,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          // 힌트 버튼
          OutlinedButton.icon(
            onPressed: canHint() ? onHint : null,
            icon: const Icon(Icons.lightbulb, size: 16),
            label: const Text('힌트', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: BorderSide(color: Colors.amber.shade400),
              foregroundColor: Colors.amber.shade700,
            ),
          ),
          const SizedBox(width: 8),
          // 답변 입력
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '답변을 입력하세요...',
                hintStyle:
                    const TextStyle(fontSize: 14, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: Color(0xFF4A90D9), width: 1.5),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: onSubmit,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          // 전송 버튼
          IconButton(
            onPressed: () => onSubmit(controller.text),
            icon: const Icon(Icons.send_rounded),
            color: const Color(0xFF4A90D9),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE8F0FE),
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/canvas/presentation/widgets/conversation_panel.dart
git commit -m "feat: ConversationPanel - 소크라테스 대화 UI (힌트 + 답변 입력)"
```

---

## Task 6: InteractiveCanvas에서 OCR 레이어 제거

**Files:**
- Modify: `lib/features/canvas/presentation/widgets/interactive_canvas.dart`

- [ ] **Step 1: interactive_canvas.dart 전체 교체**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/drawn_stroke_model.dart';
import 'drawing_painter.dart';

/// 이미지 + 드로잉 레이어를 겹쳐서 표시한다.
/// OCR 레이어는 제거됨 — Gemma 멀티모달이 이미지를 직접 처리한다.
class InteractiveCanvas extends StatelessWidget {
  final File imageFile;
  final List<DrawnStrokeModel> strokes;
  final List<Offset> currentPoints;
  final void Function(Offset) onPanStart;
  final void Function(Offset) onPanUpdate;
  final void Function() onPanEnd;

  const InteractiveCanvas({
    super.key,
    required this.imageFile,
    required this.strokes,
    required this.currentPoints,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => onPanStart(details.localPosition),
      onPanUpdate: (details) => onPanUpdate(details.localPosition),
      onPanEnd: (_) => onPanEnd(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 레이어 1: 교과서 이미지
          Image.file(imageFile, fit: BoxFit.contain),

          // 레이어 2: 사용자 드로잉
          CustomPaint(
            painter: DrawingPainter(
              strokes: strokes,
              currentPoints: currentPoints,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/canvas/presentation/widgets/interactive_canvas.dart
git commit -m "refactor: InteractiveCanvas에서 OCR 레이어 제거"
```

---

## Task 7: CanvasScreen — OCR 제거 + 이미지 합성 + ConversationPanel 연결

**Files:**
- Modify: `lib/features/canvas/presentation/canvas_screen.dart`

- [ ] **Step 1: canvas_screen.dart 전체 교체**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/services/image_composite_service.dart';
import 'providers/canvas_provider.dart';
import 'providers/gemma_provider.dart';
import 'widgets/interactive_canvas.dart';
import 'widgets/conversation_panel.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const CanvasScreen({super.key, required this.imagePath});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  late final File _imageFile;
  final GlobalKey _canvasKey = GlobalKey();
  final _compositeService = ImageCompositeService();

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
  }

  Future<void> _onStrokeEnd() async {
    if (!mounted) return;

    // 획 완료 처리
    final stroke = ref.read(canvasProvider.notifier).endStroke();
    if (stroke == null) return;

    // 컨테이너 크기 측정
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final containerSize = renderBox.size;

    // 이미지 + 드로잉 합성
    final strokes = ref.read(canvasProvider).strokes;
    final imageBytes = await _compositeService.composite(
      imageFile: _imageFile,
      strokes: strokes,
      containerSize: containerSize,
    );

    // Gemma에 전달
    if (mounted) {
      await ref.read(gemmaProvider.notifier).startConversation(imageBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gemmaState = ref.watch(gemmaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindMuse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '드로잉 초기화',
            onPressed: () {
              ref.read(canvasProvider.notifier).clearStrokes();
              ref.read(gemmaProvider.notifier).dismiss();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 메인 캔버스
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final canvasState = ref.watch(canvasProvider);
                return InteractiveCanvas(
                  key: _canvasKey,
                  imageFile: _imageFile,
                  strokes: canvasState.strokes,
                  currentPoints: canvasState.currentPoints,
                  onPanStart: (pos) =>
                      ref.read(canvasProvider.notifier).startStroke(pos),
                  onPanUpdate: (pos) =>
                      ref.read(canvasProvider.notifier).addPoint(pos),
                  onPanEnd: _onStrokeEnd,
                );
              },
            ),
          ),

          // 대화 패널 (활성 상태일 때만 표시)
          if (gemmaState.isActive) const ConversationPanel(),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/canvas/presentation/canvas_screen.dart
git commit -m "feat: CanvasScreen - OCR 제거, 이미지 합성 후 Gemma 전달, ConversationPanel 연결"
```

---

## Task 8: 빌드 확인

- [ ] **Step 1: flutter analyze 실행**

```bash
JAVA_HOME="/c/Program Files/Android/Android Studio/jbr" \
ANDROID_HOME="C:/Users/JinYoung/AppData/Local/Android/Sdk" \
C:/flutter/bin/flutter analyze
```

기대 결과: `No issues found!` (또는 info/warning만 있고 error 없음)

- [ ] **Step 2: APK 빌드**

```bash
JAVA_HOME="/c/Program Files/Android/Android Studio/jbr" \
ANDROID_HOME="C:/Users/JinYoung/AppData/Local/Android/Sdk" \
C:/flutter/bin/flutter build apk --debug
```

기대 결과: `Built build\app\outputs\flutter-apk\app-debug.apk`

- [ ] **Step 3: 최종 커밋**

```bash
git add -A
git commit -m "feat: 멀티모달 소크라테스 튜터 완성 - OCR 제거, Gemma 이미지 직접 전달, 3라운드 대화+힌트"
```

---

## 검증 기준

- 교과서 이미지에 표시 후 한국어 소크라테스 질문이 생성됨
- 프롬프트 텍스트가 응답에 그대로 노출되지 않음
- 답변 입력 후 AI 평가 + 후속 질문이 표시됨
- 힌트 버튼 탭 시 힌트가 1개씩 추가 공개됨 (최대 3개)
- 3라운드 완료 후 격려 메시지 + "학습 완료!" 버튼 표시
- 새로 표시하거나 새로고침 시 대화 패널 초기화됨
