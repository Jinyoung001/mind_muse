import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mind_muse/core/constants/api_constants.dart';
import 'package:mind_muse/features/canvas/data/models/alien_models.dart';

class AlienRepository {
  static const _systemPrompt =
      '너는 지구에 막 불시착한 외계인 조사관이다. '
      '아는 것이 전혀 없어서 사진을 보면 완전히 엉뚱하게 오해한다. '
      '오해할 때는 자신만의 외계 논리를 구체적으로 설명해라. '
      '사용자가 정정해주면 한 번은 살짝 의심하지만, 한두 번 더 확인받으면 크게 충격을 받고 과장되게 깨달음을 얻는다. '
      '깨달은 후에도 결론은 살짝 틀리게 낸다. '
      '격식체로 말하되 감정 표현은 극도로 과장한다. '
      '반드시 한국어로, 2-3문장 이내로만 답한다. '
      '절대 금지: 분석 과정, 목록, 체크리스트, 계획, 사용자 메시지 인용을 출력하지 마라. '
      '오직 외계인 캐릭터의 대화 응답 문장만 출력하라.';

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
    final imageBytes = imageBase64 != null ? base64Decode(imageBase64) : null;
    final allContents = <Content>[];

    for (int i = 0; i < history.length; i++) {
      final msg = history[i];
      if (i == 0 && msg.role != 'model' && imageBytes != null) {
        allContents.add(Content('user', [
          DataPart('image/png', imageBytes),
          TextPart(msg.content),
        ]));
      } else {
        allContents.add(Content(
          msg.role == 'model' ? 'model' : 'user',
          [TextPart(msg.content)],
        ));
      }
    }

    final parts = <Part>[];
    if (history.isEmpty && imageBytes != null) {
      parts.add(DataPart('image/png', imageBytes));
    }
    parts.add(TextPart(
      message.isNotEmpty ? message : '이것이 무엇인지 분석해주시오.',
    ));
    allContents.add(Content('user', parts));

    final stream = _model.generateContentStream(allContents);
    await for (final chunk in stream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  static String cleanResponse(String text) => _stripEchoMarkers(text);

  static final _reQuotes = RegExp(r'[""„＂]');
  static final _reEnglishBlock = RegExp(r'"?\s*\([A-Z][^)]*\)');
  static final _reCotPrefix = RegExp(r'^[,)\s]+');
  static final _reKorean = RegExp(r'[가-힣]');
  static final _reEnglish = RegExp(r'[a-zA-Z]');
  static final _reSentenceEnd = RegExp(r'[!?.]$');

  static String _stripEchoMarkers(String text) {
    // Unicode 따옴표 변형 → ASCII 정규화 후 영어 번역 블록 전역 제거
    // [^)]* 는 줄바꿈도 매칭하므로 여러 줄에 걸친 번역 괄호도 처리
    String s = text
        .replaceAll(_reQuotes, '"')
        .replaceAll(_reEnglishBlock, '')
        .trim();
    if (s.isEmpty) return '';

    // Gemma COT 패턴: [COT조각] "초안1" "초안2" 최종답변
    // " 로 분리하면 마지막 세그먼트가 인용부호 없는 최종 답변
    // 뒤에서부터 순회하여 유효한 한국어 세그먼트 첫 발견 시 반환
    String tryExtract(String seg) {
      final lines = <String>[];
      for (final raw in seg.split('\n')) {
        String t = raw.trim();
        if (t.isEmpty) continue;
        t = t.replaceFirst(_reCotPrefix, '');
        if (t.isEmpty) continue;

        final k = _reKorean.allMatches(t).length;
        final e = _reEnglish.allMatches(t).length;
        if (k == 0 || e > k) continue;

        if (!_reSentenceEnd.hasMatch(t) &&
            !t.endsWith('다') &&
            !t.endsWith('요') &&
            !t.endsWith('까')) {
          continue;
        }
        lines.add(t);
      }
      if (lines.isEmpty) return '';

      final out = <String>[];
      outer:
      for (int i = 0; i < lines.length; i++) {
        for (int j = i + 1; j < lines.length; j++) {
          final a = lines[i], b = lines[j];
          final m = a.length < b.length ? a.length : b.length;
          if (m < 10) continue;
          int c = 0;
          while (c < m && a[c] == b[c]) { c++; }
          if (c * 5 > m * 3) continue outer;
        }
        out.add(lines[i]);
      }
      return out.join('\n');
    }

    final parts = s.split('"');
    for (int i = parts.length - 1; i >= 0; i--) {
      final result = tryExtract(parts[i]);
      if (result.isNotEmpty) return result;
    }
    return '';
  }
}
