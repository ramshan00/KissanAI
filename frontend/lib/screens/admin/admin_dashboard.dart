import 'package:flutter/material.dart';
import 'package:kissanai/theme/app_colors.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminMetrics();
  }

  Future<void> _loadAdminMetrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _apiService.fetchAdminMetrics();
      setState(() {
        _metrics = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Admin Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("KissanAI Admin Portal", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.emeraldAccent),
            onPressed: _loadAdminMetrics,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.emeraldAccent))
        : _metrics == null
          ? const Center(child: Text("Failed to load metrics. Ensure backend server is active."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Platform KPIs",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                  ),
                  const SizedBox(height: 16),
                  
                  // KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          Icons.group, 
                          "Total Users", 
                          _metrics!["total_users"].toString(), 
                          Colors.blueAccent
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          Icons.engineering, 
                          "Active Providers", 
                          _metrics!["active_providers"].toString(), 
                          AppColors.emeraldAccent
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          Icons.shopping_bag, 
                          "Total Orders", 
                          _metrics!["total_bookings"].toString(), 
                          Colors.amberAccent
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Status Breakdown Chart Panel
                  const Text(
                    "Order Status Breakdown",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusChart(_metrics!["status_breakdown"] as Map<String, dynamic>),
                  
                  const SizedBox(height: 32),
                  
                  // Unresolved Disputes List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Active Disputes Mediate Review",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: const Text(
                          "ResolveAI LOGS",
                          style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildActiveDisputesList(_metrics!["active_disputes"] as List<dynamic>),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(IconData icon, String title, String value, Color col) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: col, size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusChart(Map<String, dynamic> breakdown) {
    if (breakdown.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
        child: const Text("No orders completed yet.", style: TextStyle(color: Colors.white38), textAlign: TextAlign.center),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: breakdown.entries.map((entry) {
          final String status = entry.key;
          final int count = entry.value;
          
          // Calculate arbitrary percentage bar width helper
          double maxVal = 10.0;
          for (var v in breakdown.values) {
            if (v > maxVal) maxVal = v.toDouble();
          }
          final double pct = count / maxVal;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // Base background track
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Progress fill
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.emeraldAccent, Colors.teal]),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: AppColors.emeraldAccent.withOpacity(0.2), blurRadius: 4)
                            ]
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  count.toString(),
                  style: const TextStyle(color: AppColors.emeraldAccent, fontWeight: FontWeight.bold),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveDisputesList(List<dynamic> disputes) {
    if (disputes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
        child: const Text("No active unresolved disputes. System stable.", style: TextStyle(color: Colors.white38), textAlign: TextAlign.center),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: disputes.length,
      itemBuilder: (context, index) {
        final d = disputes[index];
        final id = d["id"];
        final service = d["service_type"];
        final price = d["price"];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.04),
            border: Border.all(color: Colors.redAccent.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DISPUTE OVER BOOKING #$id", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("Service Type: ${service.toUpperCase()}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("PKR $price", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text("REVIEW ACTIVE", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
