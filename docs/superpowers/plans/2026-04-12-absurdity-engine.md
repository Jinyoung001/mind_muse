# Absurdity Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 학생의 소크라테스 대화 중 오개념이 탐지되면 인터랙티브 HTML 시뮬레이션으로 인지 부조화를 유도하고, 학생이 스스로 의심하면 Truth Mode로 전환해 올바른 개념을 설명한다.

**Architecture:** 순차 탐지 방식 — `submitAnswer()` 호출 시 오개념 탐지를 먼저 실행하고 결과에 따라 기존 소크라테스 흐름 또는 Absurdity Engine 경로로 분기한다. `absurdityTriggered` 플래그로 같은 세션 내 재발동을 방지한다. WebView는 ConversationPanel 내 인라인 카드(높이 300px)로 표시된다.

**Tech Stack:** Flutter, Riverpod, google_generative_ai, flutter_inappwebview ^6.1.5

---

## 파일 구조

| 역할 | 경로 | 신규/수정 |
|---|---|---|
| 의존성 | `pubspec.yaml` | 수정 |
| 오개념 모델 | `lib/features/canvas/data/models/misconception_model.dart` | 신규 |
| 오개념 탐지 API | `lib/features/canvas/data/repositories/misconception_repository.dart` | 신규 |
| HTML 생성 API | `lib/features/canvas/data/repositories/absurdity_repository.dart` | 신규 |
| Truth Mode API | `lib/features/canvas/data/repositories/gemma_repository.dart` | 수정 |
| 상태 + 로직 | `lib/features/canvas/presentation/providers/gemma_provider.dart` | 수정 |
| WebView 카드 위젯 | `lib/features/canvas/presentation/widgets/absurdity_webview_bubble.dart` | 신규 |
| 대화 패널 | `lib/features/canvas/presentation/widgets/conversation_panel.dart` | 수정 |
| 모델 파싱 테스트 | `test/misconception_model_test.dart` | 신규 |

---

## Task 1: 의존성 추가

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yaml에 flutter_inappwebview 추가**

`dependencies` 블록 안에 아래 줄을 추가한다:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  google_generative_ai: ^0.4.6
  image_picker: ^1.1.2
  flutter_dotenv: ^5.2.1
  flutter_inappwebview: ^6.1.5
```

- [ ] **Step 2: pub get 실행**

```bash
cd mind_muse && flutter pub get
```

예상 출력: `Got dependencies!`

- [ ] **Step 3: 커밋**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_inappwebview dependency"
```

---

## Task 2: MisconceptionModel + 파싱 테스트

**Files:**
- Create: `lib/features/canvas/data/models/misconception_model.dart`
- Create: `test/misconception_model_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/misconception_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_muse/features/canvas/data/models/misconception_model.dart';

void main() {
  group('MisconceptionResult.fromJson', () {
    test('오개념 있음 — 정상 JSON 파싱', () {
      const raw =
          '{"has_misconception": true, "subject": "biology", '
          '"false_assumption": "포식자가 없으면 동물들이 평화롭게 산다", '
          '"absurd_extreme": "사슴이 지구를 뒤덮는다", '
          '"trigger_phrase": "맞아! 시뮬레이션 만들어줄게!"}';
      final result = MisconceptionResult.fromJson(raw);
      expect(result.hasMisconception, true);
      expect(result.subject, 'biology');
      expect(result.falseAssumption, '포식자가 없으면 동물들이 평화롭게 산다');
      expect(result.absurdExtreme, '사슴이 지구를 뒤덮는다');
      expect(result.triggerPhrase, '맞아! 시뮬레이션 만들어줄게!');
    });

    test('오개념 없음', () {
      const raw = '{"has_misconception": false}';
      final result = MisconceptionResult.fromJson(raw);
      expect(result.hasMisconception, false);
    });

    test('```json 마크다운 블록 처리', () {
      const raw = '```json\n{"has_misconception": false}\n```';
      final result = MisconceptionResult.fromJson(raw);
      expect(result.hasMisconception, false);
    });

    test('JSON이 아닌 문자열 → noMisconception 반환', () {
      const raw = '이것은 JSON이 아닙니다';
      final result = MisconceptionResult.fromJson(raw);
      expect(result.hasMisconception, false);
    });

    test('has_misconception 키 누락 → noMisconception 반환', () {
      const raw = '{"subject": "biology"}';
      final result = MisconceptionResult.fromJson(raw);
      expect(result.hasMisconception, false);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
cd mind_muse && flutter test test/misconception_model_test.dart
```

예상 출력: `FAILED` (모델 파일이 없으므로)

- [ ] **Step 3: MisconceptionModel 구현**

`lib/features/canvas/data/models/misconception_model.dart`:

```dart
import 'dart:convert';

class MisconceptionResult {
  final bool hasMisconception;
  final String subject;
  final String falseAssumption;
  final String absurdExtreme;
  final String triggerPhrase;

  const MisconceptionResult({
    required this.hasMisconception,
    this.subject = '',
    this.falseAssumption = '',
    this.absurdExtreme = '',
    this.triggerPhrase = '',
  });

  factory MisconceptionResult.noMisconception() =>
      const MisconceptionResult(hasMisconception: false);

  factory MisconceptionResult.fromJson(String raw) {
    try {
      final jsonStr = _extractJson(raw);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (map['has_misconception'] != true) {
        return MisconceptionResult.noMisconception();
      }

      return MisconceptionResult(
        hasMisconception: true,
        subject: map['subject'] as String? ?? 'other',
        falseAssumption: map['false_assumption'] as String? ?? '',
        absurdExtreme: map['absurd_extreme'] as String? ?? '',
        triggerPhrase: map['trigger_phrase'] as String? ??
            '맞아! 완전히 동의해! 내가 네 논리대로 시뮬레이션을 만들어줄게!',
      );
    } catch (_) {
      return MisconceptionResult.noMisconception();
    }
  }

  static String _extractJson(String raw) {
    // ```json ... ``` 또는 ``` ... ``` 마크다운 블록 제거
    final blockMatch =
        RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
    if (blockMatch != null) return blockMatch.group(1)!;

    // { ... } 직접 추출
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return raw.substring(start, end + 1);
    }

    return raw.trim();
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
cd mind_muse && flutter test test/misconception_model_test.dart
```

예상 출력: `All tests passed!`

- [ ] **Step 5: 커밋**

```bash
git add lib/features/canvas/data/models/misconception_model.dart test/misconception_model_test.dart
git commit -m "feat: add MisconceptionModel with JSON parsing"
```

---

## Task 3: MisconceptionRepository

**Files:**
- Create: `lib/features/canvas/data/repositories/misconception_repository.dart`

- [ ] **Step 1: 파일 생성**

`lib/features/canvas/data/repositories/misconception_repository.dart`:

```dart
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/misconception_model.dart';

class MisconceptionRepository {
  late final GenerativeModel _model;

  MisconceptionRepository() {
    _model = GenerativeModel(
      model: ApiConstants.gemmaModel,
      apiKey: ApiConstants.geminiApiKey,
      systemInstruction: Content.text(
        'You are a misconception detector for a K-12 education app.\n'
        'Analyze the student\'s input and determine:\n'
        '1. Does it contain a factual misconception?\n'
        '2. If yes, what is the core false assumption?\n'
        '3. What would happen if we took this misconception to its logical extreme?\n\n'
        'Respond ONLY in this JSON format, no markdown, no explanation:\n'
        '{"has_misconception": true or false, '
        '"subject": "physics" | "biology" | "economics" | "math" | "logic" | "other", '
        '"false_assumption": "one sentence describing the wrong belief", '
        '"absurd_extreme": "one sentence describing what happens if we take this to extreme", '
        '"trigger_phrase": "short phrase the AI will say to agree and trigger the simulation"}\n'
        'If has_misconception is false, return: {"has_misconception": false}',
      ),
    );
  }

  /// 이미지 + 대화 히스토리 + 최신 답변을 분석해 오개념 여부를 반환한다.
  /// API 실패 또는 파싱 오류 시 [MisconceptionResult.noMisconception()]를 반환한다.
  Future<MisconceptionResult> detect({
    required Uint8List imageBytes,
    required List<Map<String, String>> history,
    required String latestAnswer,
  }) async {
    try {
      final historyText = history
          .map((h) => 'AI: ${h['question']}\n학생: ${h['answer']}')
          .join('\n\n');

      final prompt = '대화 기록:\n$historyText\n\n최신 학생 답변: $latestAnswer';

      final response = await _model.generateContent([
        Content.multi([
          DataPart('image/png', imageBytes),
          TextPart(prompt),
        ]),
      ]);

      return MisconceptionResult.fromJson(response.text ?? '');
    } catch (_) {
      return MisconceptionResult.noMisconception();
    }
  }
}
```

- [ ] **Step 2: 컴파일 확인**

```bash
cd mind_muse && flutter analyze lib/features/canvas/data/repositories/misconception_repository.dart
```

예상 출력: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/canvas/data/repositories/misconception_repository.dart
git commit -m "feat: add MisconceptionRepository"
```

---

## Task 4: AbsurdityRepository

**Files:**
- Create: `lib/features/canvas/data/repositories/absurdity_repository.dart`

- [ ] **Step 1: 파일 생성**

`lib/features/canvas/data/repositories/absurdity_repository.dart`:

```dart
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/constants/api_constants.dart';

class AbsurdityRepository {
  late final GenerativeModel _model;

  AbsurdityRepository() {
    _model = GenerativeModel(
      model: ApiConstants.gemmaModel,
      apiKey: ApiConstants.geminiApiKey,
      systemInstruction: Content.text(
        'You are an interactive simulation generator for an educational app.\n'
        'You will receive a student\'s misconception. Your job is to create a short, '
        'interactive HTML+CSS+JS widget that visually demonstrates what the world '
        'would look like if the misconception were taken to its absurd logical extreme.\n\n'
        'Rules:\n'
        '- Output ONLY raw HTML. No markdown, no backticks, no explanation.\n'
        '- The HTML must be fully self-contained (inline CSS and JS only, no external libraries).\n'
        '- Canvas or simple DOM animations are preferred over complex frameworks.\n'
        '- The simulation must be obviously wrong and slightly funny.\n'
        '- Include a "나도 이상한 것 같아..." button.\n'
        '  When clicked, it should call: window.flutter_inappwebview.callHandler(\'studentDoubt\')\n'
        '- Keep it simple enough to load instantly on mobile.\n'
        '- Max 150 lines of HTML.\n'
        '- Background color: #1a1a2e (dark), text color: #eee.\n'
        '- Korean UI text only.',
      ),
    );
  }

  /// HTML 생성 실패 시 반환할 fallback HTML.
  /// "이상한 것 같아..." 버튼은 항상 포함된다.
  static const String _fallbackHtml = '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body {
    background: #1a1a2e; color: #eee;
    font-family: sans-serif;
    display: flex; flex-direction: column;
    align-items: center; justify-content: center;
    height: 100vh; margin: 0; padding: 16px;
    box-sizing: border-box; text-align: center;
  }
  .emoji { font-size: 48px; margin-bottom: 16px; }
  p { margin: 4px 0; }
  .sub { font-size: 13px; color: #aaa; margin-top: 8px; }
  button {
    margin-top: 24px; padding: 12px 24px;
    background: #e94560; color: #fff;
    border: none; border-radius: 8px;
    font-size: 16px; cursor: pointer;
  }
</style>
</head>
<body>
  <div class="emoji">😅</div>
  <p>부조리한 세계를 만들지 못했어요</p>
  <p class="sub">하지만 뭔가 이상한 건 맞는 것 같아요!</p>
  <button onclick="window.flutter_inappwebview.callHandler('studentDoubt')">
    나도 이상한 것 같아...
  </button>
</body>
</html>''';

  /// [falseAssumption], [absurdExtreme], [subject]를 바탕으로
  /// 인터랙티브 HTML 시뮬레이션을 생성한다.
  /// 생성 실패 시 [_fallbackHtml]을 반환한다.
  Future<String> generateHtml({
    required String falseAssumption,
    required String absurdExtreme,
    required String subject,
  }) async {
    try {
      final prompt =
          'Student\'s false assumption: $falseAssumption\n'
          'Absurd extreme scenario: $absurdExtreme\n'
          'Subject: $subject\n\n'
          'Generate the interactive absurdity simulation now.';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      final raw = response.text ?? '';
      final html = _extractHtml(raw);
      return html.isNotEmpty ? html : _fallbackHtml;
    } catch (_) {
      return _fallbackHtml;
    }
  }

  String _extractHtml(String raw) {
    // ```html ... ``` 마크다운 블록 제거
    final blockMatch =
        RegExp(r'```(?:html)?\s*([\s\S]*?)\s*```').firstMatch(raw);
    if (blockMatch != null) return blockMatch.group(1)!.trim();

    // <!DOCTYPE 시작 지점 추출
    final doctypeIdx = raw.indexOf('<!DOCTYPE');
    if (doctypeIdx != -1) return raw.substring(doctypeIdx).trim();

    // <html 시작 지점 추출
    final htmlIdx = raw.indexOf('<html');
    if (htmlIdx != -1) return raw.substring(htmlIdx).trim();

    return raw.trim();
  }
}
```

- [ ] **Step 2: 컴파일 확인**

```bash
cd mind_muse && flutter analyze lib/features/canvas/data/repositories/absurdity_repository.dart
```

예상 출력: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/canvas/data/repositories/absurdity_repository.dart
git commit -m "feat: add AbsurdityRepository with fallback HTML"
```

---

## Task 5: GemmaRepository에 Truth Mode 메서드 추가

**Files:**
- Modify: `lib/features/canvas/data/repositories/gemma_repository.dart`

- [ ] **Step 1: generateTruthMode 메서드 추가**

기존 `evaluateAndContinue` 메서드 뒤에 아래 메서드를 추가한다:

```dart
  /// 학생이 스스로 오개념을 발견한 직후 Truth Mode 설명을 생성한다.
  Future<String> generateTruthMode({
    required Uint8List imageBytes,
    required List<Map<String, String>> history,
  }) async {
    final historyText = history
        .map((h) => 'AI: ${h['question']}\n학생: ${h['answer']}')
        .join('\n\n');

    const prompt =
        'The student has just realized their misconception on their own. '
        'Switch to honest tutoring mode. '
        'Start your response with exactly: "오! 스스로 발견했네. 사실은 이렇게 작동해:" '
        'Then explain the correct concept clearly and warmly. Korean only.\n\n'
        'Conversation history:\n';

    final response = await _model.generateContent([
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(prompt + historyText),
      ]),
    ]);
    final raw = response.text ?? '';
    return _cleanResponse(raw).isNotEmpty
        ? _cleanResponse(raw)
        : '오! 스스로 발견했네. 사실은 이렇게 작동해: 정말 잘 생각해봤어요!';
  }
```

- [ ] **Step 2: 컴파일 확인**

```bash
cd mind_muse && flutter analyze lib/features/canvas/data/repositories/gemma_repository.dart
```

예상 출력: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/canvas/data/repositories/gemma_repository.dart
git commit -m "feat: add generateTruthMode to GemmaRepository"
```

---

## Task 6: GemmaState + GemmaNotifier 확장

**Files:**
- Modify: `lib/features/canvas/presentation/providers/gemma_provider.dart`

- [ ] **Step 1: 파일 전체를 아래 내용으로 교체**

`lib/features/canvas/presentation/providers/gemma_provider.dart`:

```dart
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
  final List<String> hints;
  final int revealedHints;

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

  /// 대화 종료 여부 (소크라테스 3라운드 완료 또는 Truth Mode 완료)
  final bool isFinished;

  /// 에러 메시지 (null이면 정상)
  final String? error;

  /// 생성된 Absurdity Engine HTML. null이면 WebView 비활성.
  final String? absurdityHtml;

  /// HTML 생성 중 여부 — "부조리한 세계를 만드는 중..." 표시
  final bool isGeneratingAbsurdity;

  /// true이면 같은 세션에서 Absurdity Engine 재발동 방지
  final bool absurdityTriggered;

  const GemmaState({
    this.compositeImage,
    this.turns = const [],
    this.isLoading = false,
    this.isFinished = false,
    this.error,
    this.absurdityHtml,
    this.isGeneratingAbsurdity = false,
    this.absurdityTriggered = false,
  });

  GemmaState copyWith({
    Uint8List? compositeImage,
    List<ConversationTurn>? turns,
    bool? isLoading,
    bool? isFinished,
    String? error,
    String? absurdityHtml,
    bool? isGeneratingAbsurdity,
    bool? absurdityTriggered,
  }) =>
      GemmaState(
        compositeImage: compositeImage ?? this.compositeImage,
        turns: turns ?? this.turns,
        isLoading: isLoading ?? this.isLoading,
        isFinished: isFinished ?? this.isFinished,
        error: error,
        absurdityHtml: absurdityHtml ?? this.absurdityHtml,
        isGeneratingAbsurdity:
            isGeneratingAbsurdity ?? this.isGeneratingAbsurdity,
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
  final MisconceptionRepository _misconceptionRepo = MisconceptionRepository();
  final AbsurdityRepository _absurdityRepo = AbsurdityRepository();

  GemmaNotifier() : super(const GemmaState());

  /// 드로잉 완료 또는 버튼으로 호출 — 합성 이미지를 받아 첫 질문 생성
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

  /// 사용자 답변 제출 — 오개념 탐지 후 분기
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

      // ── 오개념 탐지 (absurdityTriggered == true이면 스킵) ──────────
      if (!state.absurdityTriggered) {
        final result = await _misconceptionRepo.detect(
          imageBytes: state.compositeImage!,
          history: history,
          latestAnswer: answer,
        );

        if (!mounted) return;

        if (result.hasMisconception) {
          // Absurdity Engine 트리거
          final triggerTurn =
              ConversationTurn(aiQuestion: result.triggerPhrase);
          final newTurns = [...state.turns, triggerTurn];
          state = state.copyWith(
            turns: newTurns,
            isLoading: false,
            isGeneratingAbsurdity: true,
            absurdityTriggered: true,
          );

          final html = await _absurdityRepo.generateHtml(
            falseAssumption: result.falseAssumption,
            absurdExtreme: result.absurdExtreme,
            subject: result.subject,
          );

          if (!mounted) return;
          state = state.copyWith(
            absurdityHtml: html,
            isGeneratingAbsurdity: false,
          );
          return;
        }
      }

      // ── 기존 소크라테스 흐름 ────────────────────────────────────────
      final isLastRound = turns.length >= kMaxRounds;
      final response = await _repository.evaluateAndContinue(
        imageBytes: state.compositeImage!,
        history: history,
        isLastRound: isLastRound,
      );

      if (!mounted) return;

      if (isLastRound) {
        final finalTurn = ConversationTurn(aiQuestion: response);
        state = state.copyWith(
          turns: [...state.turns, finalTurn],
          isLoading: false,
          isFinished: true,
        );
      } else {
        final nextTurn = ConversationTurn(aiQuestion: response);
        final newTurns = [...state.turns, nextTurn];
        state = state.copyWith(turns: newTurns, isLoading: false);
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

  /// WebView "나도 이상한 것 같아..." 버튼 클릭 시 호출 — Truth Mode 전환
  Future<void> onStudentDoubt() async {
    if (state.compositeImage == null) return;

    // WebView를 닫고 Truth Mode 로딩 시작
    // absurdityHtml을 null로 초기화하려면 새 GemmaState를 직접 생성한다
    state = GemmaState(
      compositeImage: state.compositeImage,
      turns: state.turns,
      isLoading: true,
      absurdityTriggered: state.absurdityTriggered,
      // absurdityHtml: null (기본값) → WebView 닫힘
    );

    try {
      final history = state.turns
          .map((t) => {
                'question': t.aiQuestion,
                'answer': t.userAnswer ?? '',
              })
          .toList();

      final response = await _repository.generateTruthMode(
        imageBytes: state.compositeImage!,
        history: history,
      );

      if (!mounted) return;

      final truthTurn = ConversationTurn(aiQuestion: response);
      state = state.copyWith(
        turns: [...state.turns, truthTurn],
        isLoading: false,
        isFinished: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Truth Mode 전환 실패: $e',
        isFinished: true,
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

- [ ] **Step 2: 컴파일 확인**

```bash
cd mind_muse && flutter analyze lib/features/canvas/presentation/providers/gemma_provider.dart
```

예상 출력: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/canvas/presentation/providers/gemma_provider.dart
git commit -m "feat: extend GemmaState with absurdity fields, add submitAnswer branching and onStudentDoubt"
```

---

## Task 7: AbsurdityWebviewBubble 위젯

**Files:**
- Create: `lib/features/canvas/presentation/widgets/absurdity_webview_bubble.dart`

- [ ] **Step 1: 파일 생성**

`lib/features/canvas/presentation/widgets/absurdity_webview_bubble.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Absurdity Engine HTML을 300px 카드로 표시하는 위젯.
/// HTML 내 "나도 이상한 것 같아..." 버튼 클릭 시 [onStudentDoubt]를 호출한다.
class AbsurdityWebviewBubble extends StatelessWidget {
  final String html;
  final VoidCallback onStudentDoubt;

  const AbsurdityWebviewBubble({
    super.key,
    required this.html,
    required this.onStudentDoubt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: html,
          mimeType: 'text/html',
          encoding: 'utf-8',
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          transparentBackground: true,
          disableVerticalScroll: true,
          disableHorizontalScroll: true,
        ),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'studentDoubt',
            callback: (_) => onStudentDoubt(),
          );
        },
        onReceivedError: (controller, request, error) {
          debugPrint('AbsurdityWebView error: ${error.description}');
        },
      ),
    );
  }
}

/// HTML 생성 중 표시하는 로딩 카드
class AbsurdityLoadingCard extends StatelessWidget {
  const AbsurdityLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFe94560),
            ),
          ),
          SizedBox(width: 12),
          Text(
            '부조리한 세계를 만드는 중...',
            style: TextStyle(color: Color(0xFFeeeeee), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 컴파일 확인**

```bash
cd mind_muse && flutter analyze lib/features/canvas/presentation/widgets/absurdity_webview_bubble.dart
```

예상 출력: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/canvas/presentation/widgets/absurdity_webview_bubble.dart
git commit -m "feat: add AbsurdityWebviewBubble and AbsurdityLoadingCard widgets"
```

---

## Task 8: ConversationPanel 수정

**Files:**
- Modify: `lib/features/canvas/presentation/widgets/conversation_panel.dart`

- [ ] **Step 1: import 추가**

파일 상단 import 블록에 아래 두 줄을 추가한다:

```dart
import '../providers/gemma_provider.dart';  // 기존 import (이미 있음)
import 'absurdity_webview_bubble.dart';     // 추가
```

- [ ] **Step 2: Absurdity 카드를 대화 패널에 삽입**

`conversation_panel.dart`의 `build()` 메서드 내 Column children에서,
`// 로딩 인디케이터` 주석 바로 위에 Absurdity 카드 두 블록을 추가한다.

변경 전 (기존 코드):
```dart
          // 로딩 인디케이터
          if (state.isLoading)
```

변경 후:
```dart
          // Absurdity Engine — HTML 생성 중 로딩 카드
          if (state.isGeneratingAbsurdity)
            const AbsurdityLoadingCard(),

          // Absurdity Engine — WebView 시뮬레이션 카드
          if (!state.isGeneratingAbsurdity && state.absurdityHtml != null)
            AbsurdityWebviewBubble(
              html: state.absurdityHtml!,
              onStudentDoubt: () =>
                  ref.read(gemmaProvider.notifier).onStudentDoubt(),
            ),

          // 로딩 인디케이터
          if (state.isLoading)
```

- [ ] **Step 3: 컴파일 확인**

```bash
cd mind_muse && flutter analyze lib/features/canvas/presentation/widgets/conversation_panel.dart
```

예상 출력: `No issues found!`

- [ ] **Step 4: 커밋**

```bash
git add lib/features/canvas/presentation/widgets/conversation_panel.dart
git commit -m "feat: embed AbsurdityWebviewBubble into ConversationPanel"
```

---

## Task 9: 전체 빌드 및 동작 확인

**Files:** 없음 (빌드 검증)

- [ ] **Step 1: 전체 정적 분석**

```bash
cd mind_muse && flutter analyze
```

예상 출력: `No issues found!`

- [ ] **Step 2: 모델 파싱 테스트 실행**

```bash
cd mind_muse && flutter test test/misconception_model_test.dart -v
```

예상 출력: `All tests passed!`

- [ ] **Step 3: Debug APK 빌드**

```bash
cd mind_muse && flutter build apk --debug
```

예상 출력: `✓ Built build\app\outputs\flutter-apk\app-debug.apk`

- [ ] **Step 4: 데모 시나리오 수동 확인 체크리스트**

기기에 APK 설치 후 아래 항목을 직접 테스트한다:

```
[ ] 이미지 선택 → 동그라미 → AI 첫 질문 표시
[ ] 답변 입력: "포식자가 없으면 동물들이 평화롭게 살 수 있잖아"
    → "부조리한 세계를 만드는 중..." 로딩 카드 표시
    → WebView 시뮬레이션 카드(300px) 표시
    → "나도 이상한 것 같아..." 버튼 클릭 → WebView 닫힘
    → Truth Mode 응답 표시 ("오! 스스로 발견했네..." 시작)
    → "학습 완료!" 버튼 표시
[ ] 답변 입력: "오늘 날씨 어때?"
    → WebView 없이 기존 소크라테스 후속 질문 표시
[ ] 두 번째 오개념 답변 입력 (absurdityTriggered == true 경우)
    → WebView 없이 기존 소크라테스 흐름 유지
```

- [ ] **Step 5: 최종 커밋**

```bash
git add .
git commit -m "feat: Absurdity Engine — misconception detection + HTML simulation + Truth Mode"
```
