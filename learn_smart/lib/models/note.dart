class Note {
  final int id;
  final int moduleId;
  final String title;
  final String content;
  final String? topic;
  bool isAIGenerated;
  bool isSaved;

  Note({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.content,
    this.topic,
    this.isAIGenerated = false,
    this.isSaved = false,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      moduleId: json['module'],
      title: json['title'],
      content: json['content'],
      topic: json['topic'],
      isAIGenerated: json['is_ai_generated'] ?? false,
      isSaved: json['is_saved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module': moduleId,
      'title': title,
      'content': content,
      'topic': topic,
      'is_ai_generated': isAIGenerated,
      'is_saved': isSaved,
    };
  }

  Note copyWith({
    int? id,
    int? moduleId,
    String? title,
    String? content,
    String? topic,
    bool? isAIGenerated,
    bool? isSaved,
  }) {
    return Note(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      content: content ?? this.content,
      topic: topic ?? this.topic,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
