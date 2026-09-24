import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../widgets/glass_container.dart';
import 'profile_screen.dart';

class AdminDataTablesScreen extends StatefulWidget {
  const AdminDataTablesScreen({super.key});

  @override
  State<AdminDataTablesScreen> createState() => _AdminDataTablesScreenState();
}

class _AdminDataTablesScreenState extends State<AdminDataTablesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _bags = [];
  List<dynamic> _drivers = [];
  List<dynamic> _hospitals = [];
  List<dynamic> _vehicles = [];

  bool _isLoading = true;
  String _selectedStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        ApiClient.dio.get('/bags', queryParameters: {'status': _selectedStatusFilter}),
        ApiClient.dio.get('/drivers'),
        ApiClient.dio.get('/hospitals'),
        ApiClient.dio.get('/vehicles'),
      ]);

      setState(() {
        _bags = responses[0].data['data'] ?? [];
        _drivers = responses[1].data['data'] ?? [];
        _hospitals = responses[2].data['data'] ?? [];
        _vehicles = responses[3].data['data'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load records: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'COLLECTED':
        return const Color(0xFF00D9F5);
      case 'IN_TRANSIT':
        return const Color(0xFFFF9E00);
      case 'PLANT_RECEIVED':
        return const Color(0xFF00F5A0);
      case 'DISPOSED':
        return const Color(0xFFB5179E);
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard & Live Records'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00F5A0)),
            tooltip: 'Refresh Data',
            onPressed: _fetchAllData,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00F5A0),
          labelColor: const Color(0xFF00F5A0),
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: [
            Tab(text: '📦 Bags & Plant (${_bags.length})'),
            Tab(text: '🚚 Drivers (${_drivers.length})'),
            Tab(text: '🏥 Hospitals (${_hospitals.length})'),
            Tab(text: '🚗 Vehicles (${_vehicles.length})'),
          ],
        ),
      ),
      body: LiquidBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F5A0)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildBagsTab(),
                  _buildDriversTab(),
                  _buildHospitalsTab(),
                  _buildVehiclesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildBagsTab() {
    return Column(
      children: [
        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              'ALL',
              'COLLECTED',
              'PLANT_RECEIVED',
              'DISPOSED',
            ].map((status) {
              final isSelected = _selectedStatusFilter == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(status),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00F5A0).withOpacity(0.25),
                  backgroundColor: Colors.white.withOpacity(0.06),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF00F5A0) : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  checkmarkColor: const Color(0xFF00F5A0),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatusFilter = status);
                      _fetchAllData();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
        Expanded(
          child: _bags.isEmpty
              ? Center(
                  child: Text('No bags recorded yet.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bags.length,
                  itemBuilder: (context, index) {
                    final bag = _bags[index];
                    final status = bag['status'] ?? 'COLLECTED';
                    final color = _getStatusColor(status);

                    return GlassContainer(
                      borderRadius: 18,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      opacity: 0.08,
                      baseColor: color,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.qr_code, size: 20, color: Color(0xFF00F5A0)),
                                  const SizedBox(width: 8),
                                  Text(
                                    bag['bagQrCode'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: color),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: Colors.white12),
                          Row(
                            children: [
                              Icon(Icons.local_hospital_outlined, size: 16, color: Colors.white.withOpacity(0.6)),
                              const SizedBox(width: 6),
                              Text(
                                'Hospital: ${bag['hospital']?['hospitalName']} (${bag['hospital']?['hospitalCode']})',
                                style: const TextStyle(fontSize: 13, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 16, color: Colors.white.withOpacity(0.6)),
                              const SizedBox(width: 6),
                              Text(
                                'Driver: ${bag['driver']?['driverName']}  •  Vehicle: ${bag['vehicle']?['vehicleNo']}',
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Collected: ${_formatDateTime(bag['collectedAt'])}',
                                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                              ),
                              if (bag['plantReceivedAt'] != null)
                                Text(
                                  'Plant Recv: ${_formatDateTime(bag['plantReceivedAt'])}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF00F5A0), fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDriversTab() {
    return _drivers.isEmpty
        ? Center(child: Text('No drivers registered yet.', style: TextStyle(color: Colors.white.withOpacity(0.5))))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _drivers.length,
            itemBuilder: (context, index) {
              final d = _drivers[index];
              return GlassContainer(
                borderRadius: 16,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF00F5A0).withOpacity(0.2),
                      child: const Icon(Icons.person, color: Color(0xFF00F5A0)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['driverName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                          Text('Code: ${d['driverCode']}  •  Mobile: ${d['mobileNo']}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5A0).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00F5A0)),
                      ),
                      child: const Text('ACTIVE', style: TextStyle(fontSize: 10, color: Color(0xFF00F5A0), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildHospitalsTab() {
    return _hospitals.isEmpty
        ? Center(child: Text('No hospitals registered yet.', style: TextStyle(color: Colors.white.withOpacity(0.5))))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _hospitals.length,
            itemBuilder: (context, index) {
              final h = _hospitals[index];
              return GlassContainer(
                borderRadius: 16,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF00D9F5).withOpacity(0.2),
                      child: const Icon(Icons.local_hospital, color: Color(0xFF00D9F5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h['hospitalName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                          Text('Code: ${h['hospitalCode']}\nQR: ${h['qrCodePayload']}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildVehiclesTab() {
    return _vehicles.isEmpty
        ? Center(child: Text('No vehicles registered yet.', style: TextStyle(color: Colors.white.withOpacity(0.5))))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _vehicles.length,
            itemBuilder: (context, index) {
              final v = _vehicles[index];
              return GlassContainer(
                borderRadius: 16,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFFF9E00).withOpacity(0.2),
                      child: const Icon(Icons.local_shipping, color: Color(0xFFFF9E00)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v['vehicleNo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                          Text('Type: ${v['vehicleType']}  •  QR: ${v['qrCodePayload']}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.verified, color: Color(0xFF00F5A0), size: 20),
                  ],
                ),
              );
            },
          );
  }
}
