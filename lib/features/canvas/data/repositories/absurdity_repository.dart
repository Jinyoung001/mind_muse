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
        '- REQUIRED: Include at least one animated element using CSS animation or canvas. The simulation must visually move, change, or react.\n'
        '- Use CSS keyframe animations or requestAnimationFrame for dynamic effects.\n'
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
    if (blockMatch != null) {
      final group = blockMatch.group(1);
      if (group != null) return group.trim();
    }

    // <!DOCTYPE 시작 지점 추출
    final doctypeIdx = raw.indexOf('<!DOCTYPE');
    if (doctypeIdx != -1) return raw.substring(doctypeIdx).trim();

    // <html 시작 지점 추출
    final htmlIdx = raw.indexOf('<html');
    if (htmlIdx != -1) return raw.substring(htmlIdx).trim();

    return raw.trim();
  }
}
