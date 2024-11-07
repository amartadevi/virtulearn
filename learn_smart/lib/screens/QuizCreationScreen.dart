import 'package:flutter/material.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';

class QuizCreationScreen extends StatefulWidget {
  final int moduleId;

  QuizCreationScreen({required this.moduleId});

  @override
  _QuizCreationScreenState createState() => _QuizCreationScreenState();
}

class _QuizCreationScreenState extends State<QuizCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _quizTitle;
  String? _quizDescription;
  String? _quizType;
  String? _duration; // Duration field instead of category

  List<Map<String, dynamic>> _questions = [
    {
      "questionText": "",
      "optionA": "",
      "optionB": "",
      "optionC": "",
      "optionD": "",
      "correctAnswer": ""
    }
  ];

  late ApiService _apiService;
  bool _isQuizSaved = false;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
    _apiService.updateToken(authViewModel.user.token ?? '');
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        "questionText": "",
        "optionA": "",
        "optionB": "",
        "optionC": "",
        "optionD": "",
        "correctAnswer": ""
      });
    });
  }

  Widget _buildInputField({
    required String label,
    int maxLines = 1,
    required void Function(String?) onSaved,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blue),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      maxLines: maxLines,
      onSaved: onSaved,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0), // Set the height of the AppBar
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), // Left rounded corner
            bottomRight: Radius.circular(30), // Right rounded corner
          ),
          child: AppBar(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    SizedBox(width: 8),
                    Text('Create Quiz', style: TextStyle(fontSize: 22)),
                  ],
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white, // White background for the form
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildInputField(
                  label: 'Quiz Title',
                  onSaved: (value) => _quizTitle = value,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a quiz title'
                      : null,
                ),
                SizedBox(height: 16),
                _buildInputField(
                  label: 'Description',
                  maxLines: 3,
                  onSaved: (value) => _quizDescription = value,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a quiz description'
                      : null,
                ),
                SizedBox(height: 16),
                _buildInputField(
                  label: 'Quiz Type',
                  onSaved: (value) => _quizType = value,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a quiz type'
                      : null,
                ),
                SizedBox(height: 16),
                _buildInputField(
                  label: 'Duration (in minutes)', // Duration field
                  onSaved: (value) => _duration = value,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a duration'
                      : null,
                ),
                SizedBox(height: 20),
                // List of Questions
                ListView.builder(
                  itemCount: _questions.length,
                  shrinkWrap: true, // Important for scrolling
                  physics: NeverScrollableScrollPhysics(), // Disable scrolling
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Question ${index + 1}:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            _buildInputField(
                              label: 'Enter question text',
                              onSaved: (value) {
                                _questions[index]['questionText'] = value ?? '';
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please enter a question'
                                      : null,
                            ),
                            SizedBox(height: 8),
                            Text('Options:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            _buildInputField(
                              label: 'Option A',
                              onSaved: (value) {
                                _questions[index]['optionA'] = value ?? '';
                              },
                            ),
                            _buildInputField(
                              label: 'Option B',
                              onSaved: (value) {
                                _questions[index]['optionB'] = value ?? '';
                              },
                            ),
                            _buildInputField(
                              label: 'Option C',
                              onSaved: (value) {
                                _questions[index]['optionC'] = value ?? '';
                              },
                            ),
                            _buildInputField(
                              label: 'Option D',
                              onSaved: (value) {
                                _questions[index]['optionD'] = value ?? '';
                              },
                            ),
                            _buildInputField(
                              label: 'Correct Answer',
                              onSaved: (value) {
                                _questions[index]['correctAnswer'] =
                                    value ?? '';
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please enter the correct answer'
                                      : null,
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_isQuizSaved)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveQuiz,
                  child: Text('Save Quiz'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        child: Icon(Icons.add),
        tooltip: 'Add Question',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _saveQuiz() async {
    if (_formKey.currentState?.validate() == true) {
      _formKey.currentState?.save(); // Save form fields

      try {
        await _apiService.createQuiz(
          widget.moduleId,
          _quizTitle ?? 'Untitled',
          _quizDescription ?? 'No description',
          _quizType ?? 'General',
          _duration ?? '0', // Default duration if not provided
          _questions
              .map((question) => {
                    "question_text": question["questionText"],
                    "option_a": question["optionA"],
                    "option_b": question["optionB"],
                    "option_c": question["optionC"],
                    "option_d": question["optionD"],
                    "correct_answer": question["correctAnswer"],
                  })
              .toList(),
        );

        setState(() {
          _isQuizSaved = true;
        });

        Navigator.of(context).pop();
        await _apiService.fetchQuizzes(widget.moduleId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("Error saving quiz: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save quiz: $e')),
        );
      }
    }
  }
}
