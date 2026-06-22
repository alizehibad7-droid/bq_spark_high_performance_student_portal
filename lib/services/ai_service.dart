import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'remote_config_service.dart';

class AIService {
  static Uri _requestUri() => Uri.parse(
    'https://api.groq.com/openai/v1/chat/completions',
  );

  static const String _systemPrompt =
      'You are a helpful study assistant for BQ Spark '
      'by Bano Qabil, Rawalpindi Pakistan. Help students '
      'with Flutter, Dart, Firebase, and career advice. '
      'Be concise, friendly, and encouraging.';

  Future<String> sendMessage(
      List<Map<String, String>> history,
      String userMessage,
      ) async {
    final apiKey = RemoteConfigService().groqApiKey.trim();
    if (apiKey.isEmpty) {
      return 'AI assistant is not configured yet. Please contact your admin.';
    }

    try {
      final messages = <Map<String, dynamic>>[
        {
          'role': 'system',
          'content': _systemPrompt,
        },
        ...history.map((m) => {
          'role': m['role'] ?? 'user',
          'content': m['content'] ?? '',
        }),
        {
          'role': 'user',
          'content': userMessage,
        },
      ];

      final response = await http.post(
        _requestUri(),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)
        as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices.first['message']
          as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            return content;
          }
        }
        return 'Sorry, could not parse reply. Try again!';
      } else if (response.statusCode == 429) {
        return '⚠️ AI is busy. Please wait and try again.';
      } else {
        debugPrint('Groq error ${response.statusCode}: '
            '${response.body}');
        return 'Error ${response.statusCode}. Try again!';
      }
    } catch (e) {
      debugPrint('AI Service error: $e');
      return 'Connection error. Please try again.';
    }
  }
}
