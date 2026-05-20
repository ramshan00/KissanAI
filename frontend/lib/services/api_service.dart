import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Configured to support local Wi-Fi development for physical phones.
  final String baseUrl = const String.fromEnvironment('API_URL', defaultValue: "http://192.168.200.114:8000");
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    ));

    // Add interceptor to inject JWT if present
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      // Retrieve token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token != null && token.isNotEmpty) {
        options.headers["Authorization"] = "Bearer $token";
      }
      return handler.next(options);
    }));
  }

  /// Authenticates user via local backend.
  Future<Map<String, dynamic>> loginLocal(String phone) async {
    try {
      final response = await _dio.post(
        "/api/auth/login_local",
        data: {"phone": phone},
      );
      final data = response.data as Map<String, dynamic>;
      // Persist JWT for subsequent requests
      if (data.containsKey('token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token'] as String);
      }
      return data;
    } on DioException catch (e) {
      throw Exception("Login failed: ${e.response?.data['detail'] ?? e.message}");
    }
  }

  /// Registers user via local backend.
  Future<Map<String, dynamic>> registerLocal(String phone, String name, String role) async {
    try {
      final response = await _dio.post(
        "/api/auth/register_local",
        data: {
          "phone": phone,
          "name": name,
          "role": role,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception("Registration failed: ${e.response?.data['detail'] ?? e.message}");
    }
  }

  /// Lists all active and historical bookings, optionally filtered by user ID.
  Future<List<dynamic>> fetchBookings(int userId) async {
    try {
      final response = await _dio.get("/api/booking/list", queryParameters: {"user_id": userId});
      return response.data;
    } on DioException catch (e) {
      throw Exception("Failed to load bookings: ${e.response?.data['detail'] ?? e.message}");
    }
  }

  /// Transmits agricultural voice recording to the Whisper speech-to-text multipart endpoint.
  /// Triggers full Gemini Antigravity multi-agent orchestration.
  Future<Map<String, dynamic>> voiceMatchBooking(int userId, String filePath) async {
    try {
      final file = await MultipartFile.fromFile(
        filePath,
        filename: "voice_command.wav",
      );

      final formData = FormData.fromMap({
        "user_id": userId,
        "audio": file,
      });

      final response = await _dio.post(
        "/api/booking/voice-match",
        data: formData,
        options: Options(
          contentType: "multipart/form-data",
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception("Voice match failed: ${e.response?.data['detail'] ?? e.message}");
    }
  }

  /// Transmits agricultural text command to trigger full Gemini Antigravity multi-agent orchestration.
  Future<Map<String, dynamic>> textMatchBooking(int userId, String text) async {
    try {
      final response = await _dio.post(
        "/api/booking/text-match",
        data: {
          "user_id": userId,
          "text": text,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception("Text match failed: ${e.response?.data['detail'] ?? e.message}");
    }
  }

  /// Triggers standard matching for manual fallback coordinates.
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await _dio.post("/api/booking/create", data: bookingData);
      return response.data;
    } on DioException catch (e) {
      throw Exception("Booking failed: ${e.response?.data['detail'] ?? e.message}");
    }
  }

  /// Invokes the ResolveAI Mediation Dispute Settle broker with the farmer's delay reason.
  Future<Map<String, dynamic>> disputeBooking(int bookingId, String reason) async {
    try {
      final response = await _dio.post(
        "/api/booking/$bookingId/dispute",
        data: {"reason": reason},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception("Dispute negotiation failed: ${e.response?.data['detail'] ?? e.message}");
    }
  }

  /// Fetches platform stats for administrators.
  Future<Map<String, dynamic>> fetchAdminMetrics() async {
    try {
      final response = await _dio.get("/api/admin/metrics");
      return response.data;
    } on DioException catch (e) {
      throw Exception("Admin metrics fetch failed: ${e.response?.data['detail'] ?? e.message}");
    }
  }
}
