import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:caledoro/services/subtask_generator_service.dart';

/// Wraps a JSON subtask array in the Gemini response envelope.
/// (See subtask_generator_service_test.dart for the full explanation.)
String geminiResponse(String innerJsonArray) => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': innerJsonArray},
            ],
          },
        },
      ],
    });

void main() {
  group('AI subtask service — hardening (QA-01, QA-02)', () {
    // QA-01: the service must not keep more than [maxSubtasks] subtasks, even
    // when the model returns more.
    test('caps subtasks at maxSubtasks (10) per generation', () async {
      final fifteen = List.generate(15, (i) => {'label': 'Subtask ${i + 1}'});
      final client = MockClient(
        (req) async => http.Response(geminiResponse(jsonEncode(fifteen)), 200),
      );
      final service =
          GeminiSubtaskGeneratorService(apiKey: 'test-key', client: client);

      final result = await service.generateSubtasks(
        taskTitle: 'Big task',
        taskDescription: '',
      );

      expect(result, hasLength(GeminiSubtaskGeneratorService.maxSubtasks));
      expect(result.first.label, 'Subtask 1');
      expect(result.last.label, 'Subtask 10');
    });

    // QA-02: a request that exceeds the timeout must surface the intended
    // "Request timed out" message, not the generic fallback. We inject a tiny
    // timeout and a client that responds slower than it.
    test('maps a request timeout to a "Request timed out" GeneratorException',
        () async {
      final slowClient = MockClient((req) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response(geminiResponse('[]'), 200);
      });
      final service = GeminiSubtaskGeneratorService(
        apiKey: 'test-key',
        client: slowClient,
        timeout: const Duration(milliseconds: 10),
      );

      expect(
        () => service.generateSubtasks(taskTitle: 'X', taskDescription: ''),
        throwsA(
          isA<GeneratorException>()
              .having((e) => e.message, 'message', 'Request timed out'),
        ),
      );
    });
  });
}
