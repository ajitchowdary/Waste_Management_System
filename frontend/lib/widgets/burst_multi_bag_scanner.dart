import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BurstMultiBagScanner extends StatefulWidget {
  final ValueChanged<List<String>> onBagsScanned;
  final String hospitalName;

  const BurstMultiBagScanner({
    super.key,
    required this.onBagsScanned,
    this.hospitalName = 'Hospital Pickup',
  });

  static Future<List<String>?> open(BuildContext context, {String hospitalName = 'Hospital Pickup'}) {
    return Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => BurstMultiBagScanner(
          hospitalName: hospitalName,
          onBagsScanned: (bags) => Navigator.pop(context, bags),
        ),
      ),
    );
  }

  @override
  State<BurstMultiBagScanner> createState() => _BurstMultiBagScannerState();
}

class _BurstMultiBagScannerState extends State<BurstMultiBagScanner> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final List<String> _scannedCodes = [];
  String? _lastScanned;
  DateTime _lastScanTime = DateTime.now();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onCodeDetected(BarcodeCapture capture) {
    final now = DateTime.now();
    // Throttle duplicate scanning within 1.2 seconds for the same code
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;

      if (_scannedCodes.contains(raw)) {
        if (_lastScanned == raw && now.difference(_lastScanTime).inMilliseconds < 1500) {
          continue;
        }
      }

      if (!_scannedCodes.contains(raw)) {
        setState(() {
          _scannedCodes.insert(0, raw);
          _lastScanned = raw;
          _lastScanTime = now;
        });

        _pulseController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFF00F5A0), size: 18),
                SizedBox(width: 6),
                Text('Rapid Burst Multi-Scanner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(
              widget.hospitalName,
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Continuous Live Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onCodeDetected,
          ),

          // 2. Central Scanner Target Frame with Pulse Radar
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                final glow = _pulseController.value > 0
                    ? const Color(0xFF00F5A0).withOpacity((1.0 - _pulseController.value) * 0.8)
                    : Colors.transparent;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _pulseController.isAnimating ? const Color(0xFF00F5A0) : const Color(0xFF00D9F5),
                        width: 3.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: glow,
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Point continuously at bags',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        if (_lastScanned != null && _pulseController.isAnimating)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F5A0).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF070B14), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'BAG CAPTURED!',
                                    style: TextStyle(color: Color(0xFF070B14), fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ],
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

          // 3. Top Counter Overlay Badge
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF070B14).withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00F5A0).withOpacity(0.5)),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5A0).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: Color(0xFF00F5A0), size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Continuous Burst Active',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F5A0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_scannedCodes.length} BAGS',
                      style: const TextStyle(color: Color(0xFF070B14), fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Scanned Bags Tray & Complete Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF070B14).withOpacity(0.92),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Horizontal Mini-Tray of Scanned Codes
                  if (_scannedCodes.isNotEmpty) ...[
                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _scannedCodes.length,
                        itemBuilder: (context, index) {
                          final code = _scannedCodes[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF00F5A0).withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF00F5A0)),
                                const SizedBox(width: 6),
                                Text(
                                  code,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Complete Batch Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)]),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00F5A0).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: const Color(0xFF070B14),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        widget.onBagsScanned(_scannedCodes);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.done_all_rounded, size: 20, color: Color(0xFF070B14)),
                          const SizedBox(width: 8),
                          Text(
                            _scannedCodes.isEmpty ? 'Finish Scanning' : 'Done Adding (${_scannedCodes.length} Bags)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
