import 'package:flutter/material.dart';

class HumanValidationPanel extends StatelessWidget {
  const HumanValidationPanel({super.key, required this.tags, required this.onChanged});

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Review AI-generated attributes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text('Remove anything incorrect before publishing.', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 10),
      Wrap(spacing: 7, runSpacing: 7, children: [
        for (final tag in tags)
          InputChip(
            label: Text(tag),
            onDeleted: () => onChanged(List<String>.from(tags)..remove(tag)),
            deleteIcon: const Icon(Icons.close_rounded, size: 17),
          ),
      ]),
      const SizedBox(height: 6),
      TextButton.icon(
        onPressed: () async {
          final controller = TextEditingController();
          final value = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add an attribute'),
              content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'e.g. Material: Cotton')),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add'))],
            ),
          );
          controller.dispose();
          if (value != null && value.isNotEmpty) onChanged([...tags, value]);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add / correct'),
      ),
    ]);
  }
}
