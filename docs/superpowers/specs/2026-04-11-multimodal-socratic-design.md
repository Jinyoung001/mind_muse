# MindMuse — 멀티모달 소크라테스 튜터 설계

날짜: 2026-04-11

## 배경 및 문제

현재 앱의 문제점:
1. OCR이 `TextRecognitionScript.latin`으로 설정되어 한국어 인식 불가 → 쓰레기 텍스트 생성
2. Gemma가 해당 쓰레기 텍스트를 받아 프롬프트를 그대로 echo 출력
3. 소크라테스 질문 1회 생성 후 종료 — 챗GPT/제미나이와 차별성 없음

## 목표

- OCR 레이어 제거, Gemma 4 멀티모달로 이미지 직접 전달
- 소크라테스 대화를 최대 3라운드 이어가기
- 모르면 단계별 힌트(최대 3단계) 제공
- "교과서 위에서 AI 튜터와 1:1 문답" 경험 구현

## 플로우

```
표시(드로잉) → 이미지+드로잉 합성 PNG → Gemma 4 멀티모달
→ 소크라테스 질문 생성
→ 사용자 답변 입력
→ Gemma 평가 + 후속 질문 (최대 3라운드)
  └─ 모르면: "힌트" 버튼 → 힌트 1 → 힌트 2 → 힌트 3
```

## UI 설계

말풍선(SpeechBubbleWidget) → 바텀 대화 패널(ConversationPanel)로 교체

```
┌─────────────────────────────────┐
│  [교과서 이미지 + 빨간 표시선]     │
│                                  │
├─────────────────────────────────┤
│ 🤖 이 성분은 피부에서 어떤         │
│    역할을 할 것 같아요?            │
│                                  │
│ 👤 수분 공급이요?                 │
│                                  │
│ 🤖 맞아요! 그럼 이 농도가 왜      │
│    중요할까요?                    │
│─────────────────────────────────│
│ [답변 입력...      ] [힌트] [전송] │
└─────────────────────────────────┘
```

- 대화 패널은 화면 하단 40% 차지, 드래그로 확장/축소 가능
- 힌트 버튼: 라운드당 최대 3회 탭 가능, 탭할 때마다 힌트 1개씩 추가 노출
- 3라운드 완료 시 "잘 했어요! 오늘 공부한 내용을 정리해볼게요" 후 종료

## 데이터 모델

```dart
class ConversationTurn {
  final String aiQuestion;
  final String? userAnswer;
  final String? aiEvaluation; // 다음 라운드 AI 메시지
  final List<String> hints;   // 미리 생성된 3개 힌트
  final int revealedHints;    // 현재 공개된 힌트 수 (0~3)
}

class GemmaState {
  final Uint8List? compositeImage;   // 합성된 이미지 (재사용)
  final AsyncValue<List<ConversationTurn>> conversation;
  final bool isLoading;
}
```

## API 호출 설계

### 1. 초기 질문 생성 (이미지 포함)
- 입력: 합성 이미지 bytes
- 프롬프트: "학생이 빨간 선으로 표시한 부분을 보고 소크라테스식 질문 1~2문장, 한국어, 답 직접 알려주지 말 것"
- 출력: 질문 문자열

### 2. 힌트 사전 생성 (초기 질문과 동시에)
- 입력: 합성 이미지 bytes + 생성된 질문
- 프롬프트: "이 질문에 대한 힌트를 난이도 순으로 3개 생성, JSON 배열 형식"
- 출력: `["힌트1", "힌트2", "힌트3"]`
- 초기 질문 생성 직후 백그라운드에서 미리 실행 (지연 없이 힌트 표시)

### 3. 답변 평가 + 후속 질문
- 입력: 대화 히스토리 (이전 질문들 + 사용자 답변들) + 합성 이미지
- 프롬프트: "학생의 답변을 평가하고 이어지는 소크라테스식 질문 생성, 마지막 라운드면 격려 + 핵심 정리"
- 출력: 평가 + 후속 질문 문자열

## 파일 변경 목록

### 삭제 (6개)
- `lib/features/canvas/data/repositories/ocr_repository.dart`
- `lib/features/canvas/presentation/providers/ocr_provider.dart`
- `lib/features/canvas/presentation/widgets/ocr_debug_painter.dart`
- `lib/features/canvas/data/models/text_block_model.dart`
- `lib/features/canvas/domain/services/coordinate_transform_service.dart`
- `lib/features/canvas/domain/services/intersection_service.dart`

### 신규 (2개)
- `lib/features/canvas/domain/services/image_composite_service.dart`
  - 원본 이미지 File + DrawnStroke 목록 → Uint8List (PNG bytes)
- `lib/features/canvas/presentation/widgets/conversation_panel.dart`
  - 대화 히스토리 표시 + 답변 입력 + 힌트 버튼

### 수정 (5개)
- `lib/features/canvas/data/repositories/gemma_repository.dart`
  - 멀티모달 API 호출, 힌트 생성, 답변 평가
- `lib/features/canvas/presentation/providers/gemma_provider.dart`
  - 멀티턴 대화 상태 + 힌트 상태 관리
- `lib/features/canvas/presentation/canvas_screen.dart`
  - OCR 배너 제거, ConversationPanel 연결
- `lib/features/canvas/presentation/providers/canvas_provider.dart`
  - 드로잉 상태 유지 (변경 최소)
- `lib/features/canvas/presentation/widgets/interactive_canvas.dart`
  - OCR 블록 렌더링 제거

## 성공 기준

- 교과서 이미지를 표시했을 때 한국어 소크라테스 질문이 정상 생성됨
- 사용자가 답변 입력 후 전송하면 AI가 평가 + 후속 질문 제공
- "힌트" 탭 시 단계별로 힌트 1개씩 노출
- 3라운드 후 대화 종료 + 정리 메시지
- 프롬프트가 응답에 그대로 노출되지 않음
