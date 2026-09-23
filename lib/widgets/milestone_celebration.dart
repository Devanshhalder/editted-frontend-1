import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';

class MilestoneCelebration extends StatefulWidget {
  const MilestoneCelebration({super.key, required this.child});
  final Widget child;
  @override
  State<MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<MilestoneCelebration> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = AppScope.of(context);
      final milestone = state.isIdentityVerified || state.products.length >= 10;
      if (!milestone || !mounted) return;
      setState(() => _visible = true);
      _controller.forward().whenComplete(() {
        if (mounted) setState(() => _visible = false);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(progress: _controller.value),
                  child: Center(
                    child: Opacity(
                      opacity: (1 - _controller.value).clamp(0.0, 1.0),
                      child: Container(
                        margin: const EdgeInsets.all(28),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(blurRadius: 24, offset: Offset(0, 10))]),
                        child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.celebration_rounded, size: 48, color: AppColors.saffron), SizedBox(height: 10), Text('Milestone unlocked!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('Your artisan journey is moving forward.', textAlign: TextAlign.center)]),
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

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < 42; i++) {
      final x = random.nextDouble() * size.width;
      final startY = -random.nextDouble() * size.height * .35;
      final y = startY + (size.height + 80) * progress;
      paint.color = [AppColors.forest, AppColors.clay, AppColors.saffron, AppColors.ink][i % 4];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * (i.isEven ? 1 : -1));
      canvas.drawRect(const Rect.fromLTWH(-3, -6, 6, 12), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
