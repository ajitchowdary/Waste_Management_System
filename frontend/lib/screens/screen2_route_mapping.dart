import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../widgets/glass_container.dart';
import 'profile_screen.dart';

class Screen2RouteMapping extends StatefulWidget {
  const Screen2RouteMapping({super.key});

  @override
  State<Screen2RouteMapping> createState() => _Screen2RouteMappingState();
}

class _Screen2RouteMappingState extends State<Screen2RouteMapping> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _routeNameController = TextEditingController();

  List<dynamic> _availableHospitals = [];
  final List<dynamic> _selectedHospitalsSequence = [];
  String? _currentlyPickedHospitalId;

  bool _isLoadingHospitals = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    setState(() => _isLoadingHospitals = true);
    try {
      final response = await ApiClient.dio.get('/hospitals');
      setState(() {
        _availableHospitals = response.data['data'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load hospitals from backend')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingHospitals = false);
    }
  }

  void _showAddHospitalDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSavingHosp = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Register New Hospital', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Hospital Code',
                    hintText: 'e.g. HOSP_APOLLO_01',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Hospital Name',
                    hintText: 'e.g. Apollo Speciality',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'e.g. Zone 1, Main Road',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                foregroundColor: const Color(0xFF070B14),
              ),
              onPressed: isSavingHosp
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim();
                      final name = nameCtrl.text.trim();
                      if (code.isEmpty || name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code and Name are required!')),
                        );
                        return;
                      }

                      setDialogState(() => isSavingHosp = true);
                      try {
                        await ApiClient.dio.post('/hospitals', data: {
                          'hospitalCode': code,
                          'hospitalName': name,
                          'address': addressCtrl.text.trim(),
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hospital added successfully!'),
                            backgroundColor: Color(0xFF00F5A0),
                          ),
                        );
                        _fetchHospitals();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              child: isSavingHosp
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Hospital'),
            ),
          ],
        ),
      ),
    );
  }

  void _addHospitalToRoute() {
    if (_currentlyPickedHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a hospital from dropdown first')),
      );
      return;
    }

    final hospital = _availableHospitals.firstWhere(
      (h) => h['id'] == _currentlyPickedHospitalId,
      orElse: () => null,
    );

    if (hospital != null) {
      if (_selectedHospitalsSequence.any((h) => h['id'] == hospital['id'])) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hospital already added to this route!')),
        );
        return;
      }
      setState(() {
        _selectedHospitalsSequence.add(hospital);
        _currentlyPickedHospitalId = null;
      });
    }
  }

  void _removeHospital(int index) {
    setState(() {
      _selectedHospitalsSequence.removeAt(index);
    });
  }

  Future<void> _submitRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHospitalsSequence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 hospital stop to the route!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final hospitalIds = _selectedHospitalsSequence.map((h) => h['id']).toList();
      final response = await ApiClient.dio.post('/routes/create', data: {
        'routeName': _routeNameController.text.trim(),
        'hospitalIds': hospitalIds,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.data['message'] ?? 'Route created successfully!'),
          backgroundColor: const Color(0xFF00F5A0),
        ),
      );

      _routeNameController.clear();
      setState(() {
        _selectedHospitalsSequence.clear();
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMsg = e.response?.data?['error'] ?? 'Failed to create route';
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
        title: const Text('2. Vehicle Route Map'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00F5A0)),
            tooltip: 'Reload Hospitals',
            onPressed: _fetchHospitals,
          ),
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
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
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
                                colors: [Color(0xFF7209B7), Color(0xFF4361EE)],
                              ),
                            ),
                            child: const Icon(Icons.alt_route, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Route Definition',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _routeNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Route Name',
                          hintText: 'e.g. Route-North-Zone',
                          prefixIcon: Icon(Icons.map_outlined, color: Color(0xFF00D9F5)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter Route Name' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Subform Hospital Stops in Liquid Glass
                GlassContainer(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(18),
                  opacity: 0.08,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hospital Stops Sequence',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00F5A0)),
                          ),
                          TextButton.icon(
                            onPressed: _showAddHospitalDialog,
                            icon: const Icon(Icons.local_hospital, size: 14, color: Color(0xFF00D9F5)),
                            label: const Text('+ New Hospital', style: TextStyle(fontSize: 12, color: Color(0xFF00D9F5))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _isLoadingHospitals
                                ? const Center(child: CircularProgressIndicator())
                                : DropdownButtonFormField<String>(
                                    value: _currentlyPickedHospitalId,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF0F172A),
                                    style: const TextStyle(color: Colors.white),
                                    hint: Text('Select Hospital', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                                    decoration: const InputDecoration(
                                      labelText: 'Hospital List',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    items: _availableHospitals.map<DropdownMenuItem<String>>((h) {
                                      return DropdownMenuItem<String>(
                                        value: h['id'],
                                        child: Text(
                                          '${h['hospitalName']} (${h['hospitalCode']})',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _currentlyPickedHospitalId = val);
                                    },
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)]),
                            ),
                            child: ElevatedButton(
                              onPressed: _addHospitalToRoute,
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
                      const SizedBox(height: 16),
                      if (_selectedHospitalsSequence.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No stops added. Pick a hospital and tap "+ ADD" to build route sequence.',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedHospitalsSequence.length,
                          itemBuilder: (context, index) {
                            final h = _selectedHospitalsSequence[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFF00F5A0).withOpacity(0.2),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(h['hospitalName'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('Code: ${h['hospitalCode']}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => _removeHospital(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
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
                    onPressed: _isSubmitting ? null : _submitRoute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: const Color(0xFF070B14),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Color(0xFF070B14))
                        : const Text('Submit Route', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
