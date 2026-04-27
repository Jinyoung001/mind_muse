import 'package:flutter_test/flutter_test.dart';
import 'package:mind_muse/features/canvas/data/models/alien_models.dart';
import 'package:mind_muse/features/canvas/data/repositories/alien_repository.dart';

void main() {
  group('AlienRepository', () {
    test('chat() 메서드가 존재하고 Stream<String>을 반환한다', () {
      final repository = AlienRepository();
      final stream = repository.chat(
        message: 'test',
        history: const [],
      );
      expect(stream, isA<Stream<String>>());
    });

    test('AlienMessage 직렬화/역직렬화가 올바르게 동작한다', () {
      const msg = AlienMessage(role: 'user', content: '안녕하세요');
      final json = msg.toJson();
      final restored = AlienMessage.fromJson(json);
      expect(restored.role, msg.role);
      expect(restored.content, msg.content);
    });
  });
}
