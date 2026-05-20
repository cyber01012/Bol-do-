import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiKeyRotator {
  static final GeminiKeyRotator instance = GeminiKeyRotator._internal();
  
  final List<String> _keys = [];
  int _currentIndex = 0;

  GeminiKeyRotator._internal() {
    _loadKeys();
  }

  void _loadKeys() {
    // Attempt to load multiple keys from environment
    // e.g. GEMINI_API_KEY, GEMINI_API_KEY_1, GEMINI_API_KEY_2, etc.
    
    // Check standard key
    final standardKey = dotenv.env['GEMINI_API_KEY'];
    if (standardKey != null && standardKey.trim().isNotEmpty) {
      _keys.add(standardKey.trim());
    }

    // Check indexed keys up to 10
    for (int i = 1; i <= 10; i++) {
      final key = dotenv.env['GEMINI_API_KEY_$i'];
      if (key != null && key.trim().isNotEmpty) {
        if (!_keys.contains(key.trim())) {
          _keys.add(key.trim());
        }
      }
    }

    if (_keys.isEmpty) {
      print('⚠️ CRITICAL: No Gemini API keys found in .env file!');
    } else {
      print('✅ GeminiKeyRotator initialized with ${_keys.length} keys.');
    }
  }

  /// Get the next available API key in a round-robin fashion.
  String getNextKey() {
    if (_keys.isEmpty) {
      throw Exception('Missing Gemini API Key. Please check your .env file.');
    }
    
    // Round-robin selection
    final key = _keys[_currentIndex];
    _currentIndex = (_currentIndex + 1) % _keys.length;
    return key;
  }
  
  /// Helper to sanitize logs by replacing any API keys with [REDACTED]
  String sanitizeLog(String logMessage) {
    if (_keys.isEmpty) return logMessage;
    
    String sanitized = logMessage;
    for (final key in _keys) {
      if (key.length > 10) { // Only replace strings that look like keys
        sanitized = sanitized.replaceAll(key, '[REDACTED_API_KEY]');
      }
    }
    return sanitized;
  }
}
