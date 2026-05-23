import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // FIX: proper runtime-safe baseUrl handling
  final String baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: "https://ramsha00-kissanapp.hf.space",
  );

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ),
    );

    // JWT interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');

          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }

          return handler.next(options);
        },
      ),
    );
  }

  // LOGIN
  Future<Map<String, dynamic>> loginLocal(String phone) async {
    try {
      final response = await _dio.post(
        "/api/auth/login_local",
        data: {"phone": phone},
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
      }

      return data;
    } on DioException catch (e) {
      throw Exception("Login failed: ${e.response?.data ?? e.message}");
    }
  }

  // REGISTER
  Future<Map<String, dynamic>> registerLocal(
      String phone, String name, String role) async {
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
      throw Exception("Registration failed: ${e.response?.data ?? e.message}");
    }
  }

  // BOOKINGS LIST
  Future<List<dynamic>> fetchBookings(int userId) async {
    try {
      final response = await _dio.get(
        "/api/booking/list",
        queryParameters: {"user_id": userId},
      );

      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception("Failed to load bookings: ${e.response?.data ?? e.message}");
    }
  }

  // VOICE MATCH
  Future<Map<String, dynamic>> voiceMatchBooking(
      int userId, String filePath) async {
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
        options: Options(contentType: "multipart/form-data"),
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception("Voice match failed: ${e.response?.data ?? e.message}");
    }
  }

  // TEXT MATCH
  Future<Map<String, dynamic>> textMatchBooking(
      int userId, String text) async {
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
      throw Exception("Text match failed: ${e.response?.data ?? e.message}");
    }
  }

  // CREATE BOOKING
  Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    try {
      final response = await _dio.post(
        "/api/booking/create",
        data: bookingData,
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception("Booking failed: ${e.response?.data ?? e.message}");
    }
  }

  // DISPUTE
  Future<Map<String, dynamic>> disputeBooking(
      int bookingId, String reason) async {
    try {
      final response = await _dio.post(
        "/api/booking/$bookingId/dispute",
        data: {"reason": reason},
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception("Dispute failed: ${e.response?.data ?? e.message}");
    }
  }

  // ADMIN METRICS
  Future<Map<String, dynamic>> fetchAdminMetrics() async {
    try {
      final response = await _dio.get("/api/admin/metrics");
      return response.data;
    } on DioException catch (e) {
      throw Exception("Admin metrics failed: ${e.response?.data ?? e.message}");
    }
  }
}