import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/profile.dart';
import '../models/note.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import 'notes_detail_screen.dart';

class SuggestionScreen extends StatefulWidget {
  final int quizId;
  final int studentId;
  final String studentName;
  final double percentage;

  const SuggestionScreen({
    Key? key,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.percentage,
  }) : super(key: key);

  @override
  _SuggestionScreenState createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  late ApiService _apiService;
  bool _isLoading = true;
  Map<String, dynamic>? _suggestions;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAndFetchSuggestions();
  }

  Future<void> _initializeAndFetchSuggestions() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
    _apiService.updateToken(authViewModel.user.token ?? '');
    await _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    try {
      final suggestions = await _apiService.fetchQuizSuggestions(
        widget.quizId,
        widget.studentId,
      );
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suggestions for student'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildSuggestionsContent(),
    );
  }

  Widget _buildSuggestionsContent() {
    if (widget.percentage >= 80) {
      return _buildExcellentPerformance();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceCard(),
          SizedBox(height: 20),
           if ((_suggestions!['related_notes'] as List?)?.isNotEmpty == true) ...[
              SizedBox(height: 20),
              _buildNotesSection(),
            ],
SizedBox(height: 20),
          if (_suggestions != null) ...[
            if ((_suggestions!['study_suggestions'] as List?)?.isNotEmpty == true)
              _buildSectionCard(
                'Study Suggestions',
                Icons.lightbulb_outline,
                Colors.orange,
                _suggestions!['study_suggestions'] as List<dynamic>,
              ),

            SizedBox(height: 20),

            if ((_suggestions!['key_concepts'] as List?)?.isNotEmpty == true)
              _buildSectionCard(
                'Key Concepts to Review',
                Icons.school_outlined,
                Colors.green,
                _suggestions!['key_concepts'] as List<dynamic>,
              ),

            SizedBox(height: 20),

            if ((_suggestions!['practice_exercises'] as List?)?.isNotEmpty == true)
              _buildSectionCard(
                'Practice Exercises',
                Icons.edit_note,
                Colors.purple,
                _suggestions!['practice_exercises'] as List<dynamic>,
              ),

           
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: _getScoreColor(widget.percentage),
                  size: 32,
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: ${widget.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(widget.percentage),
                      ),
                    ),
                    Text(
                      _getScoreMessage(widget.percentage),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    MaterialColor color,
    List<dynamic> items,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color[700]),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right, color: color[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    final notes = _suggestions!['related_notes'] as List;
    if (notes.isEmpty) {
      return SizedBox.shrink();  // Don't show section if no notes
    }
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.book, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  'Related Study Materials',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...notes.map((note) {
              // Debug print to verify note data
              debugPrint('Displaying note: ${note['title']} - ${note['topic']}');
              
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.description, color: Colors.blue),
                  title: Text(note['title']),
                  subtitle: Text(note['topic'] ?? 'No topic specified'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotesDetailScreen(
                          noteId: note['id'],
                          moduleId: note['module_id'],
                          isEditMode: false,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExcellentPerformance() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.amber,
          ),
          SizedBox(height: 16),
          Text(
            'Excellent Performance!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Keep up the great work!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 50) return Colors.yellow;
    return Colors.red;
  }

  String _getScoreMessage(double percentage) {
    if (percentage >= 80) return 'Excellent work!';
    if (percentage >= 60) return 'More practice needed';
    return 'Keep studying!';
  }
}
