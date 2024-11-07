import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';
import 'package:learn_smart/models/chatbot_message.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
    _apiService.updateToken(authViewModel.user.token ?? '');
    _loadChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Assistant'),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              try {
                await _apiService.clearChatbotHistory();
                setState(() {
                  _messages.clear();
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error clearing chat history')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeMessage()
                : _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.android,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Hello! How can I help you today?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Ask me anything about your courses, learning materials, or any other questions you might have.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.android, color: Colors.white, size: 20),
              radius: 16,
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 20),
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _handleSubmitted,
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () => _handleSubmitted(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.insert(0, ChatMessage(text: text.trim(), isUser: true));
    });
    _messageController.clear();

    try {
      final response = await _apiService.getChatbotResponse(text.trim());
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text: response,
            isUser: false,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text: "Sorry, I encountered an error. Please try again.",
            isUser: false,
          ),
        );
      });
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _apiService.getChatbotHistory();
      setState(() {
        _messages.clear();
        for (var message in history) {
          _messages.add(ChatMessage(text: message.message, isUser: true));
          _messages.add(ChatMessage(text: message.response, isUser: false));
        }
      });
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}