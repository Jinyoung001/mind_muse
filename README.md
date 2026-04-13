# Alien Inspector (Mind Muse Evolution) 👽

**"지구의 모든 것을 엉뚱하게 오해하는 외계인과 함께하는 역방향 튜터링(Reverse Tutoring) AI 앱"**

Alien Inspector는 Google Gemma 모델을 활용하여 학생들의 메타인지와 능동적 학습을 유도하는 혁신적인 에듀테크 애플리케이션입니다. 학생이 교과서 사진 위에 드로잉을 하면, 아무것도 모르는 엉뚱한 외계인이 그 내용을 완전히 잘못 이해하고 부조리한 주장을 펼칩니다. 학생은 이 외계인을 가르치기 위해 스스로 논리를 전개해야 하며, 이 과정에서 진정한 학습이 일어납니다.

---

## 🚀 주요 특징 (Key Features)

- **Zero-Chat Drawing UI**: 채팅창 없이 교과서 사진 위 텍스트에 동그라미나 밑줄을 긋는 것만으로 AI와 상호작용이 시작됩니다.
- **Alien Persona AI**: Gemma 모델을 통해 구축된 "호기심 많고 고집 센 외계인" 페르소나가 사용자의 입력을 엉뚱하게 해석합니다.
- **Reverse Tutoring Loop**: 외계인의 황당한 가설 → 학생의 반박 → 외계인의 과장된 깨달음(하지만 여전히 살짝 틀림)으로 이어지는 학습 루프.
- **Neon Space UI/UX**: 네온 그린과 다크 스페이스 테마, Rive 기반의 외계인 애니메이션, 타이핑 효과를 통해 몰입감 있는 우주 탐사 경험을 제공합니다.
- **Workbench View**: 캔버스와 대화 패널이 공존하는 분할 레이아웃으로 학습 맥락을 유지하며 대화할 수 있습니다.

---

## 🛠 기술 스택 (Tech Stack)

### Frontend (Flutter)
- **Framework**: Flutter 3.x (Dart)
- **State Management**: Flutter Riverpod
- **Animation**: Rive (캐릭터), Animated Text Kit (타이핑 효과)
- **UI Component**: Google Fonts (Rajdhani), Aurora Background, Neon Glow Effects
- **Communication**: Dio (FastAPI 백엔드와 REST/Streaming 통신)

### Backend (FastAPI)
- **Framework**: FastAPI (Python 3.10+)
- **AI Model**: Google Gemma (via Google AI Studio SDK)
- **Inference**: Gemma-27b-it 기반 시스템 프롬프트 엔지니어링
- **Streaming**: Server-Sent Events (SSE) 스타일의 실시간 토큰 스트리밍

---

## 📂 프로젝트 구조 (Architecture)

```
.
├── mind_muse/              # Flutter 프론트엔드 앱
│   ├── lib/
│   │   ├── core/           # 테마, 상수, 공용 위젯
│   │   ├── features/
│   │   │   ├── canvas/     # 캔버스 드로잉 및 외계인 대화 (핵심 기능)
│   │   │   └── home/       # 홈 화면 및 이미지 선택
│   │   └── main.dart
│   └── assets/             # Rive 애니메이션, 폰트 등 에셋
│
├── mindmuse_backend/       # FastAPI 백엔드 서버
│   ├── app/
│   │   ├── api/            # API 엔드포인트 (alien_routes.py)
│   │   ├── core/           # 설정 및 환경 변수
│   │   └── services/       # Gemma 연동 및 외계인 로직 (alien_service.py)
│   └── main.py             # 서버 진입점
│
└── .planning/              # GSD(Get Shit Done) 워크플로우 기획 및 관리 문서
```

---

## 🏃 시작하기 (Getting Started)

### 1. 사전 요구사항
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x 이상)
- [Python](https://www.python.org/) (3.10 이상)
- [Google AI Studio API Key](https://aistudio.google.com/)

### 2. 백엔드 설정 및 실행
```bash
cd mindmuse_backend
# 가상환경 생성 및 활성화 (선택)
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# .env 설정
echo "GEMMA_API_KEY=your_actual_api_key_here" > .env

# 서버 실행
python main.py
```

### 3. 프론트엔드 설정 및 실행
```bash
cd mind_muse
# 의존성 설치
flutter pub get

# .env 설정 (백엔드 URL 확인)
echo "API_BASE_URL=http://localhost:8000" > .env

# 앱 실행
flutter run
```

---

## 📝 개발 로드맵 (Roadmap)

- [x] **Phase 1: Backend Integration**: Gemma 기반 외계인 서비스 통합 및 API 구축.
- [x] **Phase 2: Frontend API Migration**: 로컬 SDK 의존성 제거 및 REST API 통신 전환.
- [x] **Phase 3: UI/UX Refinement**: 네온 테마 적용, Rive 애니메이션 연동, 워크벤치 레이아웃 고도화.
- [ ] **Phase 4 (Planned)**: 더 다양한 외계인 캐릭터 추가 및 태블릿 펜 압력 감지 고도화.

---

## 📄 라이선스 (License)

이 프로젝트는 **MIT License**를 따릅니다.

---
**Alien Inspector** - Gemma 4 Good Hackathon Project
Created by Jinyoung
