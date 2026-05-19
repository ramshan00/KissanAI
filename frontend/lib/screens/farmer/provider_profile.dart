import 'package:flutter/material.dart';
import '../../services/asset_helper.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF032614)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Custom Header Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      "Operator Profile",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                    ),
                    const Icon(Icons.verified, color: Colors.blueAccent),
                  ],
                ),
              ),

              // Profile Content Scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      
                      // Beautiful Avatar Circle
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.emeraldAccent, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.emeraldAccent.withOpacity(0.2),
                                blurRadius: 20,
                              )
                            ],
                          ),
                          child: AssetHelper.getAvatarPlaceholder(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Name & Badges
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Tariq Mahmood",
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.verified, color: Colors.blueAccent, size: 18),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Lahore, Punjab • Senior Tractor Operator",
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Stat Pillars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard("RATING", "⭐ 4.8", Colors.amberAccent),
                          _buildStatCard("COMPLETED JOBS", "42 Jobs", Colors.emeraldAccent),
                          _buildStatCard("EXPERIENCE", "6 Years", Colors.blueAccent),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Specialized Crops and Machinery Tags
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Specializations",
                          style: TextStyle(color: Colors.emeraldAccent.shade100, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSpecializations(),
                      
                      const SizedBox(height: 30),
                      
                      // Equipment Owned details
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Equipment Fleet Details",
                          style: TextStyle(color: Colors.emeraldAccent.shade100, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildEquipmentFleet(),
                      
                      const SizedBox(height: 30),
                      
                      // Customer Feedback Reviews
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Verified Customer Reviews",
                          style: TextStyle(color: Colors.emeraldAccent.shade100, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildReviewsList(),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String val, Color valCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(color: valCol, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSpecializations() {
    final tags = ["Deep Plowing", "Wheat Cultivation", "Laser Land Labeling", "Canal Irrigation Sowing"];
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: tags.map((t) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Text(t, style: const TextStyle(color: Colors.emeraldAccent, fontSize: 12)),
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentFleet() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          _EquipmentRow("Massey Ferguson MF 385", "85 HP Tractor", Icons.airport_shuttle),
          Divider(color: Colors.white10),
          _EquipmentRow("Gandum Kataii Thresher attachment", "Crop Harvester", Icons.agriculture),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    final reviews = [
      {"name": "Bashir Ahmad", "rating": "5.0", "comment": "Bohot achi service! Waqt par aaye aur kaam behtareen kia. Recommended!"},
      {"name": "Liaqat Ali", "rating": "4.5", "comment": "Massey Ferguson tractor bohot achi halat mein tha. Rate bhi munasib hai."}
    ];

    return Column(
      children: reviews.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r["name"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text("⭐ ${r['rating']}", style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                r["comment"]!,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EquipmentRow extends StatelessWidget {
  final String model;
  final String desc;
  final IconData icon;
  const _EquipmentRow(this.model, this.desc, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.emeraldAccent, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(model, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}
