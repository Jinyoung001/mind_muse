# MIND MUSE — 외계인 조사관 👽

🌐 **언어** · [English](README.md) · [**한국어**](README_ko.md)

---

**Gemma 4 기반 역방향 튜터링 AI 앱**

> "배우는 가장 좋은 방법이 '배우는 것'이 아니라, 완전히 어리둥절한 외계인에게 '가르치는 것'이라면?"

MIND MUSE는 AI 외계인 캐릭터를 통해 **파인만 기법(Feynman Technique)**을 구현한 Flutter 앱입니다. 학생이 교과서 이미지를 업로드하고 관심 영역에 직접 드로잉을 표시하면, 외계인 조사관이 모든 것을 완전히 엉뚱하게 해석합니다. 외계인을 바로잡으려면 학생이 자신의 이해를 직접 말로 표현해야 합니다 — 그 과정에서 진짜 학습이 일어납니다.

**Gemma 4 Good 해커톤** 출품작 · `gemma-4-26b-a4b-it` 구동

---

## 작동 방식

```
📚 교과서 이미지 업로드
        ↓
✏️  핵심 영역에 원/밑줄 드로잉
        ↓
🚀 "탐사 질문하기" 버튼 탭
        ↓
👽 외계인이 모든 것을 엉뚱하게 해석 (Gemma 4 멀티모달 비전)
        ↓
💬 학생이 외계인 오개념 정정 → 멀티턴 대화
        ↓
🧠 인지 부조화가 능동적 회상과 메타인지를 유발
```

---

## 주요 기능

- **멀티모달 AI 비전**: 드로잉 + 이미지 합성본을 Gemma 4에 직접 전송 — 학생이 표시한 내용 그대로를 모델이 인식
- **외계인 페르소나 엔지니어링**: 정교하게 설계된 시스템 프롬프트로 Gemma 4가 일관되게 틀리지만 논리적인 외계인 해석을 생성
- **멀티턴 스트리밍 대화**: 실시간 토큰 스트리밍 + 타자기 애니메이션; 전체 대화 히스토리 유지
- **스마트 응답 정제**: Gemma 4의 체인-오브-소트(CoT) 아티팩트를 제거하는 커스텀 파서로 깔끔한 한국어 대사만 출력
- **재시도 및 오류 복구**: 네트워크 장애 시 3회 자동 재시도 + 사용자 친화적 오류 메시지
- **네온 우주 UI**: 오로라 배경, 네온 그린 글로우 효과, Rajdhani 폰트 — 몰입감 있는 SF 미학

---

## Gemma 4 연동

핵심 AI 연동은 Google Generative AI SDK를 통해 **`gemma-4-26b-a4b-it`**를 사용합니다.

```dart
// lib/core/constants/api_constants.dart
static const String gemmaModel = 'gemma-4-26b-a4b-it';
```

### 멀티모달 API 호출

앱은 교과서 이미지와 드로잉 스트로크를 단일 PNG로 합성한 뒤, 이미지 바이트와 대화 텍스트를 하나의 Content 객체로 Gemma 4에 전송합니다:

```dart
// lib/features/canvas/data/repositories/alien_repository.dart
// main()의 dotenv.load() 완료 후 초기화됨
late final _model = GenerativeModel(
  model: ApiConstants.gemmaModel,        // 'gemma-4-26b-a4b-it'
  apiKey: ApiConstants.geminiApiKey,
  systemInstruction: Content.system(_systemPrompt),
);

// 첫 번째 턴: 합성 이미지 + 사용자 메시지를 함께 전송
allContents.add(Content('user', [
  DataPart('image/png', imageBytes),   // 교과서 사진 + 드로잉 스트로크 합성 PNG
  TextPart(message),
]));

// 실시간 토큰 스트리밍
final stream = _model.generateContentStream(allContents);
```

Gemma 4의 비전 기능 덕분에 외계인은 학생이 표시한 내용에 정확히 반응합니다 — 생물 다이어그램에서 미토콘드리아를 원으로 표시하면 세포벽을 표시할 때와 다른 외계인 오해가 나옵니다.

### 왜 Gemma 4여야 하는가

프로토타이핑 과정에서 동일한 외계인 페르소나 프롬프트를 Gemma 2 2B와 양자화된 Mistral-7B 변형으로도 테스트했습니다. 두 모델 모두 한국어 출력에서 존댓말 문법 오류가 지속적으로 발생했고, 3턴 후에 페르소나가 무너져 일반적인 어시스턴트 응답으로 회귀했습니다. Gemma 4-26B는 테스트한 모든 대화 길이(최대 12턴)에서 일관된 존댓말, 내적으로 일관된 외계 과학 논리, 안정적인 페르소나를 유지했습니다.

Gemma 4가 유일한 선택이 된 세 가지 속성:
- **멀티모달 입력**: Gemma 4는 합성 이미지와 학생 텍스트를 동시에 처리 — 텍스트 전용 모델은 아예 불가능
- **한국어 격식체**: 외계인의 극적인 감정 표현에는 안정적인 존댓말이 필수 — Gemma 4는 소형 모델이 못 하는 것을 일관되게 수행
- **지시 준수**: 5~10턴에 걸쳐 캐릭터를 깨지 않고 유지하려면 26B 모델의 지시 추종 능력이 필요

### 시스템 프롬프트 설계

외계인의 행동은 단일 시스템 프롬프트로 제어됩니다. 핵심 발췌문:

```
너는 수백 개의 외계 문명을 조사해온 베테랑 외계인 조사관이다.
지구는 처음이라, 지구 사물을 처음 볼 때는 자신의 외계 문명 지식으로 해석해 엉뚱한 결론을 낸다.
처음 오해할 때는 반드시 구체적인 외계 문명 사례나 외계 과학 이론에 근거한 그럴듯한 외계 논리를 설명해라.
사용자가 정정해주면: 먼저 사용자의 설명을 정확히 복창하며 이해했음을 확인한 뒤, 즉시 크게 충격받고 과장되게 놀란다.
격식체로 말하되 감정 표현은 극도로 과장한다.
반드시 한국어로, 2-3문장 이내로만 답한다.
절대 금지: 분석 과정, 목록, 체크리스트, 사용자 메시지 인용을 출력하지 마라.
```

이 프롬프트가 강제하는 네 가지 핵심 제약:
1. 외계 과학 이론에 근거한 일관된 외계인 관점 (무작위 엉터리가 아님)
2. 외계인이 반응하기 전에 학생의 정정을 정확히 복창 (모델이 내용을 이해했음을 확인)
3. 엄격한 한국어 출력, 2~3문장 최대
4. 메타 해설 금지 — 순수 캐릭터 대사만

### 응답 정제 파이프라인

Gemma 4의 체인-오브-소트가 최종 답변 전에 추론 아티팩트를 노출하는 경우가 있습니다. 커스텀 `cleanResponse()` 파이프라인이 이를 처리합니다:

```
입력:  "분석 중... (Analyzing circular DNA structure) 이것은 분명히...
        아, 이것은 호모 사피엔스의 통신 안테나로군요! 우리 행성 제타에서도..."

출력: "아, 이것은 호모 사피엔스의 통신 안테나로군요! 우리 행성 제타에서도..."
```

파이프라인 단계:
1. 유니코드 따옴표 → ASCII 정규화
2. 영어 번역 블록 제거 (정규식: `"?\s*\([A-Z][^)]*\)"`)
3. 따옴표로 분리해 CoT 세그먼트와 최종 출력 구분
4. 각 세그먼트 검증: 한국어 문자 비율 > 영어 문자 비율이어야 통과
5. 한국어 문장 종결어미 검증 (`다`, `요`, `까`, `!`, `?`, `.`)
6. 근사 중복 문장 제거 (60% 이상 문자 겹침 임계값)

---

## 아키텍처

```
lib/
├── core/
│   ├── constants/          # gemmaModel, API 키 로더
│   └── theme/              # 네온 우주 디자인 시스템
└── features/
    ├── home/               # 이미지 선택기, 앱 진입점
    └── canvas/
        ├── data/
        │   ├── models/     # AlienMessage, DrawnStroke
        │   └── repositories/
        │       └── alien_repository.dart   ← Gemma 4 API 호출 + cleanResponse()
        ├── domain/
        │   └── services/
        │       └── image_composite_service.dart  ← 이미지 + 스트로크 → PNG
        └── presentation/
            ├── providers/
            │   ├── alien_provider.dart     ← 멀티턴 상태 (Riverpod)
            │   └── canvas_provider.dart    ← 드로잉 스트로크 상태
            └── widgets/
                ├── conversation_panel.dart ← 스트리밍 AI 채팅 UI
                ├── interactive_canvas.dart ← 터치 드로잉 서피스
                └── resizable_split_view.dart  ← 드래그 가능한 캔버스/채팅 분할 레이아웃
```

**백엔드 불필요.** Gemma 4 API가 Flutter 앱에서 직접 호출됩니다 — 서버 비용 없음, 중개 서버로 인한 추가 지연 없음. 이미지는 Gemma 4 API 엔드포인트로 직접 전송되며 이 앱에서 저장하지 않습니다.

---

## 기술 스택

| 레이어 | 기술 |
|--------|------|
| 프레임워크 | Flutter 3.x (Dart) |
| 상태 관리 | Flutter Riverpod (`StateNotifierProvider`) |
| AI 모델 | Gemma 4 — `gemma-4-26b-a4b-it` |
| AI SDK | `google_generative_ai` (직접 API, 백엔드 없음) |
| 애니메이션 | `animated_text_kit` (타자기 효과) |
| UI | `aurora_background`, Google Fonts (Rajdhani), 네온 글로우 |
| 이미지 처리 | `image_picker`, Flutter `dart:ui` Canvas API, `ImageDescriptor` |

---

## 시작하기

### 사전 요구사항
- Flutter SDK 3.x 이상
- [Google AI Studio API 키](https://aistudio.google.com/) (무료 티어 사용 가능)
  > Gemma 4 모델은 Google AI Studio에서 호스팅됩니다. Studio 대시보드의 "Gemini API key"로 표시된 API 키가 Gemma 모델 접근에 사용됩니다.
- Android 기기 또는 에뮬레이터 (Android 6.0+)

### 설정

```bash
# 1. 리포지토리 클론
git clone https://github.com/Jinyoung001/mind_muse.git
cd mind_muse

# 2. 의존성 설치
flutter pub get

# 3. API 키로 .env 파일 생성
#    파일 위치: assets/.env
echo "GEMINI_API_KEY=your_api_key_here" > assets/.env

# 4. 앱 실행
flutter run

# 5. APK 빌드 (디버그)
flutter build apk --debug
```

> **릴리즈 빌드 주의사항**: 프로젝트 경로에 비-ASCII 문자(`개인프로젝트`)가 포함되어 있습니다. `gen_snapshot` AOT 컴파일러가 비-ASCII 경로에서 실패합니다. 릴리즈 APK는 ASCII 경로(예: `D:\muse_build`)로 소스를 복사한 후 `flutter build apk --release`를 실행하세요. 데모 목적으로는 디버그 APK로 충분합니다.

---

## 사용자 플로우

1. **홈 화면**: "탐사 시작" 버튼 탭
2. **이미지 선택**: 갤러리 또는 카메라에서 교과서 사진 선택
3. **캔버스 화면**: 이미지가 나타나면 관심 영역에 원이나 밑줄 드로잉
4. **외계인에게 묻기**: "탐사 질문하기" FAB 탭 — Gemma 4가 합성 이미지를 수신
5. **외계인 응답**: 외계 과학 논리로 드로잉을 엉뚱하게 해석 (스트리밍 타자기 애니메이션)
6. **학생 정정**: 정정 내용 입력 — 멀티턴 대화 계속
7. **파인만 루프**: 개념이 완전히 표현될 때까지 정정 반복

---

## 역방향 튜터링이 효과적인 이유

전통적 튜터링: 전문가 → 학생. 학생은 수동적 수신자입니다.

역방향 튜터링(파인만 기법): 학생이 "혼란스러운 학습자"에게 *설명*해야 합니다. 설명을 구성하는 행위는:
- 인출 연습을 강제 (능동적 회상)
- 이해의 공백을 표면화 (메타인지)
- 감정적 참여를 유발 (자신만만하게 틀린 외계인을 정정하는 것은 놀랍도록 동기부여가 됨)

**설계 인사이트 — 버그를 기능으로 전환하기**: 모든 대형 언어 모델은 할루시네이션을 일으킵니다 — 자신있고 그럴듯하게 틀린 답을 생성합니다. 대부분의 AI 앱 설계는 이를 억제해야 할 문제로 취급합니다. MIND MUSE는 전제 자체를 뒤집습니다: 외계인 캐릭터는 내적으로 일관된 외계 과학 논리에 근거해 *의도적으로* 자신있게 틀리도록 설계되었습니다. 할루시네이션이 언어 모델의 본질적 특성인 만큼, 이를 교육 엔진으로 삼으면 피할 수 없는 약점이 학습을 이끄는 메커니즘으로 전환됩니다. 자신만만하게 틀린 외계인을 정정하는 학생은 파인만 기법이 요구하는 바를 정확히 실천하고 있는 것입니다 — 그것도 누군가의 지시가 아니라 스스로 원해서.

MIND MUSE는 이 교육학적 루프를 자동화하고 접근 가능하게 만듭니다 — Android 폰과 교과서가 있는 학생이라면 튜터나 스터디 파트너 없이도 몇 분 만에 파인만 기법을 연습할 수 있습니다.

---

## 라이선스

MIT License — 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.

---

**MIND MUSE** · Gemma 4 Good 해커톤 · Jinyoung 제작

*모든 교과서가 대화가 됩니다. 혼란스러운 외계인 한 명이 곧 학습 기회입니다.*
