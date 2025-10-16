import 'dart:ui';
import 'package:flutter/material.dart';

/// Smooth glassmorphic card with natural light diffusion and no visible gradient lines.
/// Optimized for dark/light themes and GPU-friendly blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 20.0,
    this.opacity = 0.16,
    this.accentColor,
    this.padding = const EdgeInsets.all(16),
    this.borderWidth = 1.6,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = accentColor ?? theme.colorScheme.secondary;

    // Theme-tuned glass opacity: slightly stronger in dark for readability
    final effectiveOpacity = isDark
        ? (opacity * 0.6).clamp(0.06, 0.20)
        : opacity;
    final glassColor = Colors.white.withOpacity(effectiveOpacity);

    // Softer border in dark mode to avoid harsh edges
    final border = Border.all(
      color: accent.withOpacity(isDark ? 0.28 : 0.38),
      width: borderWidth,
    );

    // Subtle, wide shadow for depth; darker on light, lighter on dark
    final defaultShadow = [
      BoxShadow(
        color: (isDark ? Colors.black : accent).withOpacity(
          isDark ? 0.18 : 0.14,
        ),
        blurRadius: 28,
        spreadRadius: 0.5,
        offset: const Offset(0, 10),
      ),
    ];

    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Background blur
            BackdropFilter(
              // Slightly stronger blur in light, slightly reduced in dark to avoid muddy look
              filter: ImageFilter.blur(
                sigmaX: isDark ? blur * 0.9 : blur * 1.05,
                sigmaY: isDark ? blur * 0.9 : blur * 1.05,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: glassColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: border,
                  boxShadow: boxShadow ?? defaultShadow,
                ),
              ),
            ),

            // Soft ambient light (top-left glow)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.9, -0.9),
                      radius: 1.4,
                      colors: [
                        accent.withOpacity(isDark ? 0.08 : 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Reflection + content
            _SoftReflection(borderRadius: borderRadius, child: child),
          ],
        ),
      ),
    );
  }
}

/// Smoother reflection layer without visible gradient bands.
class _SoftReflection extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  const _SoftReflection({required this.child, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        child,

        // Top reflection (diffused highlight)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(borderRadius),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(isDark ? 0.10 : 0.22),
                    Colors.white.withOpacity(0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Subtle diagonal haze (very low contrast, no visible lines)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withOpacity(0.05), Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
