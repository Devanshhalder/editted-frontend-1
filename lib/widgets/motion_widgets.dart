import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

enum AiJobStatus { queued, processing, completed, failed }

class VoiceRecordingPulsar extends StatefulWidget {
  const VoiceRecordingPulsar({
    super.key,
    required this.isRecording,
    required this.isPlaying,
    required this.onTap,
    this.size = 168,
  });

  final bool isRecording;
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;

  @override
  State<VoiceRecordingPulsar> createState() => _VoiceRecordingPulsarState();
}

class _VoiceRecordingPulsarState extends State<VoiceRecordingPulsar>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  late final AnimationController _eq = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    _eq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.isRecording
          ? 'Stop recording'
          : 'Start voice recording',
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulse, _eq]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    if (widget.isRecording)
                      Opacity(
                        opacity:
                            (1 - ((_pulse.value + i / 3) % 1)) * .28,
                        child: Transform.scale(
                          scale:
                              1 + (((_pulse.value + i / 3) % 1) * .42),
                          child: Container(
                            width: widget.size * .66,
                            height: widget.size * .66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.clay.withOpacity(.22),
                            ),
                          ),
                        ),
                      ),
                  Container(
                    width: widget.size * .72,
                    height: widget.size * .72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isRecording
                          ? AppColors.clay
                          : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: widget.isRecording
                            ? AppColors.clay
                            : AppColors.saffron,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withOpacity(.10),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isRecording
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                      size: widget.size * .30,
                      color: widget.isRecording
                          ? Colors.white
                          : AppColors.clay,
                    ),
                  ),
                  if (widget.isPlaying)
                    Positioned(
                      bottom: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          4,
                          (i) => Container(
                            width: 4,
                            height: 10 +
                                ((math.sin(
                                              (_eq.value * math.pi * 2) + i,
                                            ) *
                                            .5 +
                                        .5) *
                                    14),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: AppColors.forest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class BeforeAfterSliderAnimated extends StatefulWidget {
  const BeforeAfterSliderAnimated({
    super.key,
    required this.rawImagePath,
    required this.enhancedImagePath,
  });

  final String? rawImagePath;
  final String? enhancedImagePath;

  @override
  State<BeforeAfterSliderAnimated> createState() =>
      _BeforeAfterSliderAnimatedState();
}

class _BeforeAfterSliderAnimatedState extends State<BeforeAfterSliderAnimated>
    with SingleTickerProviderStateMixin {
  double _position = .5;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  void _move(Offset position, double width) {
    setState(() {
      _position = (position.dx / width).clamp(.04, .96);
    });
  }

  Widget _image(String? path) {
    if (path != null && path.isNotEmpty) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Icon(Icons.image_outlined, size: 48),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _move(details.localPosition, width),
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              _move(box.globalToLocal(details.globalPosition), width);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _image(widget.rawImagePath),
                    if (widget.enhancedImagePath != null &&
                        widget.enhancedImagePath!.isNotEmpty)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: width * _position,
                        child: ClipRect(
                          child: _image(widget.enhancedImagePath),
                        ),
                      ),
                    Positioned(
                      left: width * _position - 1.5,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 3,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: (width * _position).clamp(32, width - 32) - 22,
                      bottom: 18,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _tag('AI Enhanced'),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _tag('Original'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AnimatedPriceCounter extends StatelessWidget {
  const AnimatedPriceCounter({
    super.key,
    required this.targetPrice,
    this.style,
  });

  final double targetPrice;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetPrice),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        '₹${value.round()}',
        style: style ??
            const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
            ),
      ),
    );
  }
}

class SyncStatusBadge extends StatefulWidget {
  const SyncStatusBadge({super.key, required this.status});

  final AiJobStatus status;

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didUpdateWidget(covariant SyncStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
        child: child,
      ),
      child: _body(
        colors,
        key: ValueKey(widget.status),
      ),
    );
  }

  Widget _body(ColorScheme colors, {required Key key}) {
    switch (widget.status) {
      case AiJobStatus.processing:
        return _pill(
          key,
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          'Processing AI',
        );
      case AiJobStatus.completed:
        return _pill(
          key,
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.forest,
            size: 17,
          ),
          'Synced',
        );
      case AiJobStatus.failed:
        return _pill(
          key,
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 17,
          ),
          'Failed · Retry',
        );
      case AiJobStatus.queued:
        return _pill(
          key,
          const Icon(Icons.schedule_rounded, size: 17),
          'Queued',
        );
    }
  }

  Widget _pill(Key key, Widget icon, String text) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SahayakFloatingBot extends StatefulWidget {
  const SahayakFloatingBot({
    super.key,
    required this.onTap,
    this.active = false,
    this.label = 'Ask Sahayak',
  });

  final VoidCallback onTap;
  final bool active;
  final String label;

  @override
  State<SahayakFloatingBot> createState() => _SahayakFloatingBotState();
}

class _SahayakFloatingBotState extends State<SahayakFloatingBot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final y = math.sin(_controller.value * math.pi) * -5;
          return Transform.translate(
            offset: Offset(0, y),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.active)
                  for (var i = 0; i < 2; i++)
                    Opacity(
                      opacity: (1 - _controller.value) * .30,
                      child: Container(
                        width: 66 + i * 16,
                        height: 66 + i * 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.forest,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                FloatingActionButton(
                  onPressed: widget.onTap,
                  heroTag: 'sahayak_voice_bot',
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  child: Icon(
                    widget.active
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
