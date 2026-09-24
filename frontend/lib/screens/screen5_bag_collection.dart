import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../widgets/glass_container.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/digital_signature_pad.dart';
import '../widgets/handover_manifest_dialog.dart';
import '../widgets/burst_multi_bag_scanner.dart';
import 'screen4_shift_assignment.dart';
import 'profile_screen.dart';

class Screen5BagCollection extends StatefulWidget {
  final Map<String, dynamic>? activeMapping;

  const Screen5BagCollection({super.key, this.activeMapping});

  @override
  State<Screen5BagCollection> createState() => _Screen5BagCollectionState();
}

class _Screen5BagCollectionState extends State<Screen5BagCollection> {
  final TextEditingController _hospitalQrController = TextEditingController();
  final TextEditingController _singleBagQrController = TextEditingController();
  final TextEditingController _supervisorNameController = TextEditingController(text: 'Dr. / Nurse In-Charge');
  final TextEditingController _weightController = TextEditingController(text: '3.5');

  String _selectedWasteType = 'YELLOW';
  final List<Map<String, dynamic>> _scannedBagsList = [];
  List<List<Offset>> _signatureStrokes = [];
  bool _isSubmitting = false;

  String _driverName = 'No Shift Selected';
  String _vehicleNo = 'N/A';
  String _routeName = 'N/A';
  String? _driverMappingId;

  List<dynamic> _availableShifts = [];

  @override
  void initState() {
    super.initState();
    if (widget.activeMapping != null) {
      _populateMappingContext(widget.activeMapping!);
    } else {
      _fetchLatestShifts();
    }
  }

  void _populateMappingContext(Map<String, dynamic> mapping) {
    setState(() {
      _driverMappingId = mapping['id'];
      _driverName = mapping['driver']?['driverName'] ?? 'Unknown Driver';
      _vehicleNo = mapping['vehicle']?['vehicleNo'] ?? 'Unknown Vehicle';
      _routeName = mapping['route']?['routeName'] ?? 'Unknown Route';
    });
  }

  Future<void> _fetchLatestShifts() async {
    try {
      final response = await ApiClient.dio.get('/drivers');
      final drivers = response.data['data'] as List<dynamic>? ?? [];

      if (drivers.isNotEmpty) {
        for (final d in drivers) {
          try {
            final shiftRes = await ApiClient.dio.get('/trips/active-shift/${d['id']}');
            if (shiftRes.data['data'] != null) {
              _availableShifts.add(shiftRes.data['data']);
            }
          } catch (_) {}
        }
      }

      if (_availableShifts.isNotEmpty) {
        _populateMappingContext(_availableShifts.first);
      }
    } catch (_) {}
  }

  void _scanHospitalQr() async {
    final scanned = await QrScannerScreen.scan(context, title: 'Scan Hospital QR');
    if (scanned != null && scanned.isNotEmpty) {
      setState(() {
        _hospitalQrController.text = scanned;
      });
    }
  }

  void _scanBagQr() async {
    final scanned = await QrScannerScreen.scan(context, title: 'Scan Waste Bag QR / Barcode');
    if (scanned != null && scanned.isNotEmpty) {
      _addBagItem(scanned);
    }
  }

  void _openBurstScanner() async {
    final hosp = _hospitalQrController.text.trim();
    final scannedList = await BurstMultiBagScanner.open(
      context,
      hospitalName: hosp.isNotEmpty ? hosp.replaceAll('HOSP:', '') : 'Hospital Bag Collection',
    );

    if (scannedList != null && scannedList.isNotEmpty) {
      final weight = double.tryParse(_weightController.text.trim()) ?? 2.5;
      int addedCount = 0;
      for (final qr in scannedList) {
        if (!_scannedBagsList.any((b) => b['qr'] == qr)) {
          _scannedBagsList.add({
            'qr': qr,
            'wasteType': _selectedWasteType,
            'weightKg': weight,
          });
          addedCount++;
        }
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ Rapid Burst added $addedCount new bags!'),
          backgroundColor: const Color(0xFF00F5A0),
        ),
      );
    }
  }

  void _addBagItem(String qr) {
    final cleanQr = qr.trim();
    if (cleanQr.isEmpty) return;
    if (_scannedBagsList.any((b) => b['qr'] == cleanQr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bag QR "$cleanQr" already scanned!')),
      );
      return;
    }

    final weight = double.tryParse(_weightController.text.trim()) ?? 2.5;

    setState(() {
      _scannedBagsList.add({
        'qr': cleanQr,
        'wasteType': _selectedWasteType,
        'weightKg': weight,
      });
      _singleBagQrController.clear();
    });
  }

  void _addManualBag() {
    _addBagItem(_singleBagQrController.text);
  }

  void _removeBag(int index) {
    setState(() {
      _scannedBagsList.removeAt(index);
    });
  }

  Future<void> _submitCollection() async {
    if (_driverMappingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No Active Shift assigned! Assign in Screen 4 first.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Go to Screen 4',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Screen4ShiftAssignment()),
              );
            },
          ),
        ),
      );
      return;
    }

    final hospitalQr = _hospitalQrController.text.trim();
    if (hospitalQr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or enter Hospital QR Code!')),
      );
      return;
    }
    if (_scannedBagsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan at least 1 Bag QR code!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final bagQrs = _scannedBagsList.map((b) => b['qr'].toString()).toList();
      final response = await ApiClient.dio.post('/bags/collect', data: {
        'hospitalQrCode': hospitalQr,
        'bagQrCodes': bagQrs,
        'driverMappingId': _driverMappingId,
      });

      if (!mounted) return;

      // Show Handover Manifest Dialog with Signature
      final savedBags = List<Map<String, dynamic>>.from(_scannedBagsList);
      final supervisor = _supervisorNameController.text.trim();
      final strokes = List<List<Offset>>.from(_signatureStrokes);

      showDialog(
        context: context,
        builder: (ctx) => HandoverManifestDialog(
          hospitalName: hospitalQr.replaceAll('HOSP:', '').replaceAll('_', ' '),
          driverName: _driverName,
          vehicleNumber: _vehicleNo,
          collectedBags: savedBags,
          supervisorName: supervisor,
          signatureStrokes: strokes,
          onPrintOrShare: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CPCB Digital Manifest PDF generated & ready for dispatch!'),
                backgroundColor: Color(0xFF00F5A0),
              ),
            );
          },
        ),
      );

      _hospitalQrController.clear();
      setState(() {
        _scannedBagsList.clear();
        _signatureStrokes.clear();
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMsg = e.response?.data?['error'] ?? 'Bag collection failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('5. Bags Collection at Hospital'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Color(0xFF00F5A0)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Shift Context Banner
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(14),
                opacity: _driverMappingId != null ? 0.12 : 0.08,
                baseColor: _driverMappingId != null ? const Color(0xFF00F5A0) : const Color(0xFFFF9E00),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _driverMappingId != null ? const Color(0xFF00F5A0) : const Color(0xFFFF9E00),
                                boxShadow: [
                                  BoxShadow(
                                    color: _driverMappingId != null ? const Color(0xFF00F5A0) : const Color(0xFFFF9E00),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _driverMappingId != null ? 'Active Shift Context:' : '⚠️ No Shift Assigned',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _driverMappingId != null ? const Color(0xFF00F5A0) : const Color(0xFFFF9E00),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (_driverMappingId == null)
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const Screen4ShiftAssignment()),
                              );
                            },
                            child: const Text('Assign Now (Screen 4)', style: TextStyle(color: Color(0xFFFF9E00), fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Driver: $_driverName', style: const TextStyle(fontSize: 13, color: Colors.white)),
                        Text('Vehicle: $_vehicleNo', style: const TextStyle(fontSize: 13, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('Route: $_routeName', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Step 1: Hospital QR Code
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF00D9F5).withOpacity(0.2),
                          ),
                          child: const Icon(Icons.local_hospital, color: Color(0xFF00D9F5), size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text('Step 1: Hospital QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _hospitalQrController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'e.g. HOSP:HOSP_APOLLO_01',
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)]),
                          ),
                          child: IconButton(
                            onPressed: _scanHospitalQr,
                            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF070B14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Step 2: Scan Bag QR Codes
              GlassContainer(
                borderRadius: 22,
                padding: const EdgeInsets.all(16),
                opacity: 0.1,
                baseColor: const Color(0xFF00F5A0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Step 2: Bag Categorization & QR',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00F5A0)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00F5A0).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00F5A0)),
                          ),
                          child: Text(
                            '${_scannedBagsList.length} Bags Added',
                            style: const TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Color Type Selector & Weight input
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _selectedWasteType,
                            dropdownColor: const Color(0xFF0F172A),
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'YELLOW', child: Text('🟡 Yellow (Incineration)')),
                              DropdownMenuItem(value: 'RED', child: Text('🔴 Red (Autoclave)')),
                              DropdownMenuItem(value: 'WHITE', child: Text('⚪ White (Sharps)')),
                              DropdownMenuItem(value: 'BLUE', child: Text('🔵 Blue (Glass/Metal)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedWasteType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Weight (KG)',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _singleBagQrController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Enter Bag QR (e.g. BAG-101)',
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF00F5A0).withOpacity(0.15),
                            border: Border.all(color: const Color(0xFF00F5A0)),
                          ),
                          child: IconButton(
                            onPressed: _scanBagQr,
                            tooltip: 'Camera Scanner',
                            icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF00F5A0), size: 20),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)]),
                          ),
                          child: ElevatedButton(
                            onPressed: _addManualBag,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: const Color(0xFF070B14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('+ ADD', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Rapid Continuous Burst Scanner Action Button
                    InkWell(
                      onTap: _openBurstScanner,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFF00F5A0).withOpacity(0.14),
                          border: Border.all(color: const Color(0xFF00F5A0).withOpacity(0.6)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt_rounded, color: Color(0xFF00F5A0), size: 20),
                            SizedBox(width: 8),
                            Text(
                              '⚡ Launch Rapid Continuous Multi-Bag Scanner',
                              style: TextStyle(
                                color: Color(0xFF00F5A0),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_scannedBagsList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Center(
                          child: Text(
                            'No bags added yet. Select category, weight and scan QR above.',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _scannedBagsList.length,
                        itemBuilder: (context, index) {
                          final item = _scannedBagsList[index];
                          final type = item['wasteType'] as String;
                          Color badgeColor = const Color(0xFFFFD166);
                          if (type == 'RED') badgeColor = const Color(0xFFEF476F);
                          if (type == 'WHITE') badgeColor = Colors.white;
                          if (type == 'BLUE') badgeColor = const Color(0xFF118AB2);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: badgeColor.withOpacity(0.6)),
                                      ),
                                      child: Text(
                                        type,
                                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 140),
                                      child: Text(
                                        item['qr'] as String,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${item['weightKg']} kg)',
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                  onPressed: () => _removeBag(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Step 3: Digital Signature & Supervisor Sign-off
              GlassContainer(
                borderRadius: 22,
                padding: const EdgeInsets.all(16),
                opacity: 0.1,
                baseColor: const Color(0xFF7209B7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF7209B7).withOpacity(0.3),
                          ),
                          child: const Icon(Icons.draw_rounded, color: Color(0xFF00D9F5), size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Step 3: Hospital Sign-Off & Manifest',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _supervisorNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'HCF Waste Officer / Nurse Name',
                        hintText: 'e.g. Dr. Sarah Jenkins',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DigitalSignaturePad(
                      height: 130,
                      signerLabel: 'Draw Digital Signature on Screen',
                      onSignatureChanged: (strokes) {
                        _signatureStrokes = strokes;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
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
                  onPressed: _isSubmitting ? null : _submitCollection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: const Color(0xFF070B14),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Color(0xFF070B14))
                      : const Text('Confirm & Generate Handover Manifest', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
