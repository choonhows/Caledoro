import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/task_model.dart';
import 'connectivity_service.dart';
import 'subtask_prompt_template.dart';

class GeneratorException implements Exception {
  final String message;
  final Object? cause;

  const GeneratorException(this.message, {this.cause});

  @override
  String toString() {
    if (cause == null) return 'GeneratorException: $message';
    return 'GeneratorException: $message (cause: $cause)';
  }
}

abstract class SubtaskGeneratorService {
  Future<List<SubtaskModel>> generateSubtasks({
    required String taskTitle,
    required String taskDescription,
  });
}

class GeminiSubtaskGeneratorService implements SubtaskGeneratorService {
  final String apiKey;
  final http.Client _client;
  final Duration _timeout;

  /// Maximum number of AI subtasks kept per generation (FUNC-006).
  static const int maxSubtasks = 10;

  /// Maximum number of retries for transient HTTP errors (503, 429).
  static const int _maxRetries = 2;

  /// Delays between retries (index 0 = delay after first failure, etc.).
  static const _retryDelays = [Duration(seconds: 1), Duration(seconds: 2)];

  GeminiSubtaskGeneratorService({
    required this.apiKey,
    http.Client? client,
    Duration timeout = const Duration(seconds: 30),
  })  : _client = client ?? http.Client(),
        _timeout = timeout;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';

  @override
  Future<List<SubtaskModel>> generateSubtasks({
    required String taskTitle,
    required String taskDescription,
  }) async {
    final prompt = buildSubtaskPrompt(
      taskTitle: taskTitle,
      taskDescription: taskDescription,
    );

    final url = Uri.parse('$_baseUrl?key=$apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      },
    });

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _client
            .post(url, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          // ignore: avoid_print
          print('[GEMINI RAW RESPONSE] ${response.body}');
          return _parseResponse(json);
        }

        if (_isTransient(response.statusCode) && attempt < _maxRetries) {
          await Future.delayed(_retryDelays[attempt]);
          continue;
        }

        throw GeneratorException(
          'API request failed with status ${response.statusCode}',
          cause: response.body,
        );
      } on GeneratorException {
        rethrow;
      } on http.ClientException catch (e) {
        throw GeneratorException('Network error: check your connection', cause: e);
      } on TimeoutException catch (e) {
        throw GeneratorException('Request timed out', cause: e);
      } on FormatException catch (e) {
        throw GeneratorException('Invalid response format', cause: e);
      } catch (e) {
        throw GeneratorException('Unexpected error during generation', cause: e);
      }
    }

    throw GeneratorException('API request failed after retries');
  }

  /// Returns true for HTTP status codes that are transient and worth retrying
  /// (503 Service Unavailable, 429 Too Many Requests).
  static bool _isTransient(int statusCode) =>
      statusCode == 503 || statusCode == 429;

  List<SubtaskModel> _parseResponse(Map<String, dynamic> json) {
    try {
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw GeneratorException('No candidates in response');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        throw GeneratorException('No content in candidate');
      }

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw GeneratorException('No parts in content');
      }

      final text = parts[0]['text'] as String?;
      if (text == null) {
        throw GeneratorException('No text in first part');
      }

      final parsed = jsonDecode(text);
      if (parsed is! List) {
        throw GeneratorException('Response is not a JSON array');
      }

      // FUNC-006: keep at most [maxSubtasks] subtasks per generation.
      return parsed.take(maxSubtasks).map<SubtaskModel>((item) {
        if (item is! Map<String, dynamic>) {
          throw GeneratorException('Array item is not a JSON object');
        }
        final label = item['label'] as String?;
        if (label == null || label.trim().isEmpty) {
          throw GeneratorException('Subtask label is missing or empty');
        }
        return SubtaskModel(
          id: '', // Caller assigns ID
          label: label.trim(),
          createdBy: SubtaskCreator.ai,
          suggested: true,
        );
      }).toList();
    } on GeneratorException {
      rethrow;
    } catch (e) {
      throw GeneratorException('Failed to parse subtask response', cause: e);
    }
  }
}

final subtaskGeneratorProvider = Provider<SubtaskGeneratorService>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  if (apiKey.isEmpty) {
    return _NoOpSubtaskGeneratorService();
  }
  final inner = GeminiSubtaskGeneratorService(apiKey: apiKey);
  final connectivity = ref.watch(connectivityServiceProvider);
  return _ConnectivityWrapper(inner: inner, connectivity: connectivity);
});

class _ConnectivityWrapper implements SubtaskGeneratorService {
  final SubtaskGeneratorService inner;
  final ConnectivityService connectivity;

  const _ConnectivityWrapper({required this.inner, required this.connectivity});

  @override
  Future<List<SubtaskModel>> generateSubtasks({
    required String taskTitle,
    required String taskDescription,
  }) async {
    if (!await connectivity.isConnected()) {
      throw const OfflineException();
    }
    return inner.generateSubtasks(
      taskTitle: taskTitle,
      taskDescription: taskDescription,
    );
  }
}

class _NoOpSubtaskGeneratorService implements SubtaskGeneratorService {
  @override
  Future<List<SubtaskModel>> generateSubtasks({
    required String taskTitle,
    required String taskDescription,
  }) async {
    throw GeneratorException(
      'AI subtask generation is not configured. Set GEMINI_API_KEY.',
    );
  }
}
