import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Enhanced Voice Command Service for Super Market Helper
/// Provides hands-free operation with natural language processing
/// Supports inventory queries, product updates, and navigation commands
class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;
  bool _isListening = false;

  // Stream controllers for voice events
  final StreamController<VoiceEvent> _voiceEventController = 
      StreamController<VoiceEvent>.broadcast();
  final StreamController<String> _speechResultController = 
      StreamController<String>.broadcast();

  // Streams for listening to voice events
  Stream<VoiceEvent> get voiceEventStream => _voiceEventController.stream;
  Stream<String> get speechResultStream => _speechResultController.stream;

  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );

      if (_isInitialized) {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('Voice command initialization error: $e');
      return false;
    }
  }

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  /// Start listening for voice commands
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_isInitialized) {
      onError?.call('Voice recognition not available');
      return;
    }

    _isListening = true;
    
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords.toLowerCase();
          onResult(text);
          processCommand(text);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    await _speechToText.stop();
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  /// Process voice command and return action
  VoiceCommand? processCommand(String text) {
    final lowercaseText = text.toLowerCase();

    // Search commands
    if (lowercaseText.contains('search') || lowercaseText.contains('find')) {
      final query = _extractQuery(lowercaseText, ['search', 'find']);
      return VoiceCommand(
        action: VoiceAction.search,
        parameter: query,
      );
    }

    // Add product commands
    if (lowercaseText.contains('add product') ||
        lowercaseText.contains('new product') ||
        lowercaseText.contains('create product')) {
      return VoiceCommand(
        action: VoiceAction.addProduct,
        parameter: null,
      );
    }

    // Show commands
    if (lowercaseText.contains('show')) {
      if (lowercaseText.contains('expired') ||
          lowercaseText.contains('expiry')) {
        return VoiceCommand(
          action: VoiceAction.showExpired,
          parameter: null,
        );
      }
      if (lowercaseText.contains('low stock')) {
        return VoiceCommand(
          action: VoiceAction.showLowStock,
          parameter: null,
        );
      }
      if (lowercaseText.contains('dashboard')) {
        return VoiceCommand(
          action: VoiceAction.showDashboard,
          parameter: null,
        );
      }
      if (lowercaseText.contains('reports')) {
        return VoiceCommand(
          action: VoiceAction.showReports,
          parameter: null,
        );
      }
    }

    // Shopping list commands
    if (lowercaseText.contains('shopping list')) {
      return VoiceCommand(
        action: VoiceAction.showShoppingList,
        parameter: null,
      );
    }

    // Scan barcode
    if (lowercaseText.contains('scan') || lowercaseText.contains('barcode')) {
      return VoiceCommand(
        action: VoiceAction.scanBarcode,
        parameter: null,
      );
    }

    // Export/Download
    if (lowercaseText.contains('export') || lowercaseText.contains('download')) {
      return VoiceCommand(
        action: VoiceAction.exportData,
        parameter: null,
      );
    }

    return null;
  }

  String _extractQuery(String text, List<String> keywords) {
    for (final keyword in keywords) {
      final index = text.indexOf(keyword);
      if (index != -1) {
        final afterKeyword = text.substring(index + keyword.length).trim();
        // Remove common words
        return afterKeyword
            .replaceAll('for', '')
            .replaceAll('the', '')
            .replaceAll('a', '')
            .trim();
      }
    }
    return '';
  }

  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
  }
}

enum VoiceAction {
  search,
  addProduct,
  showExpired,
  showLowStock,
  showDashboard,
  showReports,
  showShoppingList,
  scanBarcode,
  exportData,
  unknown,
}

enum VoiceEvent {
  listeningStarted,
  listeningStopped,
  speechRecognized,
  commandProcessed,
  error,
}

class VoiceCommand {
  final VoiceAction action;
  final String? parameter;

  VoiceCommand({
    required this.action,
    this.parameter,
  });

  @override
  String toString() => 'VoiceCommand(action: $action, parameter: $parameter)';
}
