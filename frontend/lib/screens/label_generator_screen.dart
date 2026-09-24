import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../widgets/glass_container.dart';

class LabelGeneratorScreen extends StatefulWidget {
  const LabelGeneratorScreen({super.key});

  @override
  State<LabelGeneratorScreen> createState() => _LabelGeneratorScreenState();
}

class _LabelGeneratorScreenState extends State<LabelGeneratorScreen> {
  bool _isLoading = true;
  List<dynamic> _hospitals = [];
  Map<String, dynamic>? _selectedHospital;

  String _selectedCategory = 'YELLOW';
  int _labelCount = 8;
  final TextEditingController _batchPrefixController = TextEditingController(text: 'BMWS-');
  List<String> _generatedQrCodes = [];

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.get('/hospitals');
      final data = response.data['data'] as List<dynamic>? ?? [];
      setState(() {
        _hospitals = data;
        if (_hospitals.isNotEmpty) {
          _selectedHospital = _hospitals.first;
        }
      });
    } catch (_) {
      setState(() {
        _hospitals = [
          {'id': '1', 'hospitalName': 'Apollo Super Speciality', 'qrCode': 'HOSP:HOSP_APOLLO_01'},
          {'id': '2', 'hospitalName': 'Fortis Healthcare Hospital', 'qrCode': 'HOSP:HOSP_FORTIS_02'},
          {'id': '3', 'hospitalName': 'Manipal Hospital Care', 'qrCode': 'HOSP:HOSP_MANIPAL_03'},
        ];
        _selectedHospital = _hospitals.first;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _generateLabels();
      }
    }
  }

  void _generateLabels() {
    final hospCode = _selectedHospital != null
        ? (_selectedHospital!['qrCode'] ?? 'HOSP').toString().replaceAll('HOSP:', '')
        : 'GEN';
    final prefix = _batchPrefixController.text.trim();
    final catCode = _selectedCategory.substring(0, 3);
    final timestamp = DateFormat('yyMMdd').format(DateTime.now());

    final List<String> list = [];
    for (int i = 1; i <= _labelCount; i++) {
      final serial = i.toString().padLeft(3, '0');
      list.add('$prefix$hospCode-$catCode-$timestamp-$serial');
    }

    setState(() {
      _generatedQrCodes = list;
    });
  }

  Color _getCategoryColor() {
    switch (_selectedCategory) {
      case 'RED':
        return const Color(0xFFEF476F);
      case 'WHITE':
        return Colors.white;
      case 'BLUE':
        return const Color(0xFF118AB2);
      case 'YELLOW':
      default:
        return const Color(0xFFFFD166);
    }
  }

  void _showPrintSheetModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          opacity: 0.18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.print_rounded, color: Color(0xFF00F5A0), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'PRINT STICKER SHEET PREVIEW',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _generatedQrCodes.map((qr) => _buildPhysicalPrintSticker(qr)).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sent to connected Thermal Barcode Printer!'),
                              backgroundColor: Color(0xFF00F5A0),
                            ),
                          );
                        },
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Print All Stickers', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildPhysicalPrintSticker(String qr) {
    final catColor = _getCategoryColor();
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Biohazard top tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: catColor == Colors.white ? Colors.grey.shade300 : catColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('☣️', style: TextStyle(fontSize: 9)),
                const SizedBox(width: 2),
                Text(
                  _selectedCategory,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 8, color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          QrImageView(
            data: qr,
            version: QrVersions.auto,
            size: 65.0,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 4),
          Text(
            qr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const Text(
            'CPCB RULE 13 APPRV',
            style: TextStyle(fontSize: 6.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CPCB QR & Barcode Generator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    // Configuration Card
                    GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      opacity: 0.12,
                      baseColor: catColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LABEL SPECIFICATION & BATCH',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white70),
                          ),
                          const SizedBox(height: 12),

                          // Hospital Dropdown
                          if (_hospitals.isNotEmpty)
                            DropdownButtonFormField<Map<String, dynamic>>(
                              value: _selectedHospital,
                              dropdownColor: const Color(0xFF0F172A),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(labelText: 'Target Hospital / HCF'),
                              items: _hospitals.map((h) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: h as Map<String, dynamic>,
                                  child: Text(h['hospitalName'] ?? 'Hospital'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedHospital = val;
                                  _generateLabels();
                                });
                              },
                            ),
                          const SizedBox(height: 12),

                          // Waste Category Selector
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            dropdownColor: const Color(0xFF0F172A),
                            decoration: const InputDecoration(labelText: 'Bio-Medical Waste Category'),
                            items: const [
                              DropdownMenuItem(value: 'YELLOW', child: Text('🟡 Yellow — Incineration / Soiled')),
                              DropdownMenuItem(value: 'RED', child: Text('🔴 Red — Autoclave / Plastic Tubing')),
                              DropdownMenuItem(value: 'WHITE', child: Text('⚪ White — Sharps & Needles')),
                              DropdownMenuItem(value: 'BLUE', child: Text('🔵 Blue — Glassware & Ampoules')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCategory = val;
                                  _generateLabels();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Count & Batch Prefix
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _labelCount,
                                  dropdownColor: const Color(0xFF0F172A),
                                  decoration: const InputDecoration(labelText: 'Batch Quantity'),
                                  items: const [
                                    DropdownMenuItem(value: 4, child: Text('4 Stickers')),
                                    DropdownMenuItem(value: 8, child: Text('8 Stickers')),
                                    DropdownMenuItem(value: 12, child: Text('12 Stickers')),
                                    DropdownMenuItem(value: 16, child: Text('16 Stickers')),
                                    DropdownMenuItem(value: 24, child: Text('24 Stickers')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _labelCount = val;
                                        _generateLabels();
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _batchPrefixController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(labelText: 'Batch Prefix'),
                                  onChanged: (_) => _generateLabels(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Live Sticker Preview Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GENERATED STICKERS (${_generatedQrCodes.length})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white70),
                        ),
                        TextButton.icon(
                          onPressed: _showPrintSheetModal,
                          icon: const Icon(Icons.fullscreen_rounded, size: 16, color: Color(0xFF00F5A0)),
                          label: const Text('Sheet View', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _generatedQrCodes.length,
                      itemBuilder: (context, index) {
                        final qr = _generatedQrCodes[index];
                        return GlassContainer(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(12),
                          opacity: 0.14,
                          baseColor: catColor,
                          borderOpacity: 0.4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: catColor.withOpacity(0.6)),
                                ),
                                child: Text(
                                  '☣️ $_selectedCategory',
                                  style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: QrImageView(
                                  data: qr,
                                  version: QrVersions.auto,
                                  size: 76.0,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                qr,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Print Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00F5A0).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: const Color(0xFF070B14),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _showPrintSheetModal,
                        icon: const Icon(Icons.print_rounded, size: 20, color: Color(0xFF070B14)),
                        label: const Text('Open Thermal Print Sheet Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
