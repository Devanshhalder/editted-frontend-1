import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import 'business_dashboard_screen.dart';

class BusinessDashboardHub extends StatefulWidget {
  const BusinessDashboardHub({super.key});

  @override
  State<BusinessDashboardHub> createState() => _BusinessDashboardHubState();
}

class _BusinessDashboardHubState extends State<BusinessDashboardHub> {
  int _tab = 0;
  final List<_Inquiry> _inquiries = [
    _Inquiry('Handwoven stole', 50, 'New Inquiry'),
    _Inquiry('Terracotta planters', 120, 'Sample Requested'),
    _Inquiry('Dhokra décor set', 80, 'Price Negotiating'),
  ];

  Future<void> _calculator(_Inquiry inquiry) async {
    final quantity = TextEditingController(text: inquiry.quantity.toString());
    final craftingDays = TextEditingController(text: '2');
    final batchCapacity = TextEditingController(text: '10');
    final rawMaterial = TextEditingController(text: '500');
    final price = TextEditingController(text: '1200');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          final q = int.tryParse(quantity.text) ?? 0;
          final days = double.tryParse(craftingDays.text) ?? 0;
          final capacity = double.tryParse(batchCapacity.text) ?? 1;
          final raw = double.tryParse(rawMaterial.text) ?? 0;
          final unitPrice = double.tryParse(price.text) ?? 0;
          final lead = capacity <= 0 ? 0 : (days * q / capacity).ceil();
          final discount = q >= 500
              ? .15
              : q >= 200
                  ? .10
                  : q >= 50
                      ? .05
                      : 0;
          final discountedUnit = unitPrice * (1 - discount);
          final total = discountedUnit * q;
          final quoteText = 'KarigarKart Bulk Quote\n'
              'Product: ${inquiry.product}\n'
              'Quantity: $q pieces\n'
              'Lead time: $lead days\n'
              'Discount: ${(discount * 100).round()}%\n'
              'Unit price: ₹${discountedUnit.round()}\n'
              'Total: ₹${total.round()}';

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.viewInsetsOf(sheet).bottom + 22,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instant bulk quotation',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  _numField(
                    quantity,
                    'Inquiry volume (pieces)',
                    (v) => setSheet(() {}),
                  ),
                  _numField(
                    craftingDays,
                    'Crafting days per batch',
                    (v) => setSheet(() {}),
                  ),
                  _numField(
                    batchCapacity,
                    'Batch capacity (pieces)',
                    (v) => setSheet(() {}),
                  ),
                  _numField(
                    rawMaterial,
                    'Raw material cost / unit (₹)',
                    (v) => setSheet(() {}),
                  ),
                  _numField(
                    price,
                    'Base selling price / unit (₹)',
                    (v) => setSheet(() {}),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          _calcRow('Production lead time', '$lead days'),
                          _calcRow('Bulk discount', '${(discount * 100).round()}%'),
                          _calcRow('Discounted unit price', '₹${discountedUnit.round()}'),
                          _calcRow('Material spend', '₹${(raw * q).round()}'),
                          _calcRow('Quotation total', '₹${total.round()}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(
                          'https://wa.me/?text=${Uri.encodeComponent(quoteText)}',
                        );
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text(
                        'Send Official Quote via WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(
                          'sms:?body=${Uri.encodeComponent(quoteText)}',
                        );
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text(
                        'Send Official Quote via SMS',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    quantity.dispose();
    craftingDays.dispose();
    batchCapacity.dispose();
    rawMaterial.dispose();
    price.dispose();
  }

  Widget _numField(
    TextEditingController controller,
    String label,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _calcRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(.22),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Business dashboard',
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = 0),
                        child: _Tab(
                          text: 'Dashboard',
                          selected: _tab == 0,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Wholesale inquiries',
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = 1),
                        child: _Tab(
                          text: 'Inquiries',
                          selected: _tab == 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _tab == 0
                ? const BusinessDashboardScreen()
                : _InquiryList(
                    inquiries: _inquiries,
                    onQuote: _calculator,
                    onStatus: (i, status) => setState(
                      () => _inquiries[i] = _inquiries[i].copyWith(status: status),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.text, required this.selected});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? AppColors.forest : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Inquiry {
  const _Inquiry(this.product, this.quantity, this.status);

  final String product;
  final int quantity;
  final String status;

  _Inquiry copyWith({String? status}) =>
      _Inquiry(product, quantity, status ?? this.status);
}

class _InquiryList extends StatelessWidget {
  const _InquiryList({
    required this.inquiries,
    required this.onQuote,
    required this.onStatus,
  });

  final List<_Inquiry> inquiries;
  final Future<void> Function(_Inquiry) onQuote;
  final void Function(int, String) onStatus;
  static const statuses = [
    'New Inquiry',
    'Sample Requested',
    'Price Negotiating',
    'Order Confirmed',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: inquiries.length,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
      itemBuilder: (context, index) {
        final item = inquiries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.business_center_outlined,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.product,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      '${item.quantity} pcs',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: item.status,
                  decoration: const InputDecoration(labelText: 'Inquiry status'),
                  items: statuses
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onStatus(index, v);
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => onQuote(item),
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text(
                      'Create bulk quotation',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
