# MIND MUSE — Alien Inspector 👽

🌐 **Language** · [**English**](README.md) · [한국어](README_ko.md)

---

**Reverse Tutoring AI App powered by Gemma 4**

> "What if the best way to learn isn't being taught — but teaching a hopelessly confused alien?"

MIND MUSE applies the **Feynman Technique** through an AI-driven alien character. Students upload any image — a textbook page, a diagram, a product label, a photo of anything around them — mark areas of interest by drawing on it, and then watch as an alien investigator misinterprets everything completely wrong. To correct the alien, students must articulate their own understanding — and that's where real learning happens.

Built for the **Gemma 4 Good Hackathon** · Powered by `gemma-4-26b-a4b-it`

---

## How It Works

```
📚 Upload any image (textbook, diagram, real-world photo — anything)
        ↓
✏️  Draw circles / underlines on key areas
        ↓
🚀 Tap "탐사 질문하기" (Ask Alien)
        ↓
👽 Alien misinterprets everything (multimodal Gemma 4 vision)
        ↓
💬 Student corrects the alien → multi-turn conversation
        ↓
🧠 Cognitive dissonance forces active recall & metacognition
```

---

## Key Features

- **Multimodal AI Vision**: Drawing + image composite sent directly to Gemma 4 — the model sees exactly what the student marked
- **Alien Persona Engineering**: Carefully crafted system prompt makes Gemma 4 generate consistently wrong-but-logical alien interpretations
- **Multi-turn Streaming Conversation**: Real-time token streaming with typewriter animation; full conversation history maintained
- **Smart Response Cleaning**: Custom parser strips Gemma 4's chain-of-thought artifacts, keeping only clean Korean dialogue
- **Retry & Error Recovery**: Automatic 3-attempt retry on network failures with user-friendly error messages
- **Neon Space UI**: Aurora background, neon-green glow effects, Rajdhani font — immersive sci-fi aesthetic

---

## Gemma 4 Integration

The core AI integration uses **`gemma-4-26b-a4b-it`** via the Google Generative AI SDK.

```dart
// lib/core/constants/api_constants.dart
static const String gemmaModel = 'gemma-4-26b-a4b-it';
```

### Multimodal API Call

The app composites the textbook image and drawing strokes into a single PNG, then sends both the image bytes and the conversation text to Gemma 4 in a single content object:

```dart
// lib/features/canvas/data/repositories/alien_repository.dart
// initialized after dotenv.load() completes in main()
late final _model = GenerativeModel(
  model: ApiConstants.gemmaModel,        // 'gemma-4-26b-a4b-it'
  apiKey: ApiConstants.geminiApiKey,
  systemInstruction: Content.system(_systemPrompt),
);

// First turn: composite image + user message sent together
allContents.add(Content('user', [
  DataPart('image/png', imageBytes),   // textbook photo + drawing strokes as PNG
  TextPart(message),
]));

// Streams tokens in real time
final stream = _model.generateContentStream(allContents);
```

Gemma 4's vision capability means the alien responds to exactly what the student drew — circling the mitochondria on a biology diagram produces a different alien misinterpretation than circling the cell wall.

### System Prompt Design

The alien's behavior is shaped by a single system prompt. A key excerpt (Korean, matching the Korean-language output requirement):

```
너는 수백 개의 외계 문명을 조사해온 베테랑 외계인 조사관이다.
지구는 처음이라, 지구 사물을 처음 볼 때는 자신의 외계 문명 지식으로 해석해 엉뚱한 결론을 낸다.
처음 오해할 때는 반드시 구체적인 외계 문명 사례나 외계 과학 이론에 근거한 그럴듯한 외계 논리를 설명해라.
사용자가 정정해주면: 먼저 사용자의 설명을 정확히 복창하며 이해했음을 확인한 뒤, 즉시 크게 충격받고 과장되게 놀란다.
격식체로 말하되 감정 표현은 극도로 과장한다.
반드시 한국어로, 2-3문장 이내로만 답한다.
절대 금지: 분석 과정, 목록, 체크리스트, 사용자 메시지 인용을 출력하지 마라.
```

The four key constraints this enforces:
1. Consistent alien perspective backed by alien-science theory (not random nonsense)
2. Student's correction is repeated accurately before the alien reacts (confirms the model understood)
3. Strict Korean output, 2–3 sentences maximum
4. No meta-commentary — pure character dialogue only

### Response Cleaning Pipeline

Gemma 4's chain-of-thought occasionally surfaces reasoning artifacts before the final answer — draft sentences, English translations in parentheses, or internal commentary. A custom `cleanResponse()` pipeline handles this:

```
Input:  "분석 중... (Analyzing circular DNA structure) 이것은 분명히...
         아, 이것은 호모 사피엔스의 통신 안테나로군요! 우리 행성 제타에서도..."

Output: "아, 이것은 호모 사피엔스의 통신 안테나로군요! 우리 행성 제타에서도..."
```

The pipeline:
1. Normalizes Unicode quotation marks → ASCII
2. Strips English translation blocks (regex: `"?\s*\([A-Z][^)]*\)"`)
3. Splits on quotes to separate CoT segments from final output
4. Validates each segment: Korean character ratio must exceed English character ratio
5. Validates Korean sentence terminators (`다`, `요`, `까`, `!`, `?`, `.`)
6. Deduplicates near-identical sentences (>60% character overlap threshold — catches Gemma's occasional sentence repetition)

---

## Architecture

```
lib/
├── core/
│   ├── constants/          # gemmaModel, API key loader
│   └── theme/              # Neon space design system
└── features/
    ├── home/               # Image picker, app entry
    └── canvas/
        ├── data/
        │   ├── models/     # AlienMessage, DrawnStroke
        │   └── repositories/
        │       └── alien_repository.dart   ← Gemma 4 API calls + cleanResponse()
        ├── domain/
        │   └── services/
        │       └── image_composite_service.dart  ← image + strokes → PNG
        └── presentation/
            ├── providers/
            │   ├── alien_provider.dart     ← multi-turn state (Riverpod)
            │   └── canvas_provider.dart    ← drawing stroke state
            └── widgets/
                ├── conversation_panel.dart ← streaming AI chat UI
                ├── interactive_canvas.dart ← touch drawing surface
                └── resizable_split_view.dart  ← drag-adjustable canvas/chat split layout
```

**No backend required.** Gemma 4 API is called directly from the Flutter app — zero server costs, zero additional latency from an intermediary server. Images are sent directly to the Gemma 4 API endpoint and are not stored by this application.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State Management | Flutter Riverpod (`StateNotifierProvider`) |
| AI Model | Gemma 4 — `gemma-4-26b-a4b-it` |
| AI SDK | `google_generative_ai` (direct API, no backend) |
| Animation | `animated_text_kit` (typewriter effect) |
| UI | `aurora_background`, Google Fonts (Rajdhani), neon glow |
| Image Processing | `image_picker`, Flutter `dart:ui` Canvas API, `ImageDescriptor` |

---

## Getting Started

### Prerequisites
- Flutter SDK 3.x or later
- [Google AI Studio API Key](https://aistudio.google.com/) (free tier works)
  > Gemma 4 models are hosted on Google AI Studio. The API key labeled "Gemini API key" in the Studio dashboard works for Gemma model access.
- Android device or emulator (Android 6.0+)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/Jinyoung001/mind_muse.git
cd mind_muse

# 2. Install dependencies
flutter pub get

# 3. Create the .env file with your API key
#    File location: assets/.env
echo "GEMINI_API_KEY=your_api_key_here" > assets/.env

# 4. Run the app
flutter run

# 5. Build APK (debug)
flutter build apk --debug
```

> **Note on release builds**: The project path contains non-ASCII characters (`개인프로젝트`). The `gen_snapshot` AOT compiler fails on non-ASCII paths. For release APK, copy source to an ASCII path (e.g., `D:\muse_build`) before running `flutter build apk --release`. Debug APK is sufficient for demo purposes.

---

## User Flow

1. **Home Screen**: Tap "탐사 시작" (Start Exploration)
2. **Image Selection**: Choose any photo from gallery or camera — textbook, diagram, real-world object, anything you want to understand
3. **Canvas Screen**: The image appears; draw circles or underlines on areas of interest
4. **Ask Alien**: Tap the "탐사 질문하기" (Ask Alien) FAB — Gemma 4 receives the composite image
5. **Alien Response**: The alien misinterprets the drawing with alien-science logic (streaming, typewriter animation)
6. **Student Corrects**: Type a correction — multi-turn conversation continues
7. **Feynman Loop**: Keep correcting until the concept is fully articulated

---

## Why Reverse Tutoring Works

Traditional tutoring: expert → student. Students are passive receivers.

Reverse tutoring (Feynman Technique): student must *explain* to a "confused learner." The act of formulating explanations:
- Forces retrieval practice (active recall)
- Surfaces gaps in understanding (metacognition)
- Creates emotional engagement (correcting a confidently wrong alien is surprisingly motivating)

**Design insight — turning a bug into a feature**: Every large language model hallucinates — it produces confident, plausible-sounding wrong answers. Most AI application design treats hallucination as a problem to suppress. MIND MUSE inverts the premise: the alien character is *designed* to hallucinate confidently, grounded in internally consistent alien-science logic. Since hallucination is inherent to LLMs, making it the pedagogical engine turns an unavoidable weakness into the mechanism that drives learning. A student correcting a confidently wrong alien is doing exactly what the Feynman Technique requires — and doing it because they *want* to, not because they were told to.

**Any subject. Any model size.** Because the learning mechanism lives entirely in the student's mind — not the AI's — this works for any subject the student can photograph. A biology diagram, a chemistry equation, a history map, a product label, or a photo of anything in the physical world: if you can draw a circle around it, the alien can misinterpret it. The same logic applies to model size: the AI doesn't need to be brilliant to facilitate learning — it needs to be consistently, engagingly *wrong*. The cognitive work comes from the student's expectation of teaching and the act of explanation itself. The AI is just the confused listener.

Educational research supports this: the *Protégé Effect* — the measurable learning boost that comes from expecting to teach someone else — shows that framing a task as teaching activates deeper processing, stronger memory encoding, and better long-term retention than passive study. Nestojko et al. (2014) identified a critical nuance: the effect is strongest when students **expect to teach *before* they study** — if the teaching expectation is assigned only *after* studying, the gains largely disappear. MIND MUSE builds this expectation into the design from the first tap: the moment a student draws on an image, they already know the alien will misinterpret it and they will need to explain. The teaching mindset activates before a single message is sent.

These effects are independent of listener capability — *Betty's Brain* studies show equivalent gains when students teach a virtual AI agent, confirming the mechanism lives in the student, not the listener. Independent research on AI-based Feynman bots (arXiv, 2025) found students using teach-the-AI approaches outperformed passive study groups on both learning outcomes and self-assessed confidence.

MIND MUSE makes this pedagogical loop automatic and accessible — any student with a smartphone can practice the Feynman Technique in minutes, on any subject, with no tutor or study partner required.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

**MIND MUSE** · Gemma 4 Good Hackathon · Created by Jinyoung

*Every textbook becomes a conversation. Every confused alien is a learning opportunity.*
