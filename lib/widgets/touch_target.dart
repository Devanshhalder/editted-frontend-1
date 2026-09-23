import 'package:flutter/material.dart';

/// Wrap interactive controls so every important tap target is at least 48dp.
class KarigarKartTouchTarget extends StatelessWidget {
  const KarigarKartTouchTarget({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Center(child: child),
    );
    return onTap == null ? content : InkWell(onTap: onTap, child: content);
  }
}
