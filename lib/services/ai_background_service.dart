import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import 'ai_idempotency.dart';
import 'ai_response_parser.dart';
import 'image_preprocessor.dart';

const String kAiEnhancementTask = 'karigarkart_ai_enhancement';
const String kAiEnhancementTag = 'karigarkart_ai';
const String kAiApiBaseUrl = 'http://10.70.33.153:8000';

@pragma('vm:entry-point')
void karigarKartBackgroundCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != kAiEnhancementTask) return true;
    final jobPath = inputData?['jobPath']?.toString();
    if (jobPath == null || jobPath.isEmpty) return true;
    return AiBackgroundService.runJob(jobPath);
  });
}

class AiBackgroundService {
  AiBackgroundService._();
  static bool get isBackgroundSupported => Platform.isAndroid || Platform.isIOS;

  static Future<void> initialize() async {
    await Workmanager().initialize(karigarKartBackgroundCallback);
  }

  static Future<void> enqueue({required String jobPath}) async {
    final uniqueName = 'karigarkart-ai-${jobPath.hashCode.abs()}';
    await Workmanager().registerOneOffTask(
      uniqueName,
      kAiEnhancementTask,
      inputData: <String, dynamic>{'jobPath': jobPath},
      constraints: Constraints(networkType: NetworkType.connected, requiresStorageNotLow: true),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
      tag: kAiEnhancementTag,
    );
  }

  static Future<void> createJob({required String jobPath, required String imagePath, String preset = 'Pure White', String aspectRatio = '1:1'}) async {
    final file = File(jobPath);
    await file.parent.create(recursive: true);
    final idempotencyKey = aiIdempotencyKey('studio-enhance', {
      'imagePath': imagePath,
      'preset': preset,
      'aspectRatio': aspectRatio,
    });
    await _writeState(file, <String, dynamic>{
      'status': 'queued',
      'progress': 0.05,
      'imagePath': imagePath,
      'enhancedPath': null,
      'studioPreset': preset,
      'studioAspectRatio': aspectRatio,
      'idempotencyKey': idempotencyKey,
      'errorCode': null,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> readJob(String jobPath) async {
    try {
      final file = File(jobPath);
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  static Future<String?> findLatestPendingJob() async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      final directory = Directory('${documents.path}/karigarkart_ai');
      if (!await directory.exists()) return null;
      final jobs = directory.listSync().whereType<File>().where((file) => file.path.endsWith('.job.json')).toList();
      jobs.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      for (final job in jobs) {
        final state = await readJob(job.path);
        if (state == null) continue;
        final status = state['status']?.toString();
        final imagePath = state['imagePath']?.toString();
        if ((status == 'queued' || status == 'processing') && imagePath != null && imagePath.isNotEmpty && await File(imagePath).exists()) return job.path;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clearJob(String jobPath) async {
    try {
      final file = File(jobPath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static Future<bool> runJob(String jobPath) async {
    final jobFile = File(jobPath);
    Map<String, dynamic>? job;
    try {
      if (!await jobFile.exists()) return true;
      final decoded = jsonDecode(await jobFile.readAsString());
      if (decoded is! Map<String, dynamic>) return true;
      job = decoded;
      final imagePath = job['imagePath']?.toString();
      if (imagePath == null || imagePath.isEmpty) { await _writeError(jobFile, 'imageMissing'); return true; }
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) { await _writeError(jobFile, 'imageMissing'); return true; }
      final preset = job['studioPreset']?.toString() ?? 'Pure White';
      final aspectRatio = job['studioAspectRatio']?.toString() ?? '1:1';
      final idempotencyKey = job['idempotencyKey']?.toString() ?? aiIdempotencyKey('studio-enhance', {'imagePath': imagePath, 'preset': preset, 'aspectRatio': aspectRatio});

      await _writeState(jobFile, {...job, 'status': 'processing', 'progress': 0.15, 'errorCode': null, 'updatedAt': DateTime.now().toIso8601String()});

      String backgroundColor;
      switch (preset) {
        case 'Warm Wood': backgroundColor = 'warm_wood'; break;
        case 'Neutral Studio': backgroundColor = 'neutral'; break;
        case 'Transparent PNG': backgroundColor = 'transparent'; break;
        case 'Pure White': default: backgroundColor = 'white';
      }

      final request = http.MultipartRequest('POST', Uri.parse('$kAiApiBaseUrl/ai/studio/enhance'));
      request.headers['Idempotency-Key'] = idempotencyKey;
      request.fields.addAll(<String, String>{
        'preset': preset,
        'background_color': backgroundColor,
        'remove_background': 'true',
        'enhance_lighting': 'true',
        'correct_shadows': 'true',
        'output_aspect_ratio': aspectRatio,
        'output_format': preset == 'Transparent PNG' ? 'png' : 'jpeg',
      });
      request.files.add(await http.MultipartFile.fromPath('image', imagePath, filename: 'karigarkart_product.jpg'));

      await _writeState(jobFile, {...job, 'status': 'processing', 'progress': 0.35, 'updatedAt': DateTime.now().toIso8601String()});
      final streamedResponse = await request.send().timeout(const Duration(minutes: 8));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final code = _classifyServerError(response.statusCode, response.body);
        if (_isRetryableStatus(response.statusCode)) {
          await _writeState(jobFile, {...job, 'status': 'queued', 'progress': 0.2, 'errorCode': code, 'updatedAt': DateTime.now().toIso8601String()});
          return false;
        }
        await _writeError(jobFile, code);
        return true;
      }
      if (response.bodyBytes.isEmpty) { await _writeError(jobFile, 'aiServerError'); return true; }
      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (contentType.contains('application/json')) {
        try {
          final json = await parseAiJsonInBackground(response.body);
          final success = json['success'];
          final detail = (json['detail'] ?? json['error'] ?? '').toString();
          if (success == false) { await _writeError(jobFile, _classifyServerError(422, detail)); return true; }
          final enhancedImageBase64 = json['enhanced_image_base64']?.toString() ?? '';
          if (enhancedImageBase64.isNotEmpty) {
            final comma = enhancedImageBase64.indexOf(',');
            final encoded = comma >= 0 ? enhancedImageBase64.substring(comma + 1) : enhancedImageBase64;
            final bytes = base64Decode(encoded);
            return _saveEnhancedImage(jobFile, job, imagePath, bytes, preset);
          }
          final enhancedImageUrl = json['enhanced_image_url']?.toString() ?? '';
          if (enhancedImageUrl.isNotEmpty) {
            final imageResponse = await http.get(Uri.parse(enhancedImageUrl)).timeout(const Duration(minutes: 3));
            if (imageResponse.statusCode >= 200 && imageResponse.statusCode < 300 && imageResponse.bodyBytes.isNotEmpty) return _saveEnhancedImage(jobFile, job, imagePath, imageResponse.bodyBytes, preset);
          }
          await _writeError(jobFile, 'aiServerError');
          return true;
        } catch (e) {
          stderr.writeln('KarigarKart studio JSON response error: $e');
          await _writeError(jobFile, 'aiServerError');
          return true;
        }
      }
      return _saveEnhancedImage(jobFile, job, imagePath, response.bodyBytes, preset);
    } on TimeoutException {
      await _writeError(jobFile, 'aiTimeout');
      return true;
    } on SocketException {
      await _writeState(jobFile, {...(job ?? <String, dynamic>{}), 'status': 'queued', 'progress': 0.2, 'errorCode': 'aiNetworkError', 'updatedAt': DateTime.now().toIso8601String()});
      return false;
    } on ImagePreparationException catch (e) {
      stderr.writeln('KarigarKart AI output processing error: $e');
      await _writeError(jobFile, e.code.name);
      return true;
    } catch (e, stackTrace) {
      stderr.writeln('KarigarKart AI background error: $e');
      stderr.writeln(stackTrace);
      await _writeError(jobFile, 'aiUnknown');
      return true;
    }
  }

  static Future<bool> _saveEnhancedImage(File jobFile, Map<String, dynamic>? job, String imagePath, List<int> bytes, String preset) async {
    final originalFile = File(imagePath);
    final baseName = _baseName(originalFile.path);
    final extension = preset == 'Transparent PNG' ? 'png' : 'jpg';
    final enhancedPath = '${originalFile.parent.path}/${baseName}_enhanced.$extension';
    await _writeState(jobFile, {...(job ?? <String, dynamic>{}), 'status': 'processing', 'progress': 0.78, 'updatedAt': DateTime.now().toIso8601String()});
    await File(enhancedPath).writeAsBytes(bytes, flush: true);
    final prepared = await _validateOutputImage(enhancedPath);
    if (!prepared) { await _deleteIfExists(File(enhancedPath)); await _writeError(jobFile, 'unsupportedImage'); return true; }
    await _writeState(jobFile, {...(job ?? <String, dynamic>{}), 'status': 'success', 'progress': 1.0, 'enhancedPath': enhancedPath, 'studioPreset': preset, 'errorCode': null, 'updatedAt': DateTime.now().toIso8601String()});
    return true;
  }

  static Future<bool> _validateOutputImage(String path) async {
    try {
      final file = File(path);
      if (!await file.exists() || await file.length() == 0) return false;
      final bytes = await file.readAsBytes();
      final isJpeg = bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
      final isPng = bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 && bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A;
      return isJpeg || isPng;
    } catch (_) { return false; }
  }

  static bool _isRetryableStatus(int status) => status == 408 || status == 425 || status == 429 || status >= 500;

  static String _classifyServerError(int status, String body) {
    final lower = body.toLowerCase();
    if (status == 413 || lower.contains('too large') || lower.contains('payload')) return 'imageTooLarge';
    if (status == 415 || lower.contains('unsupported') || lower.contains('format')) return 'unsupportedImage';
    if (lower.contains('blur') || lower.contains('blurry') || lower.contains('sharpness')) return 'imageBlurry';
    if (lower.contains('dark') || lower.contains('underexposed')) return 'imageTooDark';
    if (lower.contains('overexposed') || lower.contains('too bright')) return 'imageTooBright';
    if (lower.contains('subject') || (lower.contains('product') && lower.contains('detect'))) return 'subjectNotFound';
    if (status >= 500) return 'aiServerError';
    return 'aiUnknown';
  }

  static String _baseName(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static Future<void> _deleteIfExists(File file) async { try { if (await file.exists()) await file.delete(); } catch (_) {} }

  static Future<void> _writeError(File file, String code) async {
    Map<String, dynamic> current = <String, dynamic>{};
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) current = decoded;
      }
    } catch (_) {}
    await _writeState(file, {...current, 'status': 'error', 'progress': 0.0, 'errorCode': code, 'updatedAt': DateTime.now().toIso8601String()});
  }

  static Future<void> _writeState(File file, Map<String, dynamic> state) async => file.writeAsString(jsonEncode(state), flush: true);
}
