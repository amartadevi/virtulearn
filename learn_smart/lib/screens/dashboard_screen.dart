import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:learn_smart/screens/widgets/bottom_navigation.dart';
import 'package:motion_tab_bar_v2/motion-tab-controller.dart';
import '../services/api_service.dart';
import '../models/course.dart';
import '../models/profile.dart';
import '../view_models/auth_view_model.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late MotionTabBarController _motionTabBarController;
  int _selectedIndex = 0;
  late ApiService _apiService;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  String _searchQuery = '';
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _motionTabBarController = MotionTabBarController(
      initialIndex: 0,
      length: 4,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');

      print(
          "Fetching profile data for user with token: ${authViewModel.user.token}");

      try {
        // Fetch user profile with courses
        final profile = await _apiService.fetchUserProfile();
        print("Profile fetched: ${profile.username}, Role: ${profile.role}");
        print("Enrolled courses: ${profile.enrolledCourses.length}");
        print("Created courses: ${profile.createdCourses.length}");

        setState(() {
          _profile = profile;
          _allCourses = _profile?.role == 'student'
              ? _profile?.enrolledCourses ?? []
              : _profile?.createdCourses ?? [];
          _filteredCourses = _allCourses;
          _isLoading = false;
        });
      } catch (e) {
        print("Error fetching profile: $e");
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _motionTabBarController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _motionTabBarController.index = index;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredCourses = _allCourses
          .where((course) =>
              course.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _showCreateCourseDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Course'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Course Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration:
                      const InputDecoration(hintText: 'Course Description'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                print("Create course canceled");
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () async {
                print(
                    "Creating course: ${nameController.text}, ${descriptionController.text}");
                await _apiService.createCourse(
                  nameController.text,
                  descriptionController.text,
                );
                Navigator.of(context).pop();
                setState(() {
                  // Refresh the courses after creation
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Home',
        onMenuPressed: () {
          Get.toNamed('/notifications');
          print("Menu pressed");
        },
        onSearchChanged: _onSearchChanged, // Implement search logic here
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? Center(child: Text(_errorMessage))
                      : _buildCourseListScreen(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        controller: _motionTabBarController,
        currentIndex: _selectedIndex,
      ),
      floatingActionButton:
          Provider.of<AuthViewModel>(context, listen: false).user.isStudent()
              ? null
              : FloatingActionButton(
                  onPressed: _showCreateCourseDialog,
                  child: const Icon(Icons.add),
                  backgroundColor: Colors.blue,
                ),
    );
  }

  Widget _buildCourseListScreen(BuildContext context) {
    if (_filteredCourses.isEmpty) {
      return const Center(
        child: Text('No courses available'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(_profile?.role == 'student'
                ? 'Enrolled Courses'
                : 'Created Courses'),
            const SizedBox(height: 10),
            _buildCourseGrid(_filteredCourses),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            Get.toNamed('/explore');
            print("See All clicked for $title");
          },
          child: Text(
            'See All',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: const Color(0xff00A2E8)),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseGrid(List<Course> courses) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.92,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseCard(Course course) {
    final user = Provider.of<AuthViewModel>(context, listen: false).user;

    return GestureDetector(
      onTap: () async {
        print("Course selected: ${course.name}");
        final isEnrolled = course.students.contains(user.id.toString());
        print("Is user enrolled: $isEnrolled");

        Get.toNamed('/course/${course.id}', arguments: {
          'isEnrolled': isEnrolled,
        });
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                  ? Image.network(
                      course.imageUrl!,
                      fit: BoxFit.cover,
                      height: 100,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey,
                          child: const Center(
                            child: Text(
                              'Image not available',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey,
                      child: const Center(
                        child: Text(
                          'No Image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${course.students.length} Students',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
