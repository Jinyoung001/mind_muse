import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/constants/api_constants.dart';

/// Gemma 4 멀티모달 API를 호출하는 Repository.
/// 이미지 bytes를 직접 전달하여 OCR 없이 소크라테스 대화를 진행한다.
class GemmaRepository {
  late final GenerativeModel _model;

  GemmaRepository() {
    _model = GenerativeModel(
      model: ApiConstants.gemmaModel,
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  /// 합성 이미지를 보내 첫 번째 소크라테스 질문을 생성한다.
  Future<String> askInitialQuestion(Uint8List imageBytes) async {
    const prompt = '''학생이 교과서 이미지에서 빨간 선으로 표시한 부분을 보고,
그 내용에 대해 스스로 생각하도록 유도하는 소크라테스식 질문을 한국어로 1~2문장으로 만들어주세요.
답을 직접 알려주지 말고, 학생의 호기심을 자극해주세요.
질문 문장만 출력하고 다른 설명은 절대 출력하지 마세요.''';

    final response = await _model.generateContent([
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(prompt),
      ]),
    ]);
    return response.text?.trim() ?? '이 부분에 대해 어떻게 생각하나요?';
  }

  /// 첫 질문 직후 백그라운드에서 힌트 3개를 미리 생성한다.
  /// 반환 형식: List<String> 길이 3
  Future<List<String>> generateHints(
    Uint8List imageBytes,
    String question,
  ) async {
    final prompt = '''다음 질문에 대한 힌트를 3개 만들어주세요.
질문: "$question"

규칙:
- 힌트는 1→2→3으로 갈수록 더 구체적으로
- 답을 직접 알려주지 말 것
- 한국어로 작성
- 반드시 다음 형식으로만 출력 (다른 텍스트 없이):
힌트1내용|||힌트2내용|||힌트3내용''';

    final response = await _model.generateContent([
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(prompt),
      ]),
    ]);

    final text = response.text?.trim() ?? '';
    final parts = text.split('|||');
    if (parts.length >= 3) {
      return parts.take(3).map((s) => s.trim()).toList();
    }
    return [
      '표시한 부분의 핵심 단어에 집중해보세요.',
      '이 정보가 어떤 상황에서 쓰일지 상상해보세요.',
      '수치나 단위가 있다면 그것이 의미하는 바를 생각해보세요.',
    ];
  }

  /// 학생 답변을 평가하고 후속 질문(또는 마지막 라운드 정리)을 생성한다.
  ///
  /// [history]: [{question: ..., answer: ...}] 형태의 대화 히스토리
  /// [isLastRound]: true이면 격려 + 핵심 정리, false이면 후속 소크라테스 질문
  Future<String> evaluateAndContinue({
    required Uint8List imageBytes,
    required List<Map<String, String>> history,
    required bool isLastRound,
  }) async {
    final historyText = history
        .map((h) => 'AI: ${h['question']}\n학생: ${h['answer']}')
        .join('\n\n');

    final prompt = isLastRound
        ? '''다음은 교과서 내용에 대한 소크라테스 대화입니다:

$historyText

학생의 마지막 답변을 격려하고, 오늘 학습한 핵심을 2~3문장으로 정리해주세요.
한국어로만 출력하세요. 다른 설명은 출력하지 마세요.'''
        : '''다음은 교과서 내용에 대한 소크라테스 대화입니다:

$historyText

학생의 마지막 답변을 한 문장으로 간단히 평가하고,
더 깊이 생각하도록 유도하는 후속 소크라테스 질문을 1~2문장으로 이어 작성해주세요.
한국어로만 출력하세요. 다른 설명은 출력하지 마세요.''';

    final response = await _model.generateContent([
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(prompt),
      ]),
    ]);
    return response.text?.trim() ?? '좋은 생각이에요! 조금 더 생각해볼까요?';
  }
}
