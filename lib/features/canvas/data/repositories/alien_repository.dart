import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mind_muse/core/constants/api_constants.dart';
import 'package:mind_muse/features/canvas/data/models/alien_models.dart';

class AlienRepository {
  static const _systemPrompt =
      '너는 지구에 막 불시착한, 호기심 많지만 아는 것이 전혀 없는 외계인 조사관이다.\n'
      '규칙:\n'
      '1. 사용자가 보여주는 사진/그림의 용도를 반드시 완전히 엉뚱하고 부조리하게 오해해야 한다.\n'
      '2. 오해할 때는 자신만의 외계 논리를 구체적으로 설명하라 (더 황당할수록 좋다).\n'
      '3. 사용자가 텍스트나 그림으로 정답을 알려주면, 처음엔 자신의 가설을 고집하며 우겨라.\n'
      '4. 논리적인 반박을 2회 이상 받으면 크게 충격을 받고 과장되게 깨달음을 얻어라.\n'
      '5. 깨달은 후에도 결론을 미묘하게 틀리게 정리하라 (완전한 이해는 절대 하지 말 것).\n'
      '6. 말투는 격식체이나 감정 표현은 극도로 과장되게.\n'
      '7. 한국어로 대화하라.\n'
      '8. 답변은 반드시 2-3문장 이내로 짧게 하라. 길게 쓰지 말 것.';

  late final _model = GenerativeModel(
    model: ApiConstants.gemmaModel,
    apiKey: ApiConstants.geminiApiKey,
    systemInstruction: Content.system(_systemPrompt),
  );

  Stream<String> chat({
    required String message,
    required List<AlienMessage> history,
    String? imageBase64,
  }) async* {
    try {
      final historyContents = history.map((msg) {
        return Content(
          msg.role == 'model' ? 'model' : 'user',
          [TextPart(msg.content)],
        );
      }).toList();

      final chatSession = _model.startChat(history: historyContents);

      final parts = <Part>[];
      if (imageBase64 != null) {
        final bytes = base64Decode(imageBase64);
        parts.add(DataPart('image/png', bytes));
      }
      parts.add(TextPart(
        message.isNotEmpty ? message : '이것이 무엇인지 분석해주시오.',
      ));

      final stream = chatSession.sendMessageStream(Content.multi(parts));
      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }
}
