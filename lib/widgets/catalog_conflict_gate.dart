import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';

class CatalogConflictGate extends StatelessWidget {
  const CatalogConflictGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final conflicts = AppScope.of(context).products.where((product) => product.syncConflict).toList();
    return Stack(children: [
      child,
      if (conflicts.isNotEmpty)
        Positioned(
          top: 12,
          right: 18,
          child: SafeArea(
            child: Material(
              color: AppColors.clay,
              borderRadius: BorderRadius.circular(18),
              elevation: 7,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showConflict(context, conflicts.first.id),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.sync_problem_rounded, color: Colors.white, size: 17),
                    SizedBox(width: 6),
                    Text('Sync Conflict', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Future<void> _showConflict(BuildContext context, String productId) async {
    final state = AppScope.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sync Conflict', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This listing changed on another marketplace while you also changed it here. Choose which version should remain on this device.'),
        actions: [
          TextButton(
            onPressed: () {
              state.resolveProductConflict(productId, keepLocal: false);
              Navigator.pop(dialogContext);
            },
            child: const Text('Use marketplace version'),
          ),
          FilledButton(
            onPressed: () {
              state.resolveProductConflict(productId, keepLocal: true);
              Navigator.pop(dialogContext);
            },
            child: const Text('Keep my version'),
          ),
        ],
      ),
    );
  }
}
