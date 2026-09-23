import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Parses large AI JSON payloads away from the Flutter UI isolate.
Future<Map<String, dynamic>> parseAiJsonInBackground(String body) {
  return compute(_parseAiJson, body);
}

Map<String, dynamic> _parseAiJson(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const FormatException('AI response is not an object');
  }
  return Map<String, dynamic>.from(decoded);
}
