import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mind_muse/features/canvas/data/models/alien_models.dart';
import 'package:mind_muse/features/canvas/data/repositories/alien_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AlienRepository repository;
  late MockDio mockDio;

  setUp(() {
    dotenv.testLoad(fileInput: 'BACKEND_BASE_URL=http://localhost:8000');
    mockDio = MockDio();
    repository = AlienRepository(dio: mockDio);
    
    // mocktail requires registering fallback values for custom types if used in any()
    registerFallbackValue(Options());
  });

  group('AlienRepository.chat', () {
    test('emits stream of strings from backend response', () async {
      // GIVEN
      final responseBody = Stream<Uint8List>.fromIterable([
        utf8.encode('Hello '),
        utf8.encode('from '),
        utf8.encode('AI!'),
      ]);

      final response = Response(
        requestOptions: RequestOptions(path: ''),
        data: responseBody,
        statusCode: 200,
      );

      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => response);

      // WHEN
      final stream = repository.chat(
        message: 'Hi',
        history: [],
      );

      // THEN
      final results = await stream.toList();
      expect(results, ['Hello ', 'from ', 'AI!']);
    });

    test('handles errors by emitting an error message', () async {
      // GIVEN
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Connection failed',
      ));

      // WHEN
      final stream = repository.chat(
        message: 'Hi',
        history: [],
      );

      // THEN
      final results = await stream.toList();
      expect(results.first, contains('Error'));
    });
   group('AlienRepository.chat request data', () {
    test('sends correct data with base64 image', () async {
      // GIVEN
      final responseBody = Stream<Uint8List>.fromIterable([
        utf8.encode('OK'),
      ]);

      final response = Response(
        requestOptions: RequestOptions(path: ''),
        data: responseBody,
        statusCode: 200,
      );

      Map<String, dynamic>? capturedData;
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((invocation) async {
            capturedData = invocation.namedArguments[#data] as Map<String, dynamic>?;
            return response;
          });

      // WHEN
      final stream = repository.chat(
        message: 'Hi',
        history: [],
        imageBase64: 'test_base64',
      );
      await stream.toList();

      // THEN
      expect(capturedData?['message'], 'Hi');
      expect(capturedData?['image_base64'], 'test_base64');
      expect(capturedData?['history'], isEmpty);
    });
  });
  });
}
