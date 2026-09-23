import 'package:flutter/material.dart';

class AiConfidenceMeter extends StatelessWidget {
  const AiConfidenceMeter({super.key, required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final value = confidence.clamp(0.0, 1.0);
    final label = value >= .75 ? 'High confidence' : value >= .45 ? 'Medium confidence' : 'Limited market data';
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label, ${(value * 100).round()} percent',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(.55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.verified_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
            Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(value: value, minHeight: 8),
          ),
        ]),
      ),
    );
  }
}
