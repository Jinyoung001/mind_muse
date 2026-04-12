# Absurdity Engine 설계 문서

**날짜**: 2026-04-12  
**프로젝트**: MindMuse — Android 태블릿 학습 앱  
**기능**: 오개념 탐지 + 부조리 시뮬레이션 엔진

---

## 1. 개요

학생이 소크라테스 대화 중 오개념을 담은 답변을 제출하면, AI가 그 논리를 극단까지 밀어붙인 인터랙티브 HTML 시뮬레이션을 생성해 보여준다. 학생이 스스로 모순을 발견하고 "이상한 것 같아..." 버튼을 누르면 Truth Mode로 전환되어 올바른 개념을 설명한다.

**교육 철학**: 반박이 아닌 인지 부조화 — 학생이 직접 모순을 발견하게 유도.

---

## 2. 아키텍처 개요

### 새 파일

```
lib/features/canvas/
├── data/
│   ├── models/
│   │   └── misconception_model.dart         # Gemini JSON 응답 파싱 모델
│   └── repositories/
│       ├── misconception_repository.dart    # 오개념 탐지 API 호출
│       └── absurdity_repository.dart        # HTML 시뮬레이션 생성 API 호출
└── presentation/
    └── widgets/
        └── absurdity_webview_bubble.dart    # InAppWebView 카드 위젯
```

### 수정 파일

| 파일 | 변경 내용 |
|---|---|
| `gemma_provider.dart` | GemmaState 필드 추가, submitAnswer() 분기 로직, onStudentDoubt() 추가 |
| `conversation_panel.dart` | WebView 버블 인라인 삽입 |
| `pubspec.yaml` | flutter_inappwebview 의존성 추가 |

---

## 3. 데이터 레이어

### 3-1. MisconceptionModel (`misconception_model.dart`)

```dart
class MisconceptionResult {
  final bool hasMisconception;
  final String subject;          // "physics" | "biology" | "economics" | "math" | "logic" | "other"
  final String falseAssumption;  // 오개념 한 문장
  final String absurdExtreme;    // 극단 시나리오 한 문장
  final String triggerPhrase;    // AI가 동의하며 시뮬레이션 예고하는 짧은 문구
}
```

`hasMisconception == false`인 경우 나머지 필드는 빈 문자열로 처리한다.

### 3-2. MisconceptionRepository (`misconception_repository.dart`)

**메서드**: `Future<MisconceptionResult> detect(Uint8List imageBytes, List<Map<String,String>> history, String latestAnswer)`

- 이미지 + 대화 히스토리 + 최신 학생 답변을 Gemini API에 전달
- system prompt로 JSON 응답 강제 (아래 프롬프트 참조)
- JSON 파싱 실패 또는 API 에러 → `MisconceptionResult(hasMisconception: false)` 반환 (기존 흐름 보호)

**오개념 탐지 system prompt**:
```
You are a misconception detector for a K-12 education app.
Analyze the student's input and determine:
1. Does it contain a factual misconception?
2. If yes, what is the core false assumption?
3. What would happen if we took this misconception to its logical extreme?

Respond ONLY in this JSON format, no markdown, no explanation:
{
  "has_misconception": true or false,
  "subject": "physics" | "biology" | "economics" | "math" | "logic" | "other",
  "false_assumption": "one sentence describing the wrong belief",
  "absurd_extreme": "one sentence describing what happens if we take this to extreme",
  "trigger_phrase": "short phrase the AI will say to agree and trigger the simulation"
}
If has_misconception is false, return: {"has_misconception": false}
```

### 3-3. AbsurdityRepository (`absurdity_repository.dart`)

**메서드**: `Future<String> generateHtml(String falseAssumption, String absurdExtreme, String subject)`

- 이미지 없이 텍스트 프롬프트만 사용 (비용 절감)
- 반환값: 완전한 standalone HTML 문자열
- 실패 시: fallback HTML 반환 (어두운 배경 + "부조리한 세계를 만들지 못했어요" 안내 + "이상한 것 같아..." 버튼)

**HTML 생성 system prompt**:
```
You are an interactive simulation generator for an educational app.
You will receive a student's misconception. Your job is to create a short,
interactive HTML+CSS+JS widget that visually demonstrates what the world
would look like if the misconception were taken to its absurd logical extreme.

Rules:
- Output ONLY raw HTML. No markdown, no backticks, no explanation.
- The HTML must be fully self-contained (inline CSS and JS only, no external libraries).
- Canvas or simple DOM animations are preferred over complex frameworks.
- The simulation must be obviously wrong and slightly funny.
- Include a "나도 이상한 것 같아..." button.
  When clicked, it should call: window.flutter_inappwebview.callHandler('studentDoubt')
- Keep it simple enough to load instantly on mobile.
- Max 150 lines of HTML.
- Background color: #1a1a2e (dark), text color: #eee.
- Korean UI text only.
```

---

## 4. 상태 관리

### 4-1. GemmaState 추가 필드

```dart
final String? absurdityHtml;         // null이면 WebView 비활성. HTML 문자열이면 카드 표시.
final bool isGeneratingAbsurdity;    // true이면 "부조리한 세계를 만드는 중..." 스피너 표시
final bool absurdityTriggered;       // true이면 같은 세션에서 Absurdity Engine 재발동 방지
```

### 4-2. submitAnswer() 분기 흐름

```
submitAnswer(answer) 호출
  │
  ├─ absurdityTriggered == true?
  │     → 탐지 스킵, evaluateAndContinue() 바로 실행 (기존 로직)
  │
  └─ absurdityTriggered == false
        → MisconceptionRepository.detect() 실행
              │
              ├─ hasMisconception: false
              │     → evaluateAndContinue() 실행 (기존 로직)
              │
              └─ hasMisconception: true
                    → 새 ConversationTurn(aiQuestion: triggerPhrase)을 turns에 추가
                      (기존 evaluateAndContinue가 새 턴을 추가하는 것과 동일한 패턴)
                    → absurdityTriggered: true 설정 (재발동 방지)
                    → isGeneratingAbsurdity: true 설정
                    → AbsurdityRepository.generateHtml() 실행
                    → absurdityHtml 저장, isGeneratingAbsurdity: false
```

### 4-3. onStudentDoubt() 흐름

WebView 내 "이상한 것 같아..." 버튼 클릭 시 호출:

```
absurdityHtml: null 로 초기화 (WebView 닫기)
isLoading: true
Truth Mode 프롬프트로 Gemini API 호출
  → 응답을 새 ConversationTurn으로 추가
  → isFinished: true (소크라테스 대화 완전 종료)
```

**Truth Mode 프롬프트**:
```
The student has just realized their misconception on their own.
Now switch to honest tutoring mode. Start with:
"오! 스스로 발견했네. 사실은 이렇게 작동해:"
Then explain the correct concept clearly and warmly. Korean only.
```

---

## 5. UI 레이어

### 5-1. AbsurdityWebviewBubble (`absurdity_webview_bubble.dart`)

- `InAppWebView`로 HTML 렌더링, 높이 300px 고정
- `addJavaScriptHandler('studentDoubt', callback)` 등록
  - 콜백 실행 시 `ref.read(gemmaProvider.notifier).onStudentDoubt()` 호출
- 카드 스타일: 둥근 모서리, 그림자, 마진

### 5-2. ConversationPanel 수정

ListView itemBuilder에서 각 턴 렌더링 순서:

```
1. AI 질문 버블 (_AiMessage)
2. 공개된 힌트 버블들 (_HintMessage)
3. 학생 답변 버블 (_UserMessage)
4. [마지막 턴이고 isGeneratingAbsurdity == true] → 로딩 카드
5. [마지막 턴이고 absurdityHtml != null] → AbsurdityWebviewBubble
```

로딩 카드 텍스트: "부조리한 세계를 만드는 중..." + CircularProgressIndicator

---

## 6. 에러 처리

| 실패 지점 | 처리 방식 |
|---|---|
| 오개념 탐지 API 실패 | `hasMisconception: false` 반환 → 기존 소크라테스 흐름 유지 |
| JSON 파싱 실패 | 동일하게 `hasMisconception: false` 처리 |
| HTML 생성 API 실패 | fallback HTML 반환 ("이상한 것 같아..." 버튼 포함) |
| WebView 렌더링 오류 | onWebViewError 콜백으로 에러 카드 표시 |
| onStudentDoubt API 실패 | 에러 메시지 노출 후 `isFinished: true` 강제 설정 |

---

## 7. 의존성 추가

```yaml
dependencies:
  flutter_inappwebview: ^6.1.5
```

---

## 8. 데모 시나리오

| 학생 입력 | 탐지 결과 | 시뮬레이션 내용 |
|---|---|---|
| "유튜브를 많이 볼수록 공부를 더 잘하게 되는 것 같아" | 상관관계/인과관계 오개념 | 유튜브 시청 시간 폭증 → 성적 폭등 기괴한 그래프 |
| "포식자가 없으면 동물들이 평화롭게 살 수 있잖아" | 생태계 균형 오개념 | 사슴 개체수 폭증 애니메이션 |
| "오늘 날씨 어때?" | 오개념 없음 | 기존 소크라테스 흐름 유지 |
