import 'package:flutter/material.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';

class NoteCreationScreen extends StatefulWidget {
  final int moduleId;

  NoteCreationScreen({required this.moduleId});

  @override
  _NoteCreationScreenState createState() => _NoteCreationScreenState();
}

class _NoteCreationScreenState extends State<NoteCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _content;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
    _apiService.updateToken(authViewModel.user.token ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Title TextField
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Title',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold), // Label color
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.blue), // Blue border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2), // Blue border on focus
                      ),
                    ),
                    onSaved: (value) {
                      _title = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 26),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Content',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold), // Label color
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.blue), // Blue border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2), // Blue border on focus
                      ),
                    ),
                    maxLines: 20, // Allows the content to grow without limit
                    keyboardType: TextInputType.multiline,
                    onChanged: (value) {
                      _content = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter content';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _saveNote();
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text('Create Note'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    try {
      await _apiService.createNote(
        widget.moduleId,
        _title ?? 'Untitled',
        _content ?? 'No content',
      );
      Navigator.of(context).pop();
      await _apiService.fetchNotes(widget.moduleId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Note saved successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error saving note: $e"); // Log error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save note: $e')),
      );
    }
  }
}
