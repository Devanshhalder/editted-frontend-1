import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

class AiConsentGate extends StatefulWidget {
  const AiConsentGate({super.key, required this.child});
  final Widget child;

  @override
  State<AiConsentGate> createState() => _AiConsentGateState();
}

class _AiConsentGateState extends State<AiConsentGate> {
  static const _key = 'karigarkart_ai_photo_consent';
  bool _checking = true;
  bool _accepted = false;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _accepted = prefs.getBool(_key) ?? false;
      _checking = false;
    });
  }

  Future<void> _speak() async {
    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(.42);
    await _tts.speak('Aapki product photo AI processing ke liye securely process hogi. Aapki permission ke bina hum is feature ko use nahi karenge.');
  }

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    if (!mounted) return;
    setState(() => _accepted = true);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || _accepted) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black54,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Material(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 70, height: 70, decoration: BoxDecoration(color: AppColors.forest.withOpacity(.10), shape: BoxShape.circle), child: const Icon(Icons.lock_outline_rounded, size: 34, color: AppColors.forest)),
                        const SizedBox(height: 14),
                        const Text('Secure AI photo processing', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        const Text('Your product photo is sent for AI enhancement and processed securely. Review the result before publishing.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.muted)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(onPressed: _speak, icon: const Icon(Icons.volume_up_rounded), label: const Text('Listen in Hindi')),
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: FilledButton(onPressed: _accept, child: const Text('I understand & continue', style: TextStyle(fontWeight: FontWeight.w900)))),
                      ],
                    ),
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
