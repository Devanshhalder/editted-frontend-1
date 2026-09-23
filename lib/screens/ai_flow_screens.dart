
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart' as record;
import 'package:flutter_tts/flutter_tts.dart';

import '../services/app_state.dart';
import '../services/ai_background_service.dart';
import '../widgets/ai_error_dialog.dart';
import '../services/app_localization.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../services/app_transitions.dart';
import '../services/offline_request_queue.dart';

String get _apiBaseUrl =>
    'http://10.70.33.153:8000';

Color _background(BuildContext context) {
  return Theme.of(context).scaffoldBackgroundColor;
}

Color _surface(BuildContext context) {
  return Theme.of(context).colorScheme.surface;
}

Color _text(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface;
}

Color _muted(BuildContext context) {
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

Color _outline(BuildContext context) {
  return Theme.of(context).colorScheme.outline;
}

String _tr(BuildContext context, String key) {
  return AppLocalization.text(
    AppScope.of(context).language,
    key,
  );
}


class LanguageScreen extends StatefulWidget {
  const LanguageScreen({
    super.key,
    this.voiceFlow = false,
  });

  final bool voiceFlow;

  static const languages = [
    'English',
    'हिंदी',
    'বাংলা',
    'தமிழ்',
    'తెలుగు',
    'मराठी',
    'ગુજરાતી',
    'ಕನ್ನಡ',
  ];

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  bool _changing = false;

  String _languageNameKey(String language) {
    switch (language) {
      case 'English':
        return 'english';
      case 'हिंदी':
        return 'hindi';
      case 'বাংলা':
        return 'bengali';
      case 'தமிழ்':
        return 'tamil';
      case 'తెలుగు':
        return 'telugu';
      case 'मराठी':
        return 'marathi';
      case 'ગુજરાતી':
        return 'gujarati';
      case 'ಕನ್ನಡ':
        return 'kannada';
      default:
        return 'english';
    }
  }

  String _languageSymbol(String language) {
    switch (language) {
      case 'English':
        return 'A';
      case 'हिंदी':
        return 'अ';
      case 'বাংলা':
        return 'ব';
      case 'தமிழ்':
        return 'த';
      case 'తెలుగు':
        return 'తె';
      case 'मराठी':
        return 'म';
      case 'ગુજરાતી':
        return 'ગ';
      case 'ಕನ್ನಡ':
        return 'ಕ';
      default:
        return 'A';
    }
  }

  String _translatedLanguageName(
      String currentLanguage,
      String language,
      ) {
    return AppLocalization.text(
      currentLanguage,
      _languageNameKey(language),
    );
  }

  Future<void> _selectLanguage(
      BuildContext context,
      String language,
      ) async {
    final state = AppScope.of(context);

    if (_changing || state.language == language) {
      return;
    }

    setState(() {
      _changing = true;
    });

    await state.setLanguage(language);

    if (!mounted) return;

    setState(() {
      _changing = false;
    });

// Do not navigate here. Language selection only changes the app language.
// The bottom button decides whether this is a settings flow or a creation flow.
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final currentLanguage = state.language;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _background(context),
          appBar: AppBar(
            backgroundColor: _background(context),
            elevation: 0,
            title: Text(
              AppLocalization.text(
                currentLanguage,
                'selectLanguage',
              ),
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _text(context),
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLanguage == 'English'
                          ? _tr(context, 'languageVoiceTitle')
                          : AppLocalization.text(
                        currentLanguage,
                        'selectLanguage',
                      ),
                      style: TextStyle(
                        fontSize: 27,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: _text(context),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _tr(context, 'languageChoiceDescription'),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: _muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.forest.withOpacity(.09),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.forest,
                        size: 22,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          _tr(context, 'languageVoiceIntro'),
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: _text(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: LanguageScreen.languages.length,
                  itemBuilder: (context, index) {
                    final language = LanguageScreen.languages[index];
                    final selected = currentLanguage == language;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _LanguageTile(
                        language: language,
                        subtitle: _translatedLanguageName(
                          currentLanguage,
                          language,
                        ),
                        symbol: _languageSymbol(language),
                        selected: selected,
                        enabled: !_changing,
                        onTap: () => _selectLanguage(
                          context,
                          language,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: _background(context),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(.045),
                      blurRadius: 14,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: _PressButton(
                      onTap: _changing
                          ? () {}
                          : () {
                        if (widget.voiceFlow) {
                          Navigator.push(
                            context,
                            KarigarPageRoute(
                              builder: (_) =>
                              const VoiceRecordingScreen(),
                            ),
                          );
                        } else {
// Dashboard/settings language picker:
// save the language and simply return.
                          Navigator.pop(context);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.voiceFlow
                                ? (_tr(context, 'continueToRecording'))
                                : (_tr(context, 'done')),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white, // FIX: Changes text color to white
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                            color: Colors.white, // FIX: Changes arrow icon color to white
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

// Language-switch loading animation.
        IgnorePointer(
          ignoring: !_changing,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _changing ? 1 : 0,
            child: Container(
              color: _outline(context).withOpacity(.35),
              alignment: Alignment.center,
              child: AnimatedScale(
                scale: _changing ? 1 : .92,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 176,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: _surface(context),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        AppLocalization.text(
                          currentLanguage,
                          'loading',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _text(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.subtitle,
    required this.symbol,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String language;
  final String subtitle;
  final String symbol;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface(context),
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(19),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: selected
                  ? AppColors.forest
                  : Colors.black.withOpacity(.055),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(
                  selected ? .055 : .025,
                ),
                blurRadius: selected ? 14 : 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.forest
                      : AppColors.saffron.withOpacity(.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.white
                        : AppColors.clay,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _text(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: _muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.forest
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.forest
                        : Colors.black.withOpacity(.16),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VoiceDraft {
  static String text = '';
}

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  final record.AudioRecorder _recorder = record.AudioRecorder();
  final TextEditingController _manualTextController =
  TextEditingController();

  StreamSubscription<record.Amplitude>? _amplitudeSubscription;
  Timer? _timer;

  bool _recording = false;
  bool _transcribing = false;
  bool _useVoice = true;
  bool _movingForward = false;
  bool _hasPermission = false;

  int _seconds = 0;
  double _level = 0.08;
  String? _audioPath;
  String _status = '';


  @override
  void initState() {
    super.initState();
    _checkMicrophonePermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // AppScope is an inherited widget. It is safe to read it here because
    // Flutter has finished establishing this State object's dependencies.
    // Never read AppScope/localization from initState().
    if (!_recording && !_transcribing && _status.isEmpty) {
      _status = _tr(context, 'tapMicStart');
    }
  }

  Future<void> _checkMicrophonePermission() async {
    try {
      final granted = await _recorder.hasPermission();

      if (!mounted) return;

      setState(() {
        _hasPermission = granted;
        _status = granted
            ? _tr(context, 'tapMicStart')
            : _tr(context, 'micPermissionUnavailable');
      });
    } catch (e) {
      debugPrint('RECORDER PERMISSION ERROR: $e');

      if (!mounted) return;

      setState(() {
        _hasPermission = false;
        _status = _tr(context, 'micUnavailableType');
      });
    }
  }

  Future<void> _startRecording() async {
    if (_recording || _transcribing) return;

    try {
      final granted = await _recorder.hasPermission();

      if (!granted) {
        if (!mounted) return;

        setState(() {
          _hasPermission = false;
          _status =
              _tr(context, 'micPermissionPleaseText');
        });
        return;
      }

      final fileName =
          'karigarkart_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path =
          '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName';

      await _recorder.start(
        const record.RecordConfig(
          encoder: record.AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 64000,
        ),
        path: path,
      );

      _audioPath = path;
      _seconds = 0;
      _level = 0.08;

      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
            (_) {
          if (!mounted || !_recording) return;
          setState(() => _seconds++);
        },
      );

      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amplitude) {
        if (!mounted || !_recording) return;

// record reports amplitude in dB. Convert it to a stable 0..1
// value for the visual waveform.
        final normalized =
        ((amplitude.current + 60) / 60).clamp(0.05, 1.0).toDouble();

        setState(() {
          _level = normalized;
        });
      });

      if (!mounted) return;

      if (!mounted) return;

      final language = AppScope.of(context).language;

      setState(() {
        _recording = true;
        _status = 'Listening… speak naturally in $language.';
      });
    } catch (e, stackTrace) {
      debugPrint('AUDIO RECORD START ERROR: $e');
      debugPrint('AUDIO RECORD START STACK: $stackTrace');

      _timer?.cancel();
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      if (!mounted) return;

      setState(() {
        _recording = false;
        _status =
            _tr(context, 'couldNotStartRecording');
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;

    _timer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    try {
      final savedPath = await _recorder.stop();

      if (!mounted) return;

      setState(() {
        _recording = false;
        _level = 0.08;
        _audioPath = savedPath ?? _audioPath;
        _status = _audioPath != null
            ? _tr(context, 'recordingCaptured')
            : _tr(context, 'noRecordingCaptured');
      });
    } catch (e, stackTrace) {
      debugPrint('AUDIO RECORD STOP ERROR: $e');
      debugPrint('AUDIO RECORD STOP STACK: $stackTrace');

      if (!mounted) return;

      setState(() {
        _recording = false;
        _level = 0.08;
        _status =
            _tr(context, 'recordingNotSaved');
      });
    }
  }

  Future<String?> _transcribeAudio(String path) async {
    final language = AppScope.of(context).language;

    try {
      final file = File(path);

      if (!await file.exists()) {
        throw Exception(_tr(context, 'recordedFileNotFound'));
      }

      final length = await file.length();

      if (length == 0) {
        throw Exception(_tr(context, 'recordedFileEmpty'));
      }

      final uri = Uri.parse(
        '$_apiBaseUrl/ai/transcribe?language=${Uri.encodeComponent(language)}',
      );

      debugPrint('AI TRANSCRIBE REQUEST: POST $uri');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          path,
          filename: 'karigarkart_voice.m4a',
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        'AI TRANSCRIBE RESPONSE: ${response.statusCode}',
      );
      debugPrint(
        'AI TRANSCRIBE BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        String detail = _tr(context, 'speechTranscriptionFailed');

        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody['detail'] != null) {
            detail = errorBody['detail'].toString();
          }
        } catch (_) {}

        throw Exception(detail);
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic> ||
          decoded['success'] != true ||
          decoded['text'] == null) {
        throw Exception(_tr(context, 'transcriptionInvalid'));
      }

      final transcript = decoded['text'].toString().trim();

      if (transcript.isEmpty) {
        throw Exception(_tr(context, 'transcriptionEmpty'));
      }

      return transcript;
    } catch (e, stackTrace) {
      debugPrint('AI TRANSCRIBE ERROR: $e');
      debugPrint('AI TRANSCRIBE STACK: $stackTrace');
      return null;
    }
  }

  Future<void> _continue() async {
    if (_movingForward || _recording || _transcribing) return;

    final typedText = _manualTextController.text.trim();

    if (!_useVoice) {
      if (typedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(_tr(context, 'typeSomethingFirst')),
          ),
        );
        return;
      }

      VoiceDraft.text = typedText;
      _movingForward = true;

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/processing');
      return;
    }

    if (_audioPath == null || _audioPath!.isEmpty) {
// If the artisan switched from voice to text after recording was
// unavailable, the typed text remains a safe fallback.
      if (typedText.isNotEmpty) {
        VoiceDraft.text = typedText;
        _movingForward = true;

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/processing');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _tr(context, 'recordOrSwitch'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _transcribing = true;
      _status = _tr(context, 'transcribing');
    });

    final transcript = await _transcribeAudio(_audioPath!);

    if (!mounted) return;

    if (transcript == null || transcript.trim().isEmpty) {
      setState(() {
        _transcribing = false;
        _status =
            _tr(context, 'couldNotTranscribe');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _tr(context, 'voiceTranscriptionFailed'),
          ),
        ),
      );
      return;
    }

    VoiceDraft.text = transcript.trim();

    setState(() {
      _transcribing = false;
      _movingForward = true;
      _status = _tr(context, 'gotItPreparing');
    });

    Navigator.pushReplacementNamed(context, '/processing');
  }

  void _switchMode(bool voice) {
    if (_recording || _transcribing) return;

    setState(() {
      _useVoice = voice;
      _status = voice
          ? _hasPermission
          ? _tr(context, 'tapMicStart')
          : _tr(context, 'micStillTryVoice')
          : _tr(context, 'typeNaturallyAI');
    });
  }

  void _clearRecording() {
    final path = _audioPath;

    setState(() {
      _audioPath = null;
      _seconds = 0;
      _level = 0.08;
      _status = _useVoice
          ? _tr(context, 'tapMicStart')
          : _tr(context, 'typeNaturallyAI');
    });

    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        file.delete().catchError((_) => file);
      }
    }
  }

  String _formatTime() {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _manualTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).language;

    return Scaffold(
      backgroundColor: _background(context),
      appBar: AppBar(
        backgroundColor: _background(context),
        elevation: 0,
        title: Text(
          _tr(context, 'productDescription'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _text(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text(
                    _tr(context, 'tellUsProduct'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: _text(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tr(context, 'voiceOrTypeDescription'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: _muted(context),
                    ),
                  ),
                  const SizedBox(height: 20),

// Voice / text mode selector.
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _outline(context).withOpacity(.20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeButton(
                            selected: _useVoice,
                            icon: Icons.mic_rounded,
                            label: _tr(context, 'voice'),
                            onTap: () => _switchMode(true),
                          ),
                        ),
                        Expanded(
                          child: _ModeButton(
                            selected: !_useVoice,
                            icon: Icons.keyboard_rounded,
                            label: _tr(context, 'typeInstead'),
                            onTap: () => _switchMode(false),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  if (_useVoice) ...[
                    Center(
                      child: GestureDetector(
                        onTap: _recording
                            ? _stopRecording
                            : _startRecording,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: _recording ? 178 : 164,
                          height: _recording ? 178 : 164,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _recording
                                ? AppColors.clay.withOpacity(.14)
                                : AppColors.saffron.withOpacity(.14),
                            border: Border.all(
                              color: _recording
                                  ? AppColors.clay
                                  : AppColors.saffron,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_recording
                                    ? AppColors.clay
                                    : AppColors.saffron)
                                    .withOpacity(.16),
                                blurRadius: 24,
                                spreadRadius: _recording ? 5 : 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: _recording ? 124 : 114,
                              height: _recording ? 124 : 114,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _recording
                                    ? AppColors.clay
                                    : AppColors.ink,
                              ),
                              child: Icon(
                                _recording
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Center(
                      child: Text(
                        _recording
                            ? _tr(context, 'tapStop') + ' • ' + _formatTime()
                            : _audioPath != null
                            ? _tr(context, 'recordingReady')
                            : _hasPermission
                            ? _tr(context, 'tapStartRecording')
                            : _tr(context, 'microphoneUnavailable'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _recording
                              ? AppColors.clay
                              : AppColors.muted,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

// Live amplitude waveform.
                    Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _surface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _outline(context).withOpacity(.18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(28, (index) {
                          final centerDistance =
                              (index - 13.5).abs() / 13.5;
                          final variation =
                          (1 - centerDistance * .45).clamp(.45, 1.0);
                          final height = 8 +
                              (_level * 46 * variation) *
                                  (index.isEven ? .9 : 1.0);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 110),
                            width: 4,
                            height: height,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _recording
                                  ? AppColors.clay
                                  : AppColors.forest.withOpacity(.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: _muted(context),
                      ),
                    ),

                    if (_audioPath != null && !_recording) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _transcribing ? null : _clearRecording,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: Text(_tr(context, 'recordAgain')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.shadow.withOpacity(.10),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _outline(context).withOpacity(.20),
                        ),
                      ),
                      child: TextField(
                        controller: _manualTextController,
                        minLines: 7,
                        maxLines: 10,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _tr(context, 'exampleCraft'),
                          hintStyle: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: _muted(context),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: _text(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 17,
                          color: AppColors.forest,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _tr(context, 'noSpecialFormat'),
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.45,
                              color: _muted(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: _background(context),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(.045),
                    blurRadius: 14,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: _PressButton(
                    onTap: _continue,
                    child: _transcribing
                        ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                        AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _tr(context, 'createMyListing'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 9),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.forest.withOpacity(.11)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.forest : AppColors.muted,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.forest : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  double value = 0.05;
  String status = '';

  Timer? _pollTimer;
  late final AnimationController _spinController;

  String? _jobPath;
  String? _imagePath;
  bool _started = false;
  bool _showingError = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startOrResume();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (status.isEmpty) {
      status = _tr(context, 'preparingPhoto');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _pollNow();
    }
  }

  Future<void> _startOrResume() async {
    if (_started) return;
    _started = true;

    final appState = AppScope.of(context);
    var imagePath = appState.draftImagePath;

    // If Android recreated the Flutter activity/process, recover the latest
    // app-owned image from the persisted job file.
    if (imagePath == null || imagePath.isEmpty) {
      final pending = await AiBackgroundService.findLatestPendingJob();
      if (!mounted) return;

      if (pending != null) {
        final recovered = await AiBackgroundService.readJob(pending);
        if (!mounted) return;

        final recoveredImage = recovered?['imagePath']?.toString();
        if (recoveredImage != null && recoveredImage.isNotEmpty) {
          imagePath = recoveredImage;
          appState.setDraftImage(recoveredImage);
        }
      }
    }

    if (imagePath == null || imagePath.isEmpty) {
      await _showError('imageMissing');
      return;
    }

    _imagePath = imagePath;
    _jobPath = '$imagePath.job.json';

    var job = await AiBackgroundService.readJob(_jobPath!);

    if (job == null) {
      final studioState = AppScope.of(context);
      await AiBackgroundService.createJob(
        jobPath: _jobPath!,
        imagePath: imagePath,
        preset: studioState.studioPreset,
        aspectRatio: studioState.studioAspectRatio,
      );
      job = await AiBackgroundService.readJob(_jobPath!);
    }

    if (!mounted || job == null) return;

    final currentStatus = job['status']?.toString();

    if (currentStatus == 'success') {
      await _finish(job);
      return;
    }

    if (currentStatus == 'error') {
      await _showError(job['errorCode']?.toString() ?? 'aiUnknown');
      return;
    }

    // registerOneOffTask uses a stable unique name derived from the job path,
    // so calling enqueue again after a rebuild is safe with ExistingWorkPolicy.keep.
    if (AiBackgroundService.isBackgroundSupported) {
      await AiBackgroundService.enqueue(jobPath: _jobPath!);
    } else {
      // Windows/macOS development builds do not have Workmanager background
      // execution. Run the same persisted job in the current process there.
      unawaited(AiBackgroundService.runJob(_jobPath!));
    }

    if (!mounted) return;

    setState(() {
      value = (job?['progress'] as num?)?.toDouble() ?? .12;
      status = _tr(context, 'aiEnhancementInBackground');
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _pollNow(),
    );

    await _pollNow();
  }

  Future<void> _pollNow() async {
    final jobPath = _jobPath;
    if (jobPath == null || !mounted || _navigated) return;

    final job = await AiBackgroundService.readJob(jobPath);
    if (!mounted || job == null || _navigated) return;

    final jobStatus = job['status']?.toString();
    final progress = (job['progress'] as num?)?.toDouble() ?? value;

    if (jobStatus == 'success') {
      await _finish(job);
      return;
    }

    if (jobStatus == 'error') {
      _pollTimer?.cancel();
      await _showError(job['errorCode']?.toString() ?? 'aiUnknown');
      return;
    }

    setState(() {
      value = progress.clamp(.05, .92);
      status = progress < .30
          ? _tr(context, 'sendingPhotoAI')
          : progress < .75
          ? _tr(context, 'removingBackground')
          : _tr(context, 'finishingPhoto');
    });
  }

  Future<void> _finish(Map<String, dynamic> job) async {
    if (_navigated || !mounted) return;

    final imagePath = _imagePath ?? job['imagePath']?.toString();
    final enhancedPath = job['enhancedPath']?.toString();

    if (imagePath == null || imagePath.isEmpty ||
        enhancedPath == null || enhancedPath.isEmpty) {
      await _showError('aiServerError');
      return;
    }

    if (!await File(enhancedPath).exists()) {
      await _showError('aiServerError');
      return;
    }

    _navigated = true;
    _pollTimer?.cancel();

    setState(() {
      value = 1;
      status = _tr(context, 'aiEnhancedReady');
    });

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      KarigarPageRoute(
        builder: (_) => ImagePreviewScreen(
          originalImagePath: imagePath,
          enhancedImagePath: enhancedPath,
        ),
      ),
    );
  }

  Future<void> _showError(String code) async {
    if (!mounted || _showingError || _navigated) return;

    _showingError = true;
    _pollTimer?.cancel();

    setState(() {
      value = 0;
      status = _tr(context, 'couldNotEnhance');
    });

    await AiErrorDialog.show(
      context,
      code: code,
      onRetry: _retry,
    );

    if (!mounted) return;
    _showingError = false;
  }

  Future<void> _retry() async {
    final jobPath = _jobPath;
    if (jobPath == null || !mounted) return;

    final job = await AiBackgroundService.readJob(jobPath);
    if (!mounted || job == null) return;

    final imagePath = job['imagePath']?.toString();
    if (imagePath == null || imagePath.isEmpty) {
      await _showError('imageMissing');
      return;
    }

    final studioState = AppScope.of(context);
    await AiBackgroundService.createJob(
      jobPath: jobPath,
      imagePath: imagePath,
      preset: job['studioPreset']?.toString() ?? studioState.studioPreset,
      aspectRatio:
          job['studioAspectRatio']?.toString() ??
          studioState.studioAspectRatio,
    );

    if (AiBackgroundService.isBackgroundSupported) {
      await AiBackgroundService.enqueue(jobPath: jobPath);
    } else {
      unawaited(AiBackgroundService.runJob(jobPath));
    }

    if (!mounted) return;

    setState(() {
      value = .08;
      status = _tr(context, 'aiEnhancementInBackground');
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _pollNow(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _background(context),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 154,
                  height: 154,
                  child: AnimatedBuilder(
                    animation: _spinController,
                    builder: (context, child) {
                      final pulse =
                          .5 + (.5 * (1 + math.sin(_spinController.value * 2 * math.pi))) / 2;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 138,
                            height: 138,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.forest.withValues(alpha: .07),
                            ),
                          ),
                          Transform.rotate(
                            angle: _spinController.value * 6.2831853,
                            child: Container(
                              width: 118,
                              height: 118,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.forest.withValues(
                                    alpha: .12 + (.16 * pulse),
                                  ),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.forest.withValues(alpha: .11),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.forest.withValues(alpha: .10),
                                  blurRadius: 24 + (10 * pulse),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.forest,
                              size: 39,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  _tr(context, 'craftBeingPrepared'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: _text(context),
                  ),
                ),
                const SizedBox(height: 9),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    status,
                    key: ValueKey(status),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: _muted(context),
                    ),
                  ),
                ),
                const SizedBox(height: 23),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Container(
                        height: 9,
                        color: _outline(context).withValues(alpha: .11),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.forest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _muted(context),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _tr(context, 'aiEnhancementInBackground'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: _muted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({
    super.key,
    this.originalImagePath,
    this.enhancedImagePath,
  });

  final String? originalImagePath;
  final String? enhancedImagePath;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  String selectedImage = 'enhanced';
  bool _enhancedSaved = false;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    if (widget.enhancedImagePath == null ||
        widget.enhancedImagePath!.isEmpty) {
      selectedImage = 'original';
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectOriginal(AppState state) {
    final originalPath =
        widget.originalImagePath ?? state.draftImagePath;

    setState(() {
      selectedImage = 'original';
    });

    if (originalPath != null && originalPath.isNotEmpty) {
      state.setDraftImage(originalPath);
    }
  }

  void _selectEnhanced(AppState state) {
    final enhancedPath = widget.enhancedImagePath;

    setState(() {
      selectedImage = 'enhanced';
    });

    if (enhancedPath != null && enhancedPath.isNotEmpty) {
      state.setDraftImage(enhancedPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final imagePath = state.draftImagePath;
    final originalPath = widget.originalImagePath ?? imagePath;
    final enhancedPath = widget.enhancedImagePath;

    if (!_enhancedSaved &&
        enhancedPath != null &&
        enhancedPath.isNotEmpty) {
      _enhancedSaved = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          state.setDraftImage(enhancedPath);
        }
      });
    }

    return Scaffold(
      backgroundColor: _background(context),
      appBar: AppBar(
        backgroundColor: _background(context),
        elevation: 0,
        title: Text(
          _tr(context, 'aiPhotoEnhancement'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _text(context),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
        child: Column(
          children: [
            PageHeader(
              title: _tr(context, 'chooseBestPhoto'),
              subtitle: _tr(context, 'compareVersions'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                _tr(context, 'studioCompareHint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: _muted(context),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _BeforeAfterSlider(
                  originalPath: originalPath,
                  enhancedPath: enhancedPath,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _PreviewChoiceButton(
                      label: _tr(context, 'original'),
                      selected: selectedImage == 'original',
                      onTap: () => _selectOriginal(state),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PreviewChoiceButton(
                      label: _tr(context, 'aiEnhanced'),
                      selected: selectedImage == 'enhanced',
                      onTap: () => _selectEnhanced(state),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  Text(
                    selectedImage == 'original'
                        ? _tr(context, 'originalPhotoSelected')
                        : _tr(context, 'aiEnhancedPhotoSelected'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _muted(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: _PressButton(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/listing',
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            selectedImage == 'original'
                                ? _tr(context, 'useOriginalImage')
                                : _tr(context, 'useEnhancedImage'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeforeAfterSlider extends StatefulWidget {
  const _BeforeAfterSlider({
    required this.originalPath,
    required this.enhancedPath,
  });

  final String? originalPath;
  final String? enhancedPath;

  @override
  State<_BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<_BeforeAfterSlider> {
  double _position = .5;

  void _updatePosition(double width, double localDx) {
    if (width <= 0) return;

    setState(() {
      _position = (localDx / width).clamp(.06, .94);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) return;

            final local = renderBox.globalToLocal(
              details.globalPosition,
            );

            _updatePosition(
              renderBox.size.width,
              local.dx,
            );
          },
          onTapDown: (details) {
            _updatePosition(
              width,
              details.localPosition.dx,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _surface(context),
                border: Border.all(
                  color: _outline(context).withOpacity(.16),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.originalPath != null &&
                      widget.originalPath!.isNotEmpty)
                    Image.file(
                      File(widget.originalPath!),
                      fit: BoxFit.cover,
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: _muted(context),
                        size: 54,
                      ),
                    ),
                  if (widget.enhancedPath != null &&
                      widget.enhancedPath!.isNotEmpty)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: width * _position,
                      child: ClipRect(
                        child: Image.file(
                          File(widget.enhancedPath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _StudioImageBadge(
                      label: _tr(context, 'aiEnhanced'),
                      emphasized: true,
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _StudioImageBadge(
                      label: _tr(context, 'original'),
                      emphasized: false,
                    ),
                  ),
                  if (widget.enhancedPath != null &&
                      widget.enhancedPath!.isNotEmpty)
                    Positioned(
                      left: (width * _position).clamp(
                        2,
                        width - 2,
                      ) - 1.5,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 3,
                        color: Colors.white.withOpacity(.95),
                      ),
                    ),
                  if (widget.enhancedPath != null &&
                      widget.enhancedPath!.isNotEmpty)
                    Positioned(
                      left: (width * _position).clamp(
                        32,
                        width - 32,
                      ) - 22,
                      bottom: 18,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.48),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(.8),
                          ),
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PreviewChoiceButton extends StatelessWidget {
  const _PreviewChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.forest.withOpacity(.12)
          : _surface(context),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? AppColors.forest.withOpacity(.42)
                  : _outline(context).withOpacity(.18),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected
                  ? AppColors.forest
                  : _text(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudioImageBadge extends StatelessWidget {
  const _StudioImageBadge({
    required this.label,
    required this.emphasized,
  });

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.46),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: emphasized
              ? AppColors.saffron.withOpacity(.8)
              : Colors.white.withOpacity(.35),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Compare extends StatelessWidget {
  const _Compare({
    required this.label,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.imagePath,
    this.showAiBadge = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? imagePath;
  final bool showAiBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withOpacity(
                    selected ? .20 : .10,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected
                        ? AppColors.forest
                        : color.withOpacity(.35),
                    width: selected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: AppColors.forest.withOpacity(.12),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imagePath != null &&
                          imagePath!.isNotEmpty
                          ? Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                      )
                          : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              color: color,
                              size: 54,
                            ),
                            if (showAiBadge) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                  Colors.white.withOpacity(.90),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _tr(context, 'aiReady'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.forest,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected
                ? AppColors.forest
                : AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class ListingScreen extends StatefulWidget {
  const ListingScreen({super.key});

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen>
    with SingleTickerProviderStateMixin {
  final form = GlobalKey<FormState>();

  late TextEditingController title;
  late TextEditingController description;
  late TextEditingController price;

  String category = 'Textiles';

  bool _loadedDraft = false;
  bool _catalogGenerating = false;
  String? _catalogError;

  bool _descriptionGenerating = false;
  String? _descriptionError;

  bool _pricingGenerating = false;
  int? _aiSuggestedPrice;
  String? _aiPricingReasoning;
  String? _pricingError;

  String _regionalTitle = '';
  String _regionalDescription = '';

  List<String> _attributeTags = <String>[
    'Material: Pure Brass',
    'Craft: Dhokra',
    'Care: Dry Clean Only',
    'Handmade: Yes',
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    title = TextEditingController(
      text: 'Handcrafted Indigo Block Print Stole',
    );

    description = TextEditingController(
      text:
      'A beautiful hand block printed cotton stole, thoughtfully made using traditional techniques and rich natural tones.',
    );

    price = TextEditingController(
      text: '1299',
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loadedDraft) return;

    final d = AppScope.of(context).draft;

    if (d.title.isNotEmpty) {
      title.text = d.title;
    }

    if (d.description.isNotEmpty) {
      description.text = d.description;
    }

    final spokenText = VoiceDraft.text.trim();

    if (spokenText.isNotEmpty) {
      description.text = spokenText;
      VoiceDraft.text = '';
    }

    if (d.price > 0) {
      price.text = d.price.toString();
    }

    if (d.category.isNotEmpty) {
      category = _mapCategory(d.category);
    }

    _loadedDraft = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _generateCatalog(
        artisanText: spokenText.isNotEmpty
            ? spokenText
            : description.text.trim(),
      );
    });
  }

  String _mapCategory(String aiCategory) {
    final value = aiCategory.toLowerCase();

    if (value.contains('jewell') ||
        value.contains('jewelry') ||
        value.contains('jewellery')) {
      return 'Jewellery';
    }

    if (value.contains('potter') ||
        value.contains('ceramic')) {
      return 'Pottery';
    }

    if (value.contains('basket') ||
        value.contains('cane') ||
        value.contains('bamboo')) {
      return 'Basketry';
    }

    if (value.contains('wood') ||
        value.contains('carving')) {
      return 'Woodwork';
    }

    if (value.contains('textile') ||
        value.contains('cloth') ||
        value.contains('stole') ||
        value.contains('fabric') ||
        value.contains('weav')) {
      return 'Textiles';
    }

    return 'Textiles';
  }

  Future<void> _generateCatalog({
    required String artisanText,
  }) async {
    if (_catalogGenerating || artisanText.trim().isEmpty) {
      return;
    }

    setState(() {
      _catalogGenerating = true;
      _catalogError = null;
    });

    try {
      final language = AppScope.of(context).language;

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/ai/catalog/generate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'artisan_text': artisanText.trim(),
          'language': language,
          'category': category,
          'raw_material_cost': 0,
        }),
      ).timeout(
        const Duration(seconds: 90),
      );

      debugPrint(
        'AI CATALOG RESPONSE: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        debugPrint(
          'AI CATALOG BODY: ${response.body}',
        );
        throw Exception(
          _tr(context, 'catalogGenerationFailed'),
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic> ||
          decoded['success'] != true) {
        throw Exception(
          _tr(context, 'invalidCatalogResponse'),
        );
      }

      final catalog = decoded;

      final generatedTitle =
      (catalog['title'] ?? '').toString().trim();

      final generatedDescription =
      (catalog['description_en'] ?? '').toString().trim();

      final regionalTitle = generatedTitle;

      final regionalDescription =
      (catalog['description_hi'] ?? '').toString().trim();

// The multilingual catalog contract is intentionally strict:
// title_en, desc_en, title_regional, desc_regional.
// Category and price remain editable fields in the Flutter UI.
      final generatedTags = (catalog['tags'] as List?)
          ?.map((tag) => tag.toString().trim())
          .where((tag) => tag.isNotEmpty)
          .take(10)
          .toList();

      final generatedCategory = category;

      if (generatedTitle.isNotEmpty) {
        title.text = generatedTitle;
      }

      if (generatedDescription.isNotEmpty) {
        description.text = generatedDescription;
      }

      if (generatedCategory.isNotEmpty) {
        category = _mapCategory(generatedCategory);
      }

      final parsedAttributes =
          (catalog['attributes'] as List?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .take(8)
              .toList()
            ??
            generatedTags;

      if (mounted) {
        setState(() {
          _catalogGenerating = false;
          _regionalTitle = regionalTitle;
          _regionalDescription = regionalDescription;

          if (parsedAttributes != null &&
              parsedAttributes.isNotEmpty) {
            _attributeTags = parsedAttributes;
          }
        });
      }

      debugPrint(
        'AI CATALOG SUCCESS: '
            'title=$generatedTitle, '
            'category=$generatedCategory, '
            'price=unchanged',
      );
    } catch (e, stackTrace) {
      debugPrint('AI CATALOG ERROR: $e');
      debugPrint('AI CATALOG STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() {
        _catalogGenerating = false;
        _catalogError =
            _tr(context, 'catalogGenerationError');
      });
    }
  }

  Future<void> _generateDescriptionOnly() async {
    if (_descriptionGenerating) return;

    final source = description.text.trim();
    if (source.length < 8) {
      setState(() {
        _descriptionError = 'Add a few words about your craft first.';
      });
      return;
    }

    setState(() {
      _descriptionGenerating = true;
      _descriptionError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/ai/catalog/generate'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'artisan_text': source,
          'language': AppScope.of(context).language,
          'category': category,
          'raw_material_cost': 0,
        }),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        throw Exception('Description request failed');
      }

      final decoded = jsonDecode(response.body);
      final generated = decoded is Map<String, dynamic>
          ? (decoded['description_en'] ?? '').toString().trim()
          : '';

      if (generated.isEmpty) {
        throw Exception('Empty description');
      }

      if (!mounted) return;

      setState(() {
        description.text = generated;
        _descriptionGenerating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _descriptionGenerating = false;
        _descriptionError = _tr(context, 'catalogGenerationError');
      });
    }
  }

  Future<void> _speakCatalogText(
    String text, {
    required String languageCode,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final tts = FlutterTts();

    try {
      await tts.setLanguage(languageCode);
      await tts.setSpeechRate(.45);
      await tts.setPitch(1.0);
      await tts.speak(clean);
    } catch (_) {}
  }

  void _removeAttributeTag(String tag) {
    setState(() {
      _attributeTags.remove(tag);
    });
  }

  void _showAddAttributeSheet() {
    const common = <String>[
      'Material: Pure Brass',
      'Material: Cotton',
      'Material: Terracotta',
      'Craft: Dhokra',
      'Craft: Hand Block Print',
      'Craft: Handwoven',
      'Care: Dry Clean Only',
      'Care: Wipe Clean',
      'Handmade: Yes',
      'Handmade: No',
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        final existing = _attributeTags.toSet();

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(
                _tr(context, 'addAttribute'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _text(context),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: common.map((tag) {
                  final selected = existing.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          if (!_attributeTags.contains(tag)) {
                            _attributeTags.add(tag);
                          }
                        } else {
                          _attributeTags.remove(tag);
                        }
                      });
                      Navigator.pop(sheetContext);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getDynamicPrice() async {
    if (_pricingGenerating) return;

    final imagePath = AppScope.of(context).draftImagePath;
    final productDescription = description.text.trim();

    if (imagePath == null || imagePath.isEmpty) {
      setState(() {
        _pricingError = _tr(context, 'pricingPhotoRequired');
      });
      return;
    }

    if (productDescription.length < 15) {
      setState(() {
        _pricingError = _tr(context, 'pricingDescriptionRequired');
      });
      return;
    }

    setState(() {
      _pricingGenerating = true;
      _pricingError = null;
    });

    try {
      final imageFile = File(imagePath);

      if (!await imageFile.exists()) {
        throw Exception(_tr(context, 'selectedImageNotFound'));
      }

      final imageBytes = await imageFile.readAsBytes();

      if (imageBytes.isEmpty) {
        throw Exception(_tr(context, 'selectedImageEmpty'));
      }

      final imageBase64 = base64Encode(imageBytes);

// The pricing backend estimates raw-material cost itself from the
// product image and description. Do not send the selling price as cost.
      const rawMaterialCost = 0;

      final extension =
          imageFile.path.toLowerCase().split('.').last;
      final mimeType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
          ? 'image/webp'
          : 'image/jpeg';
      final imageDataUri =
          'data:$mimeType;base64,$imageBase64';

      debugPrint(
        'AI PRICING REQUEST: POST $_apiBaseUrl/ai/pricing',
      );

      final response = await http
          .post(
        Uri.parse('$_apiBaseUrl/ai/pricing'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'image_base64': imageDataUri,
          'image_url': null,
          'description': productDescription,
          'raw_material_cost': rawMaterialCost,
          'category': category,
        }),
      )
          .timeout(const Duration(seconds: 120));

      debugPrint(
        'AI PRICING RESPONSE: ${response.statusCode}',
      );
      debugPrint(
        'AI PRICING BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          _tr(context, 'pricingFailed'),
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(_tr(context, 'invalidPricingResponse'));
      }

      final suggested = decoded['suggested_price'];
      final reasoning = (decoded['reasoning'] ?? '').toString().trim();

      final parsedPrice = suggested is num
          ? suggested.round()
          : int.tryParse(suggested.toString());

      if (parsedPrice == null || parsedPrice <= 0) {
        throw Exception(_tr(context, 'invalidSuggestedPrice'));
      }

      if (!mounted) return;

      setState(() {
        _aiSuggestedPrice = parsedPrice;
        _aiPricingReasoning = reasoning.isEmpty
            ? _tr(context, 'pricingCompetitive')
            : reasoning;
        _pricingGenerating = false;
      });

      price.text = parsedPrice.toString();
    } catch (e, stackTrace) {
      debugPrint('AI PRICING ERROR: $e');
      debugPrint('AI PRICING STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() {
        _pricingGenerating = false;
        _pricingError =
            _tr(context, 'pricingUnavailable');
      });
    }
  }


  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    _controller.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: _muted(context),
      ),
      filled: true,
      fillColor: _surface(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _outline(context).withOpacity(.20),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.forest,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 17,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).language;
    final imagePath = AppScope.of(context).draftImagePath;

    return Scaffold(
      backgroundColor: _background(context),
      appBar: AppBar(
        backgroundColor: _background(context),
        elevation: 0,
        title: Text(
          _tr(context, 'editProductListing'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _text(context),
          ),
        ),
      ),
      body: Form(
        key: form,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Text(
                _tr(context, 'listingReady'),
                style: TextStyle(
                  fontSize: 27,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6,
                  color: _text(context),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _tr(context, 'reviewGeneratedDetails'),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: _muted(context),
                ),
              ),
              const SizedBox(height: 22),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _catalogGenerating
                      ? AppColors.saffron.withOpacity(.12)
                      : AppColors.forest.withOpacity(.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _catalogGenerating
                            ? AppColors.clay
                            : AppColors.forest,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: _catalogGenerating
                          ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                          AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            _catalogGenerating
                                ? _tr(context, 'aiCreatingListing')
                                : _tr(context, 'aiGeneratedDraft'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _text(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _catalogGenerating
                                ? _tr(context, 'understandingCraft')
                                : _tr(context, 'createdInLanguage'),
                            style: TextStyle(
                              fontSize: 10,
                              color: _muted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_catalogError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _catalogError!,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: _text(context),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                _tr(context, 'productPreview'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _text(context),
                ),
              ),
              const SizedBox(height: 11),
              Container(
                height: 185,
                decoration: BoxDecoration(
                  color: _surface(context),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _outline(context).withOpacity(.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(.025),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: imagePath != null &&
                    imagePath.isNotEmpty
                    ? Image.file(
                  File(imagePath),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
                    : const Center(
                  child: ProductVisual(
                    color: AppColors.clay,
                    size: 135,
                    icon: Icons.auto_awesome_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                _tr(context, 'productInformation'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _text(context),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: title,
                textCapitalization:
                TextCapitalization.sentences,
                decoration: _inputDecoration(
                  label: _tr(context, 'productTitle'),
                  hint: _tr(context, 'productTitleHint'),
                  icon: Icons.title_rounded,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return _tr(context, 'addProductTitleError');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: description,
                textCapitalization:
                TextCapitalization.sentences,
                maxLines: 5,
                decoration: _inputDecoration(
                  label: _tr(context, 'productDescription'),
                  hint: _tr(context, 'productDescriptionHint'),
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().length < 15) {
                    return _tr(context, 'descriptionDetailError');
                  }
                  return null;
                },
              ),
              _BilingualCatalogCard(
                title: title.text,
                localTitle: _regionalTitle,
                localDescription: _regionalDescription,
                englishDescription: description.text,
                language: language,
                onSpeakLocal: () => _speakCatalogText(
                  _regionalDescription,
                  languageCode: switch (language) {
                    'हिंदी' => 'hi-IN',
                    'বাংলা' => 'bn-IN',
                    'தமிழ்' => 'ta-IN',
                    'తెలుగు' => 'te-IN',
                    'मराठी' => 'mr-IN',
                    'ગુજરાતી' => 'gu-IN',
                    'ಕನ್ನಡ' => 'kn-IN',
                    _ => 'hi-IN',
                  },
                ),
                onSpeakEnglish: () => _speakCatalogText(
                  description.text,
                  languageCode: 'en-IN',
                ),
              ),
              const SizedBox(height: 14),
              _AttributeTagEditor(
                tags: _attributeTags,
                onRemove: _removeAttributeTag,
                onAdd: _showAddAttributeSheet,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: category,
                decoration: _inputDecoration(
                  label: _tr(context, 'category'),
                  hint: _tr(context, 'chooseCategory'),
                  icon: Icons.category_outlined,
                ),
                items: [
                  'Textiles',
                  'Pottery',
                  'Jewellery',
                  'Basketry',
                  'Woodwork',
                ].map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(_tr(context, item == 'Textiles' ? 'textiles' : item == 'Pottery' ? 'pottery' : item == 'Jewellery' ? 'jewellery' : item == 'Basketry' ? 'basketry' : 'woodwork')),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              _DescriptionGeneratorCard(
                generating: _descriptionGenerating,
                error: _descriptionError,
                onGenerate: _generateDescriptionOnly,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  label: _tr(context, 'suggestedPrice'),
                  hint: _tr(context, 'enterPrice'),
                  icon: Icons.currency_rupee_rounded,
                ).copyWith(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    color: _text(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                validator: (value) {
                  final amount = int.tryParse(value ?? '');

                  if (amount == null || amount <= 0) {
                    return _tr(context, 'validPriceError');
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _aiSuggestedPrice != null
                      ? AppColors.forest.withOpacity(.09)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: _aiSuggestedPrice != null
                        ? AppColors.forest.withOpacity(.22)
                        : Colors.black.withOpacity(.055),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.forest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr(context, 'aiDynamicPricing'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _text(context),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                _tr(context, 'usesPhotoDescription'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _muted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_aiSuggestedPrice != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: _surface(context),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.currency_rupee_rounded,
                              color: AppColors.forest,
                              size: 22,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '₹$_aiSuggestedPrice',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.forest,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                _tr(context, 'aiSuggestedPrice'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _muted(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((_aiPricingReasoning ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _aiPricingReasoning!,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.45,
                            color: _text(context),
                          ),
                        ),
                      ],
                    ],
                    if (_pricingError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _pricingError!,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: _muted(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _pricingGenerating ? null : _getDynamicPrice,
                        icon: _pricingGenerating
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.forest,
                          ),
                        )
                            : const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _pricingGenerating
                              ? _tr(context, 'aiCalculating')
                              : _aiSuggestedPrice == null
                              ? _tr(context, 'getAIPrice')
                              : _tr(context, 'recalculateAIPrice'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          side: BorderSide(
                            color: AppColors.forest.withOpacity(.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: AppColors.clay,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _tr(context, 'priceCanChange'),
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: _muted(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 55,
                child: _PressButton(
                  onTap: () {
                    if (!form.currentState!.validate()) {
                      return;
                    }

                    AppScope.of(context).updateDraft(
                      title: title.text.trim(),
                      description: description.text.trim(),
                      price: int.parse(price.text),
                      category: category,
                    );

                    Navigator.pushNamed(
                      context,
                      '/publish',
                    );
                  },
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 19,
                      ),
                      SizedBox(width: 9),
                      Text(
                        _tr(context, 'reviewPublish'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _BilingualCatalogCard extends StatefulWidget {
  const _BilingualCatalogCard({
    required this.title,
    required this.localTitle,
    required this.localDescription,
    required this.englishDescription,
    required this.language,
    required this.onSpeakLocal,
    required this.onSpeakEnglish,
  });

  final String title;
  final String localTitle;
  final String localDescription;
  final String englishDescription;
  final String language;
  final VoidCallback onSpeakLocal;
  final VoidCallback onSpeakEnglish;

  @override
  State<_BilingualCatalogCard> createState() => _BilingualCatalogCardState();
}

class _BilingualCatalogCardState extends State<_BilingualCatalogCard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localLabel = widget.language == 'English'
        ? AppLocalization.text(AppScope.of(context).language, 'localLanguage')
        : '${AppLocalization.text(AppScope.of(context).language, 'localLanguage')} (${widget.language})';

    final isLocal = _tab == 0;
    final titleText = isLocal
        ? (widget.localTitle.isNotEmpty ? widget.localTitle : widget.title)
        : widget.title;
    final descriptionText = isLocal
        ? (widget.localDescription.isNotEmpty
            ? widget.localDescription
            : widget.englishDescription)
        : widget.englishDescription;

    final t = (String key) => AppLocalization.text(
          AppScope.of(context).language,
          key,
        );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.forest.withOpacity(.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.forest.withOpacity(.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.translate_rounded, color: AppColors.forest, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('regionalMarketplaceCopy'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: t('speakRegionalText'),
                onPressed: isLocal ? widget.onSpeakLocal : widget.onSpeakEnglish,
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.forest,
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CatalogTab(
                    label: localLabel,
                    selected: isLocal,
                    onTap: () => setState(() => _tab = 0),
                  ),
                ),
                Expanded(
                  child: _CatalogTab(
                    label: t('englishMarketplace'),
                    selected: !isLocal,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            titleText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            descriptionText,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.forest.withOpacity(.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: selected
                  ? AppColors.forest
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttributeTagEditor extends StatelessWidget {
  const _AttributeTagEditor({
    required this.tags,
    required this.onRemove,
    required this.onAdd,
  });

  final List<String> tags;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = (String key) => AppLocalization.text(
          AppScope.of(context).language,
          key,
        );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sell_outlined, color: AppColors.clay, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('attributeTags'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(
                  t('addAttribute'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: tags.map((tag) {
              return InputChip(
                label: Text(
                  tag,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 15),
                onDeleted: () => onRemove(tag),
                backgroundColor: AppColors.forest.withOpacity(.08),
                side: BorderSide(color: AppColors.forest.withOpacity(.18)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
class _DescriptionGeneratorCard extends StatelessWidget {
  const _DescriptionGeneratorCard({
    required this.generating,
    required this.error,
    required this.onGenerate,
  });

  final bool generating;
  final String? error;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.forest.withValues(alpha: .10),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    generating
                        ? 'AI is writing your description…'
                        : 'Need a better description?',
                    key: ValueKey(generating),
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: generating ? null : onGenerate,
                child: Text(
                  generating ? 'Working' : 'Generate',
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (generating) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.forest,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                error!,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();

    OfflineRequestQueue.registerDispatcher((request) async {
      if (request.type != 'product_publish') return;
      // The current KarigarKart product flow is local-first. The queued
      // product payload is retained until connectivity returns; at that
      // point the dispatcher acknowledges the queued sync event.
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_publishing) return;

    setState(() {
      _publishing = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) return;

    final state = AppScope.of(context);
    final online = await OfflineRequestQueue.isOnline();

    if (!online) {
      final draft = state.draft;
      await OfflineRequestQueue.enqueue(
        type: 'product_publish',
        payload: {
          'title': draft.title,
          'description': draft.description,
          'price': draft.price,
          'category': draft.category,
          'imagePath': state.draftImagePath ?? '',
        },
      );
    }

    state.publishDraft();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
          (_) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          _tr(context, 'productNowLive'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context).draft;
    final imagePath = AppScope.of(context).draftImagePath;

    return Scaffold(
      backgroundColor: _background(context),
      appBar: AppBar(
        backgroundColor: _background(context),
        elevation: 0,
        title: Text(
          _tr(context, 'readyToPublish'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _text(context),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            Text(
              _tr(context, 'finalLook'),
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -.6,
                color: _text(context),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _tr(context, 'publishReadyText'),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: _muted(context),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
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
              ),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imagePath != null &&
                        imagePath.isNotEmpty
                        ? Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    )
                        : const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title.isNotEmpty
                              ? d.title
                              : _tr(context, 'handmadeProduct'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          d.category.isNotEmpty
                              ? d.category
                              : _tr(context, 'handmadeCraft'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _tr(context, 'listingChecklist'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _text(context),
              ),
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: _surface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _outline(context).withOpacity(.18),
                ),
              ),
              child: Column(
                children: [
                  _ChecklistItem(
                    icon: Icons.check_circle_rounded,
                    text: _tr(context, 'productInfoAdded'),
                  ),
                  _ChecklistItem(
                    icon: Icons.check_circle_rounded,
                    text: _tr(context, 'aiDescriptionReviewed'),
                  ),
                  _ChecklistItem(
                    icon: Icons.check_circle_rounded,
                    text: _tr(context, 'categoryPriceSelected'),
                  ),
                  _ChecklistItem(
                    icon: Icons.check_circle_rounded,
                    text: _tr(context, 'productReadyStorefront'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _surface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _outline(context).withOpacity(.18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.currency_rupee_rounded,
                    color: AppColors.clay,
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _tr(context, 'sellingPrice'),
                    style: TextStyle(
                      fontSize: 12,
                      color: _muted(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${d.price}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.clay,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 55,
              child: _PressButton(
                onTap: _publish,
                child: _publishing
                    ? const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                    AlwaysStoppedAnimation(
                      Colors.white,
                    ),
                  ),
                )
                    : Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rocket_launch_rounded,
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Text(
                      _tr(context, 'publishProduct'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(.10),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _publishing
                    ? null
                    : () => Navigator.pop(context),
                child: Text(
                  _tr(context, 'keepEditing'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _tr(context, 'alwaysInControl'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: _muted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: AppColors.forest,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _text(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  static const languages = [
    'English',
    'हिंदी',
    'বাংলা',
    'தமிழ்',
    'తెలుగు',
    'मराठी',
    'ગુજરાતી',
    'ಕನ್ನಡ',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return PopupMenuButton<String>(
      tooltip: _tr(context, 'changeLanguage'),
      onSelected: (value) => state.setLanguage(value),
      itemBuilder: (context) => languages.map((language) {
        final selected = state.language == language;
        return PopupMenuItem<String>(
          value: language,
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  language == 'English' ? 'A' : language.substring(0, 1),
                  style: TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(child: Text(language)),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.forest,
                  size: 18,
                ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.forest.withOpacity(.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          state.language,
          style: TextStyle(
            color: AppColors.forest,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PressButton extends StatefulWidget {
  const _PressButton({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? .975 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.ink,
                Color(0xFF3B3530),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

