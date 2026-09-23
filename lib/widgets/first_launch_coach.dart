import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_state.dart';
import '../theme.dart';

class FirstLaunchCoach extends StatefulWidget {
  const FirstLaunchCoach({super.key, required this.targetKey, required this.child});
  final GlobalKey targetKey;
  final Widget child;
  @override State<FirstLaunchCoach> createState() => _FirstLaunchCoachState();
}

class _FirstLaunchCoachState extends State<FirstLaunchCoach> {
  static const _seenKey = 'karigarkart_ftue_add_product_seen';
  final _prefs = SharedPreferencesAsync();
  final _tts = FlutterTts();
  bool _visible = false;
  Rect? _targetRect;
  String _language = 'English';

  @override void didChangeDependencies() { super.didChangeDependencies(); _language = AppScope.of(context).language; _maybeShow(); }
  Future<void> _maybeShow() async {
    if (_visible) return;
    final seen = await _prefs.getBool(_seenKey) ?? false;
    if (seen || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) { if (!mounted) return; final renderObject = widget.targetKey.currentContext?.findRenderObject(); if (renderObject is! RenderBox || !renderObject.hasSize) return; final topLeft = renderObject.localToGlobal(Offset.zero); setState(() { _targetRect = topLeft & renderObject.size; _visible = true; }); _speakPrompt(); });
  }

  String _locale() { switch (_language) { case 'Hindi': case 'हिंदी': return 'hi-IN'; case 'Marathi': case 'मराठी': return 'mr-IN'; case 'Bengali': case 'বাংলা': return 'bn-IN'; case 'Tamil': case 'தமிழ்': return 'ta-IN'; case 'Telugu': case 'తెలుగు': return 'te-IN'; case 'Gujarati': case 'ગુજરાતી': return 'gu-IN'; case 'Kannada': case 'ಕನ್ನಡ': return 'kn-IN'; default: return 'en-IN'; } }
  String _prompt() { switch (_language) { case 'Hindi': case 'हिंदी': return 'अपना नया उत्पाद जोड़ने के लिए यहाँ दबाएँ।'; case 'Marathi': case 'मराठी': return 'नवीन उत्पादन जोडण्यासाठी इथे दाबा.'; case 'Bengali': case 'বাংলা': return 'নতুন পণ্য যোগ করতে এখানে চাপুন।'; case 'Tamil': case 'தமிழ்': return 'புதிய பொருளைச் சேர்க்க இங்கே அழுத்தவும்.'; case 'Telugu': case 'తెలుగు': return 'కొత్త ఉత్పత్తిని జోడించడానికి ఇక్కడ నొక్కండి.'; case 'Gujarati': case 'ગુજરાતી': return 'નવું ઉત્પાદન ઉમેરવા માટે અહીં દબાવો.'; case 'Kannada': case 'ಕನ್ನಡ': return 'ಹೊಸ ಉತ್ಪನ್ನವನ್ನು ಸೇರಿಸಲು ಇಲ್ಲಿ ಒತ್ತಿರಿ.'; default: return 'Tap here to add a new product.'; } }
  Future<void> _speakPrompt() async { try { await _tts.setSpeechRate(.43); await _tts.setVolume(.9); await _tts.setPitch(1.0); await _tts.setLanguage(_locale()); await _tts.speak(_prompt()); } catch (_) {} }
  Future<void> _dismiss() async { await _prefs.setBool(_seenKey, true); try { await _tts.stop(); } catch (_) {} if (mounted) setState(() => _visible = false); }
  @override void dispose() { _tts.stop(); super.dispose(); }

  @override Widget build(BuildContext context) => Stack(children: [widget.child, if (_visible && _targetRect != null) Positioned.fill(child: GestureDetector(onTap: _dismiss, child: CustomPaint(painter: _CoachPainter(_targetRect!), child: Stack(children: [Positioned(left: 22, right: 22, bottom: math.max(108, MediaQuery.of(context).size.height - _targetRect!.bottom + 18), child: Material(color: Theme.of(context).colorScheme.surface, elevation: 12, borderRadius: BorderRadius.circular(22), child: Padding(padding: const EdgeInsets.fromLTRB(18, 16, 12, 14), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.forest.withOpacity(.10), shape: BoxShape.circle), child: const Icon(Icons.add_a_photo_outlined, color: AppColors.forest)), const SizedBox(width: 12), const Expanded(child: Text('Start here: add your first product', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.3))), IconButton(tooltip: 'Close', onPressed: _dismiss, icon: const Icon(Icons.close_rounded))]))))]))))]);
}

class _CoachPainter extends CustomPainter {
  const _CoachPainter(this.target); final Rect target;
  @override void paint(Canvas canvas, Size size) { final overlay = Path()..addRect(Offset.zero & size); final cutout = Path()..addRRect(RRect.fromRectAndRadius(target.inflate(10), const Radius.circular(24))); final paint = Paint()..color = Colors.black.withOpacity(.72); canvas.drawPath(Path.combine(PathOperation.difference, overlay, cutout), paint); final ring = Paint()..color = AppColors.saffron..style = PaintingStyle.stroke..strokeWidth = 3; canvas.drawRRect(RRect.fromRectAndRadius(target.inflate(10), const Radius.circular(24)), ring); }
  @override bool shouldRepaint(covariant _CoachPainter oldDelegate) => oldDelegate.target != target;
}
