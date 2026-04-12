import 'package:flutter_test/flutter_test.dart';
import 'package:mind_muse/features/canvas/data/models/misconception_model.dart';

void main() {
  group('MisconceptionResult.fromJson', () {
    test('오개념 있음 — 정상 JSON 파싱', () {
      const raw =
          '{"has_misconception": true, "subject": "biology", '
          '"false_assumption": "포식자가 없으면 동물들이 평화롭게 산다", '
          '"absurd_extreme": "사슴이 지구를 뒤덮는다", '
          '"trigger_phrase": "맞아! 시뮬레이션 만들어줄게!"}';
      final result = MisconceptionResult.fromJson(raw);
      expect(result.hasMisconception, true);
      expect(result.subject, 'biology');
      expect(result.falseAssumption, '포식자가 없으면 동물들이 평화롭게 산다');
      expect(result.absurdExtreme, '사슴이 지구를 뒤덮는다');
      expect(result.triggerPhrase, '맞아! 시뮬레이션 만들어줄게!');
    });

    test('오개념 없음', () {
      const raw = '{"has_misconception": false}';
      final result = MisconceptionResult.fromJson(raw);
      expect(result.hasMisconception, false);
    });

    test('```json 마크다운 블록 처리', () {
      const raw = '```json\n{"has_misconception": false}\n```';
      final result = MisconceptionResult.fromJson(raw);
      expect(result.hasMisconception, false);
    });

    test('JSON이 아닌 문자열 → noMisconception 반환', () {
      const raw = '이것은 JSON이 아닙니다';
      final result = MisconceptionResult.fromJson(raw);
      expect(result.hasMisconception, false);
    });

    test('has_misconception 키 누락 → noMisconception 반환', () {
      const raw = '{"subject": "biology"}';
      final result = MisconceptionResult.fromJson(raw);
      expect(result.hasMisconception, false);
    });
  });
}
