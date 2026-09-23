import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalLogger {
  LocalLogger._();

  static File? _file;
  static Future<void>? _initializing;
  static const int _maxBytes = 2 * 1024 * 1024;

  static Future<void> initialize() async {
    if (_file != null) return;
    _initializing ??= _init();
    await _initializing;
  }

  static Future<void> _init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logs = Directory('${directory.path}/karigarkart_logs');
      await logs.create(recursive: true);
      _file = File('${logs.path}/app.log');
    } catch (_) {}
  }

  static Future<void> error(Object error, StackTrace stackTrace, {String source = 'unknown'}) async {
    await initialize();
    final file = _file;
    if (file == null) return;

    final record = jsonEncode(<String, dynamic>{
      'time': DateTime.now().toIso8601String(),
      'level': 'error',
      'source': source,
      'error': error.toString(),
      'stack': stackTrace.toString(),
    });

    try {
      await file.writeAsString('$record\n', mode: FileMode.append, flush: true);
      if (await file.length() > _maxBytes) {
        final contents = await file.readAsString();
        final keepFrom = contents.length ~/ 2;
        await file.writeAsString(contents.substring(keepFrom), flush: true);
      }
    } catch (_) {}
  }

  static Future<void> info(String message, {String source = 'app'}) async {
    await initialize();
    final file = _file;
    if (file == null) return;
    try {
      await file.writeAsString(
        '${jsonEncode(<String, dynamic>{'time': DateTime.now().toIso8601String(), 'level': 'info', 'source': source, 'message': message})}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  /// This is intentionally a transport-neutral boundary. Firebase Crashlytics
  /// or Sentry can later be added here without changing call sites.
  static Future<void> reportToRemote(Object error, StackTrace stackTrace, {String source = 'unknown'}) async {
    await LocalLogger.error(error, stackTrace, source: source);
  }
}
