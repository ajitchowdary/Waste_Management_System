import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'badge': 'STEP 1: HOSPITAL SCANNING',
      'tagline': 'CHAIN OF CUSTODY VERIFICATION',
      'title': 'Intelligent Waste Bag\nBarcode Tracking',
      'subtitle': 'Scan hospital QR codes and audit biohazard bags (Yellow, Red, White, Blue) with camera scanning, weight logging, and real-time inventory validation.',
      'icon': Icons.qr_code_scanner_rounded,
      'gradient': [const Color(0xFF00F5A0), const Color(0xFF00D9F5)],
      'bullets': ['Color-Coded Waste Categorization', 'Weight & RFID/Barcode Verification', 'Instant Cloud Handover Receipt'],
    },
    {
      'badge': 'STEP 2: FLEET & DISPATCH',
      'tagline': 'DYNAMIC ROUTE OPTIMIZATION',
      'title': 'Automated Driver &\nVehicle Shift Logistics',
      'subtitle': 'Assign registered 4/6-wheeler vehicles and certified drivers to daily hospital pickup routes with scheduled pickup sequence monitoring.',
      'icon': Icons.alt_route_rounded,
      'gradient': [const Color(0xFFFF9E00), const Color(0xFFFF5400)],
      'bullets': ['Driver Face & License Verification', 'Dynamic Multi-Hospital Stop Routes', 'Live Shift Status Sync'],
    },
    {
      'badge': 'STEP 3: DISPOSAL & AUDIT',
      'tagline': 'TREATMENT PLANT INGESTION',
      'title': 'Gate Verification &\n6 PM Automated Disposal',
      'subtitle': 'One single vehicle scan at the treatment plant ingests all trip bags with complete audit logs, backed by an automated 6:00 PM batch disposal engine.',
      'icon': Icons.factory_rounded,
      'gradient': [const Color(0xFF9D4EDD), const Color(0xFF00D9F5)],
      'bullets': ['Single-Scan Mass Trip Ingestion', 'Automated 6:00 PM Batch Scheduler', 'CPCB Regulatory Audit Compliance'],
    },
  ];

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const LoginScreen(),
        transitionsBuilder: (context, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)]),
                          ),
                          child: const Icon(Icons.recycling_rounded, size: 20, color: Color(0xFF070B14)),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'MEDIWAS',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        backgroundColor: Colors.white.withOpacity(0.06),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView Carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    final gradient = slide['gradient'] as List<Color>;
                    final bullets = slide['bullets'] as List<String>;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          // Floating Liquid Glass Icon Box
                          GlassContainer(
                            borderRadius: 36,
                            padding: const EdgeInsets.all(28),
                            opacity: 0.12,
                            baseColor: gradient.first,
                            borderOpacity: 0.35,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: gradient),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradient.first.withOpacity(0.45),
                                    blurRadius: 30,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(slide['icon'] as IconData, size: 52, color: const Color(0xFF070B14)),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: gradient.first.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: gradient.first.withOpacity(0.5)),
                            ),
                            child: Text(
                              slide['badge'] as String,
                              style: TextStyle(
                                color: gradient.first,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Title
                          Text(
                            slide['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Subtitle Description
                          Text(
                            slide['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.white.withOpacity(0.7),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Feature Pill Bullets
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: bullets.map((b) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 13, color: gradient.first),
                                    const SizedBox(width: 6),
                                    Text(
                                      b,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.white.withOpacity(0.85),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Control Bar
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Slide Indicator Dots
                    Row(
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          width: _currentPage == i ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: _currentPage == i
                                ? const LinearGradient(colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)])
                                : null,
                            color: _currentPage == i ? null : Colors.white24,
                          ),
                        ),
                      ),
                    ),

                    // Next / Get Started Action Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F5A0).withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finishOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: const Color(0xFF070B14),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF070B14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
