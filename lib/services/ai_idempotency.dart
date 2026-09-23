import 'dart:convert';

/// Stable, dependency-free request key for retry-safe AI/background jobs.
String aiIdempotencyKey(String type, Map<String, dynamic> payload) {
  final normalized = _sortMap(payload);
  final input = '$type:${jsonEncode(normalized)}';
  var hash = 2166136261;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return 'kk-$type-$hash';
}

Map<String, dynamic> _sortMap(Map<String, dynamic> source) {
  final keys = source.keys.toList()..sort();
  return <String, dynamic>{
    for (final key in keys)
      key: source[key] is Map
          ? _sortMap(Map<String, dynamic>.from(source[key] as Map))
          : source[key],
  };
}
