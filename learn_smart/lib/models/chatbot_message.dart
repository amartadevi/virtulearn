class ChatbotMessage {
  final int id;
  final String username;
  final String message;
  final String response;
  final DateTime createdAt;

  ChatbotMessage({
    required this.id,
    required this.username,
    required this.message,
    required this.response,
    required this.createdAt,
  });

  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    return ChatbotMessage(
      id: json['id'],
      username: json['username'],
      message: json['message'],
      response: json['response'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
} 