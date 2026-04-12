import 'dart:convert';

class MisconceptionResult {
  final bool hasMisconception;
  final String subject;
  final String falseAssumption;
  final String absurdExtreme;
  final String triggerPhrase;

  const MisconceptionResult({
    required this.hasMisconception,
    this.subject = '',
    this.falseAssumption = '',
    this.absurdExtreme = '',
    this.triggerPhrase = '',
  });

  factory MisconceptionResult.noMisconception() =>
      const MisconceptionResult(hasMisconception: false);

  factory MisconceptionResult.fromJson(String raw) {
    try {
      final jsonStr = _extractJson(raw);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (map['has_misconception'] != true) {
        return MisconceptionResult.noMisconception();
      }

      return MisconceptionResult(
        hasMisconception: true,
        subject: map['subject'] as String? ?? 'other',
        falseAssumption: map['false_assumption'] as String? ?? '',
        absurdExtreme: map['absurd_extreme'] as String? ?? '',
        triggerPhrase: map['trigger_phrase'] as String? ??
            '맞아! 완전히 동의해! 내가 네 논리대로 시뮬레이션을 만들어줄게!',
      );
    } catch (_) {
      return MisconceptionResult.noMisconception();
    }
  }

  static String _extractJson(String raw) {
    // ```json ... ``` 또는 ``` ... ``` 마크다운 블록 제거
    final blockMatch =
        RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
    if (blockMatch != null) return blockMatch.group(1)!;

    // { ... } 직접 추출
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return raw.substring(start, end + 1);
    }

    return raw.trim();
  }
}
