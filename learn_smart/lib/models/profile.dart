import 'user.dart'; // Import the User model
import 'course.dart';

// Extend Profile from the User model
class Profile extends User {
  List<Course> enrolledCourses;
  List<Course> createdCourses;

  Profile({
    String? username, // Nullable if necessary
    int? id, // Nullable if necessary
    String? imageUrl, // Nullable if necessary
    String? token, // Nullable if necessary
    String? role, // Nullable if necessary
    String? email, // Nullable if necessary
    String? refreshToken,
    required this.enrolledCourses,
    required this.createdCourses,
  }) : super(
          username: username ?? 'No Username', // Provide default if null
          id: id ?? 0, // Provide default if null
          imageUrl: imageUrl ?? 'No Image', // Provide default if null
          token: token ?? 'No Token', // Provide default if null
          refreshToken: refreshToken ?? 'No Token', // Provide default if null
          role: role ?? 'No Role', // Provide default if null
          email: email ?? 'No Email', // Provide default if null
        );

  // Factory constructor to parse JSON data into Profile
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: json['user']['username'],
      id: json['user']['id'],
      imageUrl: json['user']['image'],
      token: json['access'],
      role: json['user']['role'],
      email: json['user']['email'],
      // Default value as an empty list if enrolled_courses is null or missing
      enrolledCourses: (json['enrolled_courses'] as List<dynamic>?)
              ?.map((courseJson) => Course.fromJson(courseJson))
              .toList() ??
          [], // Use empty list if no enrolled courses
      // Default value as an empty list if created_courses is null or missing
      createdCourses: (json['created_courses'] as List<dynamic>?)
              ?.map((courseJson) => Course.fromJson(courseJson))
              .toList() ??
          [], // Use empty list if no created courses
    );
  }
}
