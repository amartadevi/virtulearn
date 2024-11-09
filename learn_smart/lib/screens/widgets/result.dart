// lib/screens/quiz_detail/result_view.dart
import 'package:flutter/material.dart';

class ResultView extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswersCount;
  final VoidCallback onReview;
  final VoidCallback onReturn;

  const ResultView({
    required this.totalQuestions,
    required this.correctAnswersCount,
    required this.onReview,
    required this.onReturn,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              onPressed: onReview,
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
              onPressed: onReturn,
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
}
