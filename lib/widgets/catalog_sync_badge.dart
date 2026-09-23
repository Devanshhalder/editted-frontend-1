import 'package:flutter/material.dart';

class CatalogSyncBadge extends StatelessWidget {
  const CatalogSyncBadge({super.key, required this.status, this.onRetry});

  final String status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final queued = normalized.contains('queued') || normalized.contains('offline');
    final processing = normalized.contains('processing') || normalized.contains('ai');
    final failed = normalized.contains('failed') || normalized.contains('error');
    final synced = normalized.contains('published') || normalized.contains('synced');

    final icon = failed
        ? Icons.error_outline_rounded
        : processing
            ? Icons.auto_awesome_rounded
            : queued
                ? Icons.cloud_off_rounded
                : synced
                    ? Icons.cloud_done_rounded
                    : Icons.edit_note_rounded;

    final label = failed
        ? 'Failed • Tap to Retry'
        : processing
            ? 'Processing • AI Engine'
            : queued
                ? 'Queued • Offline'
                : synced
                    ? 'Published • Synced'
                    : 'Draft • Local';

    final child = Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (processing) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) else Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
      ]),
    );

    return failed && onRetry != null ? InkWell(onTap: onRetry, borderRadius: BorderRadius.circular(20), child: child) : child;
  }
}
