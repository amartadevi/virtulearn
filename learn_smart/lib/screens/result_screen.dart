import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/models/datastore.dart';

import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultScreen extends StatefulWidget {
  final int quizId;
  final int moduleId;

  ResultScreen({required this.quizId, required this.moduleId});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? quizResult;
  bool showReview = false;
  bool showSuggestions = false;
  Map<String, dynamic>? suggestions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      apiService.updateToken(authViewModel.user.token ?? '');
      await _fetchResult(apiService);
      
      // Fetch suggestions if score is below 80%
      if (quizResult != null) {
        final percentage = double.parse(quizResult!['percentage'].toString());
        if (percentage < 80.0) {
          await _fetchSuggestions(apiService);
        }
      }
    });
  }

  Future<void> _fetchResult(ApiService apiService) async {
    try {
      final response = await apiService.getStudentQuizReview(
        widget.quizId,
        Provider.of<AuthViewModel>(context, listen: false).user.id ?? 0,
      );
      
      setState(() {
        quizResult = response.first;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _fetchSuggestions(ApiService apiService) async {
    try {
      final userId = Provider.of<AuthViewModel>(context, listen: false).user.id ?? 0;
      final suggestionData = await apiService.fetchQuizSuggestions(
        widget.quizId,
        userId,
      );
      setState(() {
        suggestions = suggestionData;
      });
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Quiz Result'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildResultContent(),
    );
  }

  Widget _buildResultContent() {
    if (quizResult == null) {
      return const Center(child: Text('No result available.'));
    }

    final percentage = double.parse(quizResult!['percentage'].toString());
    final score = quizResult!['score'];
    final totalQuestions = quizResult!['total_questions'];
    final studentAnswers = quizResult!['student_answers'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 150,
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
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Score: $score/$totalQuestions',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _getScoreMessage(percentage),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => showReview = !showReview);
            },
            icon: Icon(showReview ? Icons.visibility_off : Icons.visibility),
            label: Text(showReview ? 'Hide Review' : 'Show Review'),
          ),
          if (percentage < 80.0 && suggestions != null) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => showSuggestions = !showSuggestions);
              },
              icon: Icon(Icons.lightbulb_outline),
              label: Text(showSuggestions ? 'Hide Suggestions' : 'View Suggestions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          if (showReview) ...[
            SizedBox(height: 16),
            _buildReviewSection(studentAnswers),
          ],
          if (showSuggestions && suggestions != null) ...[
            SizedBox(height: 16),
            _buildSuggestionsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewSection(Map<String, dynamic> studentAnswers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: studentAnswers.entries.map((entry) {
        final answer = entry.value as Map<String, dynamic>;
        final isCorrect = answer['is_correct'] as bool;
        
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${int.parse(entry.key) + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(answer['question'] as String),
                SizedBox(height: 8),
                Text(
                  'Your Answer: ${answer['selected_answer']}',
                  style: TextStyle(
                    color: isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isCorrect) ...[
                  SizedBox(height: 8),
                  Text(
                    'Correct Answer: ${answer['correct_answer']}',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Improvement Suggestions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            
            // Study Suggestions
            if (suggestions!['study_suggestions'] != null) ...[
              Text(
                'Study Tips:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(height: 8),
              ...List<String>.from(suggestions!['study_suggestions'])
                  .map((suggestion) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_right, color: Colors.blue),
                            Expanded(child: Text(suggestion)),
                          ],
                        ),
                      )),
            ],
            
            SizedBox(height: 16),
            
            // Key Concepts
            if (suggestions!['key_concepts'] != null) ...[
              Text(
                'Key Concepts to Review:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(height: 8),
              ...List<String>.from(suggestions!['key_concepts'])
                  .map((concept) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green),
                            Expanded(child: Text(concept)),
                          ],
                        ),
                      )),
            ],
            
            SizedBox(height: 16),
            
            // YouTube Links
            if (suggestions!['youtube_links'] != null) ...[
              Text(
                'Recommended Videos:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 8),
              ...List<String>.from(suggestions!['youtube_links'])
                  .map((link) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () async {
                            final url = Uri.parse(link);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_outline, color: Colors.red),
                              Expanded(
                                child: Text(
                                  link,
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(double percentage) {
    if (percentage >= 80) return 'Excellent!';
    if (percentage >= 60) return 'Good Job!';
    return 'Keep Practicing!';
  }
}
