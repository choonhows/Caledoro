import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:caledoro/models/task_model.dart';
import 'package:caledoro/services/subtask_generator_service.dart';

/// Wraps a JSON array of subtasks in the envelope the Gemini API returns.
///
/// The service digs through candidates -> content -> parts -> text, and then
/// json-decodes that `text` string as the actual subtask array. So the array
/// has to be embedded as a *string* inside the response, exactly like the real
/// API does it.
String geminiResponse(String innerJsonArray) {
  return jsonEncode({
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
}

/// Builds a service backed by a fake HTTP client that always returns [body]
/// with [status]. No network, no API key, fully deterministic.
GeminiSubtaskGeneratorService serviceReturning(String body, {int status = 200}) {
  final mockClient = MockClient((http.Request request) async {
    return http.Response(body, status);
  });
  return GeminiSubtaskGeneratorService(apiKey: 'test-key', client: mockClient);
}

void main() {
  group('GeminiSubtaskGeneratorService.generateSubtasks', () {
    test('parses a valid response into AI-tagged subtasks', () async {
      final body = geminiResponse(jsonEncode([
        {'label': 'Research the topic'},
        {'label': 'Write the outline'},
        {'label': 'Draft the introduction'},
      ]));
      final service = serviceReturning(body);

      final result = await service.generateSubtasks(
        taskTitle: 'Write essay',
        taskDescription: 'For history class',
      );

      // Right number of subtasks, in order.
      expect(result, hasLength(3));
      expect(result.map((s) => s.label), [
        'Research the topic',
        'Write the outline',
        'Draft the introduction',
      ]);
      // Every AI subtask must be tagged as AI-created and suggested, with the
      // id left blank for the provider to fill in.
      for (final subtask in result) {
        expect(subtask.createdBy, SubtaskCreator.ai);
        expect(subtask.suggested, isTrue);
        expect(subtask.id, isEmpty);
      }
    });

    test('trims surrounding whitespace on labels', () async {
      final body = geminiResponse(jsonEncode([
        {'label': '   Buy groceries   '},
      ]));
      final service = serviceReturning(body);

      final result = await service.generateSubtasks(
        taskTitle: 'Errands',
        taskDescription: '',
      );

      expect(result.single.label, 'Buy groceries');
    });

    test('returns an empty list when the task is atomic ([])', () async {
      final body = geminiResponse(jsonEncode([]));
      final service = serviceReturning(body);

      final result = await service.generateSubtasks(
        taskTitle: 'Send email',
        taskDescription: '',
      );

      expect(result, isEmpty);
    });

    test('throws GeneratorException on a blank subtask label', () async {
      final body = geminiResponse(jsonEncode([
        {'label': '   '}, // whitespace-only => empty after trim
      ]));
      final service = serviceReturning(body);

      expect(
        () => service.generateSubtasks(taskTitle: 'X', taskDescription: ''),
        throwsA(isA<GeneratorException>()),
      );
    });

    test('throws GeneratorException on a non-200 status code', () async {
      final service = serviceReturning('Server error', status: 500);

      expect(
        () => service.generateSubtasks(taskTitle: 'X', taskDescription: ''),
        throwsA(isA<GeneratorException>()),
      );
    });

    test('throws GeneratorException when the model text is not a JSON array',
        () async {
      // `text` is valid JSON overall, but the inner payload is an object, not
      // the array the parser requires.
      final body = geminiResponse(jsonEncode({'not': 'an array'}));
      final service = serviceReturning(body);

      expect(
        () => service.generateSubtasks(taskTitle: 'X', taskDescription: ''),
        throwsA(isA<GeneratorException>()),
      );
    });

    test('throws GeneratorException when the response has no candidates',
        () async {
      final service = serviceReturning(jsonEncode({'candidates': []}));

      expect(
        () => service.generateSubtasks(taskTitle: 'X', taskDescription: ''),
        throwsA(isA<GeneratorException>()),
      );
    });
  });
}
