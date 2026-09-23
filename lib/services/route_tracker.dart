import 'package:flutter/material.dart';

class KarigarKartRouteTracker extends NavigatorObserver {
  final ValueNotifier<String?> currentRoute = ValueNotifier<String?>(null);

  void _set(Route<dynamic>? route) {
    currentRoute.value = route?.settings.name;
  }

  @override void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) { super.didPush(route, previousRoute); _set(route); }
  @override void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) { super.didPop(route, previousRoute); _set(previousRoute); }
  @override void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) { super.didReplace(newRoute: newRoute, oldRoute: oldRoute); _set(newRoute); }
  @override void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) { super.didRemove(route, previousRoute); if (currentRoute.value == route.settings.name) _set(previousRoute); }
}
