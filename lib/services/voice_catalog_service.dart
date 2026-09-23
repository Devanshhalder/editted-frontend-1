import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class VoiceCatalogResult {
  const VoiceCatalogResult({
    required this.transcript,
    required this.titleEnglish,
    required this.descriptionEnglish,
    required this.titleHindi,
    required this.descriptionHindi,
    required this.bulletsEnglish,
    required this.bulletsHindi,
  });

  final String transcript;
  final String titleEnglish;
  final String descriptionEnglish;
  final String titleHindi;
  final String descriptionHindi;
  final List<String> bulletsEnglish;
  final List<String> bulletsHindi;
}

class VoiceCatalogService {
  VoiceCatalogService({
    this.baseUrl = 'http://10.70.33.153:8000',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<String> transcribe({
    required String audioPath,
    required String language,
  }) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      throw const VoiceCatalogException('Recorded audio was not found.');
    }
    if (await file.length() == 0) {
      throw const VoiceCatalogException('Recorded audio is empty.');
    }

    final uri = Uri.parse(
      '$baseUrl/ai/transcribe?language=${Uri.encodeComponent(language)}',
    );
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioPath,
        filename: 'karigarkart_voice.m4a',
      ),
    );

    final streamed = await request.send().timeout(
      const Duration(seconds: 120),
    );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw VoiceCatalogException(_detail(response.body, 'Speech transcription failed.'));
    }

    final decoded = _map(response.body);
    final text = (decoded['text'] ?? '').toString().trim();
    if (text.isEmpty) {
      throw const VoiceCatalogException('No speech was detected.');
    }
    return text;
  }

  Future<VoiceCatalogResult> generateCatalog({
    required String artisanText,
    required String language,
  }) async {
    final source = artisanText.trim();
    if (source.isEmpty) {
      throw const VoiceCatalogException('Describe the product first.');
    }

    final response = await _client
        .post(
          Uri.parse('$baseUrl/ai/catalog'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'artisan_text': source,
            'language': language,
            'raw_material_cost': 0,
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw VoiceCatalogException(_detail(response.body, 'Catalog generation failed.'));
    }

    final decoded = _map(response.body);
    final catalogValue = decoded['catalog'];
    final catalog = catalogValue is Map
        ? Map<String, dynamic>.from(catalogValue)
        : decoded;

    final titleEn = (catalog['title_en'] ?? '').toString().trim();
    final descEn = (catalog['desc_en'] ?? '').toString().trim();
    final titleHi = (catalog['title_regional'] ?? '').toString().trim();
    final descHi = (catalog['desc_regional'] ?? '').toString().trim();

    if (titleEn.isEmpty || descEn.isEmpty) {
      throw const VoiceCatalogException('The AI returned an incomplete catalog.');
    }

    return VoiceCatalogResult(
      transcript: source,
      titleEnglish: titleEn,
      descriptionEnglish: descEn,
      titleHindi: titleHi,
      descriptionHindi: descHi,
      bulletsEnglish: _bullets(
        catalog['bullets_en'] ?? catalog['key_points_en'],
        descEn,
      ),
      bulletsHindi: _bullets(
        catalog['bullets_hi'] ?? catalog['key_points_hi'],
        descHi,
      ),
    );
  }

  Map<String, dynamic> _map(String body) {
    final value = jsonDecode(body);
    if (value is! Map) {
      throw const VoiceCatalogException('Invalid AI response.');
    }
    return Map<String, dynamic>.from(value);
  }

  static String _detail(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return fallback;
  }

  static List<String> _bullets(dynamic value, String description) {
    if (value is List) {
      final result = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .take(5)
          .toList();
      if (result.isNotEmpty) return result;
    }

    final sentences = description
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((item) => item.trim())
        .where((item) => item.length > 8)
        .take(4)
        .toList();
    return sentences;
  }

  void dispose() => _client.close();
}

class VoiceCatalogException implements Exception {
  const VoiceCatalogException(this.message);
  final String message;

  @override
  String toString() => message;
}
