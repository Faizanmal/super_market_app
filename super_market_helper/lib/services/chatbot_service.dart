/// AI Chatbot Service
/// Handles communication with the AI shopping assistant

import 'api_service.dart';

class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final List<dynamic>? products;
  final List<dynamic>? recipes;
  final List<String>? suggestions;
  final List<Map<String, dynamic>>? actions;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.products,
    this.recipes,
    this.suggestions,
    this.actions,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] ?? 'assistant',
      content: json['message'] ?? json['content'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      products: json['products'],
      recipes: json['recipes'],
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : null,
      actions: json['actions'] != null
          ? List<Map<String, dynamic>>.from(json['actions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ChatbotService {
  final ApiService _apiService;
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  ChatbotService(this._apiService);

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  /// Send a message to the chatbot
  Future<ChatMessage> sendMessage(String message, {String? storeId}) async {
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);

    _isTyping = true;

    try {
      final response = await _apiService.post(
        '/api/ai/chat/message/',
        body: {
          'message': message,
          if (storeId != null) 'store_id': storeId,
        },
      );

      _isTyping = false;

      final assistantMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: response['message'] ?? 'Sorry, I couldn\'t process that.',
        timestamp: DateTime.now(),
        products: response['products'],
        recipes: response['recipes'],
        suggestions: response['suggestions'] != null
            ? List<String>.from(response['suggestions'])
            : null,
        actions: response['actions'] != null
            ? List<Map<String, dynamic>>.from(response['actions'])
            : null,
      );

      _messages.add(assistantMessage);
      return assistantMessage;
    } catch (e) {
      _isTyping = false;
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: 'Sorry, something went wrong. Please try again.',
        timestamp: DateTime.now(),
        suggestions: ['Try again', 'Help', 'Browse products'],
      );
      _messages.add(errorMessage);
      return errorMessage;
    }
  }

  /// Get conversation history
  Future<void> loadHistory() async {
    try {
      final response = await _apiService.get('/api/ai/chat/history/');
      final history = response['history'] as List? ?? [];
      _messages.clear();
      for (final msg in history) {
        _messages.add(ChatMessage(
          id: msg['timestamp'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          role: msg['role'],
          content: msg['content'],
          timestamp: DateTime.tryParse(msg['timestamp'] ?? '') ?? DateTime.now(),
        ));
      }
    } catch (e) {
      // Ignore - start fresh
    }
  }

  /// Clear conversation
  Future<void> clearHistory() async {
    try {
      await _apiService.post('/api/ai/chat/clear/', body: {});
      _messages.clear();
    } catch (e) {
      _messages.clear();
    }
  }

  /// Get suggested conversation starters
  Future<List<String>> getSuggestions() async {
    try {
      final response = await _apiService.get('/api/ai/chat/suggestions/');
      return List<String>.from(response['suggestions'] ?? []);
    } catch (e) {
      return [
        'What\'s on sale today?',
        'Find organic products',
        'Show me recipe ideas',
        'Help me find a product',
      ];
    }
  }

  /// Quick search
  Future<List<Map<String, dynamic>>> quickSearch(
    String query, {
    String type = 'product',
    String? storeId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/ai/quick-search/',
        body: {
          'query': query,
          'type': type,
          if (storeId != null) 'store_id': storeId,
        },
      );
      return List<Map<String, dynamic>>.from(response['results'] ?? []);
    } catch (e) {
      return [];
    }
  }
}

/// Visual Recognition Service
class VisualRecognitionService {
  final ApiService _apiService;

  VisualRecognitionService(this._apiService);

  /// Recognize product from image
  Future<Map<String, dynamic>> recognizeProduct(
    String base64Image, {
    String? storeId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/ai/vision/recognize/',
        body: {
          'image': base64Image,
          if (storeId != null) 'store_id': storeId,
        },
      );
      return response;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check freshness of produce
  Future<Map<String, dynamic>> checkFreshness(
    String base64Image, {
    String productType = 'produce',
  }) async {
    try {
      final response = await _apiService.post(
        '/api/ai/vision/freshness/',
        body: {
          'image': base64Image,
          'product_type': productType,
        },
      );
      return response;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Find similar products
  Future<List<Map<String, dynamic>>> findSimilar(String productId) async {
    try {
      final response = await _apiService.get(
        '/api/ai/vision/similar/',
        queryParams: {'product_id': productId},
      );
      return List<Map<String, dynamic>>.from(response['products'] ?? []);
    } catch (e) {
      return [];
    }
  }
}
