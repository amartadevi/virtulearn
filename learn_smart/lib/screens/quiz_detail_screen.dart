import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/models/quiz.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';
import 'package:learn_smart/screens/suggestion_screen.dart';
import 'package:learn_smart/screens/result_screen.dart';

class QuizDetailScreen extends StatefulWidget {
  final int moduleId;
  final int quizId;
  final bool isStudentEnrolled;
  final bool isEditMode;
  final Map<String, dynamic>? generatedQuiz;

  QuizDetailScreen({
    required this.moduleId,
    required this.quizId,
    required this.isStudentEnrolled,
    this.isEditMode = false,
    this.generatedQuiz,
  });

  @override
  _QuizDetailScreenState createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  Quiz? quiz;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late ApiService _apiService;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Map<String, dynamic>> parsedQuestions = [];

  int currentQuestionIndex = 0;
  String selectedAnswer = '';
  Map<int, String> selectedAnswers = {};
  bool showResult = false;
  bool showReview = false;

  double progress = 0.0;
  int correctAnswersCount = 0;
  Timer? _timer;
  int timeLeft = 30; // 30 seconds per question
  bool isStudent = false;
  bool hasQuizStarted = false;
  bool isGeneratedQuiz = false;
  bool isSaved = false;
  bool isExplicitlySaved = false;

  Future<void> _processGeneratedQuiz() async {
    if (widget.generatedQuiz != null) {
      setState(() {
        isGeneratedQuiz = true;
        _parseQuizContent(widget.generatedQuiz!['content']);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      isStudent = authViewModel.user.role == 'student';
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');
      await _loadQuizDetails();
    });
  }

Future<void> _loadQuizDetails() async {
  try {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    List<int> noteIds = [];
    
    // First try to get note IDs from generated quiz
    if (widget.generatedQuiz != null) {
      var rawNoteIds = widget.generatedQuiz!['note_ids'];
      debugPrint('Raw note_ids from generatedQuiz: $rawNoteIds (${rawNoteIds.runtimeType})');
      
      if (rawNoteIds is List) {
        noteIds = rawNoteIds.map((e) => int.parse(e.toString())).toList();
      } else if (rawNoteIds is String && rawNoteIds.isNotEmpty) {
        noteIds = rawNoteIds.split(',')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => int.parse(e.trim()))
            .toList();
      }

      final content = widget.generatedQuiz!['quiz_content'] ??
                     widget.generatedQuiz!['content'] ??
                     widget.generatedQuiz!['generated_content'];

      debugPrint('Extracted noteIds: $noteIds');

      setState(() {
        quiz = Quiz(
          id: widget.quizId,
          moduleId: widget.moduleId,
          title: widget.generatedQuiz!['title'] ?? 'Generated Quiz',
          content: content.toString(),
          isAIGenerated: true,
          isSaved: false,
          noteIds: noteIds,
        );
        _parseQuizContent(content.toString());
      });
    } else {
      final response = await _apiService.getQuizDetail(widget.moduleId, widget.quizId);
      setState(() {
        quiz = response;
        if (quiz?.content != null) {
          _parseQuizContent(quiz!.content);
        }
      });
    }
  } catch (e) {
    debugPrint('Error loading quiz: $e');
    setState(() {
      _hasError = true;
      _errorMessage = _getReadableErrorMessage(e);
    });
  } finally {
    setState(() => _isLoading = false);
  }
}

// Helper function to truncate content to a manageable length
String _truncateContent(String content, {int maxLength = 10000}) {
  return content.length > maxLength ? content.substring(0, maxLength) + '...' : content;
}

  void _startTimer() {
    timeLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
          progress = 1 - (timeLeft / 30);
        } else {
          timer.cancel();
          _goToNextQuestion();
        }
      });
    });
  }

void _parseQuizContent(String? content) {
  if (content == null || content.isEmpty) {
    debugPrint('Content is null or empty');
    return;
  }

  try {
    debugPrint('Starting to parse content: $content'); // Debug log
    parsedQuestions.clear();
    
    // Split content into lines and clean up
    List<String> lines = content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    debugPrint('Parsed lines: ${lines.length}'); // Debug log

    Map<String, dynamic>? currentQuestion;
    List<String> currentOptions = [];
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      debugPrint('Processing line: $line'); // Debug log
      
      // Skip introductory text and empty lines
      if (line.contains("I'm here to assist you") || 
          line.contains("Let's get started") ||
          line.contains("these questions align") ||
          line.trim().isEmpty) {
        continue;
      }

      // New question starts with a number
      if (RegExp(r'^\d+[\).]').hasMatch(line)) {
        // Save previous question if exists
        if (currentQuestion != null && currentOptions.isNotEmpty) {
          currentQuestion['options'] = List<String>.from(currentOptions);
          parsedQuestions.add(Map<String, dynamic>.from(currentQuestion));
          debugPrint('Added question: $currentQuestion'); // Debug log
        }
        
        // Start new question
        currentQuestion = {
          'question': line.replaceFirst(RegExp(r'^\d+[\).]'), '').trim(),
          'correctAnswer': '',
        };
        currentOptions = [];
        debugPrint('New question started: ${currentQuestion['question']}'); // Debug log
      }
      // Option line
      else if (RegExp(r'^[A-D][\).]').hasMatch(line)) {
        String option = line.substring(2).trim();
        currentOptions.add(option);
        debugPrint('Added option: $option'); // Debug log
      }
      // Correct answer line
      else if (line.toLowerCase().contains('correct answer')) {
        if (currentQuestion != null) {
          currentQuestion['correctAnswer'] = line
              .split(':')
              .last
              .trim()
              .replaceAll(RegExp(r'[^A-D]'), '');
          debugPrint('Set correct answer: ${currentQuestion['correctAnswer']}'); // Debug log
        }
        
        // Add the last question when we hit the correct answer
        if (currentQuestion != null && currentOptions.isNotEmpty) {
          currentQuestion['options'] = List<String>.from(currentOptions);
          parsedQuestions.add(Map<String, dynamic>.from(currentQuestion));
          debugPrint('Added final question: $currentQuestion'); // Debug log
          currentQuestion = null;
          currentOptions = [];
        }
      }
    }

    debugPrint('Parsed ${parsedQuestions.length} questions'); // Debug log
    
    if (parsedQuestions.isEmpty) {
      throw Exception('No valid questions found in the content');
    }

  } catch (e) {
    debugPrint('Error parsing quiz content: $e');
    setState(() {
      _hasError = true;
      _errorMessage = 'Failed to parse quiz content: $e';
    });
  }
}


  // Helper method to convert option letter to index
  int _getOptionIndex(String letter) {
    return letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
  }

  // Helper method to get option letter from index
  String _getOptionLetter(int index) {
    return String.fromCharCode(65 + index); // A, B, C, D
  }

  void _goToNextQuestion() {
    if (currentQuestionIndex < parsedQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = selectedAnswers[currentQuestionIndex] ?? '';
        timeLeft = 30; // Reset timer for new question
      });
    } else {
      _submitQuiz();
    }
  }

  void _calculateResult() {
    correctAnswersCount = 0;
    for (int i = 0; i < parsedQuestions.length; i++) {
      final question = parsedQuestions[i];
      final selectedAnswer = selectedAnswers[i];
      
      if (selectedAnswer != null && question['options'] != null) {
        // Get the index of the selected answer
        final selectedIndex = (question['options'] as List).indexOf(selectedAnswer);
        if (selectedIndex != -1) {
          // Convert to letter (A, B, C, etc.)
          final selectedLetter = String.fromCharCode(65 + selectedIndex);
          if (selectedLetter == question['correctAnswer']) {
            correctAnswersCount++;
          }
        }
      }
    }
    debugPrint('Correct answers: $correctAnswersCount out of ${parsedQuestions.length}');
  }

  String _generateSubmissionContent() {
    List<Map<String, dynamic>> submissionData = [];
    for (int i = 0; i < parsedQuestions.length; i++) {
      String? selectedAnswer = selectedAnswers[i];
      String? correctAnswer = parsedQuestions[i]['correctAnswer'] as String?;
      
      submissionData.add({
        'question': parsedQuestions[i]['question'],
        'selected_answer': selectedAnswer ?? '',
        'correct_answer': correctAnswer ?? '',
        'is_correct': selectedAnswer != null && 
                     correctAnswer != null && 
                     correctAnswer == selectedAnswer.substring(0, 1),
      });
    }
    return json.encode(submissionData);  // Using jsonEncode instead of json.encode
  }

void _submitQuiz() async {
  _calculateResult();
  _timer?.cancel();

  try {
    setState(() => _isLoading = true);

    final totalQuestions = parsedQuestions.length;
    final percentage = (correctAnswersCount / totalQuestions) * 100;

    Map<String, dynamic> studentAnswers = {};
    for (int i = 0; i < parsedQuestions.length; i++) {
      final question = parsedQuestions[i];
      final selectedAnswer = selectedAnswers[i];
      final selectedIndex = selectedAnswer != null ? 
          (question['options'] as List).indexOf(selectedAnswer) : -1;
      final selectedLetter = selectedIndex != -1 ? 
          String.fromCharCode(65 + selectedIndex) : '';

      studentAnswers['$i'] = {
        'question': question['question'],
        'selected_answer': selectedLetter,
        'correct_answer': question['correctAnswer'],
        'is_correct': selectedLetter == question['correctAnswer'],
      };
    }

    final resultData = {
      'score': correctAnswersCount,
      'total_questions': totalQuestions,
      'percentage': percentage,
      'student_answers': studentAnswers,
    };

    debugPrint('Submitting quiz result: $resultData');

    await _apiService.submitQuizResult(
      widget.moduleId,
      widget.quizId,
      resultData,
    );

    setState(() {
      _isLoading = false;
      showResult = true;  // This will show the result view
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quiz submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ),
    );
    debugPrint('Failed to submit quiz: $e');
  }
}

  Widget _buildQuizContent() {
    if (parsedQuestions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    // Teacher view - show full quiz content
    if (!isStudent || widget.isEditMode) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz Title
            Text(
              quiz?.title ?? 'Generated Quiz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 24),
            
            // Questions List
            ...List.generate(parsedQuestions.length, (index) {
              final question = parsedQuestions[index];
              final options = question['options'] as List<String>;
              
              return Card(
                margin: EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Number and Text
                      Text(
                        'Question ${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        question['question'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Options
                      ...List.generate(options.length, (optionIndex) {
                        final optionLetter = String.fromCharCode(65 + optionIndex);
                        final isCorrectAnswer = optionLetter == question['correctAnswer'];
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isCorrectAnswer ? Colors.green : Colors.grey[300]!,
                              width: isCorrectAnswer ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isCorrectAnswer ? Colors.green.withOpacity(0.1) : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCorrectAnswer ? Colors.green : Colors.grey[400]!,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    optionLetter,
                                    style: TextStyle(
                                      color: isCorrectAnswer ? Colors.green : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  options[optionIndex],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isCorrectAnswer ? Colors.green : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isCorrectAnswer)
                                Icon(Icons.check_circle, color: Colors.green),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    // Student view - show quiz attempt interface
    return Column(
      children: [
        // Show timer and progress only for students
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${currentQuestionIndex + 1}/${parsedQuestions.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  Container(
                    width: 45,
                    height: 45,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            timeLeft > 10 ? Colors.green : Colors.red,
                          ),
                        ),
                        Center(
                          child: Text(
                            '$timeLeft',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: timeLeft > 10 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Rest of the existing student quiz attempt UI
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parsedQuestions[currentQuestionIndex]['question'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  ..._buildOptions(),
                ],
              ),
            ),
          ),
        ),
        
        // Navigation buttons for students
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentQuestionIndex > 0)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentQuestionIndex--;
                      selectedAnswer = selectedAnswers[currentQuestionIndex] ?? '';
                      _timer?.cancel();
                      _startTimer();
                    });
                  },
                  child: Text('Previous'),
                ),
              ElevatedButton(
                onPressed: () {
                  if (currentQuestionIndex < parsedQuestions.length - 1) {
                    setState(() {
                      currentQuestionIndex++;
                      selectedAnswer = selectedAnswers[currentQuestionIndex] ?? '';
                      _timer?.cancel();
                      _startTimer();
                    });
                  } else {
                    _submitQuiz();
                  }
                },
                child: Text(
                  currentQuestionIndex < parsedQuestions.length - 1
                      ? 'Next'
                      : 'Submit',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptions() {
    final options = parsedQuestions[currentQuestionIndex]['options'] as List;
    final correctAnswerLetter = parsedQuestions[currentQuestionIndex]['correctAnswer'];
    
    return List.generate(
      options.length,
      (index) {
        final optionLetter = _getOptionLetter(index);
        final option = options[index];
        final isSelected = selectedAnswer == option;
        final isCorrectAnswer = optionLetter == correctAnswerLetter;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: showResult
                    ? isCorrectAnswer
                        ? Colors.green
                        : isSelected
                            ? Colors.red
                            : Colors.grey[300]!
                    : isSelected
                        ? Colors.blue
                        : Colors.grey[300]!,
                width: isSelected || (showResult && isCorrectAnswer) ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: showResult
                  ? isCorrectAnswer
                      ? Colors.green.withOpacity(0.1)
                      : isSelected
                          ? Colors.red.withOpacity(0.1)
                          : Colors.white
                  : isSelected
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.white,
            ),
            child: ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: showResult
                        ? isCorrectAnswer
                            ? Colors.green
                            : isSelected
                                ? Colors.red
                                : Colors.grey[400]!
                        : isSelected
                            ? Colors.blue
                            : Colors.grey[400]!,
                  ),
                  color: isSelected ? Colors.blue : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    optionLetter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                option,
                style: TextStyle(
                  color: showResult
                      ? isCorrectAnswer
                          ? Colors.green
                          : isSelected
                              ? Colors.red
                              : Colors.black87
                      : isSelected
                          ? Colors.blue
                          : Colors.black87,
                ),
              ),
              trailing: showResult
                  ? isCorrectAnswer
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : isSelected
                          ? Icon(Icons.cancel, color: Colors.red)
                          : null
                  : null,
              onTap: !showResult
                  ? () {
                      setState(() {
                        selectedAnswer = option;
                        selectedAnswers[currentQuestionIndex] = option;
                      });
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewContent() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: parsedQuestions.length,
      itemBuilder: (context, index) {
        final question = parsedQuestions[index];
        final selectedAnswer = selectedAnswers[index] ?? '';
        final correctAnswer = question['correctAnswer'];

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  question['question'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                ...question['options'].map<Widget>((option) {
                  bool isSelected = selectedAnswer == option;
                  bool isCorrect = option.startsWith(correctAnswer);

                  Color getBackgroundColor() {
                    if (isSelected && isCorrect) return Color(0xFFE8F5E9);
                    if (isSelected && !isCorrect) return Color(0xFFFFEBEE);
                    if (isCorrect) return Color(0xFFE8F5E9);
                    return Colors.white;
                  }

                  Color getBorderColor() {
                    if (isSelected && isCorrect) return Color(0xFF4CAF50);
                    if (isSelected && !isCorrect) return Color(0xFFEF5350);
                    if (isCorrect) return Color(0xFF4CAF50);
                    return Colors.grey[300]!;
                  }

                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: getBackgroundColor(),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getBorderColor(),
                        width: 2,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      children: [
                        if (isSelected && isCorrect)
                          Icon(Icons.check_circle, color: Color(0xFF4CAF50))
                        else if (isSelected && !isCorrect)
                          Icon(Icons.cancel, color: Color(0xFFEF5350))
                        else if (isCorrect)
                          Icon(Icons.check_circle_outline,
                              color: Color(0xFF4CAF50))
                        else
                          Icon(Icons.radio_button_unchecked,
                              color: Colors.grey),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultView() {
    final percentage = (correctAnswersCount / parsedQuestions.length) * 100;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 24),
          // Score Circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getScoreColor(percentage),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${percentage.round()}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$correctAnswersCount out of ${parsedQuestions.length} correct',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),
          
          // Show Suggestions Button if score is below 80%
          if (percentage < 80)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SuggestionScreen(
                      quizId: widget.quizId,
                      studentId: Provider.of<AuthViewModel>(context, listen: false).user.id ?? 0,
                      studentName: Provider.of<AuthViewModel>(context, listen: false).user.username ?? 'Student',
                      percentage: percentage,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.lightbulb_outline),
              label: Text('Get Suggestions'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewView() {
    return Column(
      children: [
        // Review Header
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    showReview = false;
                  });
                },
              ),
              Text(
                'Review Answers',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Questions List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: parsedQuestions.length,
            itemBuilder: (context, index) {
              final question = parsedQuestions[index];
              final selectedAnswer = selectedAnswers[index];
              final correctAnswerLetter = question['correctAnswer'];
              final options = question['options'] as List;
              
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        question['question'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      ...List.generate(options.length, (optionIndex) {
                        final option = options[optionIndex];
                        final optionLetter = String.fromCharCode(65 + optionIndex);
                        final isSelected = selectedAnswer == option;
                        final isCorrectAnswer = optionLetter == correctAnswerLetter;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected && !isCorrectAnswer 
                                ? Colors.red.withOpacity(0.1)
                                : isCorrectAnswer 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected && !isCorrectAnswer 
                                  ? Colors.red
                                  : isCorrectAnswer 
                                      ? Colors.green
                                      : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected && !isCorrectAnswer 
                                      ? Colors.red
                                      : isCorrectAnswer 
                                          ? Colors.green
                                          : Colors.grey[400]!,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  optionLetter,
                                  style: TextStyle(
                                    color: isSelected && !isCorrectAnswer 
                                        ? Colors.red
                                        : isCorrectAnswer 
                                            ? Colors.green
                                            : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              option,
                              style: TextStyle(
                                color: isSelected && !isCorrectAnswer 
                                    ? Colors.red
                                    : isCorrectAnswer 
                                        ? Colors.green
                                        : Colors.black87,
                              ),
                            ),
                            trailing: isSelected || isCorrectAnswer
                                ? Icon(
                                    isCorrectAnswer 
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: isCorrectAnswer 
                                        ? Colors.green
                                        : Colors.red,
                                  )
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getOptionColor(bool isSelected, bool isCorrect) {
    if (isCorrect) return Colors.green.shade100;
    if (isSelected) return Colors.red.shade100;
    return Colors.white;
  }

  Color _getOptionBorderColor(bool isSelected, bool isCorrect) {
    if (isCorrect) return Colors.green;
    if (isSelected) return Colors.red;
    return Colors.grey.shade300;
  }

  Widget _buildGeneratedQuizActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _regenerateQuiz,
            icon: Icon(
              Icons.refresh,
              color: Colors.blue,
              size: 32,
            ),
            tooltip: 'Regenerate',
          ),
          IconButton(
            onPressed: () async {
              try {
                await _saveQuiz();
                setState(() {
                  isSaved = true;
                  isExplicitlySaved = true;
                });
                _showSuccessSnackBar('Quiz saved successfully');
              } catch (e) {
                _showErrorSnackBar('Failed to save quiz: $e');
              }
            },
            icon: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 32,
            ),
            tooltip: 'Correct',
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.cancel,
              color: Colors.red,
              size: 32,
            ),
            tooltip: 'Wrong',
          ),
        ],
      ),
    );
  }

 Future<void> _regenerateQuiz() async {
  try {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    // Get note IDs from either the quiz object or generated quiz
    List<int> noteIds = [];
    
    if (quiz?.noteIds.isNotEmpty == true) {
      noteIds = quiz!.noteIds;
    } else if (widget.generatedQuiz != null) {
      final rawNoteIds = widget.generatedQuiz!['note_ids'];
      debugPrint('Regenerating with raw note_ids: $rawNoteIds');
      
      if (rawNoteIds is List) {
        noteIds = rawNoteIds.map((e) => int.parse(e.toString())).toList();
      } else if (rawNoteIds is String) {
        noteIds = rawNoteIds.split(',')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => int.parse(e.trim()))
            .toList();
      }
    }

    debugPrint('Regenerating quiz with note IDs: $noteIds');

    if (noteIds.isEmpty) {
      throw Exception('No notes found for regeneration. Please select notes first.');
    }

    // Generate new quiz with the same notes
    final response = await _apiService.generateQuizFromMultipleNotes(
      widget.moduleId,
      noteIds,
    );

    setState(() {
      quiz = Quiz(
        id: widget.quizId,
        moduleId: widget.moduleId,
        title: response['title'],
        content: response['content'],
        isAIGenerated: true,
        isSaved: false,
        noteIds: noteIds,  // Preserve the note IDs
      );

      // Reset quiz states
      parsedQuestions.clear();
      currentQuestionIndex = 0;
      selectedAnswer = '';
      selectedAnswers.clear();
      showResult = false;
      showReview = false;
      isSaved = false;
      isExplicitlySaved = false;

      // Parse new content
      _parseQuizContent(response['content']);
    });

    _showSuccessSnackBar('Quiz regenerated successfully');
  } catch (e) {
    setState(() {
      _hasError = true;
      _errorMessage = _getReadableErrorMessage(e);
    });
    _showErrorSnackBar(_errorMessage);
    debugPrint('Error regenerating quiz: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

// Helper function for user-friendly error messages
String _getReadableErrorMessage(dynamic error) {
  if (error is FormatException) {
    return 'Invalid note ID format. Please ensure note IDs are valid integers.';
  }
  return error.toString();
}


  Future<void> _saveQuiz() async {
    try {
      if (quiz == null) throw Exception('No quiz to save');
      
      // Get note IDs from the current quiz
      List<int> noteIds = quiz!.noteIds;
      if (noteIds.isEmpty && widget.generatedQuiz != null) {
        var rawNoteIds = widget.generatedQuiz!['note_ids'];
        if (rawNoteIds is List) {
          noteIds = rawNoteIds.map((e) => int.parse(e.toString())).toList();
        } else if (rawNoteIds is String && rawNoteIds.isNotEmpty) {
          noteIds = rawNoteIds.split(',')
              .where((e) => e.trim().isNotEmpty)
              .map((e) => int.parse(e.trim()))
              .toList();
        }
      }
      
      await _apiService.saveAIQuiz(
        widget.moduleId,
        {
          'title': quiz!.title,
          'content': quiz!.content,
          'is_ai_generated': true,
          'note_ids': noteIds,  // Use the extracted note IDs
        },
      );
      
      setState(() {
        isSaved = true;
        isExplicitlySaved = true;
      });
    } catch (e) {
      debugPrint('Error saving quiz: $e');
      _showErrorSnackBar('Failed to save quiz: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildAttemptQuizButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ready to test your knowledge?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                hasQuizStarted = true;
                _startTimer();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(
                'Start Quiz',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _timer?.cancel();
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: _isLoading ? 'Loading Quiz...' : (quiz?.title ?? 'Quiz'),
        ),
        body: _buildBody(),
      ),
    );
  }

Widget _buildBody() {
  if (_isLoading) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading quiz...'),
        ],
      ),
    );
  }

  if (_hasError) {
    return Center(child: Text(_errorMessage));
  }

  if (!widget.isStudentEnrolled && isStudent) {
    return const Center(
      child: Text(
        'Please enroll in the course to access this quiz',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  if (quiz == null) {
    return const Center(child: Text('Quiz not found'));
  }

  if (parsedQuestions.isEmpty) {
    return const Center(child: Text('No questions available'));
  }

  if (showResult) {
    return Scaffold(
      body: SafeArea(
        child: showReview ? _buildReviewView() : _buildResultView(),
      ),
    );
  }

  return Column(
    children: [
      Expanded(
        child: showResult
            ? _buildResultView()
            : showReview
                ? _buildReviewView()
                : isStudent && !hasQuizStarted && !widget.isEditMode
                    ? _buildAttemptQuizButton()
                    : _buildQuizContent(),
      ),
      if (!isStudent && widget.generatedQuiz != null && !isSaved)
        _buildGeneratedQuizActions(),
    ],
  );
}


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

String _cleanText(String text) {
  return text
    .replaceAll(RegExp(r'\*+'), '') // Remove asterisks
    .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
    .trim();
}

String _truncateContent(String content, {int maxLength = 4000}) {
  if (content.length <= maxLength) return content;
  
  // Find the last complete question before the maxLength
  final RegExp questionPattern = RegExp(r'\d+[\).].*?(?=\d+[\).]|$)', dotAll: true);
  final matches = questionPattern.allMatches(content.substring(0, maxLength));
  
  if (matches.isEmpty) return content.substring(0, maxLength);
  
  // Get the last complete question
  final lastMatch = matches.last;
  return content.substring(0, lastMatch.end);
}

String _getReadableErrorMessage(dynamic error) {
  final errorStr = error.toString().toLowerCase();
  
  if (errorStr.contains('model not found')) {
    return 'AI service is temporarily unavailable. Please try again later.';
  }
  
  if (errorStr.contains('too long')) {
    return 'Selected notes are too long. Please select fewer notes or shorter content.';
  }
  
  if (errorStr.contains('rate limit')) {
    return 'Too many requests. Please wait a moment and try again.';
  }
  
  // Remove technical details from error messages
  final cleanError = error.toString()
    .replaceAll(RegExp(r'Exception: '), '')
    .replaceAll(RegExp(r'\[.*?\]'), '')
    .trim();
    
  return cleanError.isEmpty ? 
    'An unexpected error occurred. Please try again.' : 
    cleanError;
}
