import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/app_state.dart';
import '../services/app_transitions.dart';
import '../theme.dart';
import '../widgets/artisan_identity_panel.dart';
import '../widgets/whatsapp_showcase_card.dart';

class MarketPublishScreen extends StatefulWidget {
  const MarketPublishScreen({super.key});

  @override
  State<MarketPublishScreen> createState() => _MarketPublishScreenState();
}

class _MarketPublishScreenState extends State<MarketPublishScreen> {
  final Map<String, bool> _destinations = {
    'ONDC Network': true,
    'GeM Portal': true,
    'Tribes India / Shilp Bazaar': true,
    'B2B Bulk Export': false,
  };

  final _retail = TextEditingController(text: '1200');
  final _wholesale = TextEditingController(text: '850');

  bool _tiersOpen = false;
  bool _publishing = false;
  final int _readiness = 90;

  @override
  void dispose() {
    _retail.dispose();
    _wholesale.dispose();
    super.dispose();
  }

  Future<void> _openShowcase() async {
    final state = AppScope.of(context);
    final draft = state.draft;
    final imagePath = state.draftImagePath;

    if (imagePath == null || imagePath.isEmpty) {
      _message('Add a product photo before creating a showcase card.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: WhatsAppShowcaseCard(
            productId: draft.id,
            productNameEnglish:
                draft.title.isEmpty ? 'Handmade Craft' : draft.title,
            productNameHindi:
                draft.title.isEmpty ? 'हस्तनिर्मित शिल्प' : draft.title,
            price: draft.price,
            fairWage: (draft.price * .4).round(),
            imagePath: imagePath,
          ),
        ),
      ),
    );
  }

  Future<void> _publish() async {
    if (_publishing) return;

    final selected = _destinations.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selected.isEmpty) {
      _message('Select at least one publication destination.');
      return;
    }

    setState(() => _publishing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    AppScope.of(context).publishDraft();
    Navigator.pushReplacement(
      context,
      KarigarPageRoute(
        builder: (_) => PublishCompleteScreen(destinations: selected),
      ),
    );
  }

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
    final state = AppScope.of(context);
    final draft = state.draft;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Publish',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            Text(
              draft.title.isEmpty ? 'Ready to publish' : draft.title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose where this listing should be prepared for marketplace discovery.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            const ProfileIdentityPreview(),
            const SizedBox(height: 18),
            _readinessCard(colors),
            const SizedBox(height: 18),
            const Text(
              'Publication destinations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ..._destinations.keys.map(
              (name) => _destination(name, colors),
            ),
            const SizedBox(height: 12),
            _bulkCard(colors),
            const SizedBox(height: 14),
            Semantics(
              button: true,
              label: 'Create WhatsApp showcase card',
              hint: 'Create a bilingual product poster with QR code and price',
              child: OutlinedButton.icon(
                onPressed: _openShowcase,
                icon: const Icon(Icons.share_outlined),
                label: const Text(
                  'Create WhatsApp Showcase Card',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 55,
              child: FilledButton.icon(
                onPressed: _publishing ? null : _publish,
                icon: _publishing
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish_rounded),
                label: Text(
                  _publishing
                      ? 'Preparing publication…'
                      : 'Publish selected channels',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Marketplace switches prepare channel-specific publication targets. This prototype does not claim direct third-party API submission.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destination(String name, ColorScheme colors) {
    final on = _destinations[name] ?? false;
    final icon = name.startsWith('ONDC')
        ? Icons.hub_outlined
        : name.startsWith('GeM')
            ? Icons.account_balance_outlined
            : name.startsWith('Tribes')
                ? Icons.park_outlined
                : Icons.local_shipping_outlined;

    return Semantics(
      label: name,
      toggled: on,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: on
                ? AppColors.forest.withOpacity(.35)
                : colors.outline.withOpacity(.16),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.forest.withOpacity(.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.forest,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _subtitle(name),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: on,
              onChanged: (value) =>
                  setState(() => _destinations[name] = value),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(String name) {
    if (name.startsWith('ONDC')) {
      return 'Open Network for Digital Commerce';
    }
    if (name.startsWith('GeM')) {
      return 'Government e-Marketplace';
    }
    if (name.startsWith('Tribes')) {
      return 'Tribes India / Shilp Bazaar channel';
    }
    return 'Buyer-ready bulk order tiers';
  }

  Widget _bulkCard(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: colors.outline.withOpacity(.16),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            leading: const Icon(
              Icons.groups_rounded,
              color: AppColors.clay,
            ),
            title: const Text(
              'B2B Bulk pricing tiers',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            subtitle: const Text(
              'Set buyer-facing retail and wholesale rates',
            ),
            trailing: Icon(
              _tiersOpen
                  ? Icons.expand_less
                  : Icons.expand_more,
            ),
            onTap: () => setState(() => _tiersOpen = !_tiersOpen),
          ),
          if (_tiersOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  _tierField('Retail (1–5 units)', _retail),
                  const SizedBox(height: 9),
                  _tierField('Wholesale (20+ units)', _wholesale),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tierField(
    String label,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
    );
  }

  Widget _readinessCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forest.withOpacity(.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.forest.withOpacity(.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: AppColors.forest,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Listing readiness',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const Text(
                '90%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _readiness / 100,
              minHeight: 9,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '$_readiness% Ready for ONDC – Add 1 more image to reach 100%',
            style: TextStyle(
              fontSize: 11.5,
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _destinations.entries
                .where((entry) => entry.value)
                .map((entry) => _miniChip(entry.key))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.forest.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.forest,
        ),
      ),
    );
  }
}

class PublishCompleteScreen extends StatefulWidget {
  const PublishCompleteScreen({
    super.key,
    required this.destinations,
  });

  final List<String> destinations;

  @override
  State<PublishCompleteScreen> createState() =>
      _PublishCompleteScreenState();
}

class _PublishCompleteScreenState extends State<PublishCompleteScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setSpeechRate(.48);
    _tts.speak(
      'Publication prepared for your selected marketplace channels',
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 105,
                  height: 105,
                  decoration: const BoxDecoration(
                    color: AppColors.forest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 65,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Publication prepared',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Your listing was added to the local published catalog and prepared for the selected channels.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.outline.withOpacity(.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected channels',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      ...widget.destinations.map(
                        (destination) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 17,
                                color: AppColors.forest,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  destination,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
