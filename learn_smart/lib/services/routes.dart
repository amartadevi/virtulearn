import 'package:get/get.dart';
import 'package:learn_smart/screens/course_detail_screen.dart';
import 'package:learn_smart/screens/dashboard_screen.dart';
import 'package:learn_smart/screens/notifications_screen.dart';
import 'package:learn_smart/screens/module_detail_screen.dart';
import 'package:learn_smart/screens/quiz_detail_screen.dart';
import 'package:learn_smart/screens/result_screen.dart';

import '../screens/explore_screen.dart';
import '../screens/profile_screen.dart';

class AppRoutes {
  static final routes = [
    // Dashboard route
    GetPage(name: '/dashboard', page: () => DashboardScreen()),
    GetPage(name: '/explore', page: () => ExploreScreen()), // Add this line

    // Course detail route
    GetPage(
      name: '/course/:id',
      page: () => CourseDetailScreen(
        courseId: int.parse(Get.parameters['id'] ?? '0'),
      ),
    ),

    // Module detail route
    GetPage(
      name: '/module-detail',
      page: () => ModuleDetailScreen(
        moduleId: Get.arguments?['moduleId'] ?? 0,
      ),
    ),

    // Quiz detail route
    GetPage(
      name: '/quiz-detail',
      page: () => QuizDetailScreen(
        quizId: Get.arguments['quiz'], // Passing quiz object from arguments
        moduleId: Get.arguments['moduleId'] ?? 0,
        isStudentEnrolled: Get.arguments['isStudentEnrolled'] ?? false,
      ),
    ),

    // Result screen route
    GetPage(
      name: '/result',
      page: () => ResultScreen(
        quizId: Get.arguments?['quizId'] ?? 0,
        moduleId: Get.arguments?['moduleId'] ?? 0,
      ),
    ),

    // Notifications route
    GetPage(
      name: '/notifications',
      page: () => NotificationsScreen(), // Directly loading the screen
    ),
    GetPage(
      name: '/profile',
      page: () => ProfileScreen(), // Directly loading the screen
    ),

    // Enrollment requests route
    GetPage(
      name: '/enrollment-requests',
      page: () => NotificationsScreen(),
    ),
  ];
}
