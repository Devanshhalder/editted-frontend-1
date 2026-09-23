import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/motion_widgets.dart';

class PricingAssistantScreen extends StatefulWidget {
  const PricingAssistantScreen({super.key});

  @override
  State<PricingAssistantScreen> createState() => _PricingAssistantScreenState();
}

class _PricingAssistantScreenState extends State<PricingAssistantScreen> {
  final _material = TextEditingController(text: '500');
  final _hours = TextEditingController(text: '8');
  final _wage = TextEditingController(text: '150');
  final _packaging = TextEditingController(text: '100');

  bool _loading = false;
  int? _recommended;
  int _min = 0;
  int _average = 0;
  int _premium = 0;
  double _profit = 0;
  double _fairWage = 0;
  String _trend = '';
  String _reason = '';
  bool _fallback = false;

  static const _baseUrl = 'http://10.70.33.153:8000';

  int _int(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  double _double(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  double get _labor => _double(_hours) * _double(_wage);

  double get _totalCost =>
      _int(_material) + _labor + _int(_packaging);

  @override
  void dispose() {
    _material.dispose();
    _hours.dispose();
    _wage.dispose();
    _packaging.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  void _step(
    TextEditingController controller,
    double amount,
    double min,
    double max,
  ) {
    final next = (_double(controller) + amount).clamp(min, max);
    controller.text = next % 1 == 0
        ? next.toInt().toString()
        : next.toStringAsFixed(1);
    _changed();
  }

  Future<void> _calculate() async {
    if (_loading) return;

    final state = AppScope.of(context);
    final path = state.draftImagePath;
    final description = state.draft.description.trim();

    if (path == null || path.isEmpty) {
      _message('Add a product photo before asking AI to value it.');
      return;
    }

    if (description.length < 15) {
      _message('Add a little more product detail before valuation.');
      return;
    }

    setState(() => _loading = true);

    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Product image not found.');
      }

      final bytes = await file.readAsBytes();
      final ext = file.path.toLowerCase().split('.').last;
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/pricing'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'image_base64':
                  'data:$mime;base64,${base64Encode(bytes)}',
              'description': description,
              'raw_material_cost': _int(_material),
              'labor_hours': _double(_hours),
              'labor_rate': _double(_wage),
              'labor_cost': _labor + _int(_packaging),
              'packaging_cost': _int(_packaging),
              'category': state.draft.category,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        throw Exception(
          'Pricing service returned ${response.statusCode}.',
        );
      }

      final data = jsonDecode(response.body);
      if (data is! Map) {
        throw Exception('Invalid pricing response.');
      }

      final suggested = _num(data['suggested_price']);
      if (suggested <= 0) {
        throw Exception('AI returned an invalid recommendation.');
      }

      final range = data['price_range'];
      final rawLow = range is Map ? _num(range['low']) : 0;
      final rawHigh = range is Map ? _num(range['high']) : 0;
      final avg = suggested < _totalCost
          ? (_totalCost * 1.15).ceil()
          : suggested;
      final low = rawLow > 0
          ? rawLow
          : (_totalCost * 1.10).ceil();
      final high = rawHigh > avg
          ? rawHigh
          : (avg * 1.25).ceil();

      if (!mounted) return;

      setState(() {
        _recommended = avg;
        _min = low < high ? low : high;
        _average = avg;
        _premium = high;
        _fairWage = _labor;
        _profit = avg - _totalCost;
        _fallback = data['fallback'] == true;
        _reason = '${data['reasoning'] ?? ''}'.trim();
        _trend = state.language == 'Hindi'
            ? 'समान ${state.draft.category.isEmpty ? 'हस्तशिल्प' : state.draft.category} की कीमत मांग, कारीगरी और मौसम के अनुसार बदल सकती है।'
            : 'Similar ${state.draft.category.isEmpty ? 'handmade products' : state.draft.category} can command different prices as demand, craftsmanship and seasonality change.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Could not calculate a live AI benchmark. Please try again.');
    }
  }

  int _num(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Dynamic Pricing Assistant',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Price your craft fairly',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            'Add your real costs. AI combines them with the product photo, craft details and market positioning.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _photo(state.draftImagePath),
          const SizedBox(height: 20),
          const Text(
            'Cost inputs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'Use the sliders or ± controls. A fair wage is included so the recommendation does not treat artisan labor as free.',
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _input(
            'Raw Material Cost',
            _material,
            Icons.inventory_2_outlined,
            0,
            10000,
            100,
            prefix: '₹',
          ),
          const SizedBox(height: 10),
          _input(
            'Days / Hours of Crafting',
            _hours,
            Icons.schedule_rounded,
            1,
            120,
            1,
            suffix: ' hrs',
            decimal: true,
          ),
          const SizedBox(height: 10),
          _input(
            'Packaging & Logistics Estimate',
            _packaging,
            Icons.local_shipping_outlined,
            0,
            2000,
            50,
            prefix: '₹',
          ),
          const SizedBox(height: 10),
          _input(
            'Fair Wage / Hour',
            _wage,
            Icons.volunteer_activism_outlined,
            50,
            1000,
            25,
            prefix: '₹',
            suffix: '/hr',
            decimal: true,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total cost floor',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '₹${_totalCost.round()}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _loading ? null : _calculate,
              icon: _loading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _loading
                    ? 'Calculating…'
                    : 'Get AI price breakdown',
              ),
            ),
          ),
          const SizedBox(height: 20),
          _breakdown(colors),
        ],
      ),
    );
  }

  Widget _photo(String? path) {
    return Container(
      height: 145,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.saffron.withOpacity(.12),
      ),
      child: path != null && path.isNotEmpty
          ? Image.file(File(path), fit: BoxFit.cover)
          : const Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: AppColors.clay,
              ),
            ),
    );
  }

  Widget _input(
    String title,
    TextEditingController controller,
    IconData icon,
    double min,
    double max,
    double step, {
    String prefix = '',
    String suffix = '',
    bool decimal = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final value = _double(controller).clamp(min, max);
    final position = (value - min) / (max - min);

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 8, 7),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(.55),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 21, color: AppColors.forest),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: 88,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: decimal,
                  ),
                  onChanged: (_) => _changed(),
                  decoration: InputDecoration(
                    prefixText: prefix,
                    suffixText: suffix,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: position.clamp(0.0, 1.0),
                  onChanged: (p) {
                    final next = min + (max - min) * p;
                    final stepped =
                        ((next - min) / step).round() * step + min;
                    controller.text = stepped % 1 == 0
                        ? stepped.toInt().toString()
                        : stepped.toStringAsFixed(1);
                    _changed();
                  },
                ),
              ),
              _stepButton(
                Icons.remove_rounded,
                () => _step(controller, -step, min, max),
              ),
              const SizedBox(width: 4),
              _stepButton(
                Icons.add_rounded,
                () => _step(controller, step, min, max),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.forest.withOpacity(.09),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 19,
            color: AppColors.forest,
          ),
        ),
      ),
    );
  }

  Widget _breakdown(ColorScheme colors) {
    if (_recommended == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.forest.withOpacity(.07),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: AppColors.forest.withOpacity(.14),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.forest,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your AI price breakdown will appear here.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    final confidenceColor = _fallback
        ? colors.onErrorContainer
        : AppColors.forest;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.forest.withOpacity(.075),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.forest.withOpacity(.17),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'AI Price Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _fallback
                      ? colors.errorContainer
                      : AppColors.forest.withOpacity(.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _fallback
                      ? 'Confidence • Medium'
                      : 'Confidence • High',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: confidenceColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            'Recommended Selling Price',
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedPriceCounter(targetPrice: _average.toDouble()),
          const SizedBox(height: 5),
          Text(
            'Recommended price includes your ₹${_totalCost.round()} listed cost floor.',
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Market Price Range',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          _range(),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Fair wage',
                  '₹${_fairWage.round()}',
                  '${_hours.text} hrs × ₹${_wage.text}/hr',
                  colors,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metric(
                  'Profit / unit',
                  '₹${_profit.round()}',
                  'after listed costs',
                  colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(.75),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  size: 19,
                  color: AppColors.forest,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Market trend note',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _trend,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.45,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Why this price?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _reason,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _range() {
    return Column(
      children: [
        SizedBox(
          height: 22,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.forest.withOpacity(.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.forest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 3,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label('Min', _min),
            _label('Average', _average),
            _label('Premium', _premium),
          ],
        ),
      ],
    );
  }

  Widget _label(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₹$value',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _metric(
    String title,
    String value,
    String subtitle,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(.72),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
