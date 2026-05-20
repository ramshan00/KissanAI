import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';

class TraceTimelineScreen extends StatelessWidget {
  const TraceTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BookingProvider>(context);
    final trace = prov.activeTrace;
    final isDone = trace.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF032615)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button Row
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),

              // Title Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Google Antigravity Engine",
                      style: TextStyle(color: Colors.emeraldAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Orchestration Trace",
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // 2. Active Timeline List / Loading Indicator
              Expanded(
                child: !isDone 
                  ? _buildOrchestrationSpinner()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                      itemCount: trace.length,
                      itemBuilder: (context, index) {
                        final step = trace[index];
                        final agent = step["agent"] ?? "Agent";
                        final status = step["status"] ?? "COMPLETED";
                        final details = step["details"] ?? "";
                        final isLast = index == trace.length - 1;

                        return _buildTimelineStep(
                          index: index + 1,
                          agent: agent,
                          status: status,
                          details: details,
                          isLast: isLast,
                        );
                      },
                    ),
              ),

              // 3. Bottom complete card
              if (isDone) _buildCompleteCard(context, prov),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrchestrationSpinner() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              color: Colors.emeraldAccent,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "AI AGENTS SYNCHRONIZING...",
            style: TextStyle(color: Colors.emeraldAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Whisper STT is translating speech claims, and Google Gemini is orchestrating matching, complexity risk grading, and dynamic pricing updates in PostgreSQL...",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required int index,
    required String agent,
    required String status,
    required String details,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circle indicator and vertical line
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.shapeCircle,
                color: Colors.emeraldAccent.withOpacity(0.12),
                border: Border.all(color: Colors.emeraldAccent, width: 2),
              ),
              child: Center(
                child: Text(
                  index.toString(),
                  style: const TextStyle(color: Colors.emeraldAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 75,
                color: Colors.emeraldAccent.withOpacity(0.3),
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Step details card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      agent.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      status,
                      style: const TextStyle(color: Colors.emeraldAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  details,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteCard(BuildContext context, BookingProvider prov) {
    final b = prov.activeBooking;
    final price = b?["price"] ?? 0.0;
    final operator = b?["provider_id"] == 1 ? "Tariq Mahmood" : "Muhammad Asif";

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.emeraldAccent, size: 24),
              const SizedBox(width: 10),
              Text(
                "Match Orchestrated Successfully!",
                style: TextStyle(color: Colors.emeraldAccent.shade100, fontSize: 16, fontWeight: FontWeight.bold),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CONFIRMED OPERATOR", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(operator, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("FAIR PRICE FARE", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text("PKR $price", style: const TextStyle(color: Colors.emeraldAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.emeraldAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              // Return to Dashboard where they see transaction loaded
              Navigator.of(context).pop();
            },
            child: const Text(
              "Done, Open Dashboard",
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          )
        ],
      ),
    );
  }
}
