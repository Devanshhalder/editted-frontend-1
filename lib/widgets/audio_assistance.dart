import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/app_state.dart';
import '../services/route_tracker.dart';
import 'motion_widgets.dart';

class AudioAssistanceOverlay extends StatefulWidget {
  const AudioAssistanceOverlay({super.key, required this.child, required this.routeTracker});
  final Widget child;
  final KarigarKartRouteTracker routeTracker;
  @override State<AudioAssistanceOverlay> createState() => _AudioAssistanceOverlayState();
}

class _AudioAssistanceOverlayState extends State<AudioAssistanceOverlay> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() { if (mounted) setState(() => _speaking = false); });
    _tts.setCancelHandler(() { if (mounted) setState(() => _speaking = false); });
    _tts.setErrorHandler((_) { if (mounted) setState(() => _speaking = false); });
  }

  String _prompt(String language, String? route) {
    final key = route ?? '';
    final hindi = language == 'Hindi' || language == 'हिंदी';
    final marathi = language == 'Marathi' || language == 'मराठी';
    final bengali = language == 'Bengali' || language == 'বাংলা';
    final tamil = language == 'Tamil' || language == 'தமிழ்';
    final telugu = language == 'Telugu' || language == 'తెలుగు';
    if (hindi) {
      if (key == '/add') return 'अपने शिल्प की फोटो लेने के लिए हरे कैमरा बटन को दबाएँ। फोन को सीधा और स्थिर रखें।';
      if (key == '/pricing-assistant') return 'सामग्री की लागत, काम के घंटे और पैकेजिंग की जानकारी भरें। उचित बिक्री मूल्य समझने के लिए मूल्य सहायता का उपयोग करें।';
      if (key == '/listing') return 'स्थानीय भाषा और अंग्रेजी में अपनी सूची की जानकारी सुनें। प्रकाशित करने से पहले विवरण जांचें।';
      return 'करिगरकार्ट में मदद सुनने के लिए आवाज सहायता का उपयोग करें।';
    }
    if (marathi) return key == '/add' ? 'तुमच्या हस्तकलेचा फोटो घेण्यासाठी हिरवे कॅमेरा बटण दाबा. फोन सरळ आणि स्थिर ठेवा.' : 'करिगरकार्ट वापरण्यासाठी आवाजातील मदत ऐका आणि प्रकाशित करण्यापूर्वी माहिती तपासा.';
    if (bengali) return key == '/add' ? 'আপনার কারুশিল্পের ছবি তুলতে সবুজ ক্যামেরা বোতামটি চাপুন। ফোনটি সোজা ও স্থির রাখুন।' : 'করিগারকার্ট ব্যবহার করতে ভয়েস সহায়তা শুনুন এবং প্রকাশের আগে তথ্য যাচাই করুন।';
    if (tamil) return key == '/add' ? 'உங்கள் கைவினைப் பொருளின் புகைப்படத்தை எடுக்க பச்சை கேமரா பொத்தானை அழுத்துங்கள். தொலைபேசியை நேராகவும் நிலையாகவும் வைத்திருங்கள்.' : 'கரிகர்கார்ட்டைப் பயன்படுத்த குரல் உதவியை கேளுங்கள். வெளியிடுவதற்கு முன் தகவலைச் சரிபார்க்கவும்.';
    if (telugu) return key == '/add' ? 'మీ చేతిపని ఫోటో తీయడానికి ఆకుపచ్చ కెమెరా బటన్‌ను నొక్కండి. ఫోన్‌ను నిటారుగా మరియు స్థిరంగా ఉంచండి.' : 'కరిగర్‌కార్ట్ ఉపయోగించడానికి వాయిస్ సహాయం వినండి. ప్రచురించే ముందు వివరాలను తనిఖీ చేయండి.';
    if (key == '/add') return 'Tap the green camera button to take a photo of your craft. Hold the phone steady and level.';
    if (key == '/pricing-assistant') return 'Enter your material cost, crafting time and packaging cost. Use the pricing assistant to understand a fair selling price.';
    if (key == '/listing') return 'Listen to your local-language and English listing text. Check the details before publishing.';
    return 'Use voice assistance to hear simple guidance for KarigarKart.';
  }

  String _ttsCode(String language) {
    switch (language) {
      case 'Hindi': case 'हिंदी': return 'hi-IN';
      case 'Marathi': case 'मराठी': return 'mr-IN';
      case 'Bengali': case 'বাংলা': return 'bn-IN';
      case 'Tamil': case 'தமிழ்': return 'ta-IN';
      case 'Telugu': case 'తెలుగు': return 'te-IN';
      case 'Gujarati': case 'ગુજરાતી': return 'gu-IN';
      case 'Kannada': case 'ಕನ್ನಡ': return 'kn-IN';
      default: return 'en-IN';
    }
  }

  Future<void> _toggle() async {
    final state = AppScope.of(context);
    if (_speaking) { await _tts.stop(); if (mounted) setState(() => _speaking = false); return; }
    await _tts.setLanguage(_ttsCode(state.language));
    await _tts.setSpeechRate(.44);
    await _tts.setPitch(1.0);
    if (mounted) setState(() => _speaking = true);
    await _tts.speak(_prompt(state.language, widget.routeTracker.currentRoute.value));
  }

  @override void dispose() { _tts.stop(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: widget.routeTracker.currentRoute,
      builder: (context, route, _) {
        final show = route == '/add' || route == '/pricing-assistant' || route == '/listing';
        return Stack(children: [
          widget.child,
          if (show)
            Positioned(
              right: 18,
              bottom: 92,
              child: SahayakFloatingBot(
                active: _speaking,
                onTap: _toggle,
                label: _speaking ? 'Stop voice assistance' : 'Voice assistance',
              ),
            ),
        ]);
      },
    );
  }
}
