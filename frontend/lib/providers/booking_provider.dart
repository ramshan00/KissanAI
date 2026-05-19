import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class BookingProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();

  // Active User Profile Context (Stubs for direct offline runtime, fully synchronized on verification)
  int currentUserId = 1;
  String currentUserName = "Bashir Ahmad";
  String currentUserPhone = "+923001234567";
  String currentUserRole = "farmer"; // "farmer" or "provider"

  List<dynamic> _bookings = [];
  Map<String, dynamic>? _activeBooking;
  List<dynamic> _activeTrace = [];
  Map<String, dynamic>? _providerLocation;
  List<Map<String, dynamic>> _disputeChat = [];
  bool _isLoading = false;

  // Getters
  List<dynamic> get bookings => _bookings;
  Map<String, dynamic>? get activeBooking => _activeBooking;
  List<dynamic> get activeTrace => _activeTrace;
  Map<String, dynamic>? get providerLocation => _providerLocation;
  List<Map<String, dynamic>> get disputeChat => _disputeChat;
  bool get isLoading => _isLoading;

  /// Logs in the user using local credentials.
  Future<void> loginLocal(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.loginLocal(phone);
      if (res["status"] == "success") {
        final user = res["user"];
        currentUserId = user["id"];
        currentUserName = user["name"];
        currentUserPhone = user["phone"];
        currentUserRole = user["role"];
        print("AuthProvider: User logged in: $currentUserName as $currentUserRole");
        await loadBookings();
      }
    } catch (e) {
      print("AuthProvider Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registers the user using local credentials.
  Future<void> registerLocal(String phone, String name, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.registerLocal(phone, name, role);
      if (res["status"] == "success") {
        final user = res["user"];
        currentUserId = user["id"];
        currentUserName = user["name"];
        currentUserPhone = user["phone"];
        currentUserRole = user["role"];
        print("AuthProvider: User registered: $currentUserName as $currentUserRole");
        await loadBookings();
      }
    } catch (e) {
      print("AuthProvider Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  /// Loads platform bookings from our FastAPI database.
  Future<void> loadBookings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _apiService.fetchBookings(currentUserRole == "farmer" ? currentUserId : 0);
      _bookings = list;
    } catch (e) {
      print("BookingProvider Error loading list: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits the farmer's raw Urdu text command to our real Gemini agent backend.
  Future<void> bookWithText(String text) async {
    _isLoading = true;
    _activeTrace = []; // Reset trace timeline
    notifyListeners();
    try {
      final result = await _apiService.textMatchBooking(currentUserId, text);
      _activeBooking = result["booking"];
      _activeTrace = result["trace"];
      await loadBookings();
    } catch (e) {
      print("BookingProvider Error text matching: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits the farmer's raw Urdu WAV recording to our real Whisper and Gemini agent backend.
  Future<void> bookWithVoice(String filePath) async {
    _isLoading = true;
    _activeTrace = []; // Reset trace timeline
    notifyListeners();
    try {
      final result = await _apiService.voiceMatchBooking(currentUserId, filePath);
      _activeBooking = result["booking"];
      _activeTrace = result["trace"];
      await loadBookings();
    } catch (e) {
      print("BookingProvider Error voice matching: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Triggers live GPS tracking sub-system for an active booking.
  void startTrackingActiveBooking(int bookingId) {
    _providerLocation = null;
    _wsService.connectFarmer(bookingId, (locationUpdate) {
      _providerLocation = locationUpdate;
      print("BookingProvider Telemetry: Matched Provider moved: $_providerLocation");
      notifyListeners();
    });
  }

  /// Stops listening to live GPS updates.
  void stopTrackingActiveBooking() {
    _wsService.disconnectFarmer();
    _providerLocation = null;
  }



  /// Triggers ResolveAI mediation broker initialization.
  void initiateDisputeMediation(Map<String, dynamic> booking) {
    _activeBooking = booking;
    _disputeChat = [];
    notifyListeners();
  }

  /// Submits Dispute resolution to the API and triggers final settlements.
  Future<void> executeResolveAIDispute(String complaint) async {
    if (_activeBooking == null) return;
    _isLoading = true;
    notifyListeners();
    
    try {
      final res = await _apiService.disputeBooking(_activeBooking!["id"], complaint);
      _activeBooking = res["booking"];
      
      // Extract dynamic trace details as chat bubbles
      final trace = res["trace"] as List<dynamic>;
      for (var t in trace) {
        _disputeChat.add({
          "sender": "agent",
          "message": "🤖 ${t['step']}: ${t['details'].toString()}"
        });
      }
      
      _disputeChat.add({
        "sender": "system",
        "message": "✅ Dispute Settle Confirmed! New price updated to PKR ${res['booking']['price']} in DB."
      });
      
      await loadBookings();
    } catch (e) {
      print("Dispute Resolution Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _wsService.shutdown();
    super.dispose();
  }
}
