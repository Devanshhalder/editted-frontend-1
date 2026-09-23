import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/offline_request_queue.dart';
import '../theme.dart';

class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});
  @override State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  List<OfflineRequest> _items = const [];
  bool _wifiOnly = false;
  bool _loading = true;

  @override void initState() { super.initState(); _refresh(); }
  Future<void> _refresh() async {
    final items = await OfflineRequestQueue.pendingRequests();
    final wifi = await OfflineRequestQueue.wifiOnly;
    if (!mounted) return;
    setState(() { _items = items; _wifiOnly = wifi; _loading = false; });
  }
  String _label(OfflineRequest item) { switch (item.type) { case 'product_publish': return 'Product upload'; case 'ai_studio_enhance': return 'Queued enhancement'; default: return item.type.replaceAll('_', ' '); } }
  Future<int> _payloadBytes(OfflineRequest item) async {
    var bytes = utf8.encode(jsonEncode(item.payload)).length;
    for (final value in item.payload.values) {
      if (value is! String) continue;
      if (!(value.contains('/') || value.contains('\\'))) continue;
      try { final file = File(value); if (await file.exists()) bytes += await file.length(); } catch (_) {}
    }
    return bytes;
  }
  String _formatSize(int bytes) { if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB queued'; if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB queued'; return '$bytes B queued'; }
  Future<void> _syncAll() async { await OfflineRequestQueue.flush(); await _refresh(); }
  Future<void> _retry(String id) async { await OfflineRequestQueue.retry(id); await _refresh(); }
  Future<void> _remove(String id) async { await OfflineRequestQueue.remove(id); await _refresh(); }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Queue')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                children: [
                  _QueueSummary(count: _items.length),
                  const SizedBox(height: 12),
                  Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
                    Row(children: [const Icon(Icons.wifi_outlined, color: AppColors.forest), const SizedBox(width: 10), const Expanded(child: Text('Pause sync on mobile data', style: TextStyle(fontWeight: FontWeight.w800))), Switch.adaptive(value: _wifiOnly, onChanged: (value) async { await OfflineRequestQueue.setWifiOnly(value); await _refresh(); })]),
                    Align(alignment: Alignment.centerLeft, child: Text('Wi-Fi only keeps queued photo uploads from using cellular data.', style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant))),
                  ]))),
                  const SizedBox(height: 12),
                  SizedBox(height: 52, child: FilledButton.icon(onPressed: _items.isEmpty ? null : _syncAll, icon: const Icon(Icons.sync_rounded), label: const Text('Sync All Now', style: TextStyle(fontWeight: FontWeight.w900)))),
                  const SizedBox(height: 18),
                  if (_items.isEmpty) const _EmptyQueue() else ..._items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _QueueItem(item: item, label: _label(item), payloadBytes: _payloadBytes(item), formatSize: _formatSize, onRetry: () => _retry(item.id), onRemove: () => _remove(item.id)))),
                ],
              ),
            ),
    );
  }
}

class _QueueSummary extends StatelessWidget {
  const _QueueSummary({required this.count});
  final int count;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: AppColors.forest.withOpacity(.09), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.forest.withOpacity(.16))), child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.cloud_upload_outlined, color: Colors.white)), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pending synchronization', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('Drafts, uploads and AI work waiting for a connection.', style: TextStyle(fontSize: 11))])), Text('$count', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: AppColors.forest))]));
}

class _QueueItem extends StatelessWidget {
  const _QueueItem({required this.item, required this.label, required this.payloadBytes, required this.formatSize, required this.onRetry, required this.onRemove});
  final OfflineRequest item;
  final String label;
  final Future<int> payloadBytes;
  final String Function(int) formatSize;
  final VoidCallback onRetry;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    final failed = item.type == 'failed_upload' || item.payload['status'] == 'failed';
    return Semantics(container: true, label: '$label, queued item', child: Card(child: ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
      leading: CircleAvatar(backgroundColor: failed ? Colors.red.withOpacity(.10) : AppColors.saffron.withOpacity(.15), child: Icon(failed ? Icons.error_outline_rounded : Icons.cloud_upload_outlined, color: failed ? Colors.red : AppColors.clay)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: FutureBuilder<int>(future: payloadBytes, builder: (context, snapshot) { final size = snapshot.hasData ? formatSize(snapshot.data!) : 'Calculating size…'; return Text('$size\n${failed ? 'Failed upload — tap retry' : 'Waiting for connection'}', style: const TextStyle(fontSize: 11, height: 1.4)); }),
      isThreeLine: true,
      trailing: Wrap(children: [IconButton(tooltip: 'Retry', onPressed: onRetry, icon: const Icon(Icons.refresh_rounded)), IconButton(tooltip: 'Remove', onPressed: onRemove, icon: const Icon(Icons.delete_outline_rounded))]),
    )));
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 50), child: Column(children: [Icon(Icons.cloud_done_outlined, size: 58, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(height: 12), const Text('Everything is synced', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 5), const Text('There are no pending uploads on this device.', textAlign: TextAlign.center)]));
}
