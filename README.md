# MindMuse

**채팅창 없는 소크라테스식 AI 튜터** — Google Gemma 4 해커톤 출품작

태블릿으로 공부하는 학생이 교과서 사진 위에 펜으로 동그라미나 밑줄을 그으면, AI가 해당 부분을 직접 인식해 소크라테스식 질문을 던집니다. 학생이 오개념을 담은 답변을 제출하면 **Absurdity Engine**이 발동하여, 그 논리를 극단까지 밀어붙인 인터랙티브 시뮬레이션을 생성합니다. 학생이 스스로 모순을 발견하는 순간 올바른 개념을 따뜻하게 설명해줍니다.

---

## 주요 기능

### 핵심 학습 루프

- **Zero-Chat UI** — 채팅창 없이 드로잉 제스처만으로 AI와 상호작용
- **멀티모달 이미지 분석** — OCR 없이 이미지 전체를 Gemini에 직접 전달, 필기·도형·다이어그램까지 인식
- **소크라테스식 3라운드 대화** — AI가 정답을 알려주는 대신 스스로 생각하도록 유도
- **힌트 시스템** — 단계별로 구체화되는 힌트 3개를 백그라운드에서 미리 생성

### Absurdity Engine (오개념 탐지 엔진)

- **오개념 자동 탐지** — 학생 답변을 Gemini가 실시간 분석, 사실 오류 여부 판별
- **부조리 시뮬레이션** — 오개념 논리를 극단까지 밀어붙인 인터랙티브 HTML 애니메이션을 채팅창 안에 인라인으로 표시
- **인지 부조화 유도** — 반박 대신 학생이 직접 "이상한 것 같아..." 버튼을 누르게 만들어 스스로 모순을 발견하게 함
- **Truth Mode** — 학생이 의심을 표명하는 순간 올바른 개념을 따뜻하게 설명하며 대화 종료

### 편의 기능

- **되돌리기(Undo)** — 마지막 드로잉 획 취소
- **드로잉 없이 AI 질문** — 이미지 전체 기반으로 AI 소크라테스 질문 시작

---

## 기술 스택

| 항목 | 기술 |
|------|------|
| 플랫폼 | Android (Flutter) |
| 상태 관리 | flutter_riverpod |
| LLM | gemma-4-27b-it (Google AI Studio) |
| LLM SDK | google_generative_ai (Dart) |
| WebView | flutter_inappwebview |
| 이미지 입력 | image_picker |

---

## 동작 흐름

```
학생이 교과서 사진 위에 드로잉
        ↓
Gemini가 이미지+드로잉을 보고 소크라테스 질문 생성
        ↓
학생이 답변 제출
        ↓
   [오개념 없음]              [오개념 감지]
        ↓                          ↓
  후속 소크라테스 질문       "맞아! 내가 시뮬레이션 만들어줄게!"
  (최대 3라운드)                   ↓
        ↓              인터랙티브 HTML 부조리 시뮬레이션 표시
  격려 메시지 + 종료               ↓
                      학생: "나도 이상한 것 같아..." 버튼 클릭
                                   ↓
                         Truth Mode: 올바른 개념 설명 + 종료
```

---

## 아키텍처

```
lib/
├── core/
│   ├── constants/           # API 키, 모델명 상수
│   └── theme/               # 앱 테마
└── features/
    ├── home/                # 홈 화면, 이미지 선택
    └── canvas/
        ├── data/
        │   ├── models/
        │   │   └── misconception_model.dart     # 오개념 탐지 JSON 파싱 모델
        │   └── repositories/
        │       ├── gemma_repository.dart         # 소크라테스 질문·힌트·Truth Mode API
        │       ├── misconception_repository.dart # 오개념 탐지 API
        │       └── absurdity_repository.dart     # HTML 시뮬레이션 생성 API
        ├── domain/
        │   └── services/
        │       └── image_composite_service.dart  # 이미지+드로잉 합성
        └── presentation/
            ├── providers/
            │   ├── canvas_provider.dart          # 드로잉 상태
            │   └── gemma_provider.dart           # 대화·Absurdity Engine 상태
            └── widgets/
                ├── interactive_canvas.dart        # 드로잉 캔버스
                ├── conversation_panel.dart        # 소크라테스 대화 패널
                └── absurdity_webview_bubble.dart  # 부조리 시뮬레이션 WebView 카드
```

---

## 설치 및 실행

### 요구사항

- Flutter 3.x 이상
- Android 에뮬레이터 또는 실제 Android 기기 (API 21+)
- Google AI Studio API 키

### 설정

```bash
git clone https://github.com/Jinyoung001/mind_muse.git
cd mind_muse
```

프로젝트 루트에 `.env` 파일 생성:

```
GEMINI_API_KEY=여기에_실제_API_키_입력
```

> API 키는 [Google AI Studio](https://aistudio.google.com)에서 발급받을 수 있습니다.

### 실행

```bash
flutter pub get
flutter run
```

---

## 사용 방법

1. 앱 실행 후 **시작하기** 버튼 탭
2. 카메라로 교과서 촬영 또는 갤러리에서 사진 선택
3. 교과서 텍스트 위에 손가락/펜으로 동그라미나 밑줄 그리기
4. 대화 패널에서 AI 소크라테스 질문 확인
5. 답변 입력 — 오개념이 감지되면 부조리 시뮬레이션 카드가 나타남
6. "나도 이상한 것 같아..." 버튼을 누르면 올바른 개념 설명으로 전환

> **드로잉 없이 질문하기**: 상단 뇌 아이콘(🧠) 버튼 탭 — 이미지 전체 기반으로 AI가 질문을 시작합니다.

---

## 라이선스

MIT
