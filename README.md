# MindMuse

**채팅창 없는 소크라테스식 AI 튜터** — Google Gemma 4 해커톤 출품작

태블릿으로 공부하는 학생이 교과서 사진 위에 펜으로 동그라미나 밑줄을 그으면, AI가 해당 텍스트를 인식하여 말풍선으로 소크라테스식 질문을 던집니다.

---

## 주요 기능

- **Zero-Chat UI** — 채팅창 없이 드로잉 제스처만으로 AI와 상호작용
- **OCR 텍스트 인식** — ML Kit으로 교과서 텍스트와 위치를 자동 추출
- **소크라테스식 질문** — Gemma 4가 답을 알려주는 대신 스스로 생각하도록 유도
- **말풍선 팝업** — 드로잉한 위치 근처에 AI 질문이 애니메이션과 함께 표시

## 기술 스택

| 항목 | 기술 |
|------|------|
| 플랫폼 | Android (Flutter) |
| 상태 관리 | flutter_riverpod |
| OCR | google_mlkit_text_recognition |
| LLM | gemma-4-26b-a4b-it (Google AI Studio) |
| LLM SDK | google_generative_ai (Dart) |
| 이미지 입력 | image_picker |

## 사용 방법

1. 앱 실행 후 **시작하기** 버튼 탭
2. 카메라로 교과서 촬영 또는 갤러리에서 사진 선택
3. 교과서 텍스트 위에 손가락/펜으로 동그라미나 밑줄 그리기
4. AI가 해당 내용에 대한 질문을 말풍선으로 표시
5. 말풍선을 탭하면 닫힘

## 설치 및 실행

### 요구사항
- Flutter 3.x 이상
- Android 에뮬레이터 또는 실제 Android 기기
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

## 아키텍처

```
lib/
├── core/
│   ├── constants/       # API 키, 모델명 상수
│   └── theme/           # 앱 테마
└── features/
    ├── home/            # 홈 화면, 이미지 선택
    └── canvas/
        ├── data/        # 모델, Repository (OCR, Gemma)
        ├── domain/      # 서비스 (좌표 변환, 충돌 계산)
        └── presentation/ # 화면, Provider, 위젯
```

**핵심 로직:**
- `CoordinateTransformService` — ML Kit 이미지 좌표 → 화면 dp 좌표 변환 (BoxFit.contain 보정 포함)
- `IntersectionService` — 드로잉 BBox와 OCR BBox 교차 계산으로 선택 텍스트 추출

## 라이선스

MIT
