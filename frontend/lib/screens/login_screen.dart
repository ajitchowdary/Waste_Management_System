import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../widgets/glass_container.dart';
import 'home_dashboard_screen.dart';
import 'screen4_shift_assignment.dart';
import 'screen6_plant_receival.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController(text: 'admin');
  final TextEditingController _passwordController = TextEditingController(text: 'admin123');
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin({String? overrideUser, String? overridePass}) async {
    final username = overrideUser ?? _usernameController.text.trim();
    final password = overridePass ?? _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (!mounted) return;
      final userData = response.data['data'];
      final session = UserSession.fromJson(userData);
      AuthManager.login(session);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${session.fullName}! (${session.role})'),
          backgroundColor: const Color(0xFF00F5A0),
        ),
      );

      if (session.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeDashboardScreen()),
        );
      } else if (session.isDriver) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Screen4ShiftAssignment()),
        );
      } else if (session.isOperator) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Screen6PlantReceival()),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMsg = e.response?.data?['error'] ?? 'Login failed. Check credentials.';
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

  void _fillDemoCredentials(String username, String password) {
    _usernameController.text = username;
    _passwordController.text = password;
    _handleLogin(overrideUser: username, overridePass: password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Luminous Glowing Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F5A0).withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.recycling_rounded, size: 44, color: Color(0xFF070B14)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bio-Medical Waste App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Smart Logistics & QR Tracking System',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  // Liquid Frosted Glass Login Card
                  GlassContainer(
                    padding: const EdgeInsets.all(24.0),
                    borderRadius: 24,
                    opacity: 0.08,
                    borderOpacity: 0.3,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Sign In to Portal',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline, color: Color(0xFF00F5A0)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00F5A0)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white54,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
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
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleLogin(),
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
                                  : const Text(
                                      'Enter Workspace',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1-Click Role Logins in Liquid Glass
                  GlassContainer(
                    padding: const EdgeInsets.all(16.0),
                    borderRadius: 20,
                    opacity: 0.05,
                    borderOpacity: 0.18,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flash_on, size: 16, color: Color(0xFF00F5A0)),
                            const SizedBox(width: 4),
                            Text(
                              'Instant 1-Click Demo Login',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleDemoPill(
                                title: '👑 Admin',
                                color: const Color(0xFF7209B7),
                                onTap: () => _fillDemoCredentials('admin', 'admin123'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRoleDemoPill(
                                title: '🚚 Driver',
                                color: const Color(0xFF00F5A0),
                                textColor: const Color(0xFF00F5A0),
                                onTap: () => _fillDemoCredentials('driver', 'driver123'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRoleDemoPill(
                                title: '🏭 Plant Op',
                                color: const Color(0xFF00D9F5),
                                textColor: const Color(0xFF00D9F5),
                                onTap: () => _fillDemoCredentials('operator', 'operator123'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDemoPill({
    required String title,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
