import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// Starts recording high-quality WAV audio to a temporary file path.
  Future<void> startRecording() async {
    try {
      // 1. Verify and request microphone permissions
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/kissanai_voice_cmd.wav';
        
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }

        // 2. Configure WAV audio parameters for OpenAI Whisper compatibility
        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000, // 16kHz is ideal for speech recognition
          numChannels: 1,    // Mono channel
          bitRate: 128000,
        );

        // 3. Start record stream
        await _recorder.start(config, path: filePath);
        _isRecording = true;
        print("AudioRecorder: Started recording to $filePath");
      } else {
        throw Exception("Microphone permission denied.");
      }
    } catch (e) {
      _isRecording = false;
      print("AudioRecorder: Failed to start recording: $e");
      rethrow;
    }
  }

  /// Stops the current recording and returns the path to the generated WAV audio file.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      print("AudioRecorder: Stopped recording. File saved at $path");
      return path;
    } catch (e) {
      _isRecording = false;
      print("AudioRecorder: Failed to stop recording: $e");
      return null;
    }
  }

  /// Releases hardware audio resources when disposed.
  void dispose() {
    _recorder.dispose();
  }
}
