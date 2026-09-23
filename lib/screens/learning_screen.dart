import 'package:flutter/material.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  static const List<(String, String)> lessons = [
    (
      'How to pack a terracotta pot',
      'Pad the fragile edges, fill empty space, seal the box and mark it fragile.',
    ),
    (
      'When the delivery partner arrives',
      'Check the parcel, keep your receipt, and hand over only after the pickup details match.',
    ),
    (
      'How to read a bulk B2B request',
      'Check quantity, delivery date, sample requirement, price terms and payment conditions.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          return Card(
            margin: const EdgeInsets.all(18),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_outline, size: 72),
                  const SizedBox(height: 24),
                  Text(
                    lesson.$1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    lesson.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 28),
                  const Chip(label: Text('Step-by-step tip')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
