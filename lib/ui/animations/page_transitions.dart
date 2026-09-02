import 'package:flutter/material.dart';

/// Custom page transitions for the Nexora app.
/// Provides smooth, audiophile-grade transitions between screens.
class AppPageTransitions {
  AppPageTransitions._();

  /// A smooth fade + scale transition for detail pages
  static PageRouteBuilder<T> fadeScale<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// A slide up transition for bottom sheets and modals
  static PageRouteBuilder<T> slideUp<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInQuart,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(opacity: curve, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// A shared axis transition for sibling screens
  static PageRouteBuilder<T> sharedAxis<T>({
    required Widget page,
    RouteSettings? settings,
    Axis direction = Axis.horizontal,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );

        final slideAnimation = Tween<Offset>(
          begin: direction == Axis.horizontal
              ? const Offset(0.05, 0)
              : const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curve);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: curve, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// A hero-like transition for album artwork
  static PageRouteBuilder<T> heroLike<T>({
    required Widget page,
    RouteSettings? settings,
    required Rect originRect,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutExpo,
          reverseCurve: Curves.easeInExpo,
        );

        return AnimatedBuilder(
          animation: curve,
          builder: (context, child) {
            return FadeTransition(opacity: curve, child: child);
          },
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
    );
  }
}

/// A widget that adds a parallax scroll effect to its child.
class ParallaxScroll extends StatelessWidget {
  final ScrollController scrollController;
  final Widget child;
  final double parallaxFactor;

  const ParallaxScroll({
    super.key,
    required this.scrollController,
    required this.child,
    this.parallaxFactor = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final offset = scrollController.hasClients
            ? scrollController.offset * parallaxFactor
            : 0.0;

        return Transform.translate(offset: Offset(0, -offset), child: child);
      },
      child: child,
    );
  }
}

/// A widget that adds a fade edge effect to scrollable content.
class FadeEdgeScroll extends StatelessWidget {
  final Widget child;
  final double fadeHeight;
  final EdgeInsets padding;

  const FadeEdgeScroll({
    super.key,
    required this.child,
    this.fadeHeight = 40,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [
            0,
            fadeHeight / bounds.height,
            1 - (fadeHeight / bounds.height),
            1,
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Padding(padding: padding, child: child),
    );
  }
}
