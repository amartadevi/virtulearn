import 'course.dart'; // Assuming you have a Course model
import 'user.dart'; // Assuming you have a User model

class EnrollmentRequest {
  final int id;
  final Course course;
  final User student;
  final String status;

  EnrollmentRequest({
    required this.id,
    required this.course,
    required this.student,
    required this.status,
  });

  // Factory constructor to create an instance of EnrollmentRequest from JSON
  factory EnrollmentRequest.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      // Return a default EnrollmentRequest if the entire JSON is null
      return EnrollmentRequest(
        id: 0,
        course: Course(
          id: 0,
          name: 'Unknown Course',
          description: 'No description available',
          createdByUsername: 'Unknown',
          courseCode: 'N/A',
          students: ['nothing here'],
          imageUrl: 'no_image.png',
        ),
        student: User(
          username: 'Unknown Student',
          id: 0,
          imageUrl: 'default_profile.png',
          email: '',
          token: '',
          refreshToken: '',
          role: '',
        ),
        status: 'unknown',
      );
    }

    return EnrollmentRequest(
      id: json['id'] ?? 0, // Default value of 0 if 'id' is null
      course: Course.fromJson(json['course'] ??
          {
            'id': 0,
            'name': 'Unknown Course',
            'description': 'No description available',
            'createdByUsername': 'Unknown',
            'courseCode': 'N/A',
            'students': ['nothing here'],
            'imageUrl': 'no_image.png',
          }), // Handle null for 'course' field
      student: User.fromJson({
        'username': json['student_username'] ?? 'Unknown Student',
        'imageUrl': json['student_image'] ?? 'default_profile.png',
      }), // Handle null for 'student' field
      status: json['status'] ?? 'unknown', // Default value for 'status' if null
    );
  }
}

class StudentEnrollmentRequest {
  final String courseName;
  final String courseDescription;
  final String courseImage;
  final String status;

  StudentEnrollmentRequest({
    required this.courseName,
    required this.courseDescription,
    required this.courseImage,
    required this.status,
  });

  // Factory constructor to create an instance of EnrollmentRequest from JSON
  factory StudentEnrollmentRequest.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      // Return a default EnrollmentRequest if the entire JSON is null
      return StudentEnrollmentRequest(
        courseName: 'Unknown Course',
        courseDescription: 'No description available',
        courseImage: 'no_image.png',
        status: 'unknown',
      );
    }

    return StudentEnrollmentRequest(
      courseName: json['course_name'] ??
          'Unknown Course', // Use 'course_name' from response
      courseDescription: json['course_description'] ??
          'No description available', // Use 'course_description'
      courseImage: json['course_image'] ?? 'no_image.png', // Use 'course_image'
      status: json['enrollment_status'] ?? 'unknown', // Use 'enrollment_status'
    );
  }
}
