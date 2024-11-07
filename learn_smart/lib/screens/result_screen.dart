import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/models/datastore.dart';

import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      apiService.updateToken(authViewModel.user.token ?? '');

      await _fetchResults(apiService);
    });
  }

  Future<void> _fetchResults(ApiService apiService) async {
    try {
      final results = await apiService.fetchQuizResults(widget.quizId);
      DataStore.setQuizResults(widget.quizId, results);
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Quiz Results'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Text('Error: $_errorMessage'),
                )
              : _buildResultList(),
    );
  }

  Widget _buildResultList() {
    final results = DataStore.getQuizResults(widget.quizId);

    if (results.isEmpty) {
      return const Center(child: Text('No results available.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          title: Text('Score: ${result['score']}%'),
          subtitle: Text('Date: ${result['date_taken']}'),
          onTap: () {
            Get.toNamed('/result-detail', arguments: {
              'resultId': result['id'],
              'quizId': widget.quizId,
              'moduleId': widget.moduleId,
            });
          },
        );
      },
    );
  }
}
