import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_colors.dart';

class TrackingMapScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const TrackingMapScreen({super.key, required this.booking});

  @override
  State<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends State<TrackingMapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Connect to WebSocket coordinate stream on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<BookingProvider>(context, listen: false);
      prov.startTrackingActiveBooking(widget.booking["id"]);
    });
  }

  @override
  void dispose() {
    // Shutdown WebSocket subscription on exit
    final prov = Provider.of<BookingProvider>(context, listen: false);
    prov.stopTrackingActiveBooking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BookingProvider>(context);
    final bookingId = widget.booking["id"];
    
    // Get live coordinates or fallback to default seeded Lahore operator Tariq
    double providerLat = prov.providerLocation?["latitude"] ?? 31.5204;
    double providerLng = prov.providerLocation?["longitude"] ?? 74.3587;
    
    // Farmer location (Lahore Farm)
    const double farmerLat = 31.5580;
    const double farmerLng = 74.3900;
    
    final LatLng providerLatLng = LatLng(providerLat, providerLng);
    const LatLng farmerLatLng = LatLng(farmerLat, farmerLng);

    // Dynamic distance tracking calculation
    final distance = Distance().as(
      LengthUnit.Meter,
      providerLatLng,
      farmerLatLng,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header stats
            _buildTrackingHeader(prov, distance.round()),

            // Map Widget Container
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: providerLatLng,
                      initialZoom: 13.0,
                    ),
                    children: [
                      // OpenStreetMap standard tiles
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.kissanai.app',
                      ),
                      
                      // Telemetry marker overlay
                      MarkerLayer(
                        markers: [
                          // 1. Farmer Marker (Lahore Farm)
                          const Marker(
                            point: farmerLatLng,
                            width: 60,
                            height: 60,
                            child: Column(
                              children: [
                                Icon(Icons.home_work, color: AppColors.emeraldAccent, size: 36),
                                Text("My Farm", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.black54)),
                              ],
                            ),
                          ),
                          
                          // 2. Matched Operator Marker
                          Marker(
                            point: providerLatLng,
                            width: 65,
                            height: 65,
                            child: Column(
                              children: [
                                const Icon(Icons.agriculture, color: Colors.blueAccent, size: 38),
                                Text(
                                  prov.providerLocation != null ? "Operator: Active" : "Operator: Tariq",
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, backgroundColor: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingHeader(BookingProvider prov, int distanceMeters) {
    final statusText = prov.providerLocation != null 
      ? "GPS WebSocket Stream Connected" 
      : "Awaiting Live Coordinates...";
    final etaMinutes = (distanceMeters / 300).ceil(); // ~18km/h farm vehicle speed estimation

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Column(
                children: [
                  Text("RIDE IN TRANSIT", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 2)),
                  const SizedBox(height: 2),
                  const Text("Tariq Mahmood - Tractor", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Icon(Icons.location_on, color: Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(Icons.directions_car, "ETA", "$etaMinutes Mins"),
              _buildMetricCard(Icons.social_distance, "Distance", "${(distanceMeters / 1000).toStringAsFixed(1)} km"),
              _buildMetricCard(Icons.wifi, "Connection", prov.providerLocation != null ? "Active" : "Standby"),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              color: prov.providerLocation != null ? AppColors.emeraldAccent : Colors.orangeAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
