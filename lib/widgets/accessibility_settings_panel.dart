import 'package:flutter/material.dart';

import '../services/app_state.dart';

class AccessibilitySettingsPanel extends StatelessWidget {
  const AccessibilitySettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Accessibility', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.onSurface)),
        const SizedBox(height: 6),
        Text('Use stronger contrast for outdoor markets and fairs.', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        const SizedBox(height: 16),
        Semantics(label: 'High contrast outdoor mode', hint: 'Switch between standard and black and white high contrast colors', toggled: state.highContrastMode, child: SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('High-contrast outdoor mode', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Bold outlines and pure black/white surfaces'), value: state.highContrastMode, onChanged: state.setHighContrastMode)),
        const SizedBox(height: 10),
        const Text('Text size follows your Android accessibility setting. The app does not override the system text scale.', style: TextStyle(fontSize: 12, height: 1.45)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, '/sync-queue'); }, icon: const Icon(Icons.sync_rounded), label: const Text('Open Sync Queue', style: TextStyle(fontWeight: FontWeight.w800)))),
      ]),
    );
  }
}
