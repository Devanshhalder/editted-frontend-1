import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BusinessToolsScreen extends StatefulWidget {
  const BusinessToolsScreen({super.key});
  @override State<BusinessToolsScreen> createState() => _BusinessToolsScreenState();
}

class _BusinessToolsScreenState extends State<BusinessToolsScreen> {
  final quantity = TextEditingController(text: '20');
  final material = TextEditingController(text: '2.0');
  final dye = TextEditingController(text: '0.25');
  final weight = TextEditingController(text: '2');
  final length = TextEditingController(text: '30');
  final width = TextEditingController(text: '20');
  final height = TextEditingController(text: '15');
  int _tab = 0;
  double get q => double.tryParse(quantity.text) ?? 0;

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Business Tools')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('Khata')), ButtonSegment(value: 1, label: Text('Plan')), ButtonSegment(value: 2, label: Text('DNK'))], selected: {_tab}, onSelectionChanged: (s) => setState(() => _tab = s.first)),
      const SizedBox(height: 16),
      if (_tab == 0) _khata() else if (_tab == 1) _plan() else _dnk(),
    ]),
  );

  Widget _khata() => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Micro-Khata', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    SizedBox(height: 190, child: PieChart(PieChartData(sections: [PieChartSectionData(value: 62, title: '62% Profit'), PieChartSectionData(value: 38, title: '38% Cost')]))),
    const ListTile(leading: Icon(Icons.schedule), title: Text('Pending Payouts'), trailing: Text('₹2,500\n3 days')),
    const ListTile(leading: Icon(Icons.account_balance), title: Text('Cleared Earnings'), trailing: Text('₹8,750')),
  ])));

  Widget _plan() => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    const Text('Plan Production', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    TextField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
    TextField(controller: material, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Raw material / unit (kg)')),
    TextField(controller: dye, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Dye / unit (kg)')),
    const SizedBox(height: 12),
    FilledButton(onPressed: () => setState(() {}), child: const Text('Calculate')), 
    ListTile(title: const Text('Raw material needed'), trailing: Text('${(q * (double.tryParse(material.text) ?? 0)).toStringAsFixed(2)} kg')),
    ListTile(title: const Text('Dye needed'), trailing: Text('${(q * (double.tryParse(dye.text) ?? 0)).toStringAsFixed(2)} kg')),
  ])));

  Widget _dnk() => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    const Text('India Post / DNK Shipping Estimate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    TextField(controller: weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)')),
    Row(children: [Expanded(child: TextField(controller: length, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'L (cm)'))), const SizedBox(width: 8), Expanded(child: TextField(controller: width, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'W (cm)'))), const SizedBox(width: 8), Expanded(child: TextField(controller: height, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'H (cm)')))]),
    const SizedBox(height: 12),
    FilledButton(onPressed: () => setState(() {}), child: const Text('Estimate')), 
    const ListTile(title: Text('Estimated shipping'), subtitle: Text('Client-side planning estimate only. Confirm the final India Post/DNK tariff before payment.')),
  ])));

  @override void dispose() { quantity.dispose(); material.dispose(); dye.dispose(); weight.dispose(); length.dispose(); width.dispose(); height.dispose(); super.dispose(); }
}
