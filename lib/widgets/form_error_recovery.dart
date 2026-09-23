import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/haptic_feedback_service.dart';
import '../theme.dart';

class VisualFieldError extends StatefulWidget {
  const VisualFieldError({super.key, required this.hasError, required this.child});
  final bool hasError;
  final Widget child;

  @override
  State<VisualFieldError> createState() => _VisualFieldErrorState();
}

class _VisualFieldErrorState extends State<VisualFieldError> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void didUpdateWidget(covariant VisualFieldError oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _pulse.forward(from: 0);
      KarigarKartHaptics.aiFailure();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final wave = math.sin(_pulse.value * math.pi);
        final width = widget.hasError ? 1.2 + (2.0 * wave) : 0.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: widget.hasError ? AppColors.clay.withOpacity(.75 + .2 * wave) : Colors.transparent,
              width: width,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class FormErrorRecovery {
  FormErrorRecovery._();

  static Future<void> focusAndScroll({required GlobalKey fieldKey}) async {
    final target = fieldKey.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic, alignment: .25);
    await KarigarKartHaptics.aiFailure();
  }
}
