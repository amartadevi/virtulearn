import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:learn_smart/screens/widgets/bottom_navigation.dart';
import 'package:motion_tab_bar_v2/motion-tab-controller.dart';
import '../services/api_service.dart';
import '../models/course.dart';
import '../view_models/auth_view_model.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  late MotionTabBarController _motionTabBarController;
  late ApiService _apiService;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _motionTabBarController = MotionTabBarController(
      initialIndex: 1,
      length: 4,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');

      print("Fetching all courses...");

      try {
        // Fetch all courses
        final courses = await _apiService.fetchCourses(); // Returns a list
        setState(() {
          _allCourses = courses;
          _filteredCourses = courses;
          _isLoading = false;
        });
      } catch (e) {
        print("Error fetching courses: $e");
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredCourses = _allCourses
          .where((course) =>
              course.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _motionTabBarController.index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Explore',
        onMenuPressed: () {
          print("Menu pressed");
        },
        onSearchChanged: _onSearchChanged, // Pass the search logic
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
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
        currentIndex: 1,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Courses',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onChanged: _onSearchChanged,
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
            _buildCourseGrid(_filteredCourses),
          ],
        ),
      ),
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
    return GestureDetector(
      onTap: () {
        Get.toNamed('/course/${course.id}');
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
                    Text(
                      '${course.students.length} Students',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
