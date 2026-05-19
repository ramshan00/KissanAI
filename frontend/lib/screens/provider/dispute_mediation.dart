import 'package:flutter/material.dart';
import 'package:kissanai/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';

class DisputeMediationScreen extends StatefulWidget {
  const DisputeMediationScreen({super.key});

  @override
  State<DisputeMediationScreen> createState() => _DisputeMediationScreenState();
}

class _DisputeMediationScreenState extends State<DisputeMediationScreen> {
  final TextEditingController _complaintController = TextEditingController(
    text: "Assalamu Alaikum. Tariq Mahmood late hogya hai khet pe anay mein. Hamein 1 ghanta intezar karna para. Please price adjust karein."
  );

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BookingProvider>(context);
    final booking = prov.activeBooking;
    final status = booking?["status"] ?? "disputed";
    final price = booking?["price"] ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF2E0C0C)], // Rich ruby red dark alert gradient
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(context, booking),

              // Chat Mediation Board
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: prov.disputeChat.length,
                  itemBuilder: (context, index) {
                    final bubble = prov.disputeChat[index];
                    final sender = bubble["sender"] ?? "system";
                    final message = bubble["message"] ?? "";
                    
                    return _buildChatBubble(sender, message);
                  },
                ),
              ),

              // Dynamic Settle trigger card
              _buildMediationControls(prov, status, price),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic>? booking) {
    final id = booking?["id"] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Column(
            children: [
              const Text("RESOLVEAI DISPUTE BROKER", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 2),
              Text("Mediation: Booking #$id", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const Icon(Icons.gavel, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String sender, String message) {
    bool isFarmer = sender == "farmer";
    bool isSystem = sender == "system";
    bool isAgent = sender == "agent";
    
    Color bubbleBg = Colors.white.withOpacity(0.06);
    Color textCol = Colors.white70;
    Alignment align = Alignment.centerLeft;
    
    if (isFarmer) {
      bubbleBg = Colors.blueAccent.withOpacity(0.12);
      textCol = Colors.blue.shade100;
      align = Alignment.centerRight;
    } else if (isSystem) {
      bubbleBg = Colors.orangeAccent.withOpacity(0.08);
      textCol = Colors.orangeAccent;
      align = Alignment.center;
    } else if (isAgent) {
      bubbleBg = Colors.redAccent.withOpacity(0.12);
      textCol = Colors.red.shade100;
      align = Alignment.centerLeft;
    }

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(14.0),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: bubbleBg,
          border: Border.all(color: textCol.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sender.toUpperCase(),
              style: TextStyle(color: textCol.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: textCol, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediationControls(BookingProvider prov, String status, double activePrice) {
    if (prov.isLoading) {
      return Container(
        padding: const EdgeInsets.all(30),
        color: Colors.black26,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    }

    if (status == "resolved") {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.emeraldAccent, size: 20),
                SizedBox(width: 8),
                Text("DISPUTE RESOLVED BY AGENT", style: TextStyle(color: AppColors.emeraldAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Adjusted Fair Price: PKR $activePrice (15% discount applied)",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white12,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Return to Dashboard", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _complaintController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              hintText: "Enter farmer delay details here...",
              hintStyle: const TextStyle(color: Colors.white24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: () async {
              // Execute the mediation call
              await prov.executeResolveAIDispute(_complaintController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ResolveAI Mediation broker finished. Database price adjusted.")),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Execute ResolveAI Settle Broker",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
