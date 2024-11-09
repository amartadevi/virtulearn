class Quiz {
  final int id;
  final String title;
  final String content;
  final bool isAIGenerated;
  final bool isSaved;
  final int moduleId; // Linking to the module the quiz belongs to

  
  Quiz({
    required this.id,
    required this.title,
    required this.content,
    required this.isAIGenerated,
    required this.isSaved,
    required this.moduleId,

  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      content: json['quiz_content'] ?? json['content'],
      isAIGenerated: json['is_ai_generated'] ?? false,
      isSaved: json['is_saved'] ?? false,
      moduleId: json['module_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_ai_generated': isAIGenerated,
      'is_saved': isSaved,
      'module_id': moduleId,
    };
  }
}

class Question {
  final String questionText;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String? correctAnswer;

  Question({
    required this.questionText,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionText: json['question_text'] ?? 'No question text provided',
      optionA: json['option_a'],
      optionB: json['option_b'],
      optionC: json['option_c'],
      optionD: json['option_d'],
      correctAnswer: json['correct_answer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_answer': correctAnswer,
    };
  }
}
