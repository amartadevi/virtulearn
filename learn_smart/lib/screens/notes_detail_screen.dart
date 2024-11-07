import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/models/datastore.dart';
import 'package:learn_smart/models/note.dart';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';

class NotesDetailScreen extends StatefulWidget {
  final int noteId;
  final int moduleId;
  final bool isEditMode;
  final Map<String, dynamic>? generatedNote;

  NotesDetailScreen({
    Key? key,
    required this.noteId,
    required this.moduleId,
    this.isEditMode = false,
    this.generatedNote,
  }) : super(key: key);

  @override
  _NotesDetailScreenState createState() => _NotesDetailScreenState();
}

class _NotesDetailScreenState extends State<NotesDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late Note note;
  late ApiService _apiService;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _topic;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');
      await _loadNoteDetails();
    });
  }

  Future<void> _loadNoteDetails() async {
    try {
      if (widget.generatedNote != null) {
        note = Note(
          id: -1,
          title: widget.generatedNote!['title'],
          content: widget.generatedNote!['content'],
          moduleId: widget.moduleId,
          isAIGenerated: true,
          topic: widget.generatedNote!['topic'],
          isSaved: false,
        );
      } else {
        final noteList = DataStore.getNotes(widget.moduleId);
        note = noteList.firstWhere((n) => n.id == widget.noteId);
      }
      _topic = note.topic;

      if (widget.isEditMode) {
        _titleController.text = note.title ?? '';
        _contentController.text = note.content ?? '';
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Note Details',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text(_errorMessage))
              : _buildNoteView(note),
    );
  }

  Widget _buildNoteView(Note note) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            note.title ?? 'Untitled',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Markdown(
            data: note.content.toString(),
            styleSheet: MarkdownStyleSheet(
              h1: TextStyle(fontSize: 24),
              h2: TextStyle(fontSize: 22),
              p: TextStyle(fontSize: 16),
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (widget.generatedNote != null || (note.isAIGenerated && !note.isSaved)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Correct (Check) Icon Button
            IconButton(
              onPressed: () async {
                try {
                  setState(() => _isLoading = true);
                  
                  await _apiService.saveAINote(
                    widget.moduleId,
                    {
                      'title': note.title,
                      'content': note.content,
                      'topic': note.topic,
                      'is_ai_generated': true,
                      'is_saved': true,
                    },
                  );

                  setState(() {
                    note.isSaved = true;
                  });

                  _showSuccessSnackBar('Note saved successfully.');
                  Navigator.pop(context);
                } catch (e) {
                  _showErrorSnackBar('Failed to save note: $e');
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              icon: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
              tooltip: 'Correct',
            ),
            
            // Regenerate Button (in the middle)
            ElevatedButton.icon(
              onPressed: () async {
                await _regenerateNote();
              },
              icon: Icon(Icons.refresh),
              label: Text('Regenerate'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            // Wrong (Cross) Icon Button
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
    } else {
      return Container();
    }
  }

  Future<void> _regenerateNote() async {
    if (_topic == null || _topic!.isEmpty) {
      _showErrorSnackBar('Please provide a topic to generate the note.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final generatedNote = await _apiService.generateAINoteForModule(
        widget.moduleId,
        _topic!,
      );

      setState(() {
        note = Note(
          id: note.id,
          title: generatedNote['title'],
          content: generatedNote['content'],
          moduleId: widget.moduleId,
          isAIGenerated: true,
          topic: _topic!,
          isSaved: false,
        );
      });

      _showSuccessSnackBar('Note regenerated. Click "Correct" to save.');
    } catch (e) {
      _showErrorSnackBar('Failed to generate the note: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
