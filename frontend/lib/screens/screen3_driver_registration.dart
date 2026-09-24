import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../widgets/glass_container.dart';
import 'profile_screen.dart';

class Screen3DriverRegistration extends StatefulWidget {
  const Screen3DriverRegistration({super.key});

  @override
  State<Screen3DriverRegistration> createState() => _Screen3DriverRegistrationState();
}

class _Screen3DriverRegistrationState extends State<Screen3DriverRegistration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _selectedPhoto = File(picked.path);
      });
    }
  }

  Future<void> _submitDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final formData = FormData.fromMap({
        'driverName': _nameController.text.trim(),
        'mobileNo': _mobileController.text.trim(),
        if (_selectedPhoto != null)
          'photo': await MultipartFile.fromFile(
            _selectedPhoto!.path,
            filename: _selectedPhoto!.path.split(Platform.pathSeparator).last,
          ),
      });

      final response = await ApiClient.dio.post('/drivers/register', data: formData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.data['message'] ?? 'Driver registered successfully!'),
          backgroundColor: const Color(0xFF00F5A0),
        ),
      );

      _nameController.clear();
      _mobileController.clear();
      setState(() {
        _selectedPhoto = null;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMsg = e.response?.data?['error'] ?? 'Driver registration failed';
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
        title: const Text('3. Driver Registration'),
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
                                colors: [Color(0xFF00F5A0), Color(0xFF00A896)],
                              ),
                            ),
                            child: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Driver Credentials',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Driver Full Name',
                          prefixIcon: Icon(Icons.person, color: Color(0xFF00F5A0)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter Driver Name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: '10-digit mobile number',
                          prefixIcon: Icon(Icons.phone, color: Color(0xFF00F5A0)),
                        ),
                        validator: (val) => val == null || val.trim().length < 10 ? 'Enter valid mobile number' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Driver Photo Card in Liquid Glass
                GlassContainer(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Driver Identity Photo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF00F5A0).withOpacity(0.6), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F5A0).withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _selectedPhoto != null
                                ? Image.file(_selectedPhoto!, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.white.withOpacity(0.06),
                                    child: Icon(Icons.camera_alt, size: 40, color: Colors.white.withOpacity(0.4)),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5A0).withOpacity(0.2),
                              foregroundColor: const Color(0xFF00F5A0),
                              side: const BorderSide(color: Color(0xFF00F5A0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, size: 18, color: Colors.white70),
                            label: const Text('Gallery', style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
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
                    onPressed: _isLoading ? null : _submitDriver,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: const Color(0xFF070B14),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF070B14))
                        : const Text('Submit Driver Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
