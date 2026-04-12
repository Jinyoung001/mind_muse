import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/misconception_model.dart';

/// 오개념 탐지 Repository.
/// 이미지 + 대화 히스토리 + 최신 답변을 분석해 학생의 오개념 여부를 탐지한다.
class MisconceptionRepository {
  late final GenerativeModel _model;

  MisconceptionRepository() {
    _model = GenerativeModel(
      model: ApiConstants.gemmaModel,
      apiKey: ApiConstants.geminiApiKey,
      systemInstruction: Content.text(
        'You are a misconception detector for a K-12 education app.\n'
        'Analyze the student\'s input and determine:\n'
        '1. Does it contain a factual misconception?\n'
        '2. If yes, what is the core false assumption?\n'
        '3. What would happen if we took this misconception to its logical extreme?\n\n'
        'Respond ONLY in this JSON format, no markdown, no explanation:\n'
        '{"has_misconception": true or false, '
        '"subject": "physics" | "biology" | "economics" | "math" | "logic" | "other", '
        '"false_assumption": "one sentence describing the wrong belief", '
        '"absurd_extreme": "one sentence describing what happens if we take this to extreme", '
        '"trigger_phrase": "short phrase the AI will say to agree and trigger the simulation"}\n'
        'If has_misconception is false, return: {"has_misconception": false}',
      ),
    );
  }

  /// 이미지 + 대화 히스토리 + 최신 답변을 분석해 오개념 여부를 반환한다.
  /// API 실패 또는 파싱 오류 시 [MisconceptionResult.noMisconception()]를 반환한다.
  Future<MisconceptionResult> detect({
    required Uint8List imageBytes,
    required List<Map<String, String>> history,
    required String latestAnswer,
  }) async {
    try {
      final historyText = history
          .map((h) => 'AI: ${h['question']}\n학생: ${h['answer']}')
          .join('\n\n');

      final prompt = '대화 기록:\n$historyText\n\n최신 학생 답변: $latestAnswer';

      final response = await _model.generateContent([
        Content.multi([
          DataPart('image/png', imageBytes),
          TextPart(prompt),
        ]),
      ]);

      return MisconceptionResult.fromJson(response.text ?? '');
    } catch (_) {
      return MisconceptionResult.noMisconception();
    }
  }
}
