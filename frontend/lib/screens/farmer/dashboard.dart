import 'package:flutter/material.dart';
import 'package:kissanai/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/audio_recorder.dart';
import 'trace_timeline.dart';
import 'tracking_map.dart';
import '../provider/dispute_mediation.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> with SingleTickerProviderStateMixin {
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  late AnimationController _micAnimationController;
  bool _isListening = false;
  String _recordingStatus = "Press & Hold Microphone to speak...";

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // Load bookings on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
    });
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await _audioRecorder.startRecording();
      setState(() {
        _isListening = true;
        _recordingStatus = "Assalamu Alaikum! Recording your command...";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Microphone access failed - $e")),
      );
    }
  }

  Future<void> _stopAndSubmitRecording() async {
    if (!_isListening) return;
    setState(() {
      _isListening = false;
      _recordingStatus = "Processing speech via Whisper STT...";
    });
    
    final path = await _audioRecorder.stopRecording();
    if (path != null) {
      try {
        final prov = Provider.of<BookingProvider>(context, listen: false);
        
        // Push timeline screen to watch AI Orchestration live
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TraceTimelineScreen()),
        );

        // Dispatch to AI orchestrator in background
        await prov.bookWithVoice(path);
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss timeline if crashed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Orchestration failed: $e")),
          );
          setState(() {
            _recordingStatus = "Press & Hold Microphone to speak...";
          });
        }
      }
    }
  }

  String _getTranslatedRecordingStatus(LanguageProvider lang) {
    if (_recordingStatus.contains("Press & Hold") || _recordingStatus.contains("speak")) {
      return lang.translate('tap_to_speak');
    } else if (_recordingStatus.contains("Assalamu Alaikum")) {
      return lang.isUrdu ? "السلام علیکم! آپ کی آواز ریکارڈ کی جا رہی ہے..." : "Assalamu Alaikum! Recording your command...";
    } else if (_recordingStatus.contains("Processing")) {
      return lang.isUrdu ? "رومن اردو آواز کی ترجمانی کی جا رہی ہے..." : "Processing speech via Whisper STT...";
    }
    return _recordingStatus;
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BookingProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate blue
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF042F1A)], // Agritech rich emerald blend
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // 1. Premium Glassmorphic Header Card
              _buildHeader(prov, langProvider),

              // 2. Main interactive contents
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Command shortcuts banner
                      _buildShortcutsHeader(langProvider),
                      const SizedBox(height: 10),
                      _buildShortcutsGrid(langProvider),
                      
                      const SizedBox(height: 30),
                      
                      // Central Microphone interaction panel
                      _buildMicrophonePanel(langProvider),
                      
                      const SizedBox(height: 30),
                      
                      // Active bookings list
                      _buildBookingsHeader(prov, langProvider),
                      const SizedBox(height: 10),
                      _buildBookingsList(prov, langProvider),
                      
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

  Widget _buildHeader(BookingProvider prov, LanguageProvider langProvider) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: -2,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                langProvider.translate('assalamu_alaikum'),
                style: TextStyle(color: AppColors.emeraldAccent.shade100, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                prov.currentUserName,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                langProvider.isUrdu ? "کردار: کِسان موبائل ایپ" : "Role: Farmer Mobile App",
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ],
          ),
          
          // Premium Bilingual Language Toggle Switch Pill
          InkWell(
            onTap: () {
              langProvider.toggleLanguage();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "EN",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: langProvider.isUrdu ? Colors.white38 : AppColors.emeraldAccent,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 1,
                    height: 8,
                    color: Colors.white24,
                  ),
                  Text(
                    "اردو",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: langProvider.isUrdu ? AppColors.emeraldAccent : Colors.white38,
                      fontFamily: 'Noto Naskh Arabic',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsHeader(LanguageProvider lang) {
    return Row(
      children: [
        const Icon(Icons.mic_none, color: AppColors.emeraldAccent, size: 18),
        const SizedBox(width: 8),
        Text(
          lang.translate('voice_match'),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildShortcutsGrid(LanguageProvider lang) {
    final shortcuts = lang.isUrdu ? [
      "مجھے کل صبح لاہور میں ٹریکٹر چاہیے",
      "فیصل آباد میں فوری ہارویسٹر کی ضرورت ہے!",
      "ملتان میں گندم کی کٹائی کے لیے تھریشر چاہیے",
    ] : [
      "Mujhe kal subah Lahore mein tractor chahiye",
      "Urgent harvester required in Faisalabad immediately!",
      "Multan mein gandum ki katai k liye thresher chahiye",
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: shortcuts.map((txt) {
        return GestureDetector(
          onTap: () async {
            // Trigger auto matched search instantly
            final prov = Provider.of<BookingProvider>(context, listen: false);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TraceTimelineScreen()),
            );
            // Dispatch preset commands
            await prov.bookWithText(txt);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Text(
              txt,
              style: const TextStyle(color: AppColors.emeraldAccent, fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMicrophonePanel(LanguageProvider lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            _getTranslatedRecordingStatus(lang),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Pulsing Microphone Card
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopAndSubmitRecording(),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: _isListening ? 1.2 : 1.0).animate(
                CurvedAnimation(parent: _micAnimationController, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isListening 
                      ? [Colors.redAccent, Colors.pink] 
                      : [AppColors.emeraldAccent, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.redAccent : AppColors.emeraldAccent).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Text(
            _isListening 
                ? (lang.isUrdu ? "بکنگ کے لیے مائیک چھوڑیں" : "RELEASE TO ORCHESTRATE")
                : (lang.isUrdu ? "بولنے کے لیے دبا کر رکھیں" : "HOLD TO SPEAK"),
            style: TextStyle(
              color: _isListening ? Colors.redAccent : AppColors.emeraldAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBookingsHeader(BookingProvider prov, LanguageProvider lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: AppColors.emeraldAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              lang.translate('recent_bookings'),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (prov.isLoading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emeraldAccent),
          )
      ],
    );
  }

  Widget _buildBookingsList(BookingProvider prov, LanguageProvider lang) {
    if (prov.bookings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          lang.translate('no_bookings'),
          style: const TextStyle(color: Colors.white38, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: prov.bookings.length,
      itemBuilder: (context, index) {
        final b = prov.bookings[index];
        final id = b["id"];
        final service = b["service_type"] ?? "tractor";
        final loc = b["location"] ?? "Lahore";
        final status = b["status"] ?? "pending";
        final price = b["price"] ?? 0.0;
        final operatorName = b["provider_id"] == 1 ? "Tariq Mahmood" : "Muhammad Asif";

        // Translate service type
        String serviceDisplayName = service.toUpperCase();
        if (lang.isUrdu) {
          if (service.toLowerCase() == "tractor") serviceDisplayName = "ٹریکٹر";
          else if (service.toLowerCase() == "harvester") serviceDisplayName = "ہارویسٹر";
          else if (service.toLowerCase() == "thresher") serviceDisplayName = "تھریشر";
          else if (service.toLowerCase() == "seeder") serviceDisplayName = "سیڈر";
        }

        // Translate status badge
        String statusDisplayName = status.toUpperCase();
        if (lang.isUrdu) {
          if (status == "pending") statusDisplayName = "انتظار میں";
          else if (status == "confirmed") statusDisplayName = "تصدیق شدہ";
          else if (status == "completed") statusDisplayName = "مکمل شدہ";
          else if (status == "disputed") statusDisplayName = "تنازعہ";
          else if (status == "resolved") statusDisplayName = "حل شدہ";
        }

        // Status badge colors
        Color badgeColor = Colors.yellow;
        if (status == "confirmed" || status == "completed") {
          badgeColor = AppColors.emeraldAccent;
        } else if (status == "disputed" || status == "resolved") {
          badgeColor = Colors.orangeAccent;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        service == "harvester" ? Icons.agriculture : Icons.airport_shuttle,
                        color: AppColors.emeraldAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$serviceDisplayName - #$id",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      statusDisplayName,
                      style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              
              Text(
                lang.isUrdu ? "📍 جگہ: $loc" : "📍 Location: $loc", 
                style: const TextStyle(color: Colors.white70, fontSize: 13)
              ),
              const SizedBox(height: 4),
              Text(
                lang.isUrdu ? "👤 آپریٹر: $operatorName" : "👤 Operator: $operatorName", 
                style: const TextStyle(color: Colors.white70, fontSize: 13)
              ),
              const SizedBox(height: 4),
              Text(
                lang.isUrdu ? "💰 کل کرایہ: روپے $price" : "💰 Total Fare: PKR $price", 
                style: const TextStyle(color: Colors.white70, fontSize: 13)
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Tracking button
                  if (status == "confirmed" || status == "active")
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.emeraldAccent.withOpacity(0.12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.map, color: AppColors.emeraldAccent, size: 16),
                      label: Text(
                        lang.translate('gps_tracking'), 
                        style: const TextStyle(color: AppColors.emeraldAccent)
                      ),
                      onPressed: () {
                        // Open Leaflet Live Tracking OSM Map
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TrackingMapScreen(booking: b),
                          ),
                        );
                      },
                    ),
                  const SizedBox(width: 8),
                  
                  // Dispute button
                  if (status == "confirmed" || status == "disputed" || status == "resolved")
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.orangeAccent.withOpacity(0.12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 16),
                      label: Text(
                        lang.isUrdu 
                            ? (status == "disputed" ? "جاری فیصلہ" : status == "resolved" ? "فیصلے کی تفصیل" : "شکایت درج کریں") 
                            : (status == "disputed" ? "Negotiating" : status == "resolved" ? "Resolved Logs" : "Dispute Delay"), 
                        style: const TextStyle(color: Colors.orangeAccent)
                      ),
                      onPressed: () {
                        // Open ResolveAI mediation chat
                        prov.initiateDisputeMediation(b);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const DisputeMediationScreen()),
                        );
                      },
                    ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
