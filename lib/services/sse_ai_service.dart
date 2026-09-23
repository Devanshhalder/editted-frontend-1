import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// SSE client used by future streaming AI endpoints. It exposes partial text
/// as soon as a `data:` event arrives instead of waiting for the whole body.
class SseAiService {
  SseAiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Stream<String> streamText(Uri uri, {Map<String, String>? headers}) async* {
    final request = http.Request('GET', uri);
    request.headers.addAll(headers ?? const {});
    final response = await _client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AI stream failed: ${response.statusCode}');
    }

    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final events = buffer.split('\n\n');
      buffer = events.removeLast();
      for (final event in events) {
        for (final line in event.split('\n')) {
          if (!line.startsWith('data:')) continue;
          final data = line.substring(5).trimLeft();
          if (data == '[DONE]') return;
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map && decoded['text'] != null) {
              yield decoded['text'].toString();
            } else if (decoded is String) {
              yield decoded;
            }
          } catch (_) {
            if (data.isNotEmpty) yield data;
          }
        }
      }
    }
  }

  void dispose() => _client.close();
}
