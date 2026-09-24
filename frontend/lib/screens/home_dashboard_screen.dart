import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../widgets/glass_container.dart';
import 'profile_screen.dart';
import 'screen1_vehicle_registration.dart';
import 'screen2_route_mapping.dart';
import 'screen3_driver_registration.dart';
import 'screen4_shift_assignment.dart';
import 'screen5_bag_collection.dart';
import 'screen6_plant_receival.dart';
import 'admin_data_tables_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'trip_progress_tracker_screen.dart';
import 'label_generator_screen.dart';
import 'anomaly_detection_screen.dart';
import 'live_gps_map_screen.dart';
import '../widgets/notification_drawer.dart';
import '../core/notification_service.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  void _showSettingsDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiClient.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Server Configuration', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Backend Base URL',
            hintText: 'e.g. http://192.168.1.5:5000/api',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F5A0),
              foregroundColor: const Color(0xFF070B14),
            ),
            onPressed: () {
              ApiClient.updateBaseUrl(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Backend URL set to: ${ApiClient.baseUrl}')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthManager.currentUser;

    final modules = [
      {
        'num': '01',
        'title': 'Vehicle Registration',
        'subtitle': '4/6 wheeler setup & printable QR sticker generation',
        'icon': Icons.local_shipping_outlined,
        'gradient': [const Color(0xFF00D9F5), const Color(0xFF0077B6)],
        'page': const Screen1VehicleRegistration(),
      },
      {
        'num': '02',
        'title': 'Vehicle Route Map',
        'subtitle': 'Ordered hospital collection sequence & route stops',
        'icon': Icons.alt_route,
        'gradient': [const Color(0xFF7209B7), const Color(0xFF4361EE)],
        'page': const Screen2RouteMapping(),
      },
      {
        'num': '03',
        'title': 'Driver Registration',
        'subtitle': 'Camera photo capture & credential verification',
        'icon': Icons.person_add_alt_1_outlined,
        'gradient': [const Color(0xFF00F5A0), const Color(0xFF00A896)],
        'page': const Screen3DriverRegistration(),
      },
      {
        'num': '04',
        'title': 'Driver + Vehicle - Route Map',
        'subtitle': 'Active shift mapping (Driver + Vehicle + Route)',
        'icon': Icons.assignment_ind_outlined,
        'gradient': [const Color(0xFFFF9E00), const Color(0xFFFF5400)],
        'page': const Screen4ShiftAssignment(),
      },
      {
        'num': '05',
        'title': 'Bags Collection at Hospital',
        'subtitle': 'Scan Hospital QR + Multi-bag rapid barcode counter',
        'icon': Icons.qr_code_scanner,
        'gradient': [const Color(0xFF00F5A0), const Color(0xFF00D9F5)],
        'page': const Screen5BagCollection(),
      },
      {
        'num': '06',
        'title': 'Vehicle Scan at Plant',
        'subtitle': 'Central Plant Gate verification & bulk bag ingestion',
        'icon': Icons.factory_outlined,
        'gradient': [const Color(0xFFB5179E), const Color(0xFF7209B7)],
        'page': const Screen6PlantReceival(),
      },
    ];

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Glass Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
                            ),
                          ),
                          child: const Icon(Icons.recycling_rounded, size: 24, color: Color(0xFF070B14)),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waste Logistics',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              'Liquid Glass Architecture',
                              style: TextStyle(fontSize: 11, color: Color(0xFF00F5A0)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Notification Bell with Live Unread Badge
                        ValueListenableBuilder<List<AppNotification>>(
                          valueListenable: NotificationService.instance.notificationsNotifier,
                          builder: (context, notifs, child) {
                            final unread = NotificationService.instance.unreadCount;
                            return Stack(
                              alignment: Alignment.topRight,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                                  tooltip: 'Alerts & Dispatches',
                                  onPressed: () => NotificationDrawer.show(context),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF476F),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune_rounded, color: Colors.white70),
                          tooltip: 'Server Settings',
                          onPressed: () => _showSettingsDialog(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.account_circle, size: 28, color: Color(0xFF00F5A0)),
                          tooltip: 'Profile & Logout',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  children: [
                    // User Session Pill
                    if (currentUser != null)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 14),
                          borderRadius: 14,
                          opacity: 0.06,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF00F5A0),
                                      boxShadow: [
                                        BoxShadow(color: Color(0xFF00F5A0), blurRadius: 6),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${currentUser.fullName} (${currentUser.role})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                  ),
                                ],
                              ),
                              const Row(
                                children: [
                                  Text('Profile', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.w600)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF00F5A0)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Enterprise Regulatory Tools Grid
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AnalyticsDashboardScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(14),
                              borderRadius: 18,
                              opacity: 0.12,
                              baseColor: const Color(0xFF00F5A0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00F5A0).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF00F5A0), size: 20),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Waste Analytics', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text('CPCB Charts', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.55))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TripProgressTrackerScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 18,
                              opacity: 0.12,
                              baseColor: const Color(0xFF00D9F5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D9F5).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.alt_route_rounded, color: Color(0xFF00D9F5), size: 20),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Route Stepper', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text('Live Stepper', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.55))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LabelGeneratorScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 18,
                              opacity: 0.12,
                              baseColor: const Color(0xFFFF9E00),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9E00).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFFFF9E00), size: 20),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Label Maker', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text('Sticker Roll', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.55))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Secondary Intelligence Row: Live GPS Map & Rule 13 Anomaly Engine
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LiveGpsMapScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 18,
                              opacity: 0.12,
                              baseColor: const Color(0xFF00D9F5),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D9F5).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.satellite_alt_rounded, color: Color(0xFF00D9F5), size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('GPS Fleet Map', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                                        Text('Live Radar & ETA', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.55))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AnomalyDetectionScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 18,
                              opacity: 0.12,
                              baseColor: const Color(0xFFEF476F),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF476F).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF476F), size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Rule 13 Audits', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                                        Text('Anomaly Engine', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.55))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Admin Live Data Tables Banner (Glassmorphism + Neon Glow)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminDataTablesScreen()),
                        );
                      },
                      child: GlassContainer(
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 20),
                        borderRadius: 20,
                        opacity: 0.12,
                        baseColor: const Color(0xFF00D9F5),
                        borderOpacity: 0.35,
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00D9F5), Color(0xFF7209B7)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D9F5).withOpacity(0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Live Admin Data & Reports',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Real-time Bags, Drivers, Hospitals & Plant logs',
                                    style: TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Color(0xFF00D9F5), size: 16),
                          ],
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Operations Workflow',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '6 Modules',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Module Cards in Liquid Glass
                    ...modules.map((m) {
                      final gradient = m['gradient'] as List<Color>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => m['page'] as Widget),
                            );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            borderRadius: 18,
                            opacity: 0.06,
                            borderOpacity: 0.18,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(colors: gradient),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gradient.first.withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(m['icon'] as IconData, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            m['num'] as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: gradient.first,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              m['title'] as String,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        m['subtitle'] as String,
                                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withOpacity(0.4)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
