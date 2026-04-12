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
      systemInstruction: Content.text(
        '당신은 한국어로만 답변하는 소크라테스식 교육 튜터입니다. '
        '요청받은 내용만 출력하고, 자기 평가·사고 과정·영어 설명은 절대 출력하지 마세요.',
      ),
    );
  }

  // ── 응답 후처리 헬퍼 ──────────────────────────────────────────────────

  /// 모델이 평가 체크리스트나 영어 접두어를 출력할 때 한국어 본문만 추출한다.
  String _cleanResponse(String raw) {
    // 한국어가 포함된 줄만 추출
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && RegExp(r'[가-힣]').hasMatch(l))
        .toList();

    if (lines.isEmpty) return raw.trim();

    // 줄 결합 후 따옴표 제거
    String result = lines.join(' ').replaceAll('"', '').trim();

    // 동일 텍스트가 두 번 반복되면 한 번만 취함
    if (result.length >= 20) {
      final half = result.length ~/ 2;
      if (result.substring(0, half).trim() == result.substring(half).trim()) {
        result = result.substring(0, half).trim();
      }
    }

    return result;
  }

  /// 힌트 응답을 파싱한다. '|||' 구분 실패 시 줄바꿈 형식도 시도한다.
  List<String> _parseHints(String raw) {
    // 형식 1: "힌트1|||힌트2|||힌트3"
    if (raw.contains('|||')) {
      final parts = raw
          .split('|||')
          .map((s) => s.replaceAll('"', '').trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length >= 3) return parts.take(3).toList();
    }

    // 형식 2: 줄바꿈 구분 (숫자·기호 접두어 제거)
    final lines = raw
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'^[\d\.\-\*\s]+'), '').trim())
        .where((l) => l.isNotEmpty && RegExp(r'[가-힣]').hasMatch(l))
        .toList();
    if (lines.length >= 3) return lines.take(3).toList();

    // 기본 힌트 반환
    return _defaultHints();
  }

  List<String> _defaultHints() => [
        '표시한 부분의 핵심 단어에 집중해보세요.',
        '이 정보가 어떤 상황에서 쓰일지 상상해보세요.',
        '비슷한 개념이나 예시를 떠올려보세요.',
      ];

  // ── 공개 API ──────────────────────────────────────────────────────────

  /// 합성 이미지를 보내 첫 번째 소크라테스 질문을 생성한다.
  /// [hasDrawing] false이면 전체 이미지 기반 질문 생성
  Future<String> askInitialQuestion(Uint8List imageBytes,
      {bool hasDrawing = true}) async {
    final prompt = hasDrawing
        ? '이미지에서 빨간 선으로 표시된 부분을 보고, 학생이 스스로 생각하도록 유도하는 '
              '소크라테스식 질문을 한국어로 1~2문장 작성하세요. 질문만 출력하세요.'
        : '이미지 전체 내용에서 중요한 개념 하나를 골라, 학생이 스스로 생각하도록 유도하는 '
              '소크라테스식 질문을 한국어로 1~2문장 작성하세요. 질문만 출력하세요.';

    final response = await _model.generateContent([
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(prompt),
      ]),
    ]);
    final raw = response.text ?? '';
    final cleaned = _cleanResponse(raw);
    return cleaned.isNotEmpty ? cleaned : '이 부분에 대해 어떻게 생각하나요?';
  }

  /// 첫 질문 직후 백그라운드에서 힌트 3개를 미리 생성한다.
  Future<List<String>> generateHints(
    Uint8List imageBytes,
    String question,
  ) async {
    final prompt =
        '아래 질문에 대한 힌트 3개를 한국어로 작성하세요. '
        '힌트는 1→3으로 갈수록 구체적이지만 정답은 직접 알려주지 마세요.\n'
        '질문: $question\n\n'
        '출력 형식 (이 형식만 사용, 다른 텍스트 없이):\n'
        '힌트1내용|||힌트2내용|||힌트3내용';

    try {
      final response = await _model.generateContent([
        Content.multi([
          DataPart('image/png', imageBytes),
          TextPart(prompt),
        ]),
      ]);
      return _parseHints(response.text ?? '');
    } catch (_) {
      return _defaultHints();
    }
  }

  /// 학생 답변을 평가하고 후속 질문(또는 마지막 라운드 정리)을 생성한다.
  Future<String> evaluateAndContinue({
    required Uint8List imageBytes,
    required List<Map<String, String>> history,
    required bool isLastRound,
  }) async {
    final historyText = history
        .map((h) => 'AI: ${h['question']}\n학생: ${h['answer']}')
        .join('\n\n');

    final prompt = isLastRound
        ? '다음 대화를 바탕으로 학생을 격려하고 핵심 내용을 2~3문장으로 정리하세요. '
              '한국어만 출력하세요.\n\n$historyText'
        : '다음 대화를 바탕으로 학생 답변을 한 문장으로 평가하고, '
              '더 깊이 생각하도록 유도하는 후속 질문을 1~2문장 작성하세요. '
              '한국어만 출력하세요.\n\n$historyText';

    final response = await _model.generateContent([
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(prompt),
      ]),
    ]);
    final raw = response.text ?? '';
    return _cleanResponse(raw).isNotEmpty
        ? _cleanResponse(raw)
        : '좋은 생각이에요! 조금 더 생각해볼까요?';
  }

  /// 학생이 스스로 오개념을 발견한 직후 Truth Mode 설명을 생성한다.
  Future<String> generateTruthMode({
    required Uint8List imageBytes,
    required List<Map<String, String>> history,
  }) async {
    final historyText = history
        .map((h) => 'AI: ${h['question']}\n학생: ${h['answer']}')
        .join('\n\n');
    const prompt =
        'The student has just realized their misconception on their own. '
        'Switch to honest tutoring mode. '
        'Start your response with exactly: "오! 스스로 발견했네. 사실은 이렇게 작동해:" '
        'Then explain the correct concept clearly and warmly. Korean only.\n\n'
        'Conversation history:\n';
    final response = await _model.generateContent([
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(prompt + historyText),
      ]),
    ]);
    final raw = response.text ?? '';
    return _cleanResponse(raw).isNotEmpty
        ? _cleanResponse(raw)
        : '오! 스스로 발견했네. 사실은 이렇게 작동해: 정말 잘 생각해봤어요!';
  }
}
