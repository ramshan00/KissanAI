import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String wsBaseUrl = const String.fromEnvironment('WS_URL', defaultValue: "wss://ramsha00-kissanapp.hf.space");
  WebSocketChannel? _farmerChannel;
  WebSocketChannel? _providerChannel;

  /// Connects the farmer to real-time provider telemetry streams.
  void connectFarmer(int bookingId, Function(Map<String, dynamic> locationData) onLocationUpdate) {
    disconnectFarmer();
    final url = "$wsBaseUrl/api/tracking/ws/track/farmer/$bookingId";
    print("WebSocket: Farmer connecting to $url");
    
    try {
      _farmerChannel = WebSocketChannel.connect(Uri.parse(url));
      _farmerChannel!.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> parsed = jsonDecode(message);
            onLocationUpdate(parsed);
          } catch (e) {
            print("WebSocket: Error parsing farmer broadcast frame: $e");
          }
        },
        onError: (err) {
          print("WebSocket: Farmer connection error: $err");
        },
        onDone: () {
          print("WebSocket: Farmer tracking closed.");
        },
      );
    } catch (e) {
      print("WebSocket: Failed to establish farmer socket: $e");
    }
  }

  /// Closes the farmer's GPS telemetry subscriber socket.
  void disconnectFarmer() {
    _farmerChannel?.sink.close();
    _farmerChannel = null;
  }

  /// Connects the provider to the coordinates broadcaster socket.
  void connectProvider(int bookingId) {
    disconnectProvider();
    final url = "$wsBaseUrl/api/tracking/ws/track/provider/$bookingId";
    print("WebSocket: Provider tracker connecting to $url");
    
    try {
      _providerChannel = WebSocketChannel.connect(Uri.parse(url));
    } catch (e) {
      print("WebSocket: Failed to establish provider socket: $e");
    }
  }

  /// Broadcasts current GPS telemetry coordinates up to the WebSocket tracking broker.
  void sendGpsUpdate(int bookingId, int providerId, double lat, double lng) {
    if (_providerChannel == null) {
      print("WebSocket: Cannot broadcast update - provider channel offline.");
      return;
    }
    
    final payload = jsonEncode({
      "latitude": lat,
      "longitude": lng,
      "provider_id": providerId,
    });
    
    try {
      _providerChannel!.sink.add(payload);
    } catch (e) {
      print("WebSocket: Error sending GPS broadcast frame: $e");
    }
  }

  /// Closes the provider's GPS telemetry broadcaster socket.
  void disconnectProvider() {
    _providerChannel?.sink.close();
    _providerChannel = null;
  }

  /// Fully shuts down all active WebSocket channels.
  void shutdown() {
    disconnectFarmer();
    disconnectProvider();
  }
}
