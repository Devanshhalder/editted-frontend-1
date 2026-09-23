import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'models/product.dart';
import 'services/accessibility_theme.dart';
import 'services/ai_background_service.dart';
import 'services/app_localization.dart';
import 'services/app_state.dart';
import 'services/app_transitions.dart';
import 'services/artisan_identity_storage.dart';
import 'services/catalog_local_db.dart';
import 'services/deep_link_service.dart';
import 'services/haptic_feedback_service.dart';
import 'services/local_logger.dart';
import 'services/offline_request_queue.dart';
import 'services/profile_storage.dart';
import 'services/route_tracker.dart';
import 'services/session_service.dart';
import 'screens/add_product_screen.dart';
import 'screens/ai_flow_screens.dart';
import 'screens/auth_screen.dart';
import 'screens/business_manager_hub.dart';
import 'screens/catalog_enhanced_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/market_linkage_screen.dart';
import 'screens/market_publish_screen.dart';
import 'screens/pricing_assistant_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/profile_enhanced_screen.dart';
import 'screens/sync_queue_screen.dart';
import 'theme.dart';
import 'widgets/ai_consent_gate.dart';
import 'widgets/audio_assistance.dart';
import 'widgets/network_status_overlay.dart';

final KarigarKartRouteTracker _routeTracker = KarigarKartRouteTracker();
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

String _tr(BuildContext context, String key) => AppLocalization.text(AppScope.of(context).language, key);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalLogger.initialize();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    LocalLogger.error(details.exception, details.stack ?? StackTrace.current, source: 'FlutterError.onError');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    LocalLogger.error(error, stack, source: 'PlatformDispatcher.onError');
    return true;
  };

  await CatalogLocalDb.initialize();
  final state = AppState();
  if (await SessionService.isLoggedIn()) state.login();
  final profile = await ProfileStorage.load();
  state.updateProfile(name: profile['name'] ?? 'USER', business: profile['shop'] ?? 'User handicrafts', contact: profile['contact'] ?? state.contactInfo);
  final identity = await ArtisanIdentityStorage.load();
  state.updateArtisanIdentity(pehchanId: identity['pehchanId'] ?? '', giTag: identity['giTag'] ?? '', affiliation: identity['affiliation'] ?? '');
  await state.restoreCatalog();
  await OfflineRequestQueue.initialize();
  if (AiBackgroundService.isBackgroundSupported) await AiBackgroundService.initialize();

  runApp(_PrecacheAssets(state: state));
  unawaited(DeepLinkService.initialize(navigatorKey: _navigatorKey, state: state));
}

class _PrecacheAssets extends StatefulWidget {
  const _PrecacheAssets({required this.state});
  final AppState state;
  @override
  State<_PrecacheAssets> createState() => _PrecacheAssetsState();
}

class _PrecacheAssetsState extends State<_PrecacheAssets> {
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_precache());
  }

  Future<void> _precache() async {
    await Future.wait([
      precacheImage(const AssetImage('assets/1789124007216.png'), context),
      precacheImage(const AssetImage('assets/loginbackground.jpeg'), context),
      precacheImage(const AssetImage('assets/s1.png'), context),
      precacheImage(const AssetImage('assets/s2.png'), context),
      precacheImage(const AssetImage('assets/s3.png'), context),
    ]);
  }

  @override
  Widget build(BuildContext context) => KarigarKartApp(state: widget.state);
}

class KarigarKartApp extends StatelessWidget {
  const KarigarKartApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => AppScope(
        state: state,
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'KarigarKart',
          debugShowCheckedModeBanner: false,
          theme: state.highContrastMode ? buildHighContrastTheme(darkMode: false) : buildTheme(),
          darkTheme: state.highContrastMode ? buildHighContrastTheme(darkMode: true) : buildTheme(darkMode: true),
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          themeAnimationDuration: const Duration(milliseconds: 250),
          navigatorObservers: [_routeTracker],
          builder: (context, child) => AudioAssistanceOverlay(
            routeTracker: _routeTracker,
            child: NetworkStatusOverlay(
              child: ScrollConfiguration(behavior: const _AppScrollBehavior(), child: child ?? const SizedBox.shrink()),
            ),
          ),
          home: const EntryGate(),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/home': return KarigarPageRoute(settings: settings, beginOffset: const Offset(0, .012), builder: (_) => const MainShell());
              case '/add': return KarigarPageRoute(settings: settings, builder: (_) => const AddProductScreen());
              case '/language': return KarigarPageRoute(settings: settings, builder: (_) => const LanguageScreen());
              case '/processing': return KarigarPageRoute(settings: settings, builder: (_) => const AiConsentGate(child: ProcessingScreen()));
              case '/preview': return KarigarPageRoute(settings: settings, builder: (_) => const ImagePreviewScreen());
              case '/listing': return KarigarPageRoute(settings: settings, builder: (_) => const ListingScreen());
              case '/publish': return KarigarPageRoute(settings: settings, builder: (_) => const MarketPublishScreen());
              case '/catalog': return KarigarPageRoute(settings: settings, builder: (_) => const CatalogEnhancedScreen());
              case '/product-detail':
                final product = settings.arguments;
                if (product is Product) return KarigarPageRoute(settings: settings, builder: (_) => ProductDetailScreen(product: product));
                return KarigarPageRoute(settings: settings, builder: (_) => const CatalogEnhancedScreen());
              case '/market-linkage': return KarigarPageRoute(settings: settings, builder: (_) => const MarketLinkageScreen());
              case '/pricing-assistant': return KarigarPageRoute(settings: settings, builder: (_) => const PricingAssistantScreen());
              case '/profile': return KarigarPageRoute(settings: settings, builder: (_) => const ProfileEnhancedScreen());
              case '/sync-queue': return KarigarPageRoute(settings: settings, builder: (_) => const SyncQueueScreen());
            }
            return null;
          },
          onUnknownRoute: (settings) => KarigarPageRoute(settings: settings, builder: (_) => const EntryGate()),
        ),
      ),
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad};
}

class EntryGate extends StatelessWidget {
  const EntryGate({super.key});
  @override
  Widget build(BuildContext context) {
    final loggedIn = AppScope.of(context).isLoggedIn;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(opacity: curved, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .018), end: Offset.zero).animate(curved), child: ScaleTransition(scale: Tween<double>(begin: .992, end: 1).animate(curved), child: child)));
      },
      child: loggedIn ? const MainShell(key: ValueKey('main-shell')) : const AuthScreen(key: ValueKey('auth-screen')),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  int _previousIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const DashboardScreen(), const BusinessManagerHub(), const CatalogEnhancedScreen(embedded: true), const ProfileEnhancedScreen(embedded: true)];
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        reverseDuration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
          final direction = index >= _previousIndex ? 1.0 : -1.0;
          return FadeTransition(opacity: curved, child: SlideTransition(position: Tween<Offset>(begin: Offset(.045 * direction, .012), end: Offset.zero).animate(curved), child: ScaleTransition(scale: Tween<double>(begin: .985, end: 1).animate(curved), child: child)));
        },
        child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 76,
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: colors.outline, width: .7), boxShadow: [BoxShadow(color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? .25 : .08), blurRadius: 22, offset: const Offset(0, 8))]),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) {
              if (value == index) return;
              KarigarKartHaptics.selection();
              setState(() { _previousIndex = index; index = value; });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 76,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: _tr(context, 'home')),
              NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights_rounded), label: _tr(context, 'dashboard')),
              NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view_rounded), label: _tr(context, 'catalog')),
              NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: _tr(context, 'profile')),
            ],
          ),
        ),
      ),
    );
  }
}
