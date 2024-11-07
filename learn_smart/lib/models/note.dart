class Note {
  int id;
  String? title; // Removed final
  String? content; // Removed final
  String? topic; // Removed final
  final int moduleId;
  final bool isAIGenerated;
  bool isSaved;

  Note({
    required this.id,
    this.title,
    this.content,
    this.topic,
    required this.moduleId,
    required this.isAIGenerated,
    this.isSaved = false,
  });

  void markAsSaved() {
    isSaved = true;
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? 0, // Default value if 'id' is null
      title: json['title'] ?? 'Untitled', // Default value if 'title' is null
      content:
          json['content'] ?? 'No content', // Default value if 'content' is null
      moduleId: json['module'] ?? 0, // Default value for moduleId
      isAIGenerated: json['isAIGenerated'] ?? false,
      isSaved: json['isSaved'] ?? false,
      topic: json['topic'] ?? 'No topic',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'module': moduleId,
      'isAIGenerated': isAIGenerated,
      'isSaved': isSaved,
      'topic': topic,
    };
  }
}
