import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:mind_muse/core/constants/api_constants.dart';
import 'package:mind_muse/features/canvas/data/models/alien_models.dart';

class AlienRepository {
  final Dio _dio;

  AlienRepository({Dio? dio}) : _dio = dio ?? Dio();

  Stream<String> chat({
    required String message,
    required List<AlienMessage> history,
    String? imageBase64,
  }) async* {
    try {
      final request = AnalyzeRequest(
        message: message,
        imageBase64: imageBase64,
        history: history,
      );

      final url = '${ApiConstants.backendBaseUrl}${ApiConstants.alienChatEndpoint}';

      final response = await _dio.post(
        url,
        data: request.toJson(),
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data as Stream<Uint8List>;
      await for (final chunk in stream) {
        yield utf8.decode(chunk);
      }
    } on DioException catch (e) {
      yield 'Error: ${e.message}';
    } catch (e) {
      yield 'Error: $e';
    }
  }
}
