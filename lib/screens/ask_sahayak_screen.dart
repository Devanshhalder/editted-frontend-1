import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AskSahayakScreen extends StatefulWidget {
  const AskSahayakScreen({super.key});

  @override
  State<AskSahayakScreen> createState() => _AskSahayakScreenState();
}

class _AskSahayakScreenState extends State<AskSahayakScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _listening = false;
  String _text = '';

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _listening = false);
      }
      return;
    }

    final ok = await _speech.initialize();
    if (!ok || !mounted) return;

    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _text = result.recognizedWords);
      },
      localeId: 'hi-IN',
    );
  }

  Future<void> _answer(String text) async {
    await _tts.setLanguage('hi-IN');
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask Sahayak')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                button: true,
                label: _listening ? 'Stop speaking' : 'Ask Sahayak by voice',
                child: FloatingActionButton.large(
                  onPressed: _toggle,
                  child: Icon(_listening ? Icons.stop : Icons.mic),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _text.isEmpty ? 'Boliye — main madad karunga.' : _text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _promptChip(
                    'Price help',
                    'Apne material cost aur labour hours batayein.',
                  ),
                  _promptChip(
                    'Order status',
                    'Main aapko order status check karne ke steps bata sakta hoon.',
                  ),
                  _promptChip(
                    'Packing help',
                    'Main aapko packing ke steps bata sakta hoon.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promptChip(String label, String answer) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _answer(answer),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}
