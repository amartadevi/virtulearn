import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  final TextEditingController _suggestionController = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suggestions for ${widget.studentName}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Score: ${widget.percentage.round()}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: _getScoreColor(widget.percentage),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Add Suggestion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green;
    } else if (percentage >= 70) {
      return Colors.orange;
    } else if (percentage >= 50) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }
}
