import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/app_state.dart';
import '../services/app_localization.dart';
import '../services/ai_background_service.dart';
import '../services/image_preprocessor.dart';
import '../widgets/ai_error_dialog.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../services/app_transitions.dart';
import 'camera_capture_screen.dart';
import 'ai_flow_screens.dart';

String _tr(BuildContext context, String key) {
  return AppLocalization.text(
    AppScope.of(context).language,
    key,
  );
}


class VoiceDraft {
  static String text = '';
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _restoredPendingJob = false;
  bool _preparingImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_selectedImage == null) {
      final savedPath = AppScope.of(context).draftImagePath;

      if (savedPath != null && savedPath.isNotEmpty) {
        _selectedImage = XFile(savedPath);
      }
    }

    if (!_restoredPendingJob) {
      _restoredPendingJob = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restorePendingJob();
      });
    }
  }

  Future<void> _restorePendingJob() async {
    final jobPath = await AiBackgroundService.findLatestPendingJob();
    if (!mounted || jobPath == null) return;

    final job = await AiBackgroundService.readJob(jobPath);
    if (!mounted || job == null) return;

    final imagePath = job['imagePath']?.toString();
    if (imagePath == null || imagePath.isEmpty) return;

    final imageFile = File(imagePath);
    if (!await imageFile.exists() || !mounted) return;

    AppScope.of(context).setDraftImage(imagePath);
    setState(() {
      _selectedImage = XFile(imagePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          _tr(context, 'addProductTitle'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Text(
            _tr(context, 'step1Photo'),
            style: TextStyle(
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _tr(context, 'startWithPhoto'),
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.forest,
                  Color(0xFF4D8B76),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'aiPoweredListing'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tr(context, 'aiHelpCraft'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            _tr(context, 'takePhoto'),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tr(context, 'placeProductGoodLight'),
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),

          _PickOption(
            icon: Icons.camera_alt_rounded,
            iconBackground: const Color(0xFFFFE7D4),
            iconColor: AppColors.clay,
            title: _tr(context, 'snapPhoto'),
            subtitle: _tr(context, 'useCameraCapture'),
            tag: _tr(context, 'step1'),
            onTap: () => _openCustomCamera(_tr(context, 'camera')),
          ),

          _PickOption(
            icon: Icons.photo_library_outlined,
            iconBackground: const Color(0xFFE5F0EB),
            iconColor: AppColors.forest,
            title: _tr(context, 'choosePhoto'),
            subtitle: _tr(context, 'useExistingPhoto'),
            tag: _tr(context, 'alternative'),
            onTap: () => _pickImage(ImageSource.gallery, _tr(context, 'gallery')),
          ),

          const SizedBox(height: 18),

          _StudioSettingsCard(
            preset: AppScope.of(context).studioPreset,
            aspectRatio: AppScope.of(context).studioAspectRatio,
            onPresetChanged: (value) {
              AppScope.of(context).setStudioSettings(preset: value);
            },
            onAspectRatioChanged: (value) {
              AppScope.of(context).setStudioSettings(aspectRatio: value);
            },
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.outline.withOpacity(0.16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.tips_and_updates_outlined,
                    color: AppColors.clay,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'betterResults'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tr(context, 'naturalLightTip'),
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomCamera(String sourceName) async {
    if (_preparingImage) return;

    final captured = await Navigator.push<XFile?>(
      context,
      KarigarDetailRoute(
        builder: (_) => CameraCaptureScreen(
          title: _tr(context, 'camera'),
          guideText: _tr(context, 'placeProductGoodLight'),
        ),
      ),
    );

    if (!mounted || captured == null) return;

    await _prepareSelectedImage(captured, sourceName);
  }

  Future<void> _prepareSelectedImage(
      XFile image,
      String sourceName,
      ) async {
    if (_preparingImage) return;

    setState(() {
      _preparingImage = true;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _tr(dialogContext, 'photoPreparing'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final prepared = await ImagePreprocessor.prepare(image.path);

      if (!mounted) return;

      setState(() {
        _selectedImage = XFile(prepared.path);
      });

      AppScope.of(context).setDraftImage(prepared.path);

      if (!mounted) return;

      Navigator.of(context).pop();
      setState(() {
        _preparingImage = false;
      });
      _showPhotoSelected(sourceName);
    } on ImagePreparationException catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();
      setState(() {
        _preparingImage = false;
      });

      await AiErrorDialog.show(
        context,
        code: e.code.name,
      );
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context).pop();
      setState(() {
        _preparingImage = false;
      });

      await AiErrorDialog.show(
        context,
        code: 'aiUnknown',
      );
    }
  }

  Future<void> _pickImage(
      ImageSource source,
      String sourceName,
      ) async {
    if (_preparingImage) return;

    final image = await _picker.pickImage(source: source);

    if (image == null || !mounted) return;

    await _prepareSelectedImage(image, sourceName);
  }

  void _showPhotoSelected(String source) {
    final colors = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.forest.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.forest,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$source ${_tr(context, 'photoSelected')}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _tr(context, 'photoReady'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.onSurface,
                      foregroundColor: colors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      if (_selectedImage == null) return;

                      AppScope.of(context).setDraftImage(
                        _selectedImage!.path,
                      );

                      Navigator.pop(sheetContext);

                      if (!mounted) return;

                      Navigator.push(
                        context,
                        KarigarPageRoute(
                          builder: (_) => const LanguageScreen(
                            voiceFlow: true,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _tr(context, 'continue'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 19,
                          color: colors.surface,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _StudioSettingsCard extends StatelessWidget {
  const _StudioSettingsCard({
    required this.preset,
    required this.aspectRatio,
    required this.onPresetChanged,
    required this.onAspectRatioChanged,
  });

  final String preset;
  final String aspectRatio;
  final ValueChanged<String> onPresetChanged;
  final ValueChanged<String> onAspectRatioChanged;

  static const _presets = [
    'Pure White',
    'Warm Wood',
    'Neutral Studio',
    'Transparent PNG',
  ];

  static const _ratios = ['1:1', '4:5'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outline.withOpacity(.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr(context, 'studioPresetTitle'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _tr(context, 'studioPresetSubtitle'),
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _presets.map((item) {
                final selected = item == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: selected,
                    onSelected: (_) => onPresetChanged(item),
                    selectedColor: AppColors.forest.withOpacity(.14),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.forest
                          : colors.onSurface,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.forest.withOpacity(.35)
                          : colors.outline.withOpacity(.16),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _tr(context, 'studioAspectRatio'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _ratios.map((item) {
              final selected = item == aspectRatio;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: item == _ratios.first ? 8 : 0,
                  ),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: selected,
                    onSelected: (_) => onAspectRatioChanged(item),
                    selectedColor: AppColors.clay.withOpacity(.14),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? AppColors.clay
                          : colors.onSurface,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.clay.withOpacity(.35)
                          : colors.outline.withOpacity(.16),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PickOption extends StatelessWidget {
  const _PickOption({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tag,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.outline.withOpacity(0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          if (tag != null) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.saffron.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag!,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.clay,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// REAL SPEECH-TO-TEXT VOICE SCREEN
// ============================================================================

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() =>
      _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  // FIX #3/#6/#7: Single shared TTS instance so stop() actually stops the
  // same object that is speaking.
  final FlutterTts _tts = FlutterTts();

  bool _available = false;
  bool _recording = false;
  bool _finished = false;
  bool _playing = false;

  int _seconds = 0;
  Timer? _timer;

  String _recognizedText = '';
  String _errorMessage = '';

  late final AnimationController _pulseController;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // FIX #7: Use completion handler instead of a fragile manual delay.
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _playing = false;
      });
    });

    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;

        _timer?.cancel();

        setState(() {
          _recording = false;
          _finished = _recognizedText.trim().isNotEmpty;
          _errorMessage = error.errorMsg;
        });

        _pulseController.stop();
      },
      onStatus: (status) {
        if (!mounted) return;

        if (status == 'done' || status == 'notListening') {
          _timer?.cancel();

          setState(() {
            _recording = false;
            _finished = _recognizedText.trim().isNotEmpty;
          });

          _pulseController.stop();
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _available = available;

      if (!available) {
        _errorMessage = _tr(context, 'speechUnavailable');
      }
    });
  }

  Future<String?> _findLocaleId(String language) async {
    try {
      final locales = await _speech.locales();

      final prefix = switch (language) {
        'हिंदी' => 'hi',
        'বাংলা' => 'bn',
        'தமிழ்' => 'ta',
        'తెలుగు' => 'te',
        'मराठी' => 'mr',
        'ગુજરાતી' => 'gu',
        'ಕನ್ನಡ' => 'kn',
        _ => 'en',
      };

      for (final locale in locales) {
        if (locale.localeId.toLowerCase().startsWith(prefix)) {
          return locale.localeId;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _startListening() async {
    if (_recording) return;

    if (!_available) {
      await _initializeSpeech();
      if (!_available || !mounted) return;
    }

    setState(() {
      _recording = true;
      _finished = false;
      _seconds = 0;
      _recognizedText = '';
      _errorMessage = '';
      _playing = false;
    });

    _pulseController.repeat(reverse: true);
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!mounted || !_recording) return;

        setState(() {
          _seconds++;
        });
      },
    );

    final language = AppScope.of(context).language;
    final localeId = await _findLocaleId(language);

    try {
      await _speech.listen(
        localeId: localeId,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            _recognizedText = result.recognizedWords;
            _finished = _recognizedText.trim().isNotEmpty;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;

      _timer?.cancel();
      _pulseController.stop();

      setState(() {
        _recording = false;
        _errorMessage = _tr(context, 'couldNotStartMicrophone');
      });
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (!mounted) return;

    _timer?.cancel();
    _pulseController.stop();

    setState(() {
      _recording = false;
      _finished = _recognizedText.trim().isNotEmpty;
    });
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _listenToRecognizedText() async {
    final text = _recognizedText.trim();

    if (text.isEmpty) return;

    // FIX #3/#6: Use the shared _tts instance so stop() works correctly.
    if (_playing) {
      await _tts.stop();

      if (!mounted) return;

      setState(() {
        _playing = false;
      });

      return;
    }

    final language = AppScope.of(context).language;

    try {
      final locale = switch (language) {
        'हिंदी' => 'hi-IN',
        'বাংলা' => 'bn-IN',
        'தமிழ்' => 'ta-IN',
        'తెలుగు' => 'te-IN',
        'मराठी' => 'mr-IN',
        'ગુજરાતી' => 'gu-IN',
        'ಕನ್ನಡ' => 'kn-IN',
        _ => 'en-IN',
      };

      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(.46);
      await _tts.setPitch(1.0);

      setState(() {
        _playing = true;
      });

      // FIX #7: _tts.setCompletionHandler in initState handles resetting
      // _playing — no fragile manual delay needed here.
      await _tts.speak(text);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _playing = false;
      });
    }
  }

  void _reRecord() {
    _timer?.cancel();
    _speech.stop();
    _tts.stop();
    _pulseController.stop();

    setState(() {
      _recording = false;
      _finished = false;
      _seconds = 0;
      _recognizedText = '';
      _errorMessage = '';
      _playing = false;
    });
  }

  void _useDescription() {
    final text = _recognizedText.trim();

    if (text.isEmpty) {
      setState(() {
        _errorMessage = _tr(context, 'speakMomentFirst');
      });
      return;
    }

    VoiceDraft.text = text;

    Navigator.pushNamed(
      context,
      '/processing',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    _tts.stop();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _formatDuration() {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          _tr(context, 'describeByVoice'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            children: [
              Text(
                _recording
                    ? _tr(context, 'listening')
                    : _finished
                    ? _tr(context, 'voiceNoteReady')
                    : _tr(context, 'voiceRecorderTitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tr(context, 'voiceRecorderSubtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (_recording || _seconds > 0)
                _VoiceWaveform(
                  active: _recording,
                  level: _recording ? 1 : .35,
                  animation: _waveController,
                ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 95,
                  maxHeight: 155,
                ),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _recording
                        ? AppColors.clay.withOpacity(.35)
                        : colors.outline.withOpacity(.16),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _recognizedText.trim().isEmpty
                              ? _tr(
                            context,
                            'voiceOrTypeDescription',
                          )
                              : _recognizedText,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: _recognizedText.trim().isEmpty
                                ? colors.onSurfaceVariant
                                : colors.onSurface,
                          ),
                        ),
                      ),
                      if (_recognizedText.trim().isNotEmpty)
                        IconButton(
                          tooltip: _tr(
                            context,
                            'speakRegionalText',
                          ),
                          onPressed: _listenToRecognizedText,
                          icon: Icon(
                            _playing
                                ? Icons.volume_up_rounded
                                : Icons.volume_down_rounded,
                            color: AppColors.forest,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.redAccent,
                  ),
                ),
              ],
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulse =
                  _recording ? .93 + (_pulseController.value * .14) : 1.0;

                  return Transform.scale(
                    scale: pulse,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _recording
                          ? AppColors.clay.withOpacity(.16)
                          : AppColors.saffron.withOpacity(.13),
                      border: Border.all(
                        color: _recording
                            ? AppColors.clay.withOpacity(.30)
                            : AppColors.saffron.withOpacity(.28),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _recording
                              ? AppColors.clay
                              : colors.surface,
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withOpacity(.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _recording
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          size: 52,
                          color: _recording
                              ? Colors.white
                              : AppColors.clay,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDuration(),
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _recording
                    ? _tr(context, 'stopRecording')
                    : _tr(context, 'tapToSpeak'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _finished ? _reRecord : null,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(_tr(context, 'reRecord')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        side: BorderSide(
                          color: AppColors.forest.withOpacity(.30),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _finished ? _listenToRecognizedText : null,
                      icon: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.headphones_rounded,
                      ),
                      label: Text(
                        _playing
                            ? _tr(context, 'pauseListen')
                            : _tr(context, 'listen'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        side: BorderSide(
                          color: AppColors.forest.withOpacity(.30),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _finished ? _useDescription : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    disabledBackgroundColor:
                    AppColors.forest.withOpacity(.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    // FIX: was missing const here (minor lint warning)
                    'useVoiceNote',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceWaveform extends StatelessWidget {
  const _VoiceWaveform({
    required this.active,
    required this.level,
    required this.animation,
  });

  final bool active;
  final double level;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _WaveformPainter(
              active: active,
              level: level,
              phase: animation.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.active,
    required this.level,
    required this.phase,
  });

  final bool active;
  final double level;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active
          ? AppColors.clay
          : AppColors.forest.withOpacity(.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const bars = 32;
    final gap = size.width / bars;

    for (var i = 0; i < bars; i++) {
      final normalized = i / (bars - 1);
      // FIX #4/#5: math.sin / math.pi / math.max now work with dart:math import
      final wave =
          .35 + (.65 * math.sin((normalized * math.pi * 4) + phase * math.pi * 2).abs());
      final height = 7 + (22 * level * wave);

      final x = (i + .5) * gap;
      final center = size.height / 2;

      canvas.drawLine(
        Offset(x, center - height / 2),
        Offset(x, center + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.active != active ||
        oldDelegate.level != level ||
        oldDelegate.phase != phase;
  }
}