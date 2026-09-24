import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blur;
  final Color? baseColor;
  final double opacity;
  final double borderOpacity;
  final Border? customBorder;
  final List<BoxShadow>? shadows;
  final Gradient? borderGradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20.0,
    this.blur = 16.0,
    this.baseColor,
    this.opacity = 0.08,
    this.borderOpacity = 0.25,
    this.customBorder,
    this.shadows,
    this.borderGradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBaseColor = baseColor ?? Colors.white;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: effectiveBaseColor.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveBaseColor.withOpacity(opacity + 0.08),
                  effectiveBaseColor.withOpacity(opacity),
                  effectiveBaseColor.withOpacity(opacity * 0.5),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: customBorder ??
                  Border.all(
                    color: Colors.white.withOpacity(borderOpacity),
                    width: 1.2,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class LiquidBackground extends StatelessWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Futuristic Mesh Canvas
        Container(
          color: const Color(0xFF070B14),
        ),

        // Glowing Ambient Orb 1 (Cyber Emerald)
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00F5A0).withOpacity(0.28),
                  const Color(0xFF00D9F5).withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Glowing Ambient Orb 2 (Deep Cyber Cyan / Indigo)
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00B4D8).withOpacity(0.22),
                  const Color(0xFF7209B7).withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Glowing Ambient Orb 3 (Solar Neon / Purple accent)
        Positioned(
          top: 350,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7209B7).withOpacity(0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Foreground Content
        child,
      ],
    );
  }
}
