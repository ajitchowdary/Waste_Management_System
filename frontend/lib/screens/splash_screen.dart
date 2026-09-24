import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.6, 1.0, curve: Curves.easeInOutSine)),
    );

    _animController.forward();

    _navTimer = Timer(const Duration(milliseconds: 3200), _goToOnboarding);
  }

  void _goToOnboarding() {
    if (!mounted) return;
    _navTimer?.cancel();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const OnboardingScreen(),
        transitionsBuilder: (context, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _goToOnboarding,
        child: LiquidBackground(
          child: Stack(
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Multi-layered Pulsing Glow Icon
                            Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer Ambient Halo
                                  Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFF00F5A0).withOpacity(0.3),
                                          const Color(0xFF00D9F5).withOpacity(0.1),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Glassmorphic Outer Ring
                                  GlassContainer(
                                    borderRadius: 80,
                                    padding: const EdgeInsets.all(16),
                                    opacity: 0.14,
                                    borderOpacity: 0.4,
                                    baseColor: const Color(0xFF00F5A0),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00F5A0).withOpacity(0.5),
                                            blurRadius: 36,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.recycling_rounded,
                                          size: 56,
                                          color: Color(0xFF070B14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Brand Title
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Color(0xFF00F5A0), Color(0xFF00D9F5)],
                              ).createShader(bounds),
                              child: const Text(
                                'MEDIWAS',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subtitle Tagline
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Text(
                                'BIO-MEDICAL WASTE LOGISTICS & AUDIT',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                            const SizedBox(height: 54),

                            // Loading Bar
                            SizedBox(
                              width: 140,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: const LinearProgressIndicator(
                                  backgroundColor: Colors.white12,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5A0)),
                                  minHeight: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Security / Build Tag
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 13, color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 6),
                      Text(
                        'Cloud Connected • ISO 14001 Compliant',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
