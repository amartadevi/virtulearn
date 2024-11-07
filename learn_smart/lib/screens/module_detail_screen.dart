import 'package:flutter/material.dart';
import 'package:learn_smart/screens/NoteCreationScreen.dart';
import 'package:learn_smart/screens/QuizCreationScreen.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/models/datastore.dart';
import 'package:learn_smart/models/note.dart' as modelsNote;
import 'package:learn_smart/models/quiz.dart' as modelsQuiz;
import 'package:learn_smart/view_models/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'notes_detail_screen.dart';
import 'quiz_detail_screen.dart';

class ModuleDetailScreen extends StatefulWidget {
  final int moduleId;

  ModuleDetailScreen({
    Key? key,
    required this.moduleId,
  }) : super(key: key);

  @override
  _ModuleDetailScreenState createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen>
    with SingleTickerProviderStateMixin {
  String moduleTitle = "Loading...";
  String moduleDescription = "Loading description...";
  late TabController _tabController;
  late ApiService _apiService;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSelectionMode = false;
  List<int> _selectedNoteIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');

      await _loadModuleDetails();
    });
  }

  Future<void> _loadModuleDetails() async {
    try {
      final module = DataStore.getModuleById(widget.moduleId);

      setState(() {
        moduleTitle = module?.title ?? "Unknown Module Title";
        moduleDescription = module?.description ?? "No description available";
        _isLoading = false;
      });

      await _apiService.fetchNotes(widget.moduleId);
      await _apiService.fetchQuizzes(widget.moduleId);

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

  void _toggleNoteSelection(int noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  Future<void> _generateAIQuiz(int noteId) async {
    try {
      setState(() => _isLoading = true);
      
      final quizData = await _apiService.generateQuizFromNote(
        moduleId: widget.moduleId,
        noteId: noteId,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizDetailScreen(
              quizId: -1,
              moduleId: widget.moduleId,
              isStudentEnrolled: false,
              generatedQuiz: quizData,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quiz: $e')),
        );
      }
    }
  }

  Future<void> _generateQuiz() async {
    try {
      if (_selectedNoteIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one note')),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      final quizData = await _apiService.generateQuizFromMultipleNotes(
        widget.moduleId,
        _selectedNoteIds,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizDetailScreen(
              quizId: -1,
              moduleId: widget.moduleId,
              isStudentEnrolled: false,
              generatedQuiz: quizData,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quiz: $e')),
        );
      }
    }
  }

  Widget _buildNotesSection() {
    final notes = DataStore.getNotes(widget.moduleId);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    bool isTeacher = authViewModel.user.role == 'teacher';
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final modelsNote.Note note = notes[index];
                  return Card(
                    color: Colors.white,
                    elevation: 4.0, // Add elevation to give a shadow effect
                    margin:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 16.0), // Center the content
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.note,
                              color: Color.fromARGB(255, 217, 224, 229)),
                        ),
                        title: Text(
                          note.title ?? 'Untitled Note',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        trailing: isTeacher
                            ? _isSelectionMode
                                ? Checkbox(
                                    value: _selectedNoteIds.contains(note.id),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _toggleNoteSelection(note.id);
                                      });
                                    },
                                    activeColor: Colors.blue,
                                  )
                                : _buildNotePopupMenu(note)
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotesDetailScreen(
                                noteId: note.id,
                                moduleId: widget.moduleId,
                                isEditMode: true,
                              ),
                            ),
                          );
                        },
                        onLongPress: isTeacher
                            ? () {
                                _toggleNoteSelection(note.id);
                              }
                            : null,
                        selected: _selectedNoteIds.contains(note.id),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isTeacher)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _generateQuiz, // Handle quiz generation
                        icon: const Icon(Icons.auto_fix_high),
                        label: Text('Use AI to Create Quiz'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16), // Space between buttons
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAIInputDialog(context),
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Use AI to Create Notes'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ));
  }

  void _showEditNoteDialog(modelsNote.Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotesDetailScreen(
            noteId: note.id,
            moduleId: widget.moduleId,
            isEditMode: true), // Pass edit mode
      ),
    );
  }

  Widget _buildNotePopupMenu(modelsNote.Note note) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'Edit') {
          _showEditNoteDialog(note);
        } else if (value == 'Delete') {
          _confirmDeleteNote(note);
        } else if (value == 'Generate AI Quiz') {
          _generateAIQuiz(note.id);
        } else if (value == "Select") {
          setState(() {
            _isSelectionMode = !_isSelectionMode; // Toggle selection mode
          });
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'Select',
          child: Text('Select'),
        ),
        const PopupMenuItem(
          value: 'Generate AI Quiz',
          child: Text('Generate AI Quiz'),
        ),
        const PopupMenuItem(
          value: 'Edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'Delete',
          child: Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteNote(modelsNote.Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteNote(note);
    }
  }

  Widget _buildQuizzesSection() {
    final quizzes = DataStore.getQuizzes(widget.moduleId);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    bool isTeacher = authViewModel.user.role == 'teacher';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              // padding: const EdgeInsets.all(8.0),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final modelsQuiz.Quiz quiz = quizzes[index];
                return Card(
                  color: Colors
                      .white, // Set the background color of the card to white
                  elevation: 4.0, // Add elevation to give a shadow effect
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 16.0),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.question_answer,
                            color: Colors.white),
                      ),
                      title: Text(quiz.title ?? 'Untitled Quiz'),
                      trailing: isTeacher ? _buildQuizPopupMenu(quiz) : null,
                      onTap: () {
                        if (authViewModel.user.role == 'student') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizDetailScreen(
                                quizId: quiz.id,
                                moduleId: widget.moduleId,
                                isStudentEnrolled: true,
                              ),
                            ),
                          );
                        } else if (authViewModel.user.role == 'teacher') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizDetailScreen(
                                quizId: quiz.id,
                                moduleId: widget.moduleId,
                                isStudentEnrolled: false, // For teachers
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditQuizDialog(modelsQuiz.Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizDetailScreen(
            quizId: quiz.id,
            moduleId: widget.moduleId,
            isStudentEnrolled: false,
            isEditMode: false // Pass edit mode
            ),
      ),
    );
  }

  Future<void> _confirmDeleteQuiz(modelsQuiz.Quiz quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this quiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteQuiz(quiz);
    }
  }

  Widget _buildQuizPopupMenu(modelsQuiz.Quiz quiz) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'Edit') {
          _showEditQuizDialog(quiz);
        } else if (value == 'Delete') {
          await _confirmDeleteQuiz(quiz);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'Edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'Delete',
          child: Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _showAIInputDialog(BuildContext context) async {
    String topic = '';
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate AI Note'),
        content: TextField(
          onChanged: (value) => topic = value,
          decoration: InputDecoration(
            labelText: 'Enter topic',
            hintText: 'e.g., ACID properties',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (topic.isNotEmpty) {
                Navigator.pop(context);
                await _createAINote(topic: topic);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a topic')),
                );
              }
            },
            child: Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAINote({required String topic}) async {
    try {
      setState(() => _isLoading = true);
      
      final noteData = await _apiService.generateAINoteForModule(
        widget.moduleId,
        topic,
      );
      
      setState(() => _isLoading = false);

      // Navigate to the note detail screen with the generated content
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotesDetailScreen(
              noteId: -1, // Temporary ID for unsaved note
              moduleId: widget.moduleId,
              isEditMode: false,
              generatedNote: noteData, // Pass the generated content
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating AI note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote(modelsNote.Note note) async {
    try {
      await _apiService.deleteNote(moduleId: widget.moduleId, noteId: note.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note Deleted successfully')),
      );
      await _apiService.fetchNotes(widget.moduleId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting note: $e')),
      );
    }
  }

  Future<void> _deleteQuiz(modelsQuiz.Quiz quiz) async {
    try {
      await _apiService.deleteQuiz(
        moduleId: widget.moduleId,
        quizId: quiz.id,
      );
      await _apiService.fetchQuizzes(widget.moduleId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting quiz: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        toolbarHeight: 80,
        title: Text(
          moduleTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        actions: [
          if (Provider.of<AuthViewModel>(context, listen: false).user.role ==
              'teacher')
            Padding(
              padding: const EdgeInsets.only(right: 18.0),
              child: Material(
                color: Colors.white, // White background
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _showOptionDialog(context); // Show dialog on tap
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3), // Reduced padding for smaller size
                    child: Icon(Icons.add, color: Colors.blue), // Icon color
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text(_errorMessage))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModuleHeader(),
                    _buildTabs(),
                  ],
                ),
    );
  }

// Function to show dialog with two options: Quiz and Notes
  void _showOptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select an option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.note_add),
                title: Text('Notes'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          NoteCreationScreen(moduleId: widget.moduleId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.quiz),
                title: Text('Quiz'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          QuizCreationScreen(moduleId: widget.moduleId),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModuleHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            moduleTitle,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            moduleDescription,
            style: TextStyle(
                fontSize: 16, color: const Color.fromARGB(255, 155, 145, 145)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Expanded(
      child: Column(
        children: [
          TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black,
              tabs: [
                Tab(text: "Notes"),
                Tab(text: "Quizzes"),
              ],
              onTap: (index) {
                setState(() {
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildNotesSection(),
                        _buildQuizzesSection(),
                      ],
                    ),
                  );
                });
              }),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesSection(),
                _buildQuizzesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateNoteDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String? _title;
    String? _content;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Note'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Title'),
                  onSaved: (value) => _title = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Content'),
                  onSaved: (value) => _content = value,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    await _apiService.createNote(
                      widget.moduleId,
                      _title ?? 'Untitled',
                      _content ?? 'No content',
                    );
                    
                    // Refresh notes list
                    await _apiService.fetchNotes(widget.moduleId);
                    
                    // Get the latest notes
                    final notes = DataStore.getNotes(widget.moduleId);
                    
                    // Close the dialog
                    Navigator.of(context).pop();
                    
                    // Get the most recently created note (last in the list)
                    if (notes.isNotEmpty) {
                      final latestNote = notes.last;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotesDetailScreen(
                            noteId: latestNote.id,
                            moduleId: widget.moduleId,
                            isEditMode: false,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating note: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
