import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/artisan_identity_storage.dart';
import '../theme.dart';

class ArtisanIdentityPanel extends StatefulWidget {
  const ArtisanIdentityPanel({super.key});

  @override
  State<ArtisanIdentityPanel> createState() => _ArtisanIdentityPanelState();
}

class _ArtisanIdentityPanelState extends State<ArtisanIdentityPanel> {
  late final TextEditingController _pehchan;
  late final TextEditingController _affiliation;
  bool _loaded = false;

  static const _giTags = [
    'Chanderi Silk',
    'Dhokra Art',
    'Madhubani Painting',
    'Banarasi Silk',
    'Kutch Embroidery',
    'Kashmir Pashmina',
    'Blue Pottery',
    'Other / Not Listed',
  ];

  @override
  void initState() {
    super.initState();
    _pehchan = TextEditingController();
    _affiliation = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final saved = await ArtisanIdentityStorage.load();
    if (!mounted) return;
    final state = AppScope.of(context);
    state.updateArtisanIdentity(
      pehchanId: saved['pehchanId'] ?? '',
      giTag: saved['giTag'] ?? '',
      affiliation: saved['affiliation'] ?? '',
    );
    _pehchan.text = state.pehchanId;
    _affiliation.text = state.artisanAffiliation;
    setState(() => _loaded = true);
  }

  Future<void> _save(String giTag) async {
    final state = AppScope.of(context);
    state.updateArtisanIdentity(
      pehchanId: _pehchan.text,
      giTag: giTag,
      affiliation: _affiliation.text,
    );
    await ArtisanIdentityStorage.save(
      pehchanId: state.pehchanId,
      giTag: state.giTag,
      affiliation: state.artisanAffiliation,
    );
  }

  @override
  void dispose() {
    _pehchan.dispose();
    _affiliation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final state = AppScope.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          'Pehchan & Craft Identity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add verification details used for artisan identity and authenticity.',
          style: TextStyle(
            fontSize: 11,
            height: 1.4,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pehchan,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => _save(state.giTag),
          decoration: const InputDecoration(
            labelText: 'Pehchan ID / Artisan Card Number',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: state.giTag.isEmpty ? null : state.giTag,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Geographical Indication (GI) Tag',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          items: _giTags
              .map(
                (tag) => DropdownMenuItem(
              value: tag,
              child: Text(tag, overflow: TextOverflow.ellipsis),
            ),
          )
              .toList(),
          onChanged: (value) {
            if (value != null) _save(value);
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _affiliation,
          onChanged: (_) => _save(state.giTag),
          decoration: const InputDecoration(
            labelText: 'SHG / Cluster / Cooperative Affiliation',
            prefixIcon: Icon(Icons.groups_outlined),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: state.isIdentityVerified
                ? AppColors.forest.withOpacity(.09)
                : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: state.isIdentityVerified
                  ? AppColors.forest.withOpacity(.25)
                  : colors.outline.withOpacity(.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                state.isIdentityVerified
                    ? Icons.verified_rounded
                    : Icons.shield_outlined,
                color: state.isIdentityVerified
                    ? AppColors.forest
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.isIdentityVerified
                      ? 'Handmade / Authentic Craftsperson'
                      : 'Add identity details to preview your authenticity badge.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF332F2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileIdentityPreview extends StatelessWidget {
  const ProfileIdentityPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.isIdentityVerified) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.forest.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.forest.withOpacity(.25)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 16, color: AppColors.forest),
          SizedBox(width: 5),
          Text(
            'Handmade / Authentic Craftsperson',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
            ),
          ),
        ],
      ),
    );
  }
}