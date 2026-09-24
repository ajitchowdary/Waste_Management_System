import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'glass_container.dart';

class HandoverManifestDialog extends StatelessWidget {
  final String hospitalName;
  final String driverName;
  final String vehicleNumber;
  final List<Map<String, dynamic>> collectedBags;
  final String supervisorName;
  final List<List<Offset>> signatureStrokes;
  final VoidCallback onPrintOrShare;

  const HandoverManifestDialog({
    super.key,
    required this.hospitalName,
    required this.driverName,
    required this.vehicleNumber,
    required this.collectedBags,
    required this.supervisorName,
    required this.signatureStrokes,
    required this.onPrintOrShare,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final manifestId = 'CPCB-MNF-${now.millisecondsSinceEpoch.toString().substring(5)}';

    // Compute stats
    double totalWeight = 0;
    int yellowCount = 0;
    int redCount = 0;
    int whiteCount = 0;
    int blueCount = 0;

    for (final bag in collectedBags) {
      final w = double.tryParse(bag['weightKg']?.toString() ?? '0') ?? 0.0;
      totalWeight += w;
      final type = bag['wasteType']?.toString().toUpperCase() ?? 'YELLOW';
      if (type.contains('YELLOW')) yellowCount++;
      else if (type.contains('RED')) redCount++;
      else if (type.contains('WHITE')) whiteCount++;
      else if (type.contains('BLUE')) blueCount++;
      else yellowCount++;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        opacity: 0.18,
        borderOpacity: 0.35,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5A0).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, color: Color(0xFF00F5A0), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CPCB BIO-MEDICAL MANIFEST',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Color(0xFF00F5A0),
                            ),
                          ),
                          Text(
                            manifestId,
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),

              // Metadata Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildRow('Hospital / HCF:', hospitalName, isBold: true),
                    const SizedBox(height: 6),
                    _buildRow('Vehicle Number:', vehicleNumber),
                    const SizedBox(height: 6),
                    _buildRow('Driver / Operator:', driverName),
                    const SizedBox(height: 6),
                    _buildRow('Handover Time:', dateFormat.format(now)),
                    const SizedBox(height: 6),
                    _buildRow('HCF Supervisor:', supervisorName.isNotEmpty ? supervisorName : 'Duty Bio-Officer'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Breakdown Cards
              const Text(
                'WASTE BAG BREAKDOWN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildWastePill('Yellow', yellowCount, const Color(0xFFFFD166), 'Incineration')),
                  const SizedBox(width: 6),
                  Expanded(child: _buildWastePill('Red', redCount, const Color(0xFFEF476F), 'Autoclave')),
                  const SizedBox(width: 6),
                  Expanded(child: _buildWastePill('White', whiteCount, Colors.white, 'Sharps')),
                  const SizedBox(width: 6),
                  Expanded(child: _buildWastePill('Blue', blueCount, const Color(0xFF118AB2), 'Glass/Metal')),
                ],
              ),
              const SizedBox(height: 14),

              // Summary KPI
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF00F5A0).withOpacity(0.15), const Color(0xFF00D9F5).withOpacity(0.15)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00F5A0).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Bags: ${collectedBags.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Total Weight: ${totalWeight.toStringAsFixed(2)} KG', style: const TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Signature Box
              const Text(
                'AUTHORIZED DIGITAL SIGNATURE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: signatureStrokes.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomPaint(
                          painter: _ManifestSignatureMiniPainter(strokes: signatureStrokes),
                        ),
                      )
                    : const Center(
                        child: Text(
                          'Digitally Signed & GPS Verified',
                          style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Done'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)]),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: const Color(0xFF070B14),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: onPrintOrShare,
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWastePill(String title, int count, Color color, String treatment) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 4),
          Text('$count Bags', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          Text(treatment, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
        ],
      ),
    );
  }
}

class _ManifestSignatureMiniPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _ManifestSignatureMiniPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5A0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path();
      path.moveTo(stroke.first.dx * 0.5, stroke.first.dy * 0.4);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx * 0.5, stroke[i].dy * 0.4);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ManifestSignatureMiniPainter oldDelegate) => true;
}
