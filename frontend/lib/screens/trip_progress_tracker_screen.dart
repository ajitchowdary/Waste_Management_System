import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../widgets/glass_container.dart';
import 'screen5_bag_collection.dart';
import 'screen6_plant_receival.dart';

class TripProgressTrackerScreen extends StatefulWidget {
  const TripProgressTrackerScreen({super.key});

  @override
  State<TripProgressTrackerScreen> createState() => _TripProgressTrackerScreenState();
}

class _TripProgressTrackerScreenState extends State<TripProgressTrackerScreen> {
  bool _isLoading = true;
  List<dynamic> _routes = [];
  Map<String, dynamic>? _selectedRoute;
  int _activeStopIndex = 1; // 0 is Depot, 1 is 1st hospital, etc.

  @override
  void initState() {
    super.initState();
    _fetchRoutesAndStops();
  }

  Future<void> _fetchRoutesAndStops() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.get('/routes');
      final data = response.data['data'] as List<dynamic>? ?? [];
      setState(() {
        _routes = data;
        if (_routes.isNotEmpty) {
          _selectedRoute = _routes.first;
        }
      });
    } catch (_) {
      // Fallback sample data if offline
      setState(() {
        _routes = [
          {
            'id': 'route-1',
            'routeName': 'North Zone Metro Line A',
            'hospitalStops': [
              {'hospital': {'hospitalName': 'Apollo Super Speciality', 'address': 'Bannerghatta Rd'}},
              {'hospital': {'hospitalName': 'Fortis Healthcare Hospital', 'address': 'Cunningham Rd'}},
              {'hospital': {'hospitalName': 'Manipal Hospital Care', 'address': 'Old Airport Rd'}},
            ]
          }
        ];
        _selectedRoute = _routes.first;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stops = (_selectedRoute?['hospitalStops'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Route & Trip Stepper'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00F5A0)),
            onPressed: _fetchRoutesAndStops,
          ),
        ],
      ),
      body: LiquidBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F5A0)))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Route Selector Header
                    GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      opacity: 0.12,
                      baseColor: const Color(0xFF00D9F5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ACTIVE LOGISTICS TRIP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF00D9F5),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F5A0).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF00F5A0).withOpacity(0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF00F5A0)),
                                    SizedBox(width: 4),
                                    Text('LIVE EN-ROUTE', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_routes.isNotEmpty)
                            DropdownButtonFormField<Map<String, dynamic>>(
                              value: _selectedRoute,
                              dropdownColor: const Color(0xFF0F172A),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              decoration: const InputDecoration(
                                labelText: 'Select Route',
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              items: _routes.map((r) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: r as Map<String, dynamic>,
                                  child: Text(r['routeName'] ?? 'Unnamed Route'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedRoute = val;
                                  _activeStopIndex = 1;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Trip Live Metrics Bar
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard('Completed Stops', '$_activeStopIndex / ${stops.length + 1}', Icons.check_circle_outline, const Color(0xFF00F5A0)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard('Est. Weight', '${_activeStopIndex * 24.5} KG', Icons.scale_outlined, const Color(0xFFFF9E00)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard('Next Stop ETA', '12 Mins', Icons.timer_outlined, const Color(0xFF00D9F5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Visual Checkpoint Timeline Stepper
                    const Text(
                      'ROUTE PROGRESSION CHECKPOINTS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white70),
                    ),
                    const SizedBox(height: 12),

                    // 1. Central Logistics Depot Node
                    _buildTimelineNode(
                      stepNumber: '00',
                      title: 'Central Logistics Base Depot',
                      subtitle: 'Vehicle pre-trip inspection & driver dispatch confirmed',
                      isCompleted: true,
                      isActive: false,
                      isStart: true,
                    ),

                    // 2. Hospital Stops
                    for (int i = 0; i < stops.length; i++)
                      _buildTimelineNode(
                        stepNumber: '0${i + 1}',
                        title: stops[i]['hospital']?['hospitalName'] ?? 'Hospital Stop ${i + 1}',
                        subtitle: stops[i]['hospital']?['address'] ?? 'Scheduled Sequence Stop',
                        isCompleted: i < _activeStopIndex,
                        isActive: i == _activeStopIndex,
                        onScanTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Screen5BagCollection()),
                          );
                        },
                      ),

                    // 3. Central Treatment Plant Node
                    _buildTimelineNode(
                      stepNumber: 'END',
                      title: 'Central Bio-Medical Treatment Plant',
                      subtitle: 'Incineration & Autoclave Ingestion Facility',
                      isCompleted: _activeStopIndex > stops.length,
                      isActive: _activeStopIndex == stops.length,
                      isEnd: true,
                      onScanTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Screen6PlantReceival()),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Next Checkpoint Navigation Controller
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _activeStopIndex > 0
                                ? () => setState(() => _activeStopIndex--)
                                : null,
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Prev Stop'),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)]),
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: const Color(0xFF070B14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _activeStopIndex <= stops.length
                                  ? () => setState(() => _activeStopIndex++)
                                  : null,
                              icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF070B14)),
                              label: const Text('Advance Stop', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color accentColor) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    bool isStart = false,
    bool isEnd = false,
    VoidCallback? onScanTap,
  }) {
    Color nodeColor = Colors.white24;
    if (isCompleted) nodeColor = const Color(0xFF00F5A0);
    if (isActive) nodeColor = const Color(0xFF00D9F5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stepper Visual Line & Dot
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? nodeColor.withOpacity(0.25) : (isCompleted ? const Color(0xFF00F5A0).withOpacity(0.2) : Colors.white10),
                border: Border.all(
                  color: nodeColor,
                  width: isActive ? 2.5 : 1.5,
                ),
                boxShadow: isActive
                    ? [BoxShadow(color: const Color(0xFF00D9F5).withOpacity(0.4), blurRadius: 12, spreadRadius: 2)]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 18, color: Color(0xFF00F5A0))
                    : Text(
                        stepNumber,
                        style: TextStyle(
                          color: isActive ? const Color(0xFF00D9F5) : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (!isEnd)
              Container(
                width: 2,
                height: 55,
                color: isCompleted ? const Color(0xFF00F5A0).withOpacity(0.6) : Colors.white12,
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Stepper Details Card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(14),
              opacity: isActive ? 0.16 : 0.07,
              baseColor: isActive ? const Color(0xFF00D9F5) : Colors.white,
              borderOpacity: isActive ? 0.4 : 0.15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isActive ? const Color(0xFF00D9F5) : Colors.white,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D9F5).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF00D9F5)),
                          ),
                          child: const Text('CURRENT STOP', style: TextStyle(color: Color(0xFF00D9F5), fontSize: 9, fontWeight: FontWeight.bold)),
                        )
                      else if (isCompleted)
                        const Text('VISITED ✓', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.6))),
                  if (isActive && onScanTap != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F5A0),
                          foregroundColor: const Color(0xFF070B14),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: onScanTap,
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        label: Text(isEnd ? 'Open Plant Ingestion' : 'Start Bag Collection (Screen 5)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
