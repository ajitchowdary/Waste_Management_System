import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../widgets/glass_container.dart';
import 'profile_screen.dart';
import 'screen5_bag_collection.dart';

class Screen4ShiftAssignment extends StatefulWidget {
  const Screen4ShiftAssignment({super.key});

  @override
  State<Screen4ShiftAssignment> createState() => _Screen4ShiftAssignmentState();
}

class _Screen4ShiftAssignmentState extends State<Screen4ShiftAssignment> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _drivers = [];
  List<dynamic> _vehicles = [];
  List<dynamic> _routes = [];

  String? _selectedDriverId;
  String? _selectedVehicleId;
  String? _selectedRouteId;

  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    setState(() => _isLoadingDropdowns = true);
    try {
      final responses = await Future.wait([
        ApiClient.dio.get('/drivers'),
        ApiClient.dio.get('/vehicles'),
        ApiClient.dio.get('/routes'),
      ]);

      setState(() {
        _drivers = responses[0].data['data'] ?? [];
        _vehicles = responses[1].data['data'] ?? [];
        _routes = responses[2].data['data'] ?? [];

        if (AuthManager.currentUser?.driverId != null) {
          _selectedDriverId = AuthManager.currentUser!.driverId;
        } else if (_drivers.isNotEmpty) {
          _selectedDriverId = _drivers.first['id'];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load active drivers, vehicles, or routes')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingDropdowns = false);
    }
  }

  Future<void> _submitMapping() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await ApiClient.dio.post('/trips/mapping', data: {
        'driverId': _selectedDriverId,
        'vehicleId': _selectedVehicleId,
        'routeId': _selectedRouteId,
      });

      if (!mounted) return;
      final mappingData = response.data['data'];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift and Route mapped successfully!'),
          backgroundColor: Color(0xFF00F5A0),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Screen5BagCollection(
            activeMapping: mappingData,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMsg = e.response?.data?['error'] ?? 'Mapping failed';
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
    final user = AuthManager.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('4. Shift Assignment'),
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
        child: _isLoadingDropdowns
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F5A0)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Active Driver Banner
                      if (user != null)
                        GlassContainer(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          opacity: 0.1,
                          baseColor: const Color(0xFFFF9E00),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF9E00).withOpacity(0.2),
                                ),
                                child: const Icon(Icons.verified_user, color: Color(0xFFFF9E00), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Driver: ${user.fullName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
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
                                      colors: [Color(0xFFFF9E00), Color(0xFFFF5400)],
                                    ),
                                  ),
                                  child: const Icon(Icons.assignment_ind_outlined, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Daily Shift Mapping',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            // Driver Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedDriverId,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0F172A),
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Driver Name',
                                prefixIcon: Icon(Icons.person, color: Color(0xFFFF9E00)),
                              ),
                              items: _drivers.map<DropdownMenuItem<String>>((d) {
                                return DropdownMenuItem<String>(
                                  value: d['id'],
                                  child: Text('${d['driverName']} (${d['mobileNo']})', style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedDriverId = val),
                              validator: (val) => val == null ? 'Select Driver' : null,
                            ),
                            const SizedBox(height: 16),
                            // Vehicle Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedVehicleId,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0F172A),
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Assigned Vehicle',
                                prefixIcon: Icon(Icons.directions_car, color: Color(0xFFFF9E00)),
                              ),
                              items: _vehicles.map<DropdownMenuItem<String>>((v) {
                                return DropdownMenuItem<String>(
                                  value: v['id'],
                                  child: Text('${v['vehicleNo']} - ${v['vehicleType']}', style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedVehicleId = val),
                              validator: (val) => val == null ? 'Select Vehicle' : null,
                            ),
                            const SizedBox(height: 16),
                            // Route Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedRouteId,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0F172A),
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Target Route',
                                prefixIcon: Icon(Icons.alt_route, color: Color(0xFFFF9E00)),
                              ),
                              items: _routes.map<DropdownMenuItem<String>>((r) {
                                return DropdownMenuItem<String>(
                                  value: r['id'],
                                  child: Text('${r['routeName']} (${r['routeHospitals']?.length ?? 0} stops)', style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedRouteId = val),
                              validator: (val) => val == null ? 'Select Route' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9E00), Color(0xFFFF5400)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9E00).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitMapping,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Start Shift & Collect Bags',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
