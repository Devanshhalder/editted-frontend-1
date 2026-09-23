import 'package:flutter/material.dart';

class AiSkeleton extends StatefulWidget {
  const AiSkeleton({super.key, this.height = 18, this.width, this.radius = 10});

  final double height;
  final double? width;
  final double radius;

  @override
  State<AiSkeleton> createState() => _AiSkeletonState();
}

class _AiSkeletonState extends State<AiSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(base, Theme.of(context).colorScheme.surface, _controller.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class AiResultSkeleton extends StatelessWidget {
  const AiResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AiSkeleton(height: 22, width: 210),
        SizedBox(height: 12),
        AiSkeleton(height: 14),
        SizedBox(height: 8),
        AiSkeleton(height: 14, width: 270),
        SizedBox(height: 18),
        AiSkeleton(height: 92),
        SizedBox(height: 14),
        Row(children: [
          Expanded(child: AiSkeleton(height: 38)),
          SizedBox(width: 10),
          Expanded(child: AiSkeleton(height: 38)),
        ]),
      ],
    );
  }
}
