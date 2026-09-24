import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';
import 'profile_screen.dart';
import 'udyam_help_screen.dart';

/// Enhanced profile entry point.
///
/// Utility actions live in normal layout flow rather than floating over the
/// profile preferences section or bottom navigation.
class ProfileEnhancedScreen extends StatelessWidget {
  const ProfileEnhancedScreen({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear local catalog?'),
        content: const Text(
          'This removes locally stored products and drafts from this device. '
              'It does not delete server-side data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await AppScope.of(context).clearLocalCatalog();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local catalog cache cleared.'),
      ),
    );
  }

  void _openUdyamHelp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UdyamHelpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ProfileScreen(
            embedded: embedded,
          ),
        ),

        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withOpacity(.18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openUdyamHelp(context),
                      icon: const Icon(
                        Icons.support_agent_rounded,
                        size: 18,
                      ),
                      label: const Text('Help'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}