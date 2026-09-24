import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';

class LiveGpsMapScreen extends StatefulWidget {
  const LiveGpsMapScreen({super.key});

  @override
  State<LiveGpsMapScreen> createState() => _LiveGpsMapScreenState();
}

class _LiveGpsMapScreenState extends State<LiveGpsMapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isMoving = true;
  double _vehicleProgress = 0.35; // 0.0 to 1.0 along the route path
  Timer? _simTimer;

  final List<Map<String, dynamic>> _waypoints = [
    {'name': 'Central Depot (Start)', 'x': 0.15, 'y': 0.80, 'type': 'DEPOT'},
    {'name': 'Apollo Hospital (Stop 1)', 'x': 0.30, 'y': 0.45, 'type': 'HOSPITAL', 'bags': 12},
    {'name': 'Fortis Care (Stop 2)', 'x': 0.65, 'y': 0.30, 'type': 'HOSPITAL', 'bags': 18},
    {'name': 'Manipal Clinic (Stop 3)', 'x': 0.85, 'y': 0.60, 'type': 'HOSPITAL', 'bags': 9},
    {'name': 'Treatment Plant (End)', 'x': 0.75, 'y': 0.85, 'type': 'PLANT'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _simTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isMoving && mounted) {
        setState(() {
          _vehicleProgress += 0.003;
          if (_vehicleProgress > 1.0) _vehicleProgress = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live GPS Fleet Map'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isMoving ? Icons.pause_circle_outline : Icons.play_circle_outline, color: const Color(0xFF00F5A0)),
            tooltip: _isMoving ? 'Pause Simulation' : 'Resume Simulation',
            onPressed: () => setState(() => _isMoving = !_isMoving),
          ),
        ],
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Top HUD Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GlassContainer(
                borderRadius: 18,
                padding: const EdgeInsets.all(14),
                opacity: 0.12,
                baseColor: const Color(0xFF00D9F5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D9F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_shipping, size: 18, color: Color(0xFF070B14)),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KA-01-EA-1234 (Driver: Rajesh)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            Text(
                              'Route North Line A • In Transit',
                              style: TextStyle(fontSize: 11, color: Color(0xFF00D9F5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5A0).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00F5A0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed, size: 12, color: Color(0xFF00F5A0)),
                          SizedBox(width: 4),
                          Text('42 KM/H', style: TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Interactive Vector Map Canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    color: const Color(0xFF0A0F1D),
                    child: Stack(
                      children: [
                        // Map Grid Canvas & Polyline
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _LiveGpsMapPainter(
                                waypoints: _waypoints,
                                progress: _vehicleProgress,
                                pulseValue: _animController.value,
                              ),
                              size: Size.infinite,
                            );
                          },
                        ),

                        // Compass & Geofence Tag
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF070B14).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.explore_outlined, color: Color(0xFF00F5A0), size: 16),
                                SizedBox(width: 4),
                                Text('NE 52°', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                        // Active Geofence Alert Trigger
                        Positioned(
                          bottom: 14,
                          left: 14,
                          right: 14,
                          child: GlassContainer(
                            borderRadius: 14,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            opacity: 0.2,
                            baseColor: const Color(0xFF00F5A0),
                            child: Row(
                              children: [
                                const Icon(Icons.radar_rounded, color: Color(0xFF00F5A0), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _vehicleProgress < 0.5
                                        ? 'Geofence Active: Approaching Apollo Hospital (320m)'
                                        : 'Geofence Active: En route to Fortis Healthcare (850m)',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
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
              ),
            ),

            // Bottom Waypoints Quick Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildWaypointPill('Depot', 'Visited ✓', const Color(0xFF00F5A0)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildWaypointPill('Apollo', 'Next 📍', const Color(0xFF00D9F5)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildWaypointPill('Fortis', 'Pending', Colors.white38),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildWaypointPill('Plant', 'Dest', const Color(0xFF7209B7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointPill(String title, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
          Text(status, style: TextStyle(fontSize: 9.5, color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }
}

class _LiveGpsMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> waypoints;
  final double progress;
  final double pulseValue;

  _LiveGpsMapPainter({
    required this.waypoints,
    required this.progress,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle background radar grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 2. Convert waypoints to screen offsets
    final List<Offset> points = waypoints.map((w) {
      return Offset(
        (w['x'] as double) * size.width,
        (w['y'] as double) * size.height,
      );
    }).toList();

    // 3. Draw Route Polyline Road
    final roadGlowPaint = Paint()
      ..color = const Color(0xFF00D9F5).withOpacity(0.25)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roadPaint = Paint()
      ..color = const Color(0xFF00D9F5).withOpacity(0.7)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, roadGlowPaint);
    canvas.drawPath(path, roadPaint);

    // 4. Draw Waypoint Nodes & Geofence Rings
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final w = waypoints[i];
      final type = w['type'] as String;

      Color pinColor = const Color(0xFF00D9F5);
      if (type == 'DEPOT') pinColor = const Color(0xFF00F5A0);
      if (type == 'PLANT') pinColor = const Color(0xFF7209B7);

      // Radar pulse ring around hospitals
      if (type == 'HOSPITAL') {
        final radarPaint = Paint()
          ..color = pinColor.withOpacity((1.0 - pulseValue) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(p, 16 + (pulseValue * 14), radarPaint);
      }

      // Outer pin circle
      canvas.drawCircle(p, 8, Paint()..color = pinColor);
      canvas.drawCircle(p, 4, Paint()..color = const Color(0xFF070B14));
    }

    // 5. Compute Vehicle Position along Polyline Path
    if (points.length >= 2) {
      final totalSegments = points.length - 1;
      final scaled = progress * totalSegments;
      final currentSegIndex = scaled.floor().clamp(0, totalSegments - 1);
      final segProgress = scaled - currentSegIndex;

      final p1 = points[currentSegIndex];
      final p2 = points[currentSegIndex + 1];

      final vehicleX = p1.dx + (p2.dx - p1.dx) * segProgress;
      final vehicleY = p1.dy + (p2.dy - p1.dy) * segProgress;
      final vehiclePos = Offset(vehicleX, vehicleY);

      // Draw Vehicle Pulsing Aura
      final auraPaint = Paint()
        ..color = const Color(0xFF00F5A0).withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(vehiclePos, 16, auraPaint);

      // Draw Vehicle Marker Pin
      canvas.drawCircle(vehiclePos, 9, Paint()..color = const Color(0xFF00F5A0));
      canvas.drawCircle(vehiclePos, 5, Paint()..color = const Color(0xFF070B14));
    }
  }

  @override
  bool shouldRepaint(covariant _LiveGpsMapPainter oldDelegate) => true;
}
