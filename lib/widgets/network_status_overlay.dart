import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../services/offline_request_queue.dart';
import '../theme.dart';

class NetworkStatusOverlay extends StatefulWidget {
  const NetworkStatusOverlay({super.key, required this.child});
  final Widget child;
  @override State<NetworkStatusOverlay> createState() => _NetworkStatusOverlayState();
}

class _NetworkStatusOverlayState extends State<NetworkStatusOverlay> with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;
  bool _offline = false;
  bool _ready = false;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _update(result);
      _refreshPending();
    });
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshPending());
  }

  Future<void> _check() async {
    try { _update(await _connectivity.checkConnectivity()); } catch (_) {}
    await _refreshPending();
  }

  void _update(List<ConnectivityResult> result) {
    if (!mounted) return;
    setState(() {
      _offline = !result.any((item) => item != ConnectivityResult.none);
      _ready = true;
    });
  }

  Future<void> _refreshPending() async {
    final count = await OfflineRequestQueue.pendingCount();
    if (mounted && count != _pending) setState(() => _pending = count);
  }

  @override void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _check(); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _subscription?.cancel(); _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final visible = _ready && (_offline || _pending > 0);
    final colors = Theme.of(context).colorScheme;
    final text = _offline ? 'You are offline. Changes will stay on this device.' : '$_pending item${_pending == 1 ? '' : 's'} waiting to upload when online';
    final icon = _offline ? Icons.cloud_off_rounded : Icons.cloud_upload_outlined;
    final accent = _offline ? AppColors.clay : AppColors.forest;
    return Stack(children: [
      widget.child,
      if (visible)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: colors.outline.withOpacity(.28)), boxShadow: [BoxShadow(color: colors.shadow.withOpacity(.18), blurRadius: 18, offset: const Offset(0, 7))]),
                  child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: accent.withOpacity(.12), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: accent, size: 19)),
                    const SizedBox(width: 11),
                    Expanded(child: Text(text, style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w700))),
                    if (!_offline && _pending > 0) ...[
                      const SizedBox(width: 10),
                      const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
