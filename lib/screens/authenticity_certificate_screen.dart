import 'package:flutter/material.dart';

class AuthenticityCertificateScreen extends StatelessWidget {
  const AuthenticityCertificateScreen({super.key, this.productName = 'Handmade Craft'});
  final String productName;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Craft Heritage Passport')), body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.verified, size: 70), const SizedBox(height: 12), const Text('Authenticity Certificate', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), const SizedBox(height: 18), Text(productName, style: const TextStyle(fontSize: 20)), const Divider(height: 32), const ListTile(title: Text('Craftsperson'), subtitle: Text('Verified profile information')), const ListTile(title: Text('Provenance'), subtitle: Text('Artisan profile • cluster • GI information')), const SizedBox(height: 12), FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.qr_code), label: const Text('Generate provenance QR'))]))))));
}
