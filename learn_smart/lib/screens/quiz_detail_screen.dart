import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/models/quiz.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';

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
  late Quiz quiz;
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
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');
      await _loadQuizDetails();
    });
  }

  Future<void> _loadQuizDetails() async {
    try {
      if (widget.generatedQuiz != null) {
        debugPrint('Loading generated quiz: ${widget.generatedQuiz}');
        
        // Extract content, handling both possible field names
        final content = widget.generatedQuiz!['quiz_content'] ?? 
                       widget.generatedQuiz!['content'] ??
                       '';
        
        quiz = Quiz(
          id: -1,
          title: widget.generatedQuiz!['title'] ?? 'Generated Quiz',
          content: content.toString(),
          isAIGenerated: true,
          isSaved: false,
        );

        debugPrint('Parsing quiz content: ${quiz.content}');
        _parseQuizContent(quiz.content);
        
        if (!widget.isEditMode && isStudent) {
          _startTimer();
        }
      } else {
        final response = await _apiService.getQuizDetail(widget.moduleId, widget.quizId);
        quiz = response;
        
        if (quiz.content != null) {
          debugPrint('Parsing quiz content from API: ${quiz.content}');
          _parseQuizContent(quiz.content);
          if (!widget.isEditMode && isStudent) {
            _startTimer();
          }
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading quiz: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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

  void _parseQuizContent(String content) {
    List<String> questionBlocks = content.split("\n\n");
    parsedQuestions.clear(); // Clear existing questions

    for (var block in questionBlocks) {
      List<String> lines = block.trim().split("\n");
      if (lines.length >= 4) { // Changed condition to handle varying number of options
        String questionText = lines[0].trim();
        List<String> options = [];
        String correctAnswer = '';

        // Extract options and correct answer
        for (int i = 1; i < lines.length; i++) {
          String line = lines[i].trim();
          if (line.startsWith('Correct Answer:')) {
            correctAnswer = _extractCorrectAnswer(line);
            break;
          } else if (line.isNotEmpty) {
            options.add(line);
          }
        }

        // Only add the question if we have both options and a correct answer
        if (options.isNotEmpty && correctAnswer.isNotEmpty) {
          parsedQuestions.add({
            'question': questionText,
            'options': options,
            'correctAnswer': correctAnswer,
          });
        }
      }
    }
  }

  String _extractCorrectAnswer(String line) {
    final correctAnswerPattern = RegExp(r'Correct Answer:\s*([A-D])');
    final match = correctAnswerPattern.firstMatch(line);
    return match?.group(1) ?? '';
  }

  // Helper method to convert option letter to index
  int _getOptionIndex(String letter) {
    return letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
  }

  // Helper method to get option letter from index
  String _getOptionLetter(int index) {
    return String.fromCharCode('A'.codeUnitAt(0) + index);
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
      String correctAnswer = parsedQuestions[i]['correctAnswer'];
      String? selectedAnswer = selectedAnswers[i];

      if (selectedAnswer != null &&
          correctAnswer == selectedAnswer.substring(0, 1)) {
        correctAnswersCount++;
      }
    }
  }

  void _submitQuiz() {
    _calculateResult();
    setState(() {
      showResult = true;
      _timer?.cancel();
    });
  }

  Widget _buildQuizContent() {
    if (parsedQuestions.isEmpty) {
      return Center(child: Text('No questions available'));
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${currentQuestionIndex + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  Text(
                    parsedQuestions[currentQuestionIndex]['question'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Options
                  ...List.generate(
                    (parsedQuestions[currentQuestionIndex]['options'] as List).length,
                    (index) {
                      final option = parsedQuestions[currentQuestionIndex]['options'][index];
                      final isSelected = selectedAnswer == option;
                      final correctAnswerLetter = parsedQuestions[currentQuestionIndex]['correctAnswer'];
                      final isCorrectAnswer = _getOptionLetter(index) == correctAnswerLetter;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isCorrectAnswer 
                                  ? Colors.green 
                                  : isSelected 
                                      ? Colors.blue 
                                      : Colors.grey[300]!,
                              width: isCorrectAnswer || isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isCorrectAnswer 
                                ? Colors.green.withOpacity(0.1)
                                : isSelected 
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.white,
                          ),
                          child: RadioListTile<String>(
                            value: option,
                            groupValue: selectedAnswer,
                            onChanged: (value) {
                              setState(() {
                                selectedAnswer = value!;
                                selectedAnswers[currentQuestionIndex] = value;
                              });
                            },
                            title: Row(
                              children: [
                                Text(
                                  '${_getOptionLetter(index)}) ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: isCorrectAnswer 
                                          ? Colors.green
                                          : isSelected 
                                              ? Colors.blue 
                                              : Colors.black87,
                                      fontWeight: isCorrectAnswer 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            secondary: isCorrectAnswer
                                ? Icon(Icons.check_circle, color: Colors.green)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Bottom action buttons
        if (widget.generatedQuiz != null && !isSaved)
          _buildGeneratedQuizActions(),
      ],
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
    int totalQuestions = parsedQuestions.length;
    double percentage = (correctAnswersCount / totalQuestions) * 100;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Quiz Completed!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A4A44),
          ),
        ),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '${percentage.round()}%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A4A44),
                ),
              ),
              Text(
                '$correctAnswersCount out of $totalQuestions correct',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showReview = true;
                });
              },
              child: Text('Review Answers'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Color(0xFF1A4A44),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(width: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Return'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGeneratedQuizActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!isExplicitlySaved) ...[
            // Save Button
            IconButton(
              onPressed: !isSaved ? _saveQuiz : null, // Disable if already saved
              icon: Icon(
                Icons.check_circle,
                color: !isSaved ? Colors.green : Colors.grey,
                size: 32,
              ),
              tooltip: !isSaved ? 'Save Quiz' : 'Quiz Already Saved',
            ),
            
            // Regenerate Button
            ElevatedButton.icon(
              onPressed: _regenerateQuiz,
              icon: Icon(Icons.refresh),
              label: Text('Regenerate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ] else ...[
            // Show saved status
            Text(
              'Quiz Saved',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          
          // Cancel/Close Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.cancel,
              color: Colors.red,
              size: 32,
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (isSaved) {
      _showErrorSnackBar('Quiz has already been saved');
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // Create quiz data map
      Map<String, dynamic> quizData = {
        'title': quiz.title ?? '',
        'content': quiz.content ?? '',
        'note_ids': widget.generatedQuiz?['note_ids'] ?? [], // Include note IDs
      };
      
      await _apiService.saveAIQuiz(
        widget.moduleId,
        quizData,
      );

      setState(() {
        isExplicitlySaved = true;
        isSaved = true;
      });
      
      _showSuccessSnackBar('Quiz saved successfully');
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('Failed to save quiz: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _regenerateQuiz() async {
    if (isSaved) {
      _showErrorSnackBar('Cannot regenerate a saved quiz');
      return;
    }

    try {
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _isLoading = true;
        // Clear existing quiz data
        selectedAnswer = '';
        selectedAnswers.clear();
        currentQuestionIndex = 0;
      });
      
      List<int> noteIds = [];
      if (widget.generatedQuiz != null && widget.generatedQuiz!['note_ids'] != null) {
        noteIds = List<int>.from(widget.generatedQuiz!['note_ids']);
      }
      
      if (noteIds.isEmpty) {
        throw Exception('No notes available for regeneration');
      }
      
      debugPrint('Regenerating quiz with note IDs: $noteIds');
      
      final response = await _apiService.generateQuizFromMultipleNotes(
        widget.moduleId,
        noteIds,
      );

      if (!mounted) return; // Check again after async operation

      // Update quiz with new content
      quiz = Quiz(
        id: -1,
        title: response['title'] ?? 'Generated Quiz',
        content: response['quiz_content'] ?? response['content'] ?? '',
        isAIGenerated: true,
        isSaved: false,
      );
      
      // Parse new quiz content
      if (quiz.content != null) {
        _parseQuizContent(quiz.content!);
      }
      
      if (!mounted) return; // Final mounted check before setState
      setState(() {
        isExplicitlySaved = false;
        isSaved = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar(e.toString());
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _timer?.cancel(); // Cancel timer before popping
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(title: 'Quiz'),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Regenerating quiz...'),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: showResult
                        ? _buildResultView()
                        : showReview
                            ? _buildReviewContent()
                            : _buildQuizContent(),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
