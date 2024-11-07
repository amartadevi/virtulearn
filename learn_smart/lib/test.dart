// import 'dart:convert'; // Added to handle JSON encoding/decoding
// import 'package:http/http.dart' as http;

// class Datastore {
//   static Map<int, Course> courses = {};
//   static Map<int, List<Note>> notes = {};
//   static Map<int, List<Quiz>> quizzes = {};

//   static void addCourse(Course course) {
//     courses[course.id!] = course;
//   }

//   static Course? getCourse(int id) {
//     return courses[id];
//   }

//   static void removeCourse(int id) {
//     courses.remove(id);
//   }

//   static List<Course> getAllCourses() {
//     return courses.values.toList();
//   }

//   static void setNotes(int moduleId, List<Note> newNotes) {
//     notes[moduleId] = newNotes;
//   }

//   static List<Note> getNotes(int moduleId) {
//     return notes[moduleId] ?? [];
//   }

//   static void setQuizzes(int moduleId, List<Quiz> newQuizzes) {
//     quizzes[moduleId] = newQuizzes;
//   }

//   static List<Quiz> getQuizzes(int moduleId) {
//     return quizzes[moduleId] ?? [];
//   }
// }

// class User {
//   String? username;
//   String? token;
//   int? id;
//   String? imageUrl;
//   String? role;
//   String? email;

//   User({
//     required this.username,
//     required this.id,
//     required this.imageUrl,
//     required this.token,
//     required this.role,
//     required this.email,
//   });

//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       username: json['user']['username'],
//       id: json['user']['id'],
//       role: json['user']['role'],
//       imageUrl: json['user']['image'],
//       token: json['access'],
//       email: json['user']['email'],
//     );
//   }

//   User getUserProfile() {
//     return User(
//       username: this.username,
//       id: this.id,
//       imageUrl: this.imageUrl,
//       email: this.email,
//       token: this.token,
//       role: this.role,
//     );
//   }

//   bool isStudent() {
//     return role == 'student';
//   }

//   void display() {
//     print('Username: $username');
//     print('Email: $email');
//     print('Token: $token');
//   }
// }

// class Course {
//   final int? id;
//   final String? name;
//   final String? code;
//   final String? description;
//   final String? createdByUsername;
//   final String? createdByRole;
//   final List<String?> students;
//   final String imageUrl;

//   Course({
//     required this.id,
//     required this.name,
//     required this.code,
//     required this.description,
//     required this.createdByUsername,
//     required this.createdByRole,
//     required this.students,
//     required this.imageUrl,
//   });

//   factory Course.fromJson(Map<String, dynamic> json) {
//     return Course(
//       id: json['id'],
//       name: json['name'],
//       code: json['code'],
//       description: json['description'],
//       createdByUsername: json['created_by']['username'],
//       createdByRole: json['created_by']['role'],
//       students: List<String>.from(json['students']),
//       imageUrl: json['image'],
//     );
//   }
// }

// class Note {
//   final int id;
//   final String title;
//   final String content;
//   final int moduleId; // Linking to the module the note belongs to

//   Note({
//     required this.id,
//     required this.title,
//     required this.content,
//     required this.moduleId,
//   });

//   factory Note.fromJson(Map<String, dynamic> json) {
//     return Note(
//       id: json['id'] ?? 0,
//       title: json['title'] ?? 'Untitled',
//       content: json['content'] ?? 'No content',
//       moduleId: json['module'] ?? 0,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'title': title,
//       'content': content,
//       'module': moduleId,
//     };
//   }
// }

// class Quiz {
//   final int id;
//   final String title;
//   final String description;
//   final String quizType;
//   final String category;
//   final int moduleId; // Linking to the module the quiz belongs to

//   Quiz({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.quizType,
//     required this.category,
//     required this.moduleId,
//   });

//   factory Quiz.fromJson(Map<String, dynamic> json) {
//     return Quiz(
//       id: json['id'] ?? 0,
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//       quizType: json['quiz_type'] ?? '',
//       category: json['category'] ?? '',
//       moduleId: json['module'] ?? 0,
//     );
//   }
// }

// late User user;

// Future<void> login(String username, String password) async {
//   String baseUrl = 'http://127.0.0.1:8000/api/users/login/';
//   final response = await http.post(
//     Uri.parse(baseUrl),
//     headers: {
//       'Content-Type': 'application/json',
//     },
//     body: jsonEncode({
//       "username": username,
//       "password": password,
//     }),
//   );

//   if (response.statusCode == 200) {
//     final jsonResponse = jsonDecode(response.body); // Decode the response body
//     user = User.fromJson(jsonResponse);
//   } else {
//     print('Login failed: ${response.statusCode}');
//     print('Response body: ${response.body}');
//   }
// }

// Future<void> getCourses(String? token) async {
//   String baseUrl = 'http://127.0.0.1:8000/api/courses/';
//   final response = await http.get(
//     Uri.parse(baseUrl),
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//   );

//   if (response.statusCode == 200) {
//     List<dynamic> jsonResponse =
//         jsonDecode(response.body); // Decode the response as a List
//     Datastore.courses = {
//       for (var courseJson in jsonResponse)
//         Course.fromJson(courseJson).id!: Course.fromJson(courseJson)
//     }; // Convert each JSON object into a Course instance and add it to the Datastore

//     Datastore.getAllCourses().forEach((course) {
//       print(
//           'Course ID: ${course.id}, Course: ${course.name}, Created by: ${course.createdByUsername}, Course Description: ${course.description}');
//     });
//   } else {
//     print('Failed to load courses: ${response.statusCode}');
//     print('Response body: ${response.body}');
//   }
// }

// Future<void> getNotes(int moduleId, String? token) async {
//   String baseUrl = 'http://127.0.0.1:8000/api/modules/$moduleId/notes/';
//   final response = await http.get(
//     Uri.parse(baseUrl),
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//   );

//   if (response.statusCode == 200) {
//     List<dynamic> jsonResponse =
//         jsonDecode(response.body); // Decode the response as a List
//     Datastore.setNotes(
//       moduleId,
//       jsonResponse.map((json) => Note.fromJson(json)).toList(),
//     ); // Add notes to the datastore
//     print(Datastore.getNotes(moduleId));
//   } else {
//     print('Failed to load notes: ${response.statusCode}');
//     print('Response body: ${response.body}');
//   }
// }

// Future<void> getQuizzes(int moduleId, String? token) async {
//   String baseUrl = 'http://127.0.0.1:8000/api/modules/$moduleId/quizzes/';
//   final response = await http.get(
//     Uri.parse(baseUrl),
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//   );

//   if (response.statusCode == 200) {
//     List<dynamic> jsonResponse =
//         jsonDecode(response.body); // Decode the response as a List
//     Datastore.setQuizzes(
//       moduleId,
//       jsonResponse.map((json) => Quiz.fromJson(json)).toList(),
//     ); // Add quizzes to the datastore
//     print('Datastore: ' + Datastore.getQuizzes(moduleId).toString());
//   } else {
//     print('Failed to load quizzes: ${response.statusCode}');
//     print('Response body: ${response.body}');
//   }
// }

// void main() async {
//   await login('teacher', '123123');
//   user.getUserProfile();
//   await getCourses(user.token);
//   print(Datastore.getAllCourses());
//   int moduleId = 1;
//   await getNotes(moduleId, user.token);
//   await getQuizzes(moduleId, user.token);
// }

import 'dart:convert'; // Added to handle JSON encoding/decoding
import 'package:http/http.dart' as http;

class Datastore {
  static Map<int, Course> courses = {};
  static Map<int, List<Note>> notes = {};
  static Map<int, List<Quiz>> quizzes = {};

  static void addCourse(Course course) {
    courses[course.id!] = course;
  }

  static Course? getCourse(int id) {
    return courses[id];
  }

  static void removeCourse(int id) {
    courses.remove(id);
  }

  static List<Course> getAllCourses() {
    return courses.values.toList();
  }

  static void setNotes(int moduleId, List<Note> newNotes) {
    notes[moduleId] = newNotes;
  }

  static List<Note> getNotes(int moduleId) {
    return notes[moduleId] ?? [];
  }

  static void setQuizzes(int moduleId, List<Quiz> newQuizzes) {
    quizzes[moduleId] = newQuizzes;
  }

  static List<Quiz> getQuizzes(int moduleId) {
    return quizzes[moduleId] ?? [];
  }
}

// User class remains as it was
class User {
  String? username;
  String? token;
  int? id;
  String? imageUrl;
  String? role;
  String? email;

  User({
    required this.username,
    required this.id,
    required this.imageUrl,
    required this.token,
    required this.role,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['user']['username'],
      id: json['user']['id'],
      role: json['user']['role'],
      imageUrl: json['user']['image'],
      token: json['access'],
      email: json['user']['email'],
    );
  }

  bool isStudent() {
    return role == 'student';
  }

  void display() {
    print('Username: $username');
    print('Email: $email');
    print('Token: $token');
  }
}

class Profile extends User {
  List<Course> enrolledCourses;
  List<Course> createdCourses;

  Profile({
    required String? username,
    required int? id,
    required String? imageUrl,
    required String? token,
    required String? role,
    required String? email,
    required this.enrolledCourses,
    required this.createdCourses,
  }) : super(
          username: username,
          id: id,
          imageUrl: imageUrl,
          token: token,
          role: role,
          email: email,
        );

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: json['user']['username'] ?? 'not found',
      id: json['user']['id'] ?? 0,
      imageUrl: json['user']['image'] ?? 'not found',
      token: json['access'] ?? 'not found',
      role: json['user']['role'] ?? 'not found',
      email: json['user']['email'] ?? 'not found',
      enrolledCourses: (json['enrolled_courses'] as List<dynamic>?)
              ?.map((courseJson) => Course.fromJson(courseJson))
              .toList() ??
          [],
      createdCourses: (json['created_courses'] as List<dynamic>?)
              ?.map((courseJson) => Course.fromJson(courseJson))
              .toList() ??
          [],
    );
  }

  @override
  void display() {
    super.display();
    print('Enrolled Courses: ${enrolledCourses.length}');
    print('Created Courses: ${createdCourses.length}');
  }
}

class Course {
  final int? id;
  final String? name;
  final String? code;
  final String? description;
  final String? createdByUsername;
  final String? createdByRole;
  final List<String?> students;
  final String imageUrl;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.createdByUsername,
    required this.createdByRole,
    required this.students,
    required this.imageUrl,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      createdByUsername: json['created_by']['username'],
      createdByRole: json['created_by']['role'],
      students: List<String>.from(json['students']),
      imageUrl: json['image'],
    );
  }
}

// Simplified versions for Note and Quiz (these remain the same)
class Note {
  final int id;
  final String title;
  final String content;
  final int moduleId;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.moduleId,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled',
      content: json['content'] ?? 'No content',
      moduleId: json['module'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'module': moduleId,
    };
  }
}

class Quiz {
  final int id;
  final String title;
  final String description;
  final String quizType;
  final String category;
  final int moduleId;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.quizType,
    required this.category,
    required this.moduleId,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      quizType: json['quiz_type'] ?? '',
      category: json['category'] ?? '',
      moduleId: json['module'] ?? 0,
    );
  }
}

late Profile profile;

Future<void> login(String username, String password) async {
  String baseUrl = 'http://127.0.0.1:8000/api/users/login/';
  final response = await http.post(
    Uri.parse(baseUrl),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "username": username,
      "password": password,
    }),
  );

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    profile = Profile.fromJson(jsonResponse);
    profile.display(); // Debugging: print user profile
  } else {
    print('Login failed: ${response.statusCode}');
    print('Response body: ${response.body}');
  }
}

Future<void> getCourses(String? token) async {
  String baseUrl = 'http://127.0.0.1:8000/api/courses/';
  final response = await http.get(
    Uri.parse(baseUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> jsonResponse = jsonDecode(response.body);
    Datastore.courses = {
      for (var courseJson in jsonResponse)
        Course.fromJson(courseJson).id!: Course.fromJson(courseJson)
    };

    // Debugging: print all retrieved courses
    Datastore.getAllCourses().forEach((course) {
      print('Course ID: ${course.id}, Course: ${course.name}');
    });
  } else {
    print('Failed to load courses: ${response.statusCode}');
    print('Response body: ${response.body}');
  }
}

void main() async {
  await login('student', '123123');
  print(profile.enrolledCourses); // Debugging: print enrolled courses
  print(profile.createdCourses); // Debugging: print created courses

  await getCourses(profile.token);
  print(Datastore.getAllCourses());
}
