import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:learn_smart/models/datastore.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/models/course.dart';
import 'package:learn_smart/models/module.dart';

import '../models/user.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;

  CourseDetailScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late ApiService _apiService;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  User user = User(
      username: 'username',
      id: 0,
      imageUrl: 'imageUrl',
      token: 'token',
      refreshToken: 're-token',
      role: 'role',
      email: 'email');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');
      user = authViewModel.user;

      try {
        await _apiService.getCourseDetail(widget.courseId);
        await _apiService.fetchModules(widget.courseId);
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    });
  }

  bool _isEnrolled(AuthViewModel authViewModel) {
    final course = DataStore.getCourse(widget.courseId);
    return course?.students.contains(authViewModel.user.username) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final course = DataStore.getCourse(widget.courseId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: course?.name ?? 'Course Details',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(course),
                      const SizedBox(height: 24),
                      _buildCourseOverview(course),
                      const SizedBox(height: 24),
                      Text(
                        'Modules',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildModulesList(),
                    ],
                  ),
                ),
      bottomNavigationBar:
          authViewModel.user.isStudent() && !_isEnrolled(authViewModel)
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _showCourseCodeDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0095FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Enroll',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                )
              : null,
      floatingActionButton: authViewModel.user.isStudent() ? null : _buildFAB(),
    );
  }

  Widget _buildHeader(Course? course) {
    final courseImage = course?.imageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: courseImage != null
              ? Image.network(
                  courseImage,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/icons/default_course_image.png',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/screens/background.png'),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructed by',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  course?.createdByUsername ?? 'Not Found!',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCourseOverview(Course? course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          course?.description ?? 'No description available.',
          style: TextStyle(color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          course?.courseCode ?? 'No Course Code available.',
          style: TextStyle(color: Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildModulesList() {
    final modules = DataStore.getModules(widget.courseId);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: ModuleCard(
            isStudent: user.isStudent(),
            module: module,
            onTap: () {
              Get.toNamed('/module-detail', arguments: {
                'moduleId': module.id,
                'title': module.title,
              });
            },
            onEdit: () {
              _showEditModuleDialog(module);
            },
            onDelete: () async {
              await _apiService.deleteModule(module.id, widget.courseId);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        _showCreateModuleDialog();
      },
      child: const Icon(Icons.add),
      backgroundColor: Colors.blue,
    );
  }

  // Show course code input dialog
  void _showCourseCodeDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? _courseCode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Course Code'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Course Code'),
              onSaved: (value) {
                _courseCode = value;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a course code';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  if (_courseCode != null) {
                    await _enrollWithCourseCode(_courseCode!);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _enrollWithCourseCode(String courseCode) async {
    try {
      await _apiService.enrollInCourse(widget.courseId, courseCode);
      setState(() {});
    } catch (e) {
      print("Error enrolling in course: $e");
    }
  }

  void _showCreateModuleDialog() {
    final _formKey = GlobalKey<FormState>();
    String? _title;
    String? _description;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Module'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title'),
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
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onSaved: (value) {
                    _description = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  await _apiService.createModule(
                      widget.courseId, _title!, _description!);
                  Navigator.of(context).pop();
                  setState(() {});
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showEditModuleDialog(Module module) {
    final _formKey = GlobalKey<FormState>();
    String? _title = module.title;
    String? _description = module.description;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Module'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
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
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onSaved: (value) {
                    _description = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  await _apiService.updateModule(
                      module.id, widget.courseId, _title!, _description!);
                  Navigator.of(context).pop();
                  setState(() {});
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

class ModuleCard extends StatelessWidget {
  final Module module;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool? isStudent;

  ModuleCard(
      {required this.module,
      this.onEdit,
      this.onDelete,
      this.onTap,
      this.isStudent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/module_img.png',
                width: 50,
                height: 50,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      module.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null && !isStudent!)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: onEdit,
                ),
              if (onDelete != null && !isStudent!)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
