import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/log_entry.dart';
import '../services/logging_service.dart';

class VoiceAgent {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _speechToText.isListening;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (val) => print('STT Error: $val'),
        onStatus: (val) => print('STT Status: $val'),
      );
    } catch (e) {
      print('STT Initialization failed: $e');
      _isAvailable = false;
    }
    return _isAvailable;
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isAvailable) {
      print('Speech recognition is not initialized or available');
      return;
    }

    await LoggingService.log(LogEntry(
      agent: 'Voice Agent',
      workflowStage: 'voice-input',
      decision: 'Starting voice recording',
      reasoning: 'User activated microphone',
      actionTaken: 'start_listening',
      severity: 'info',
      timestamp: DateTime.now(),
    ));

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
  }

  Future<void> stopListening() async {
    await LoggingService.log(LogEntry(
      agent: 'Voice Agent',
      workflowStage: 'voice-input',
      decision: 'Stopping voice recording',
      reasoning: 'Microphone deactivated or timeout',
      actionTaken: 'stop_listening',
      severity: 'info',
      timestamp: DateTime.now(),
    ));
    await _speechToText.stop();
  }

  Future<void> speak(String text, {String language = 'en-US'}) async {
    await LoggingService.log(LogEntry(
      agent: 'Voice Agent',
      workflowStage: 'voice-output',
      decision: 'Generating voice response',
      reasoning: 'TTS conversion',
      actionTaken: 'speak_text',
      severity: 'info',
      timestamp: DateTime.now(),
    ));

    await _flutterTts.setLanguage(language);
    await _flutterTts.speak(text);
  }
}
