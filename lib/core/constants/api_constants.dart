import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  const ApiConstants._(); // 인스턴스화 방지

  static String get geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    assert(key != null && key.isNotEmpty, 'GEMINI_API_KEY가 .env에 설정되지 않았습니다');
    return key ?? '';
  }

  static String get backendBaseUrl {
    final url = dotenv.env['BACKEND_BASE_URL'];
    assert(url != null && url.isNotEmpty, 'BACKEND_BASE_URL이 .env에 설정되지 않았습니다');
    return url ?? 'http://10.0.2.2:8000';
  }

  static const String alienChatEndpoint = '/api/alien/chat';

  static const String gemmaModel = 'gemma-4-26b-a4b-it';
}
