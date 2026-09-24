import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../widgets/glass_container.dart';
import 'profile_screen.dart';

class Screen1VehicleRegistration extends StatefulWidget {
  const Screen1VehicleRegistration({super.key});

  @override
  State<Screen1VehicleRegistration> createState() => _Screen1VehicleRegistrationState();
}

class _Screen1VehicleRegistrationState extends State<Screen1VehicleRegistration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleNoController = TextEditingController();
  String _selectedVehicleType = 'FOUR_WHEELER';
  String? _generatedQrPayload;
  bool _isLoading = false;

  void _generateQr() {
    final vehicleNo = _vehicleNoController.text.trim().toUpperCase();
    if (vehicleNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a vehicle number first!')),
      );
      return;
    }
    setState(() {
      _generatedQrPayload = 'VEH:$vehicleNo';
    });
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    final vehicleNo = _vehicleNoController.text.trim().toUpperCase();

    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.post('/vehicles/register', data: {
        'vehicleNo': vehicleNo,
        'vehicleType': _selectedVehicleType,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.data['message'] ?? 'Vehicle registered successfully!'),
          backgroundColor: const Color(0xFF00F5A0),
        ),
      );

      setState(() {
        _generatedQrPayload = 'VEH:$vehicleNo';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMsg = e.response?.data?['error'] ?? e.message ?? 'Registration failed';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('1. Vehicle Registration'),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassContainer(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(20.0),
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
                                colors: [Color(0xFF00D9F5), Color(0xFF0077B6)],
                              ),
                            ),
                            child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Vehicle Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _vehicleNoController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Vehicle No',
                          hintText: 'e.g. AP39HG9999',
                          prefixIcon: Icon(Icons.directions_car, color: Color(0xFF00D9F5)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter Vehicle No' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                          prefixIcon: Icon(Icons.category_outlined, color: Color(0xFF00D9F5)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'FOUR_WHEELER', child: Text('4 Wheeler')),
                          DropdownMenuItem(value: 'SIX_WHEELER', child: Text('6 Wheeler')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedVehicleType = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _generateQr,
                  icon: const Icon(Icons.qr_code_2, color: Color(0xFF00F5A0)),
                  label: const Text('Generate QR Code Preview', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: const Color(0xFF00F5A0).withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                if (_generatedQrPayload != null) ...[
                  const SizedBox(height: 18),
                  Center(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(18),
                      borderRadius: 20,
                      opacity: 0.15,
                      baseColor: const Color(0xFF00D9F5),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                            ),
                            child: QrImageView(
                              data: _generatedQrPayload!,
                              version: QrVersions.auto,
                              size: 160.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _generatedQrPayload!,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00F5A0), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
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
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: const Color(0xFF070B14),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Color(0xFF070B14), strokeWidth: 2.5),
                          )
                        : const Text('Submit Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
