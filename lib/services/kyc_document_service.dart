import 'dart:convert';
import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class KycDocument {
  const KycDocument({required this.type, required this.path, this.extracted = const {}});
  final String type;
  final String path;
  final Map<String, String> extracted;

  Map<String, dynamic> toJson() => {'type': type, 'path': path, 'extracted': extracted};
  factory KycDocument.fromJson(Map<String, dynamic> json) => KycDocument(
        type: '${json['type'] ?? ''}',
        path: '${json['path'] ?? ''}',
        extracted: Map<String, String>.from(json['extracted'] as Map? ?? const {}),
      );
}

class KycDocumentService {
  KycDocumentService._();
  static final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static Future<Directory> _vault() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/kyc_vault');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  static Future<KycDocument> importDocument(File source, String type) async {
    final vault = await _vault();
    final safe = type.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final target = File('${vault.path}/${safe}_${DateTime.now().millisecondsSinceEpoch}${_extension(source.path)}');
    await source.copy(target.path);
    final input = InputImage.fromFile(target);
    final result = await _recognizer.processImage(input);
    final text = result.text;
    final extracted = <String, String>{};
    if (type == 'Bank Passbook' || type == 'Cancelled Cheque') {
      final account = RegExp(r'(?:account|a/c|acct)[^0-9]{0,20}([0-9]{8,20})', caseSensitive: false).firstMatch(text)?.group(1);
      final ifsc = RegExp(r'\b[A-Z]{4}0[A-Z0-9]{6}\b', caseSensitive: false).firstMatch(text)?.group(0);
      if (account != null) extracted['Account Number'] = account;
      if (ifsc != null) extracted['IFSC Code'] = ifsc.toUpperCase();
    }
    return KycDocument(type: type, path: target.path, extracted: extracted);
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot) : '.jpg';
  }

  static String encodeDocuments(List<KycDocument> docs) => jsonEncode(docs.map((e) => e.toJson()).toList());
  static List<KycDocument> decodeDocuments(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try { return (jsonDecode(raw) as List).whereType<Map>().map((e) => KycDocument.fromJson(Map<String, dynamic>.from(e))).toList(); } catch (_) { return []; }
  }

  static Future<void> dispose() => _recognizer.close();
}
