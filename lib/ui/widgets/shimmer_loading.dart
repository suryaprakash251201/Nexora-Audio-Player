import 'package:flutter/material.dart';

import '../theme.dart';

/// Premium shimmer loading skeleton for the Nexora Hi-Fi design.
///
/// Uses a subtle wave animation that travels across placeholder blocks,
/// giving the impression of content being prepared. Much more polished
/// than a static spinner.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlideGradientTransform(percent: _controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double percent;

  const _SlideGradientTransform({required this.percent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * 2 * (percent - 0.5), 0, 0);
  }
}

/// Pre-built shimmer placeholders for common content shapes.
class ShimmerPlaceholders {
  ShimmerPlaceholders._();

  /// A shimmer block with customizable dimensions and radius.
  static Widget block({double? width, double? height, double radius = 8}) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  /// Circular shimmer placeholder (for avatars, album art).
  static Widget circle({double size = 48}) {
    return ShimmerLoading(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Song list item shimmer with artwork + text lines.
  static Widget songTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          circle(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(width: double.infinity, height: 14, radius: 4),
                const SizedBox(height: 8),
                block(width: 120, height: 12, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Album grid item shimmer.
  static Widget albumGridItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: block(radius: 8)),
        const SizedBox(height: 8),
        block(width: double.infinity, height: 14, radius: 4),
        const SizedBox(height: 4),
        block(width: 80, height: 12, radius: 4),
      ],
    );
  }

  /// Horizontal scrolling row shimmer (for recent songs, etc).
  static Widget horizontalRow({int itemCount = 6}) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: block(radius: 8)),
              const SizedBox(height: 8),
              block(width: double.infinity, height: 14, radius: 4),
              const SizedBox(height: 4),
              block(width: 100, height: 12, radius: 4),
            ],
          ),
        ),
      ),
    );
  }

  /// Hero section shimmer for home screen.
  static Widget heroSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(width: 200, height: 28, radius: 6),
          const SizedBox(height: 16),
          block(width: double.infinity, height: 160, radius: 12),
        ],
      ),
    );
  }
}
