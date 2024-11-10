import 'package:flutter/foundation.dart';

class Quiz {
  final int id;
  final int moduleId;
  final String title;
  final String content;
  final bool isAIGenerated;
  final bool isSaved;
  final List<int> noteIds;

  Quiz({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.content,
    this.isAIGenerated = false,
    this.isSaved = false,
    this.noteIds = const [],
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    List<int> processNoteIds() {
      final rawNoteIds = json['note_ids'];
      debugPrint('Processing raw note_ids in Quiz.fromJson: $rawNoteIds (${rawNoteIds.runtimeType})');
      
      if (rawNoteIds == null) return [];
      
      if (rawNoteIds is List) {
        return rawNoteIds.map((e) => int.parse(e.toString())).toList();
      }
      if (rawNoteIds is String && rawNoteIds.isNotEmpty) {
        return rawNoteIds
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => int.parse(e.trim()))
            .toList();
      }
      return [];
    }

    final noteIds = processNoteIds();
    debugPrint('Processed note IDs in Quiz.fromJson: $noteIds');

    return Quiz(
      id: json['id'] ?? -1,
      moduleId: json['module'] ?? json['module_id'],
      title: json['title'] ?? 'Generated Quiz',
      content: json['content'] ?? json['quiz_content'] ?? '',
      isAIGenerated: json['is_ai_generated'] ?? false,
      isSaved: json['is_saved'] ?? false,
      noteIds: noteIds,
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
      'note_ids': noteIds,
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
