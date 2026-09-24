import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/qr_scanner_dialog.dart';
import 'profile_screen.dart';

class Screen6PlantReceival extends StatefulWidget {
  const Screen6PlantReceival({super.key});

  @override
  State<Screen6PlantReceival> createState() => _Screen6PlantReceivalState();
}

class _Screen6PlantReceivalState extends State<Screen6PlantReceival> {
  final TextEditingController _vehicleQrController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _receivalSummary;

  Future<void> _scanVehicleQr() async {
    final scannedCode = await QrScannerScreen.scan(context, title: 'Scan Vehicle QR Code');
    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _vehicleQrController.text = scannedCode;
      });
    }
  }

  Future<void> _submitPlantReceival() async {
    final vehicleQr = _vehicleQrController.text.trim();
    if (vehicleQr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or enter Vehicle QR Code!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _receivalSummary = null;
    });

    try {
      final response = await ApiClient.dio.post('/plant/receive-vehicle', data: {
        'vehicleQrCode': vehicleQr,
      });

      if (!mounted) return;
      setState(() {
        _receivalSummary = response.data;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.data['message'] ?? 'Bags received at plant!'),
          backgroundColor: const Color(0xFF00F5A0),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMsg = e.response?.data?['error'] ?? 'Plant verification failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bagsList = _receivalSummary?['bagsDetails'] as List<dynamic>? ?? [];
    final user = AuthManager.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('6. Plant Gate Verification'),
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null)
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  opacity: 0.1,
                  baseColor: const Color(0xFF7209B7),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF7209B7).withOpacity(0.3),
                        ),
                        child: const Icon(Icons.factory, color: Color(0xFF00D9F5), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Operator: ${user.fullName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                            Text(
                              'Role: ${user.role}',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              GlassContainer(
                borderRadius: 22,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB5179E), Color(0xFF7209B7)],
                            ),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Gate Vehicle Ingestion',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _vehicleQrController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Scan Vehicle QR Code',
                              hintText: 'e.g. VEH:AP39HG9999',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(colors: [Color(0xFFB5179E), Color(0xFF7209B7)]),
                          ),
                          child: IconButton(
                            onPressed: _scanVehicleQr,
                            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                  onPressed: _isLoading ? null : _submitPlantReceival,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: const Color(0xFF070B14),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF070B14))
                      : const Text('Verify & Receive Vehicle at Plant',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              if (_receivalSummary != null) ...[
                GlassContainer(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(18),
                  opacity: 0.12,
                  baseColor: const Color(0xFF00F5A0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Vehicle: ${_receivalSummary!['vehicleNo'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F5A0).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00F5A0)),
                            ),
                            child: Text(
                              '${_receivalSummary!['totalBagsReceived']} Bags Received',
                              style: const TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.white24),
                      if (bagsList.isEmpty)
                        Text('No bags in transit found for this vehicle.', style: TextStyle(color: Colors.white.withOpacity(0.6)))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bagsList.length,
                          itemBuilder: (context, index) {
                            final bag = bagsList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.verified, color: Color(0xFF00F5A0), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Bag: ${bag['bagQrCode']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Hospital: ${bag['hospitalName']} (${bag['hospitalCode']})',
                                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                                        ),
                                        Text(
                                          'Driver: ${bag['driverName']}  •  Route: ${bag['routeName']}',
                                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
