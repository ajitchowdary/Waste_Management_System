import 'package:flutter/material.dart';
import '../core/auth_state.dart';
import '../core/api_client.dart';
import '../widgets/glass_container.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out of your session?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              AuthManager.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFF7209B7);
      case 'DRIVER':
        return const Color(0xFF00F5A0);
      case 'PLANT_OPERATOR':
        return const Color(0xFF00D9F5);
      default:
        return Colors.teal;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'DRIVER':
        return Icons.local_shipping;
      case 'PLANT_OPERATOR':
        return Icons.factory;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthManager.currentUser;
    final role = user?.role ?? 'DRIVER';
    final roleColor = _getRoleColor(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile & Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Liquid Glass Profile Card
              GlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(24.0),
                opacity: 0.1,
                baseColor: roleColor,
                child: Column(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: roleColor.withOpacity(0.2),
                        border: Border.all(color: roleColor, width: 2),
                        boxShadow: [
                          BoxShadow(color: roleColor.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Icon(_getRoleIcon(role), size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.fullName ?? 'User Profile',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user?.username ?? 'username'}',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getRoleIcon(role), size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'ROLE: $role',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Account Details List
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Divider(height: 24, color: Colors.white24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.badge_outlined, color: Color(0xFF00F5A0)),
                      title: Text('User ID', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                      subtitle: Text(user?.id ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    if (user?.driver != null) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.phone_android, color: Color(0xFF00F5A0)),
                        title: Text('Driver Mobile', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                        subtitle: Text(user!.driver?['mobileNo'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.qr_code, color: Color(0xFF00F5A0)),
                        title: Text('Driver Code', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                        subtitle: Text(user.driver?['driverCode'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.dns_outlined, color: Color(0xFF00F5A0)),
                      title: Text('Connected Backend API', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                      subtitle: Text(ApiClient.baseUrl, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout from Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
