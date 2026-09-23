import 'package:flutter/material.dart';

class SchemeHubScreen extends StatelessWidget {
  const SchemeHubScreen({super.key, this.trade = 'Artisan'});
  final String trade;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Schemes & Support')), body: ListView(padding: const EdgeInsets.all(16), children: [Text('Support for $trade', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 16), const Card(child: ListTile(leading: Icon(Icons.account_balance), title: Text('PM Vishwakarma'), subtitle: Text('Check official eligibility, benefits and application requirements.'), trailing: Icon(Icons.chevron_right))), const Card(child: ListTile(leading: Icon(Icons.business_center), title: Text('PMEGP'), subtitle: Text('Prepare your business information for an application.'), trailing: Icon(Icons.chevron_right))), const SizedBox(height: 12), const Text('Eligibility and benefit amounts can change. Confirm details on the official government portal before applying.') ]));
}
