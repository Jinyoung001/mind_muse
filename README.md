# Alien Inspector (Mind Muse) 👽

**"지구의 모든 것을 엉뚱하게 오해하는 외계인과 함께하는 역방향 튜터링(Reverse Tutoring) AI 앱"**

Alien Inspector는 Google Gemma 모델을 활용하여 학생들의 메타인지와 능동적 학습을 유도하는 혁신적인 에듀테크 애플리케이션입니다. 학생이 교과서 사진 위에 드로잉을 하면, 아무것도 모르는 엉뚱한 외계인이 그 내용을 완전히 잘못 이해하고 부조리한 주장을 펼칩니다. 학생은 이 외계인을 가르치기 위해 스스로 논리를 전개해야 하며, 이 과정에서 진정한 학습이 일어납니다.

---

## 🚀 주요 특징 (Key Features)

- **Drawing-First UI**: 교과서 사진 위에 동그라미나 밑줄을 긋는 것만으로 AI와 상호작용이 시작됩니다.
- **Alien Persona AI**: Gemma 모델로 구축된 "호기심 많고 고집 센 외계인 👽" 페르소나가 사용자의 입력을 엉뚱하게 해석합니다.
- **Reverse Tutoring Loop**: 외계인의 황당한 가설 → 학생의 반박 → 외계인의 과장된 깨달음(하지만 여전히 살짝 틀림)으로 이어지는 학습 루프.
- **Neon Space UI/UX**: 네온 그린과 다크 스페이스 테마, 우주 분위기의 오로라 배경으로 몰입감 있는 탐사 경험을 제공합니다.
- **세로 분할 레이아웃**: 이미지(상단 38%)와 대화 패널(하단 62%)이 공존해 학습 맥락을 유지하며 대화할 수 있습니다.

---

## 🛠 기술 스택 (Tech Stack)

### Flutter (단일 앱, 백엔드 없음)
- **Framework**: Flutter 3.x (Dart)
- **State Management**: Flutter Riverpod
- **AI**: Google Gemma API (`google_generative_ai` SDK) — 앱에서 직접 호출
- **Animation**: Animated Text Kit (타이핑 효과)
- **UI**: Google Fonts (Rajdhani), Aurora Background, Neon Glow Effects

---

## 📂 프로젝트 구조 (Architecture)

```
mind_muse/
├── lib/
│   ├── core/
│   │   ├── constants/      # API 키, 모델명 상수
│   │   └── theme/          # 네온 스페이스 테마
│   └── features/
│       ├── canvas/
│       │   ├── data/
│       │   │   ├── models/     # 드로잉 획, 외계인 메시지 모델
│       │   │   └── repositories/  # AlienRepository (Gemma API 직접 호출)
│       │   ├── domain/
│       │   │   └── services/   # ImageCompositeService (이미지+드로잉 합성)
│       │   └── presentation/
│       │       ├── providers/  # Riverpod 상태 관리
│       │       ├── widgets/    # ConversationPanel, InteractiveCanvas 등
│       │       └── canvas_screen.dart
│       └── home/           # 홈 화면 및 이미지 선택
└── assets/
    └── .env                # API 키
```

---

## 🏃 시작하기 (Getting Started)

### 1. 사전 요구사항
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x 이상)
- [Google AI Studio API Key](https://aistudio.google.com/)

### 2. 설정 및 실행
```bash
cd mind_muse

# 의존성 설치
flutter pub get

# .env 파일 생성 (프로젝트 루트)
echo "GEMINI_API_KEY=your_actual_api_key_here" > .env

# 앱 실행
flutter run

# APK 빌드
flutter build apk --debug
```

---

## 📝 개발 로드맵 (Roadmap)

- [x] **Phase 1**: Gemma API 직접 연동 및 외계인 대화 로직 구현
- [x] **Phase 2**: 드로잉 + 이미지 합성 → AI 전송 기능
- [x] **Phase 3**: 네온 테마 UI, 세로 분할 레이아웃, 타이핑 애니메이션
- [ ] **Phase 4 (계획)**: 더 다양한 외계인 캐릭터 및 태블릿 펜 압력 감지

---

## 📄 라이선스 (License)

이 프로젝트는 **MIT License**를 따릅니다.

---
**Alien Inspector** - Gemma 4 Good Hackathon Project  
Created by Jinyoung
