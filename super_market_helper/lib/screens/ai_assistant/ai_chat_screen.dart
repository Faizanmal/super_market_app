/// AI Chat Screen
/// Interactive chat interface with the AI shopping assistant

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/chatbot_service.dart';
import '../../services/api_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late final ChatbotService _chatbotService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _chatbotService = ChatbotService(ApiService());
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _chatbotService.loadHistory();
    final suggestions = await _chatbotService.getSuggestions();
    setState(() {
      _messages = _chatbotService.messages;
      _suggestions = suggestions;
    });
    
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        id: 'welcome',
        role: 'assistant',
        content: 'Hi! 👋 I\'m your shopping assistant. How can I help you today?\n\nYou can ask me about:\n• Finding products\n• Checking prices\n• Recipe ideas\n• Store navigation\n• Order status',
        timestamp: DateTime.now(),
        suggestions: _suggestions,
      ));
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    _messageController.clear();
    setState(() => _isLoading = true);
    
    await _chatbotService.sendMessage(message);
    
    setState(() {
      _messages = _chatbotService.messages;
      _isLoading = false;
    });
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shopping Assistant', style: TextStyle(fontSize: 16)),
                Text('Online', style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _chatbotService.clearHistory();
              setState(() => _messages = []);
              _addWelcomeMessage();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Quick suggestions
          if (_messages.isNotEmpty && _messages.last.suggestions != null)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _messages.last.suggestions!.length,
                itemBuilder: (context, index) {
                  final suggestion = _messages.last.suggestions![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ActionChip(
                      label: Text(suggestion),
                      onPressed: () => _sendMessage(suggestion),
                    ),
                  );
                },
              ),
            ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () {
                      // Voice input - would integrate speech_to_text
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voice input coming soon!')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {
                      // Visual search
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Visual search coming soon!')),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(_messageController.text),
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

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ),
            
            // Products carousel
            if (message.products != null && message.products!.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: message.products!.length,
                  itemBuilder: (context, index) {
                    final product = message.products![index];
                    return _buildProductCard(product);
                  },
                ),
              ),
            
            // Recipes carousel
            if (message.recipes != null && message.recipes!.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: message.recipes!.length,
                  itemBuilder: (context, index) {
                    final recipe = message.recipes![index];
                    return _buildRecipeCard(recipe);
                  },
                ),
              ),
            
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(right: 8, top: 8),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      margin: const EdgeInsets.only(right: 8, top: 8),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.timer, size: 14),
                const SizedBox(width: 4),
                Text('${recipe['prep_time'] ?? 0 + (recipe['cook_time'] ?? 0)} min'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            _buildDot(1),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5 + value * 0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays > 0) {
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
