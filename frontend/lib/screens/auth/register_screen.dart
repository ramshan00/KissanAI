import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/asset_helper.dart';
import '../farmer/dashboard.dart';

class RegisterScreen extends StatefulWidget {
  final String phoneNumber;
  const RegisterScreen({super.key, required this.phoneNumber});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String _selectedRole = "farmer"; // "farmer" or "provider"
  bool _isLoading = false;
  bool _photoUploaded = false;

  void _registerAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final prov = Provider.of<BookingProvider>(context, listen: false);
        // Synchronize and register user details inside PostgreSQL/SQLite
        await prov.registerLocal(
          widget.phoneNumber,
          _nameController.text.trim(),
          _selectedRole
        );
        
        setState(() {
          _isLoading = false;
        });

        // Route to dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const FarmerDashboardScreen()),
          (route) => false,
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF022E17)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Create Profile",
                          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Complete registration to book heavy machinery instantly.",
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 24),

                        // Interactive Profile Photo component
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _photoUploaded = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Profile avatar uploaded successfully!")),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.emeraldAccent, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: Colors.emeraldAccent.withOpacity(0.1), blurRadius: 15)
                                    ],
                                  ),
                                  child: _photoUploaded 
                                    ? AssetHelper.getAvatarPlaceholder() 
                                    : Container(
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12),
                                        child: const Icon(Icons.camera_alt, color: Colors.white70, size: 28),
                                      ),
                                ),
                                if (_photoUploaded)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.emeraldAccent),
                                      child: const Icon(Icons.check, color: Color(0xFF0F172A), size: 12),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),

                        // Registration Form Details Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Full name
                              _buildLabel("FULL NAME"),
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: _buildInputDecoration("Liaqat Ali"),
                                validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                              ),
                              
                              const SizedBox(height: 20),

                              // CNIC
                              _buildLabel("CNIC NUMBER (NATIONAL ID)"),
                              TextFormField(
                                controller: _cnicController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.5),
                                decoration: _buildInputDecoration("34101-1234567-1"),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return "CNIC is required";
                                  if (val.trim().length != 15) {
                                    return "Must be exactly 15 characters (with dashes)";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // City
                              _buildLabel("CITY / TEHSIL"),
                              TextFormField(
                                controller: _cityController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: _buildInputDecoration("Lahore, Punjab"),
                                validator: (val) => val == null || val.isEmpty ? "City is required" : null,
                              ),

                              const SizedBox(height: 24),

                              // Role selector
                              _buildLabel("REGISTER MY ACCOUNT AS"),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Farmer Selection
                                  Expanded(
                                    child: _buildRoleCard("farmer", "Farmer", Icons.agriculture),
                                  ),
                                  const SizedBox(width: 12),
                                  // Operator Selection
                                  Expanded(
                                    child: _buildRoleCard("provider", "Operator", Icons.engineering),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.emeraldAccent,
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _isLoading ? null : _registerAccount,
                                child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
                                    )
                                  : const Text(
                                      "Register Profile",
                                      style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String txt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        txt,
        style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.emeraldAccent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.emeraldAccent.withOpacity(0.12) : Colors.white.withOpacity(0.04),
          border: Border.all(color: isSelected ? Colors.emeraldAccent : Colors.white.withOpacity(0.08), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.emeraldAccent : Colors.white60, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            )
          ],
        ),
      ),
    );
  }
}
