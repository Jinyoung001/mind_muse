import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/constants/api_constants.dart';

/// Gemma 4 API를 호출하여 소크라테스식 질문을 생성하는 Repository.
class GemmaRepository {
  late final GenerativeModel _model;

  GemmaRepository() {
    _model = GenerativeModel(
      model: ApiConstants.gemmaModel,
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  /// 선택된 텍스트를 바탕으로 소크라테스식 질문을 생성한다.
  /// [selectedTexts]: IntersectionService가 추출한 텍스트 목록
  /// 반환값: AI가 생성한 질문 문자열
  Future<String> askSocraticQuestion(List<String> selectedTexts) async {
    final combinedText = selectedTexts.join(' ');

    final prompt = '''
당신은 학생의 이해를 돕는 소크라테스식 튜터입니다.
학생이 교과서에서 다음 텍스트에 표시를 했습니다:

"$combinedText"

이 내용에 대해 학생 스스로 생각하고 답을 찾도록 유도하는 짧은 질문 하나를 한국어로 만들어 주세요.
- 질문은 1~2문장으로 간결하게
- 답을 직접 알려주지 말 것
- 학생의 호기심을 자극하는 방식으로
''';

    final response = await _model.generateContent([
      Content.text(prompt),
    ]);

    return response.text ?? '이 부분에 대해 더 생각해볼 수 있을까요?';
  }
}
