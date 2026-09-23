import 'package:flutter/material.dart';

/// Lightweight app-wide route transition used by KarigarKart.
///
/// It combines a short fade, a tiny horizontal slide and a subtle scale.
/// The animation only affects the route's composited layer, keeping it
/// inexpensive enough for lower-end Android devices.
class KarigarPageRoute<T> extends PageRouteBuilder<T> {
  KarigarPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    this.beginOffset = const Offset(.035, 0),
  }) : super(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 190),
    pageBuilder: (context, animation, secondaryAnimation) =>
        builder(context),
    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slide = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(curved);

      final scale = Tween<double>(
        begin: .985,
        end: 1,
      ).animate(curved);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(
            scale: scale,
            child: child,
          ),
        ),
      );
    },
  );

  final Offset beginOffset;
}

/// Use for modal/detail screens where a little more vertical motion feels
/// natural than the normal horizontal navigation transition.
class KarigarDetailRoute<T> extends KarigarPageRoute<T> {
  KarigarDetailRoute({
    required super.builder,
    super.settings,
  }) : super(beginOffset: const Offset(0, .025));
}
