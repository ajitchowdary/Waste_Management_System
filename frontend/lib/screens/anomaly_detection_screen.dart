import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';

class AnomalyDetectionScreen extends StatefulWidget {
  const AnomalyDetectionScreen({super.key});

  @override
  State<AnomalyDetectionScreen> createState() => _AnomalyDetectionScreenState();
}

class _AnomalyDetectionScreenState extends State<AnomalyDetectionScreen> {
  String _selectedFilter = 'ALL';

  final List<Map<String, dynamic>> _anomalies = [
    {
      'id': 'ANM-101',
      'title': '48-Hour CPCB Rule 13 Expiry Breach',
      'severity': 'CRITICAL',
      'entity': 'Apollo Super Speciality (Room 4B Storage)',
      'description': 'Bio-medical waste bags remained uncollected for 51 hours, exceeding the statutory 48-hour treatment deadline.',
      'time': '18 mins ago',
      'resolved': false,
      'color': const Color(0xFFEF476F),
      'icon': Icons.timer_off_outlined,
    },
    {
      'id': 'ANM-102',
      'title': 'Abnormal Weight Outlier Detected',
      'severity': 'WARNING',
      'entity': 'Bag #BAG-YEL-088 (Manipal Hospital)',
      'description': 'Recorded weight was 0.08 KG, which falls 94% below normal threshold for yellow anatomical waste.',
      'time': '42 mins ago',
      'resolved': false,
      'color': const Color(0xFFFF9E00),
      'icon': Icons.scale_outlined,
    },
    {
      'id': 'ANM-103',
      'title': 'Vehicle Payload Capacity Exceeded',
      'severity': 'WARNING',
      'entity': 'Vehicle KA-01-EA-1234 (Driver: Rajesh)',
      'description': 'Total trip cargo reached 892 KG against registered 800 KG maximum payload (11.5% overload).',
      'time': '2 hours ago',
      'resolved': true,
      'color': const Color(0xFFFFD166),
      'icon': Icons.local_shipping_outlined,
    },
    {
      'id': 'ANM-104',
      'title': 'Color / Barcode Category Mismatch',
      'severity': 'CRITICAL',
      'entity': 'Bag #BAG-RED-041 (Fortis Clinic)',
      'description': 'Metallic scalpels/sharps barcode scanned into Red Autoclave container instead of White Puncture-Proof box.',
      'time': '3 hours ago',
      'resolved': false,
      'color': const Color(0xFFEF476F),
      'icon': Icons.warning_amber_rounded,
    },
  ];

  void _toggleResolve(int index) {
    setState(() {
      _anomalies[index]['resolved'] = !_anomalies[index]['resolved'];
    });
    final isRes = _anomalies[index]['resolved'] as bool;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isRes ? 'Incident marked as Resolved & Logged!' : 'Incident marked as Active'),
        backgroundColor: isRes ? const Color(0xFF00F5A0) : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _anomalies.where((a) {
      if (_selectedFilter == 'CRITICAL') return a['severity'] == 'CRITICAL';
      if (_selectedFilter == 'WARNING') return a['severity'] == 'WARNING';
      if (_selectedFilter == 'RESOLVED') return a['resolved'] == true;
      return true;
    }).toList();

    final criticalCount = _anomalies.where((a) => a['severity'] == 'CRITICAL' && !a['resolved']).length;
    final warningCount = _anomalies.where((a) => a['severity'] == 'WARNING' && !a['resolved']).length;
    final resolvedCount = _anomalies.where((a) => a['resolved']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CPCB Rule 13 & Anomaly Engine'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF00F5A0)),
            tooltip: 'Export Incident Log',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CPCB Audit Incident Log exported to PDF!'),
                  backgroundColor: Color(0xFF00F5A0),
                ),
              );
            },
          ),
        ],
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary KPI Row
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard('Critical', '$criticalCount', const Color(0xFFEF476F), Icons.error_outline),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard('Warnings', '$warningCount', const Color(0xFFFF9E00), Icons.warning_amber),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard('Resolved', '$resolvedCount', const Color(0xFF00F5A0), Icons.check_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['ALL', 'CRITICAL', 'WARNING', 'RESOLVED'].map((f) {
                    final isSel = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: isSel,
                        selectedColor: const Color(0xFF00F5A0),
                        backgroundColor: Colors.white.withOpacity(0.06),
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFF070B14) : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) => setState(() => _selectedFilter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Incident Cards List
              Text(
                'LIVE TELEMETRY INCIDENTS (${filtered.length})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white70),
              ),
              const SizedBox(height: 10),

              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No anomalies found under "$_selectedFilter"',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              else
                ...filtered.asMap().entries.map((entry) {
                  final item = entry.value;
                  final originalIndex = _anomalies.indexOf(item);
                  final isResolved = item['resolved'] as bool;
                  final color = item['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(16),
                      opacity: 0.12,
                      baseColor: isResolved ? Colors.white : color,
                      borderOpacity: isResolved ? 0.2 : 0.45,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(item['icon'] as IconData, size: 18, color: color),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item['id'] as String,
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isResolved ? const Color(0xFF00F5A0) : color).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isResolved ? const Color(0xFF00F5A0) : color),
                                ),
                                child: Text(
                                  isResolved ? 'RESOLVED ✓' : item['severity'] as String,
                                  style: TextStyle(
                                    color: isResolved ? const Color(0xFF00F5A0) : color,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['entity'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF00D9F5)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['description'] as String,
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), height: 1.35),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['time'] as String,
                                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                              ),
                              ElevatedButton(
                                onPressed: () => _toggleResolve(originalIndex),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isResolved ? Colors.white12 : color.withOpacity(0.2),
                                  foregroundColor: isResolved ? Colors.white70 : color,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: isResolved ? Colors.white24 : color),
                                  ),
                                ),
                                child: Text(
                                  isResolved ? 'Re-Open' : 'Acknowledge & Resolve',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      opacity: 0.1,
      baseColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }
}
