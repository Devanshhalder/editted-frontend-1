
import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/session_service.dart';
import '../services/profile_storage.dart';
import '../services/app_localization.dart';
import '../theme.dart';

String _tr(BuildContext context, String key) {
  return AppLocalization.text(
    AppScope.of(context).language,
    key,
  );
}


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, .035),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      const Duration(milliseconds: 80),
          () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _editProfile(AppState state) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(state: state),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _tr(context, 'profileUpdated'),
            ),
          ),
        );
    }
  }

  Future<void> _showShopDetails(AppState state) async {
    final saved = await ProfileStorage.load();
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InfoSheet(
        icon: Icons.storefront_rounded,
        title: _tr(context, 'shopDetails'),
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.storefront_outlined,
              label: _tr(context, 'shopName'),
              value: state.businessName.trim().isEmpty ? 'User handicrafts' : state.businessName,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: _tr(context, 'artisan'),
              value: state.profileName.trim().isEmpty ? 'USER' : state.profileName,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: _tr(context, 'contact'),
              value: state.contactInfo,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: _tr(context, 'location'),
              value: 'MP INDIA',
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        icon: Icons.notifications_active_rounded,
        title: _tr(context, 'notifications'),
        child: Column(
          children: [
            _NotificationRow(
              icon: Icons.shopping_bag_outlined,
              title: _tr(context, 'orderUpdates'),
              subtitle:
              _tr(context, 'orderUpdatesSubtitle'),
            ),
            SizedBox(height: 10),
            _NotificationRow(
              icon: Icons.auto_awesome_rounded,
              title: _tr(context, 'aiSuggestions'),
              subtitle:
              _tr(context, 'aiSuggestionsSubtitle'),
            ),
            SizedBox(height: 10),
            _NotificationRow(
              icon: Icons.trending_up_rounded,
              title: _tr(context, 'shopInsights'),
              subtitle:
              _tr(context, 'shopInsightsSubtitle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InfoSheet(
        icon: Icons.support_agent_rounded,
        title: _tr(context, 'helpSupport'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr(context, 'howCanHelp'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _HelpButton(
              icon: Icons.auto_awesome_rounded,
              title: _tr(context, 'usingAITools'),
              onTap: () => _showMessage(
                _tr(context, 'usingAIToolsMessage'),
              ),
            ),
            const SizedBox(height: 9),
            _HelpButton(
              icon: Icons.mic_none_rounded,
              title: _tr(context, 'voiceDescriptions'),
              onTap: () => _showMessage(
                _tr(context, 'voiceDescriptionsMessage'),
              ),
            ),
            const SizedBox(height: 9),
            _HelpButton(
              icon: Icons.storefront_outlined,
              title: _tr(context, 'catalogPublishing'),
              onTap: () => _showMessage(
                _tr(context, 'catalogPublishingMessage'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    Navigator.pop(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _tr(context, 'logoutQuestion'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          _tr(context, 'logoutMessage'),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: Text(_tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text(_tr(context, 'logOut')),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    AppScope.of(context).logout();
    await SessionService.clearSession();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                14,
                20,
                110,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr(context, 'myProfile'),
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.7,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _tr(context, 'profileSubtitle'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ScaleTap(
                      onTap: () => _editProfile(state),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.brightness ==
                              Brightness.dark
                              ? AppColors.clay
                              : AppColors.ink,
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 17,
                            ),
                            SizedBox(width: 6),
                            Text(
                              _tr(context, 'editProfile'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _ProfileCard(state: state),

                const SizedBox(height: 26),

                Text(
                  _tr(context, 'yourStorefront'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 10),

                _ProfileAction(
                  icon: Icons.storefront_outlined,
                  title: _tr(context, 'shopDetails'),
                  subtitle: state.businessName.trim().isEmpty ? 'User handicrafts' : state.businessName,
                  accent: AppColors.clay,
                  onTap: () =>
                      _showShopDetails(state),
                ),

                const SizedBox(height: 10),

                _ProfileAction(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: state.language,
                  accent: AppColors.forest,
                  onTap: () =>
                      Navigator.pushNamed(
                        context,
                        '/language',
                      ),
                ),

                const SizedBox(height: 24),

                Text(
                  _tr(context, 'preferencesSupport'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 10),

                // =========================================================
                // DARK MODE
                // =========================================================

                _DarkModeAction(
                  isDarkMode: state.isDarkMode,
                  onChanged: (value) {
                    state.isDarkMode = value;
                    state.notifyListeners();
                  },
                ),

                const SizedBox(height: 10),

                _ProfileAction(
                  icon: Icons.notifications_none_rounded,
                  title: _tr(context, 'notifications'),
                  subtitle:
                  _tr(context, 'ordersProductUpdates'),
                  accent: AppColors.saffron,
                  onTap: _showNotifications,
                ),

                const SizedBox(height: 10),

                _ProfileAction(
                  icon: Icons.help_outline_rounded,
                  title: _tr(context, 'helpSupport'),
                  subtitle:
                  _tr(context, 'helpLanguage'),
                  accent: AppColors.forest,
                  onTap: _showHelp,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 19,
                    ),
                    label: Text(
                      _tr(context, 'logOut'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  _tr(context, 'footer'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
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

// ============================================================================
// DARK MODE ACTION
// ============================================================================

class _DarkModeAction extends StatelessWidget {
  const _DarkModeAction({
    required this.isDarkMode,
    required this.onChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outline,
          width: .7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark
                  ? .18
                  : .035,
            ),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.forest.withOpacity(.22)
                  : AppColors.saffron.withOpacity(.12),
              borderRadius:
              BorderRadius.circular(15),
            ),
            child: AnimatedSwitcher(
              duration:
              const Duration(milliseconds: 250),
              transitionBuilder:
                  (child, animation) {
                return RotationTransition(
                  turns: Tween<double>(
                    begin: .75,
                    end: 1,
                  ).animate(animation),
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                key: ValueKey(isDarkMode),
                color: isDarkMode
                    ? AppColors.saffron
                    : AppColors.clay,
                size: 23,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: AnimatedSwitcher(
              duration:
              const Duration(milliseconds: 220),
              transitionBuilder:
                  (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey(isDarkMode),
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr(context, 'darkMode'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDarkMode
                        ? _tr(context, 'darkModeOn')
                        : _tr(context, 'darkModeOff'),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                      colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Switch.adaptive(
            value: isDarkMode,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROFILE CARD
// ============================================================================

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.forest,
            Color(0xFF4D8B76),
          ],
        ),
        borderRadius:
        BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest
                .withOpacity(.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(.17),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white
                        .withOpacity(.36),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.profileName.trim().isEmpty ? 'USER' : state.profileName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight:
                        FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'MP INDIA',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified_rounded,
                color: Colors.white,
                size: 21,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            height: 1,
            color: Colors.white
                .withOpacity(.15),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  state.businessName.trim().isEmpty ? 'User handicrafts' : state.businessName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  state.contactInfo,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EDIT PROFILE SHEET
// ============================================================================

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.state,
  });

  final AppState state;

  @override
  State<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState
    extends State<_EditProfileSheet> {
  final _formKey =
  GlobalKey<FormState>();

  late final TextEditingController
  _nameController;

  late final TextEditingController
  _businessController;

  late final TextEditingController
  _contactController;

  late final TextEditingController
  _locationController;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(
          text: widget.state.profileName,
        );

    _businessController =
        TextEditingController(
          text: widget.state.businessName,
        );

    _contactController =
        TextEditingController(
          text: widget.state.contactInfo,
        );

    _locationController =
        TextEditingController(
          text: 'MP INDIA',
        );

    ProfileStorage.load().then((saved) {
      if (!mounted) return;
      _locationController.text = saved['location'] ?? 'MP INDIA';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String? _required(
      String? value,
      String label,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return '$label is required';
    }

    if (value.trim().length < 2) {
      return '$label is too short';
    }

    return null;
  }

  String? _contactValidator(
      BuildContext context,
      String? value,
      ) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return _tr(context, 'contactRequired');
    }

    final valid = RegExp(
      r'^[+0-9][0-9\s-]{7,17}$',
    ).hasMatch(text);

    if (!valid) {
      return _tr(context, 'validPhone');
    }

    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState
        ?.validate() ??
        false)) {
      return;
    }

    final name = _nameController.text.trim();
    final shop = _businessController.text.trim();
    final contact = _contactController.text.trim();
    final location = _locationController.text.trim();

    widget.state.updateProfile(
      name: name,
      business: shop,
      contact: contact,
    );

    await ProfileStorage.save(
      name: name,
      location: location,
      shop: shop,
      contact: contact,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.viewInsetsOf(context).bottom;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding:
        EdgeInsets.only(bottom: bottom),
        child: Container(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            22,
          ),
          decoration: BoxDecoration(
            color:
            theme.scaffoldBackgroundColor,
            borderRadius:
            const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outline,
                        borderRadius:
                        BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    _tr(context, 'editProfile'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _tr(context, 'updateProfileInfo'),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                      colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller:
                    _nameController,
                    textCapitalization:
                    TextCapitalization.words,
                    validator: (v) =>
                        _required(
                          v,
                          _tr(context, 'name'),
                        ),
                    decoration:
                    InputDecoration(
                      labelText: _tr(context, 'name'),
                      hintText: _tr(context, 'yourName'),
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                    _businessController,
                    textCapitalization:
                    TextCapitalization.words,
                    validator: (v) =>
                        _required(
                          v,
                          _tr(context, 'businessName'),
                        ),
                    decoration:
                    InputDecoration(
                      labelText:
                      _tr(context, 'businessName'),
                      hintText:
                      _tr(context, 'yourShopName'),
                      prefixIcon: Icon(
                        Icons.storefront_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                    _contactController,
                    keyboardType:
                    TextInputType.phone,
                    validator: (v) => _contactValidator(context, v),
                    decoration:
                    InputDecoration(
                      labelText:
                      _tr(context, 'contactInfo'),
                      hintText:
                      '+91 98765 43210',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => _required(
                      v,
                      _tr(context, 'location'),
                    ),
                    decoration: InputDecoration(
                      labelText: _tr(context, 'location'),
                      hintText: 'MP INDIA',
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(
                        Icons.check_rounded,
                      ),
                      label: Text(
                        _tr(context, 'saveChanges'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SCALE TAP
// ============================================================================

class _ScaleTap extends StatefulWidget {
  const _ScaleTap({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_ScaleTap> createState() =>
      _ScaleTapState();
}

class _ScaleTapState
    extends State<_ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? .95 : 1,
        duration:
        const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// PROFILE ACTION
// ============================================================================

class _ProfileAction
    extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
          BorderRadius.circular(20),
          border: Border.all(
            color: colors.outline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                theme.brightness ==
                    Brightness.dark
                    ? .18
                    : .035,
              ),
              blurRadius: 13,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withOpacity(.11),
                borderRadius:
                BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: accent,
                size: 23,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                      colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// INFO SHEET
// ============================================================================

class _InfoSheet
    extends StatelessWidget {
  const _InfoSheet({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Container(
        padding:
        const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          22,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
          const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius:
                BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.forest
                        .withOpacity(.10),
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.forest,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            child,
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DETAIL ROW
// ============================================================================

class _DetailRow
    extends StatelessWidget {
  _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color: colors.outline,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.clay,
            size: 20,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                    colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NOTIFICATION ROW
// ============================================================================

class _NotificationRow
    extends StatelessWidget {
  _NotificationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color: colors.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.saffron
                  .withOpacity(.13),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.clay,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    color:
                    colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELP BUTTON
// ============================================================================

class _HelpButton
    extends StatelessWidget {
  const _HelpButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceVariant,
      borderRadius:
      BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(15),
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(15),
            border: Border.all(
              color: colors.outline,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.forest,
                size: 20,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
