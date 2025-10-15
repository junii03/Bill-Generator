import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// A small helper that provides a consistent morphing Hero flight between
/// an origin (typically a FAB or card) and a destination container.
///
/// Usage:
/// - Wrap the source widget with `Hero(tag: 'morph-<name>', child: ...)`.
/// - Wrap the destination container with the same `Hero` tag.
/// - Pass a [flightShuttleBuilder] is provided to create a smooth morphing
///   visual during navigation.
class MorphTransition {
  static Widget flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    // Enhanced morph with dynamic blur, 3D rotation, and perspective transforms
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(animation.value);

        // Dynamic blur with cubic curve for stronger depth effect
        final blurT = Curves.easeInOutCubic.transform(animation.value);
        final blurSigma = 12.0 * (1 - blurT); // Increased from 2.0 to 12.0

        // 3D rotation calculation - peaks at mid-transition (t=0.5)
        final rotationT = math.sin(animation.value * math.pi);
        final rotationAngle = rotationT * 0.21; // ~12 degrees in radians

        // Rotation direction based on flight direction
        final rotationDirection = flightDirection == HeroFlightDirection.push
            ? 1.0
            : -1.0;

        // Scale for additional depth perception
        final scale = 0.92 + (0.08 * t); // Scale from 0.92 to 1.0

        final width = lerpDouble(
          _widgetSize(fromHeroContext).width,
          _widgetSize(toHeroContext).width,
          t,
        )!;
        final height = lerpDouble(
          _widgetSize(fromHeroContext).height,
          _widgetSize(toHeroContext).height,
          t,
        )!;
        final radius =
            BorderRadius.lerp(
              BorderRadius.circular(28),
              BorderRadius.circular(12),
              t,
            ) ??
            BorderRadius.circular(12);
        final bg =
            _extractBackgroundColor(fromHeroContext) ??
            _extractBackgroundColor(toHeroContext) ??
            Colors.white;

        return Opacity(
          opacity: 0.95 + 0.05 * t,
          child: Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // Perspective for 3D effect
                ..rotateY(rotationAngle * rotationDirection)
                ..scale(scale),
              child: SizedBox(
                width: width,
                height: height,
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Enhanced blurred backdrop for dramatic depth
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: blurSigma,
                            sigmaY: blurSigma,
                          ),
                          child: Container(color: bg.withOpacity(0.7)),
                        ),
                      ),
                      // Material elevation animation
                      Center(
                        child: AnimatedPhysicalModel(
                          duration: const Duration(milliseconds: 300),
                          shape: BoxShape.rectangle,
                          elevation: lerpDouble(2, 14, t)!,
                          color: bg,
                          shadowColor: Colors.black.withOpacity(0.2),
                          borderRadius: radius,
                          child: (toHeroContext.widget as Hero).child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: toHeroContext.widget,
    );
  }

  static Size _widgetSize(BuildContext ctx) {
    final renderBox = ctx.findRenderObject() as RenderBox?;
    return renderBox?.size ?? const Size(100, 56);
  }

  static Color? _extractBackgroundColor(BuildContext ctx) {
    final widget = ctx.widget;
    if (widget is Hero) {
      final child = widget.child;
      if (child is Material) return child.color;
      if (child is DecoratedBox) {
        final deco = child.decoration;
        if (deco is BoxDecoration) return deco.color;
      }
    }
    return null;
  }
}

double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  final aa = a?.toDouble() ?? 0.0;
  final bb = b?.toDouble() ?? 0.0;
  return aa + (bb - aa) * t;
}
