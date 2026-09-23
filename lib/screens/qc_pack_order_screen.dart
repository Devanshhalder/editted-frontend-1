import 'package:flutter/material.dart';

class QcPackOrderScreen extends StatefulWidget {
  const QcPackOrderScreen({super.key});
  @override State<QcPackOrderScreen> createState() => _QcPackOrderScreenState();
}
class _QcPackOrderScreenState extends State<QcPackOrderScreen> {
  final checks = <String, bool>{'GI Tag attached': false, 'Fragile edges padded': false, 'Correct product and quantity': false, 'Parcel sealed securely': false};
  @override Widget build(BuildContext context) { final ready = checks.values.every((e) => e); return Scaffold(appBar: AppBar(title: const Text('Quality Check')), body: ListView(padding: const EdgeInsets.all(16), children: [const Text('Before dispatch', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), const SizedBox(height: 8), ...checks.keys.map((k) => CheckboxListTile(value: checks[k], title: Text(k), onChanged: (v) => setState(() => checks[k] = v ?? false))), const SizedBox(height: 16), FilledButton.icon(onPressed: ready ? () {} : null, icon: const Icon(Icons.local_shipping), label: Text(ready ? 'Ready for shipping label' : 'Complete all checks'))])); }
}
