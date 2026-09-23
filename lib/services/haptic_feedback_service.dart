import 'package:flutter/services.dart';

class KarigarKartHaptics {
  KarigarKartHaptics._();

  static Future<void> recordingStarted() => HapticFeedback.mediumImpact();
  static Future<void> recordingStopped() => HapticFeedback.lightImpact();
  static Future<void> aiSuccess() => HapticFeedback.mediumImpact();
  static Future<void> aiFailure() => HapticFeedback.heavyImpact();
  static Future<void> selection() => HapticFeedback.selectionClick();
}
